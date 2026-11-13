import 'dart:async';

import '../../core/api/api_exception.dart';
import 'world_tour_models.dart';
import 'world_tour_pending_store.dart';

/// The two server calls World Tour needs. A fake stands in for tests.
abstract class WorldTourApi {
  Future<WorldTourMe> fetchMe();

  Future<WorldTourAttachResult> attach({
    required String missionId,
    required String activityId,
  });
}

/// What happened to one finished run.
sealed class WorldTourOutcome {
  const WorldTourOutcome();
}

/// The server linked the run (or had already linked it).
class WorldTourAttached extends WorldTourOutcome {
  const WorldTourAttached(this.result);
  final WorldTourAttachResult result;
}

/// The server refused for good (not verified, not yours, mission finished...).
/// The run does not count toward the trip.
class WorldTourNotCounted extends WorldTourOutcome {
  const WorldTourNotCounted(this.reason);
  final String reason;
}

/// No answer yet (offline, timeout, server error, validation not finished).
/// The run stays in the pending list and is sent again later.
class WorldTourRetryLater extends WorldTourOutcome {
  const WorldTourRetryLater();
}

/// Links finished runs to missions and survives an app restart: the run is
/// written to the pending list BEFORE the call, and removed only when the
/// server answers. Repeating a call is safe because the server is idempotent
/// per run.
class WorldTourCoordinator {
  WorldTourCoordinator({
    required this.api,
    required this.store,
    this.timeout = const Duration(seconds: 8),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Built on first use, so a screen that only reads an empty pending list
  /// never needs the network client.
  final WorldTourApi Function() api;
  final WorldTourPendingStore store;
  final Duration timeout;
  final DateTime Function() _clock;

  /// Server answers that mean "this run will never count".
  static const _permanent = {
    'activity_not_found',
    'activity_not_yours',
    'run_not_verified',
    'run_already_linked',
    'mission_completed',
    'mission_not_found',
  };

  Future<WorldTourOutcome> attachAfterRun({
    required String uid,
    required String missionId,
    required String activityId,
  }) async {
    try {
      await store.add(
        WorldTourPendingRun(
          uid: uid,
          missionId: missionId,
          activityId: activityId,
          savedAt: _clock(),
        ),
      );
    } catch (_) {
      // Storage trouble must not block the call itself.
    }
    return _send(uid, missionId, activityId);
  }

  /// Sends every pending run of [uid] again. Returns what each one became.
  Future<List<WorldTourOutcome>> retryPending(String uid) async {
    List<WorldTourPendingRun> pending;
    try {
      pending = (await store.load(now: _clock()))
          .where((run) => run.uid == uid)
          .toList();
    } catch (_) {
      return const [];
    }
    final outcomes = <WorldTourOutcome>[];
    for (final run in pending) {
      outcomes.add(await _send(uid, run.missionId, run.activityId));
    }
    return outcomes;
  }

  Future<WorldTourOutcome> _send(
    String uid,
    String missionId,
    String activityId,
  ) async {
    try {
      final result = await api()
          .attach(missionId: missionId, activityId: activityId)
          .timeout(timeout);
      await _forget(uid, activityId);
      return WorldTourAttached(result);
    } on ApiException catch (error) {
      if (_permanent.contains(error.detail)) {
        await _forget(uid, activityId);
        return WorldTourNotCounted(error.detail);
      }
      await _tried(uid, activityId);
      return const WorldTourRetryLater();
    } catch (_) {
      // Offline, timeout, token trouble, server error.
      await _tried(uid, activityId);
      return const WorldTourRetryLater();
    }
  }

  Future<void> _forget(String uid, String activityId) async {
    try {
      await store.remove(uid, activityId);
    } catch (_) {}
  }

  Future<void> _tried(String uid, String activityId) async {
    try {
      await store.markTried(uid, activityId);
    } catch (_) {}
  }
}
