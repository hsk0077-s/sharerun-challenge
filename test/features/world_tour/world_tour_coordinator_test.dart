import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_coordinator.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_models.dart';
import 'package:share_run_challenge/features/world_tour/world_tour_pending_store.dart';

import 'world_tour_support.dart';

WorldTourCoordinator _coordinator(
  FakeWorldTourApi api, {
  WorldTourPendingStore? store,
  Duration timeout = const Duration(seconds: 2),
  DateTime Function()? clock,
}) =>
    WorldTourCoordinator(
      api: () => api,
      store: store ?? WorldTourPendingStore(),
      timeout: timeout,
      clock: clock,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the run is written to the pending list before the server is called',
      () async {
    final store = WorldTourPendingStore();
    final api = _CheckingApi(store);

    final outcome = await _coordinator(api, store: store)
        .attachAfterRun(uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');

    expect(outcome, isA<WorldTourAttached>());
    expect(api.pendingWhileCalling, ['a1']);
    expect(await store.load(), isEmpty, reason: 'answered, so nothing to retry');
  });

  test('offline: the run stays pending and a restarted app sends it again',
      () async {
    final offline = FakeWorldTourApi()..attachError = const SocketException('x');
    final first = await _coordinator(offline)
        .attachAfterRun(uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');
    expect(first, isA<WorldTourRetryLater>());

    // "Restart": new store, new coordinator, same device storage.
    final pending = await WorldTourPendingStore().load();
    expect(pending.single.activityId, 'a1');
    expect(pending.single.missionId, 'france_eiffel');
    expect(pending.single.attempts, 1);

    final online = FakeWorldTourApi();
    final outcomes = await _coordinator(online).retryPending('u1');

    expect(outcomes.single, isA<WorldTourAttached>());
    expect(online.attachCalls, [('france_eiffel', 'a1')]);
    expect(await WorldTourPendingStore().load(), isEmpty);
  });

  test('sending the same run twice never counts it twice', () async {
    final api = FakeWorldTourApi();
    final coordinator = _coordinator(api);

    final one = await coordinator.attachAfterRun(
        uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');
    final two = await coordinator.attachAfterRun(
        uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');

    final a = (one as WorldTourAttached).result;
    final b = (two as WorldTourAttached).result;
    expect(a.alreadyAttached, isFalse);
    expect(b.alreadyAttached, isTrue);
    expect(b.progressKm, a.progressKm);
    expect(b.newlyCompleted, isFalse, reason: 'the stamp moment happens once');
  });

  test('pending keeps one entry per run', () async {
    final store = WorldTourPendingStore();
    final run = WorldTourPendingRun(
      uid: 'u1',
      missionId: 'france_eiffel',
      activityId: 'a1',
      savedAt: DateTime(2026, 11, 12),
    );
    await store.add(run);
    await store.add(run);
    expect(await store.load(now: DateTime(2026, 11, 12)), hasLength(1));
  });

  test('a refusal that can never change is dropped, not retried forever',
      () async {
    for (final detail in [
      'run_not_verified',
      'activity_not_yours',
      'mission_completed',
      'run_already_linked',
    ]) {
      SharedPreferences.setMockInitialValues({});
      final api = FakeWorldTourApi()
        ..attachError = ApiException(statusCode: 409, detail: detail);
      final outcome = await _coordinator(api).attachAfterRun(
          uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');
      expect(outcome, isA<WorldTourNotCounted>(), reason: detail);
      expect(await WorldTourPendingStore().load(), isEmpty, reason: detail);
    }
  });

  test('"not finalized yet" and server errors are retried later', () async {
    for (final error in [
      const ApiException(statusCode: 409, detail: 'run_not_finalized'),
      const ApiException(statusCode: 500, detail: 'boom'),
      TimeoutException('slow'),
    ]) {
      SharedPreferences.setMockInitialValues({});
      final api = FakeWorldTourApi()..attachError = error;
      final outcome = await _coordinator(api).attachAfterRun(
          uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');
      expect(outcome, isA<WorldTourRetryLater>(), reason: '$error');
      expect(await WorldTourPendingStore().load(), hasLength(1));
    }
  });

  test('a server that never answers does not hold the app', () async {
    final api = FakeWorldTourApi()..attachGate = Completer<void>();
    final outcome = await _coordinator(
      api,
      timeout: const Duration(milliseconds: 20),
    ).attachAfterRun(uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');
    expect(outcome, isA<WorldTourRetryLater>());
    expect(await WorldTourPendingStore().load(), hasLength(1));
  });

  test('only the signed-in user\'s pending runs are sent', () async {
    final offline = FakeWorldTourApi()..attachError = const SocketException('x');
    final c = _coordinator(offline);
    await c.attachAfterRun(uid: 'u1', missionId: 'france_eiffel', activityId: 'a1');
    await c.attachAfterRun(uid: 'u2', missionId: 'india_taj', activityId: 'b1');

    final online = FakeWorldTourApi();
    await _coordinator(online).retryPending('u2');

    expect(online.attachCalls, [('india_taj', 'b1')]);
    final left = await WorldTourPendingStore().load();
    expect(left.map((r) => r.activityId), ['a1']);
  });

  test('entries older than a week are forgotten', () async {
    final offline = FakeWorldTourApi()..attachError = const SocketException('x');
    await _coordinator(offline, clock: () => DateTime(2026, 11, 1)).attachAfterRun(
        uid: 'u1', missionId: 'france_eiffel', activityId: 'old');

    final later = await WorldTourPendingStore().load(now: DateTime(2026, 11, 20));
    expect(later, isEmpty);
  });

  test('nothing pending means the network client is never even built',
      () async {
    var built = false;
    final coordinator = WorldTourCoordinator(
      api: () {
        built = true;
        return FakeWorldTourApi();
      },
      store: WorldTourPendingStore(),
    );
    expect(await coordinator.retryPending('u1'), isEmpty);
    expect(built, isFalse);
  });

  test('models read the server json and pick the recommended and next trip',
      () {
    final fresh = WorldTourMe.fromJson(meJson());
    expect(fresh.missions.map((m) => m.missionId), [
      'france_eiffel',
      'india_taj',
      'japan_fuji',
      'egypt_pyramids',
      'usa_liberty',
    ]);
    expect(fresh.hasAnyProgress, isFalse);
    expect(fresh.recommended!.missionId, 'france_eiffel');

    final partway = WorldTourMe.fromJson(
      meJson(progress: {'india_taj': 0.5}, done: {'france_eiffel'}),
    );
    expect(partway.hasAnyProgress, isTrue);
    expect(partway.completedCount, 1);
    expect(partway.mission('india_taj')!.remainingKm, closeTo(1.5, 1e-9));
    expect(partway.mission('india_taj')!.fraction, closeTo(0.25, 1e-9));
    expect(partway.nextAfter('france_eiffel')!.missionId, 'india_taj');
    expect(partway.nextAfter('usa_liberty')!.missionId, 'india_taj');

    final all = WorldTourMe.fromJson(meJson(done: {
      'france_eiffel',
      'india_taj',
      'japan_fuji',
      'egypt_pyramids',
      'usa_liberty',
    }));
    expect(all.nextAfter('usa_liberty'), isNull);
  });
}

/// Records what was in the pending list at the moment of the call.
class _CheckingApi extends FakeWorldTourApi {
  _CheckingApi(this.store);

  final WorldTourPendingStore store;
  final pendingWhileCalling = <String>[];

  @override
  Future<WorldTourAttachResult> attach({
    required String missionId,
    required String activityId,
  }) async {
    pendingWhileCalling.addAll((await store.load()).map((r) => r.activityId));
    return super.attach(missionId: missionId, activityId: activityId);
  }
}
