import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/run_reward.dart';
import 'package:share_run_wear/core/run_session.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/sync_uploader.dart';
import 'package:share_run_wear/core/watch_account.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/l10n/watch_copy.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

import 'support/watch_helpers.dart';

class _Sensors implements WatchSensors {
  var snapshot = const SensorSnapshot();

  @override
  Future<Set<String>> requestPermissions() async => {'gps'};

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<SensorSnapshot> read() async => snapshot;
}

class _Poster implements JsonPoster {
  _Poster(this.replies);

  final List<HttpReply> replies;

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (uri.path == '/auth/watch-pair') {
      return const HttpReply(200, {'uid': 'u1', 'custom_token': 'c'});
    }
    if (uri.toString().contains('signInWithCustomToken')) {
      return const HttpReply(200, {
        'idToken': 'id-1',
        'refreshToken': 'refresh-1',
        'expiresIn': '3600',
      });
    }
    if (uri.path == '/actions/runs/validate') {
      return replies.isEmpty ? const HttpReply(503, {}) : replies.removeAt(0);
    }
    return const HttpReply(404, {});
  }
}

PendingRun _run(String id) => PendingRun(
      activityId: id,
      distanceKm: 3.2,
      durationSeconds: 1200,
      heartRates: const [150],
      startedAt: DateTime.utc(2026, 11, 28, 9),
      endedAt: DateTime.utc(2026, 11, 28, 9, 20),
    );

void main() {
  group('RunReward.fromReply reads only what the server decided', () {
    test('verified with VALUE is a confirmed amount', () {
      expect(
        RunReward.fromReply(200, {'verified': true, 'value_token_reward': 37}),
        isA<RunReward>()
            .having((r) => r.kind, 'kind', RunRewardKind.confirmed)
            .having((r) => r.value, 'value', 37),
      );
    });

    test('a partly capped reward still shows the credited amount', () {
      final r = RunReward.fromReply(
          200, {'verified': true, 'value_token_reward': 5, 'daily_cap_applied': true});
      expect(r!.kind, RunRewardKind.confirmed);
      expect(r.value, 5);
    });

    test('verified at the daily cap with nothing left', () {
      expect(
        RunReward.fromReply(
                200, {'verified': true, 'value_token_reward': 0, 'daily_cap_applied': true})!
            .kind,
        RunRewardKind.capReached,
      );
    });

    test('verified with no reward and no cap', () {
      expect(
        RunReward.fromReply(200, {'verified': true, 'value_token_reward': 0})!.kind,
        RunRewardKind.noReward,
      );
    });

    test('not verified, or a body the server refuses, did not count', () {
      expect(
        RunReward.fromReply(200, {'verified': false, 'value_token_reward': 99})!.kind,
        RunRewardKind.notCounted,
      );
      for (final status in [400, 409, 413, 422]) {
        expect(RunReward.fromReply(status, const {})!.kind, RunRewardKind.notCounted,
            reason: '$status');
      }
    });

    test('offline-like answers stay pending (null)', () {
      for (final status in [0, 401, 429, 500, 503]) {
        expect(RunReward.fromReply(status, const {}), isNull, reason: '$status');
      }
    });

    test('a missing or odd reward field is never invented', () {
      expect(RunReward.fromReply(200, {'verified': true})!.kind, RunRewardKind.noReward);
      expect(
        RunReward.fromReply(200, {'verified': true, 'value_token_reward': 'lots'})!.kind,
        RunRewardKind.noReward,
      );
    });
  });

  test('the uploader reports each final answer and nothing for a retry', () async {
    final poster = _Poster([
      const HttpReply(200, {'verified': true, 'value_token_reward': 12}),
      const HttpReply(422, {'detail': 'bad'}),
      const HttpReply(503, {}),
    ]);
    final account = WatchAccount(
      store: MemoryStore(),
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    final queue = SyncQueue()
      ..add(_run('a'))
      ..add(_run('b'))
      ..add(_run('c'));
    final seen = <String, RunReward>{};
    final uploader = SyncUploader(
      account: account,
      queue: queue,
      onResult: (id, reward) => seen[id] = reward,
    );

    await uploader.flush();

    expect(seen.keys, ['a', 'b']);
    expect(seen['a']!.kind, RunRewardKind.confirmed);
    expect(seen['a']!.value, 12);
    expect(seen['b']!.kind, RunRewardKind.notCounted);
    expect(queue.runs.map((r) => r.activityId), ['c']);
  });

  testWidgets('the summary shows the server line, and nothing without one',
      (tester) async {
    final session = RunSession()
      ..start()
      ..addDistance(2)
      ..finish();
    Future<void> pump(RunReward? reward) => tester.pumpWidget(
          MaterialApp(
            home: SummaryFace(session: session, onDone: () {}, reward: reward),
          ),
        );
    const en = Locale('en');

    await pump(null);
    expect(find.byKey(SummaryFace.rewardKey), findsNothing);

    await pump(RunReward.pending);
    expect(find.text(watchUi(en, 'rewardPending')), findsOneWidget);

    await pump(RunReward.checking);
    expect(find.text(watchUi(en, 'rewardChecking')), findsOneWidget);

    await pump(RunReward.fromReply(200, {'verified': true, 'value_token_reward': 40}));
    expect(find.text(watchUi(en, 'rewardConfirmed', n: 40)), findsOneWidget);
    expect(find.text('VALUE 40 confirmed'), findsOneWidget);

    await pump(RunReward.fromReply(
        200, {'verified': true, 'value_token_reward': 0, 'daily_cap_applied': true}));
    expect(find.text(watchUi(en, 'rewardCapReached')), findsOneWidget);

    await pump(RunReward.fromReply(200, {'verified': false}));
    expect(find.text(watchUi(en, 'rewardNotCounted')), findsOneWidget);
  });

  test('every reward line exists in all 11 watch languages', () {
    for (final key in [
      'rewardConfirmed',
      'rewardChecking',
      'rewardPending',
      'rewardCapReached',
      'rewardNone',
      'rewardNotCounted',
    ]) {
      final row = watchUiRows[key]!;
      expect(row, hasLength(watchLanguageOrder.length), reason: key);
      for (final text in row) {
        expect(text.trim(), isNotEmpty, reason: key);
      }
      expect(row[watchLanguageOrder.indexOf('ko')], isNot(row[1]), reason: key);
    }
    expect(watchUiRows['rewardConfirmed']!.every((t) => t.contains('{n}')), isTrue);
  });

  testWidgets('after a run the summary waits, then shows the server reward',
      (tester) async {
    final poster = _Poster([
      const HttpReply(200, {'verified': true, 'value_token_reward': 25}),
    ]);
    final account = WatchAccount(
      store: MemoryStore(),
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    final sensors = _Sensors();
    var now = DateTime.utc(2026, 11, 28, 1);
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(
        account: account,
        queue: SyncQueue(),
        sensors: sensors,
        newId: () => 'watch_reward_flow',
        clock: () => now = now.add(const Duration(seconds: 20)),
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));
    await startRun(tester);
    sensors.snapshot = const SensorSnapshot(distanceKm: 1.2, hasGps: true);
    await tester.pump(const Duration(milliseconds: 150));
    await swipeToControls(tester);
    await holdToStop(tester);
    await tester.pumpAndSettle();

    const en = Locale('en');
    expect(find.byKey(SummaryFace.rewardKey), findsOneWidget);
    expect(find.text(watchUi(en, 'rewardConfirmed', n: 25)), findsOneWidget);
  });

  testWidgets('offline after a run keeps the "confirmed after upload" line',
      (tester) async {
    final poster = _Poster([]); // every validate answers 503
    final account = WatchAccount(
      store: MemoryStore(),
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    final sensors = _Sensors();
    var now = DateTime.utc(2026, 11, 28, 1);
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(
        account: account,
        queue: SyncQueue(),
        sensors: sensors,
        newId: () => 'watch_reward_offline',
        clock: () => now = now.add(const Duration(seconds: 20)),
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));
    await startRun(tester);
    sensors.snapshot = const SensorSnapshot(distanceKm: 1.2, hasGps: true);
    await tester.pump(const Duration(milliseconds: 150));
    await swipeToControls(tester);
    await holdToStop(tester);
    await tester.pumpAndSettle();

    expect(find.text(watchUi(const Locale('en'), 'rewardPending')), findsOneWidget);
  });

  group('RunReward.forSummary', () {
    const answer = RunReward.checking; // any non-null answer
    test('hidden when nothing was queued to upload', () {
      expect(RunReward.forSummary(queued: false, answer: null, uploading: false), isNull);
      expect(RunReward.forSummary(queued: false, answer: null, uploading: true), isNull);
    });

    test('checking while an upload is on its way, else confirmed after upload', () {
      expect(RunReward.forSummary(queued: true, answer: null, uploading: true),
          RunReward.checking);
      expect(RunReward.forSummary(queued: true, answer: null, uploading: false),
          RunReward.pending);
    });

    test('the server answer wins', () {
      final confirmed = RunReward.fromReply(200, {'verified': true, 'value_token_reward': 3});
      expect(RunReward.forSummary(queued: true, answer: confirmed, uploading: true), confirmed);
      expect(RunReward.forSummary(queued: true, answer: answer, uploading: false), answer);
    });
  });

  test('new and changed lines', () {
    const ko = Locale('ko');
    expect(watchUi(ko, 'rewardChecking'), '적립 확인 중…');
    expect(watchUi(ko, 'rewardPending'), '기록을 올리면 적립이 확인돼요');
    expect(watchUi(ko, 'rewardNone'), '인정됐어요 · 이번엔 적립이 없어요');
    final row = watchUiRows['rewardChecking']!;
    expect(row, hasLength(watchLanguageOrder.length));
    expect(row.every((t) => t.trim().isNotEmpty), isTrue);
    expect(RunReward.checking.copyKey, 'rewardChecking');
  });

  testWidgets('a zero-distance run shows no reward line', (tester) async {
    final account = WatchAccount(
      store: MemoryStore(),
      poster: _Poster([]),
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    var now = DateTime.utc(2026, 11, 28, 1);
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(
        account: account,
        queue: SyncQueue(),
        sensors: _Sensors(),
        newId: () => 'watch_zero',
        clock: () => now = now.add(const Duration(seconds: 20)),
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));
    await startRun(tester);
    await swipeToControls(tester);
    await holdToStop(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SummaryFace), findsOneWidget);
    expect(find.byKey(SummaryFace.rewardKey), findsNothing);
  });

  testWidgets('online upload shows "checking" until the server answers', (tester) async {
    final poster = _GatedPoster([
      const HttpReply(200, {'verified': true, 'value_token_reward': 9}),
    ]);
    final account = WatchAccount(
      store: MemoryStore(),
      poster: poster,
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    final sensors = _Sensors();
    var now = DateTime.utc(2026, 11, 28, 1);
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(
        account: account,
        queue: SyncQueue(),
        sensors: sensors,
        newId: () => 'watch_checking',
        clock: () => now = now.add(const Duration(seconds: 20)),
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));
    await startRun(tester);
    sensors.snapshot = const SensorSnapshot(distanceKm: 1.2, hasGps: true);
    await tester.pump(const Duration(milliseconds: 150));
    await swipeToControls(tester);
    await holdToStop(tester);
    await tester.pump(const Duration(milliseconds: 300));

    const en = Locale('en');
    expect(find.byType(SummaryFace), findsOneWidget);
    expect(find.text(watchUi(en, 'rewardChecking')), findsOneWidget);
    expect(find.text(watchUi(en, 'rewardPending')), findsNothing);

    poster.gate.complete();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(watchUi(en, 'rewardConfirmed', n: 9)), findsOneWidget);
  });

  testWidgets('finish runs once: a second hold or a swipe while saving does nothing',
      (tester) async {
    final account = WatchAccount(
      store: MemoryStore(),
      poster: _Poster([]), // 503: the run stays in the queue so it can be counted
      baseUrl: 'https://api.test',
      apiKey: 'key',
    );
    await account.pair('482910');
    final sensors = _SlowStopSensors();
    final haptics = FakeHaptics();
    final queue = SyncQueue();
    var now = DateTime.utc(2026, 11, 28, 1);
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(
        account: account,
        queue: queue,
        sensors: sensors,
        haptics: haptics,
        newId: () => 'watch_finish_once',
        clock: () => now = now.add(const Duration(seconds: 20)),
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));
    await startRun(tester);
    sensors.snapshot = const SensorSnapshot(distanceKm: 1.2, hasGps: true);
    await tester.pump(const Duration(milliseconds: 150));
    await swipeToControls(tester);

    await holdToStop(tester); // finishing: waits on sensors.stop()
    expect(sensors.stops, 1);
    final buzzes = haptics.patterns.length;

    await holdToStop(tester); // second hold while saving
    await tester.fling(find.byType(PageView), const Offset(400, 0), 2000); // off the controls
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(sensors.stops, 1);
    expect(haptics.patterns.length, buzzes, reason: 'no second finish, no resume');

    sensors.stopGate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SummaryFace), findsOneWidget);
    expect(sensors.stops, 1);
    expect(queue.runs.map((r) => r.activityId), ['watch_finish_once']);
  });
}

/// Holds every validate reply until [gate] completes (an upload on its way).
class _GatedPoster extends _Poster {
  _GatedPoster(super.replies);

  final gate = Completer<void>();

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    if (uri.path == '/actions/runs/validate') await gate.future;
    return super.post(uri, body, headers: headers);
  }
}

/// `stop()` waits until [stopGate] completes, so finishing stays in progress.
class _SlowStopSensors extends _Sensors {
  final stopGate = Completer<void>();
  var stops = 0;

  @override
  Future<void> stop() async {
    stops++;
    await stopGate.future;
  }
}
