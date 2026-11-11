import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/run_draft.dart';
import 'package:share_run_wear/core/run_session.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/sync_uploader.dart';
import 'package:share_run_wear/core/watch_account.dart';
import 'package:share_run_wear/core/watch_haptics.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

import 'support/watch_helpers.dart';

/// 네트워크를 켜고 끌 수 있고, 올라온 기록을 모아 두는 가짜 서버.
class _Server implements JsonPoster {
  var online = false;
  var delay = Duration.zero;
  final validated = <Map<String, Object?>>[];
  var securetoken = const HttpReply(200, {'id_token': 'id-2', 'expires_in': '3600'});

  @override
  Future<HttpReply> post(
    Uri uri,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    final url = uri.toString();
    if (url.contains('/auth/watch-pair')) {
      return const HttpReply(200, {'custom_token': 'c', 'nickname': '달림이'});
    }
    if (url.contains('signInWithCustomToken')) {
      return const HttpReply(200, {'idToken': 'id-1', 'refreshToken': 'r-1', 'expiresIn': '3600'});
    }
    if (!online) throw Exception('offline');
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (url.contains('securetoken')) return securetoken;
    if (url.endsWith('/actions/runs/validate')) {
      validated.add(body);
      return const HttpReply(200, {'decision': 'verified'});
    }
    return const HttpReply(404, {});
  }
}

WatchAccount _account(_Server server, MemoryStore store, {DateTime Function()? clock}) =>
    WatchAccount(
      store: store,
      poster: server,
      baseUrl: 'https://api.test',
      apiKey: 'key',
      clock: clock,
    );

Future<WatchAccount> _paired(_Server server, MemoryStore store) async {
  final account = _account(server, store);
  await account.pair('482910');
  return account;
}

PendingRun _run(String id, {double km = 1.0}) => PendingRun(
      activityId: id,
      distanceKm: km,
      durationSeconds: 360,
      heartRates: const [],
      startedAt: DateTime.utc(2026, 11, 10, 6),
      endedAt: DateTime.utc(2026, 11, 10, 6, 6),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localeTestValue =
        const Locale('ko');
  });

  group('3·2·1 카운트다운', () {
    testWidgets('시작을 누르면 3·2·1 뒤에 달리기가 시작되고, 숫자마다 진동한다', (tester) async {
      final haptics = FakeHaptics();
      final sensors = FakeSensors();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(queue: SyncQueue(), haptics: haptics, sensors: sensors, newId: () => 'a'),
      ));
      await tester.tap(find.byKey(StartFace.buttonKey));
      await tester.pump();
      expect(find.byKey(CountdownFace.numberKey), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(sensors.started, 0); // 아직 기록하지 않는다
      expect(haptics.patterns, [WatchHaptics.countdown]);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byKey(CountdownFace.numberKey), findsNothing);
      expect(find.byKey(RunningFace.distanceKey), findsOneWidget);
      expect(sensors.started, 1);
      expect(haptics.patterns, [
        WatchHaptics.countdown,
        WatchHaptics.countdown,
        WatchHaptics.countdown,
        WatchHaptics.go,
      ]);
      expect(WatchHaptics.go[1], greaterThan(WatchHaptics.countdown[1] * 3));
    });

    testWidgets('카운트다운 중에 탭하면 취소하고 시작 화면으로 돌아간다', (tester) async {
      final sensors = FakeSensors();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(queue: SyncQueue(), sensors: sensors),
      ));
      await tester.tap(find.byKey(StartFace.buttonKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(CountdownFace.numberKey));
      await tester.pump();
      expect(find.byKey(StartFace.buttonKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(sensors.started, 0);
      expect(find.byKey(RunningFace.distanceKey), findsNothing);
    });

    testWidgets('시계 타일로 열리면 곧바로 카운트다운을 시작한다', (tester) async {
      final events = FakeEvents()..autostart = true;
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(queue: SyncQueue(), events: events),
      ));
      await tester.pump();
      expect(find.byKey(CountdownFace.numberKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.byKey(RunningFace.distanceKey), findsOneWidget);
    });

    testWidgets('앱이 떠 있을 때 타일을 눌러도 시작 화면이면 카운트다운이 시작된다', (tester) async {
      final events = FakeEvents();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(queue: SyncQueue(), events: events),
      ));
      await tester.pump();
      expect(find.byKey(StartFace.buttonKey), findsOneWidget);
      events.fireAutostart();
      await tester.pump();
      expect(find.byKey(CountdownFace.numberKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      // 달리는 중에 또 누르면 아무 일도 없다.
      events.fireAutostart();
      await tester.pump();
      expect(find.byKey(CountdownFace.numberKey), findsNothing);
    });
  });

  group('길게 눌러 종료', () {
    testWidgets('한 번 탭해서는 끝나지 않고, 길게 눌러야 끝난다', (tester) async {
      final haptics = FakeHaptics();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(queue: SyncQueue(), haptics: haptics),
      ));
      await startRun(tester);
      await swipeToControls(tester);
      expect(find.text('길게 눌러 종료'), findsOneWidget);

      await tester.tap(find.byKey(ControlsFace.stopKey));
      await tester.pump();
      expect(find.byKey(SummaryFace.confirmKey), findsNothing);
      expect(haptics.patterns.where((p) => p == WatchHaptics.finished), isEmpty);

      await holdToStop(tester);
      expect(find.byKey(SummaryFace.confirmKey), findsOneWidget);
      expect(haptics.patterns.last, WatchHaptics.finished);
    });
  });

  group('달리는 화면: 탭하면 큰 숫자가 바뀐다', () {
    double fontOf(WidgetTester tester, Key key) =>
        tester.widget<Text>(find.byKey(key)).style!.fontSize!;

    testWidgets('거리 → 시간 → 페이스 → 거리', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RunFlow(queue: SyncQueue())));
      await startRun(tester);
      // 처음: 거리가 크다. 시간·페이스는 작게.
      expect(fontOf(tester, RunningFace.distanceKey), greaterThan(fontOf(tester, RunningFace.elapsedKey)));
      expect(fontOf(tester, RunningFace.distanceKey), greaterThan(fontOf(tester, RunningFace.paceKey)));

      await tester.tap(find.byKey(RunningFace.distanceKey));
      await tester.pump();
      expect(fontOf(tester, RunningFace.elapsedKey), greaterThan(fontOf(tester, RunningFace.distanceKey)));

      await tester.tap(find.byKey(RunningFace.elapsedKey));
      await tester.pump();
      expect(fontOf(tester, RunningFace.paceKey), greaterThan(fontOf(tester, RunningFace.distanceKey)));
      expect(fontOf(tester, RunningFace.paceKey), greaterThan(fontOf(tester, RunningFace.elapsedKey)));

      await tester.tap(find.byKey(RunningFace.paceKey));
      await tester.pump();
      expect(fontOf(tester, RunningFace.distanceKey), greaterThan(fontOf(tester, RunningFace.paceKey)));
    });

    testWidgets('세 값(거리·시간·페이스)이 언제나 한 번씩만 보인다', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RunFlow(queue: SyncQueue())));
      await startRun(tester);
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(RunningFace.distanceKey), findsOneWidget);
        expect(find.byKey(RunningFace.elapsedKey), findsOneWidget);
        expect(find.byKey(RunningFace.paceKey), findsOneWidget);
        await tester.tap(find.byKey(RunningFace.timeKey));
        await tester.pump();
      }
    });
  });

  group('경로 선 화면', () {
    test('점을 정사각형 안에 맞춰 그리고, 가로세로 비율을 지킨다', () {
      const size = Size(100, 100);
      // 위도 0.002도(약 222m) 위로, 경도 0.001도(약 111m) 옆으로.
      final pts = RoutePainter.project(const [(37.5, 127.0), (37.502, 127.0), (37.502, 127.001)], size);
      expect(pts, hasLength(3));
      for (final p in pts) {
        expect(p.dx, inInclusiveRange(0, 100));
        expect(p.dy, inInclusiveRange(0, 100));
      }
      // 북쪽이 위(작은 y). 처음 점이 가장 아래.
      expect(pts[0].dy, greaterThan(pts[1].dy));
      // 높이가 너비의 약 2배(경도는 cos(위도)를 곱해 줄어든다: 111m*cos37.5° ≈ 88m).
      final height = pts[0].dy - pts[1].dy;
      final width = pts[2].dx - pts[1].dx;
      expect(height / width, closeTo(222 / 88, 0.1));
    });

    test('점이 둘 미만이면 그릴 것이 없다', () {
      expect(RoutePainter.project(const [], const Size(10, 10)), isEmpty);
      expect(RoutePainter.project(const [(37.5, 127.0)], const Size(10, 10)), isEmpty);
    });

    test('같은 자리의 점들만 있어도 깨지지 않는다', () {
      final pts = RoutePainter.project(const [(37.5, 127.0), (37.5, 127.0)], const Size(100, 100));
      expect(pts, hasLength(2));
      expect(pts.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
    });

    test('긴 경로는 처음과 끝을 남기고 고르게 줄인다', () {
      final route = fakeRoute(2000);
      final small = downsampleFixes(route, kMaxRoutePoints);
      expect(small, hasLength(kMaxRoutePoints));
      expect(small.first, same(route.first));
      expect(small.last, same(route.last));
      // 짧으면 그대로.
      expect(downsampleFixes(fakeRoute(10), kMaxRoutePoints), hasLength(10));
      // 긴 달리기의 앞부분이 사라지지 않는다(끝만 남기지 않는다).
      final middle = small[kMaxRoutePoints ~/ 2];
      expect(route.indexOf(middle), inInclusiveRange(900, 1100));
    });

    testWidgets('오른쪽으로 밀면 경로 화면: 점이 없으면 GPS 대기 문구, 있으면 선', (tester) async {
      final sensors = FakeSensors();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(queue: SyncQueue(), sensors: sensors, pollInterval: const Duration(milliseconds: 100)),
      ));
      await startRun(tester);
      await swipeToRoute(tester);
      expect(find.byKey(RouteFace.waitingKey), findsOneWidget);
      expect(find.text('GPS 신호 기다리는 중'), findsOneWidget);

      sensors.snapshot = SensorSnapshot(distanceKm: 0.2, hasGps: true, route: fakeRoute(8));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(RouteFace.paintKey), findsOneWidget);
      expect(find.byKey(RouteFace.waitingKey), findsNothing);

      // 경로 화면에서는 일시정지되지 않는다. 가운데로 돌아와도 그대로 달리는 중.
      expect(find.byKey(ControlsFace.stopKey), findsNothing);
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(RunningFace.distanceKey), findsOneWidget);
    });
  });

  group('종료 후 짧은 요약', () {
    testWidgets('거리·시간·평균 페이스·경로 썸네일·폰 안내', (tester) async {
      final sensors = FakeSensors();
      var now = DateTime.utc(2026, 11, 10, 6);
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          queue: SyncQueue(),
          sensors: sensors,
          clock: () => now = now.add(const Duration(seconds: 30)),
          pollInterval: const Duration(milliseconds: 100),
        ),
      ));
      await startRun(tester);
      sensors.snapshot = SensorSnapshot(distanceKm: 1.2, hasGps: true, route: fakeRoute(30));
      await tester.pump(const Duration(milliseconds: 250));
      await swipeToControls(tester);
      await holdToStop(tester);

      expect(find.text('러닝 종료'), findsOneWidget);
      expect(find.byKey(SummaryFace.distanceKey), findsOneWidget);
      expect(find.text('1.20'), findsOneWidget);
      expect(find.byKey(SummaryFace.timeKey), findsOneWidget);
      expect(find.byKey(SummaryFace.paceKey), findsOneWidget);
      expect(find.byKey(SummaryFace.thumbKey), findsOneWidget);
      expect(find.byKey(SummaryFace.phoneHintKey), findsOneWidget);
      await tester.tap(find.byKey(SummaryFace.confirmKey));
      await tester.pump();
      expect(find.byKey(StartFace.buttonKey), findsOneWidget);
    });
  });

  group('폰 없이 혼자 기록하고 연결되면 올린다', () {
    testWidgets('오프라인에서 끝낸 기록은 워치에 저장돼 있다가, 연결이 생기면 한 번만 올라간다',
        (tester) async {
      final server = _Server();
      final store = MemoryStore();
      final account = await _paired(server, store);
      final queueStore = QueueStore(store);
      final queue = SyncQueue();
      final sensors = FakeSensors();
      final events = FakeEvents();
      var now = DateTime.utc(2026, 11, 10, 6);
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          account: account,
          queue: queue,
          queueStore: queueStore,
          sensors: sensors,
          events: events,
          clock: () => now = now.add(const Duration(seconds: 20)),
          pollInterval: const Duration(milliseconds: 100),
          newId: () => 'watch_offline_1',
        ),
      ));
      await startRun(tester);
      sensors.snapshot = SensorSnapshot(distanceKm: 1.0, hasGps: true, route: fakeRoute(12));
      await tester.pump(const Duration(milliseconds: 250));
      await swipeToControls(tester);
      await holdToStop(tester);
      await tester.pump(const Duration(milliseconds: 50));

      // 오프라인: 올라가지 못하고 워치 안(저장소)에 남는다.
      expect(server.validated, isEmpty);
      expect(queue.length, 1);
      final saved = await queueStore.load();
      expect(saved.length, 1);
      expect(saved.runs.single.activityId, 'watch_offline_1');
      expect(saved.runs.single.gpsRoute, isNotEmpty);

      // 확인을 누르면 시작 화면에 "올릴 기록 1"이 작게 보인다.
      await tester.tap(find.byKey(SummaryFace.confirmKey));
      await tester.pump();
      expect(find.byKey(StartFace.pendingKey), findsOneWidget);
      expect(find.text('올릴 기록 1'), findsOneWidget);

      // 연결이 생겨 안드로이드가 알려 준다.
      server.online = true;
      events.fireNetwork();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(server.validated, hasLength(1));
      expect(server.validated.single['activity_id'], 'watch_offline_1');
      expect(queue.length, 0);
      expect((await queueStore.load()).length, 0);
      expect(find.byKey(StartFace.pendingKey), findsNothing);

      // 연결 알림이 또 와도(재연결, 앞으로 나옴) 같은 기록은 다시 올라가지 않는다.
      events.fireNetwork();
      await tester.pump(const Duration(milliseconds: 50));
      expect(server.validated, hasLength(1));
    });

    testWidgets('올리지 못한 기록은 앱이 켜져 있는 동안 주기적으로 다시 시도한다', (tester) async {
      final server = _Server();
      final store = MemoryStore();
      final account = await _paired(server, store);
      final queue = SyncQueue()..add(_run('retry_1'));
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          account: account,
          queue: queue,
          retryEvery: const Duration(seconds: 30),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      expect(server.validated, isEmpty);
      expect(find.text('올릴 기록 1'), findsOneWidget);

      server.online = true;
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 50));
      expect(server.validated, hasLength(1));
      expect(queue.length, 0);
    });

    testWidgets('기록이 없으면 올릴 기록 표시가 없다', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RunFlow(queue: SyncQueue())));
      expect(find.byKey(StartFace.pendingKey), findsNothing);
    });
  });

  group('같은 기록이 두 번 올라가지 않는다', () {
    test('같은 id는 대기열에 한 번만 담긴다', () {
      final queue = SyncQueue();
      expect(queue.add(_run('same')), isTrue);
      expect(queue.add(_run('same')), isFalse);
      expect(queue.length, 1);
    });

    test('여러 곳에서 동시에 올리기를 시작해도 서버로는 한 번만 나간다', () async {
      final server = _Server()
        ..online = true
        ..delay = const Duration(milliseconds: 50);
      final store = MemoryStore();
      final account = await _paired(server, store);
      final queue = SyncQueue()..add(_run('dup_1'));
      SyncUploader uploader() => SyncUploader(account: account, queue: queue);
      final results = await Future.wait([
        uploader().flush(deviceId: 'dev-12345678'),
        uploader().flush(deviceId: 'dev-12345678'),
        uploader().flush(deviceId: 'dev-12345678'),
      ]);
      expect(server.validated, hasLength(1));
      expect(results.reduce((a, b) => a + b), 1);
      // 성공한 기록은 빠졌으니 다시 올려도 나가지 않는다.
      await uploader().flush(deviceId: 'dev-12345678');
      expect(server.validated, hasLength(1));
    });

    test('서버가 받은 기록의 activity_id는 워치가 만든 고유 번호 그대로다', () async {
      final server = _Server()..online = true;
      final account = await _paired(server, MemoryStore());
      final queue = SyncQueue()
        ..add(_run('watch_a'))
        ..add(_run('watch_b'));
      await SyncUploader(account: account, queue: queue).flush(deviceId: 'dev-12345678');
      expect(server.validated.map((b) => b['activity_id']), ['watch_a', 'watch_b']);
    });

    testWidgets('앱을 다시 켜서 저장된 기록을 불러와도 이미 올린 기록은 다시 나가지 않는다', (tester) async {
      final server = _Server()..online = true;
      final store = MemoryStore();
      final account = await _paired(server, store);
      final queueStore = QueueStore(store);
      final first = SyncQueue()..add(_run('once_1'));
      await queueStore.save(first);
      await SyncUploader(account: account, queue: first, onChanged: () => queueStore.save(first))
          .flush(deviceId: 'dev-12345678');
      expect(server.validated, hasLength(1));
      // 올리고 나서 저장소도 비었다 → 다시 켜도 올릴 것이 없다.
      final reopened = await queueStore.load();
      expect(reopened.length, 0);
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(account: account, queue: reopened, queueStore: queueStore),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      expect(server.validated, hasLength(1));
    });
  });

  group('달리는 도중 앱이 죽어도 기록이 남는다', () {
    testWidgets('몇 초마다 임시 기록을 저장하고, 정상 종료하면 지운다', (tester) async {
      final store = MemoryStore();
      final queueStore = QueueStore(store);
      final sensors = FakeSensors();
      var now = DateTime.utc(2026, 11, 10, 6);
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          queue: SyncQueue(),
          queueStore: queueStore,
          sensors: sensors,
          clock: () => now = now.add(const Duration(seconds: 1)),
          pollInterval: const Duration(milliseconds: 100),
          draftEvery: 2,
          newId: () => 'draft_run',
        ),
      ));
      await startRun(tester);
      sensors.snapshot = SensorSnapshot(distanceKm: 0.8, hasGps: true, route: fakeRoute(9));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(seconds: 3));
      final draft = await queueStore.loadDraft();
      expect(draft, isNotNull);
      expect(draft!.activityId, 'draft_run');
      expect(draft.distanceKm, closeTo(0.8, 1e-9));
      expect(draft.route, hasLength(9));

      await swipeToControls(tester);
      await holdToStop(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(await queueStore.loadDraft(), isNull);
      expect((await queueStore.load()).runs.single.activityId, 'draft_run');
    });

    testWidgets('죽은 뒤 다시 켜면 달리는 화면으로 이어진다', (tester) async {
      final server = _Server()..online = true;
      final store = MemoryStore();
      final account = await _paired(server, store);
      final queueStore = QueueStore(store);
      final savedAt = DateTime.now().toUtc().subtract(const Duration(seconds: 30));
      await queueStore.saveDraft(RunDraft(
        activityId: 'crashed_run',
        startedAt: savedAt.subtract(const Duration(seconds: 1180)),
        savedAt: savedAt,
        movingSeconds: 1180,
        distanceKm: 3.1,
        route: fakeRoute(20),
      ));
      final queue = SyncQueue();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(account: account, queue: queue, queueStore: queueStore),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(RunningFace.distanceKey), findsOneWidget);
      expect(find.text('3.10'), findsOneWidget);
      expect(queue.length, 0);
      expect(server.validated, isEmpty);
      expect(await queueStore.loadDraft(), isNotNull);

      await swipeToControls(tester);
      await holdToStop(tester);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(SummaryFace.confirmKey), findsOneWidget);
      expect(server.validated, hasLength(1));
      final body = server.validated.single;
      expect(body['activity_id'], 'crashed_run');
      expect(body['distance_km'], 3.1);
      expect((body['gps_route']! as List), hasLength(20));
      expect(await queueStore.loadDraft(), isNull);
    });

    testWidgets('오래전에 멈춘 임시 기록은 이어 달리지 않고 올릴 기록으로 남는다', (tester) async {
      final server = _Server()..online = true;
      final store = MemoryStore();
      final account = await _paired(server, store);
      final queueStore = QueueStore(store);
      await queueStore.saveDraft(RunDraft(
        activityId: 'old_run',
        startedAt: DateTime.utc(2026, 11, 10, 6),
        savedAt: DateTime.utc(2026, 11, 10, 6, 20),
        movingSeconds: 1180,
        distanceKm: 3.1,
        route: fakeRoute(20),
      ));
      final queue = SyncQueue();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          account: account,
          queue: queue,
          queueStore: queueStore,
          clock: () => DateTime.utc(2026, 11, 11, 6),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(RunningFace.distanceKey), findsNothing);
      expect(server.validated, hasLength(1));
      expect(server.validated.single['activity_id'], 'old_run');
      expect(await queueStore.loadDraft(), isNull);
    });

    testWidgets('센서가 0부터 다시 시작해도 저장된 거리에 이어서 쌓는다', (tester) async {
      final store = MemoryStore();
      final queueStore = QueueStore(store);
      final savedAt = DateTime.now().toUtc().subtract(const Duration(seconds: 20));
      await queueStore.saveDraft(RunDraft(
        activityId: 'resumed_run',
        startedAt: savedAt.subtract(const Duration(seconds: 600)),
        savedAt: savedAt,
        movingSeconds: 600,
        distanceKm: 2,
        steps: 100,
        route: fakeRoute(10),
      ));
      final sensors = FakeSensors()
        ..snapshot = SensorSnapshot(distanceKm: 0.3, steps: 40, hasGps: true, route: fakeRoute(3));
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          queue: SyncQueue(),
          queueStore: queueStore,
          sensors: sensors,
          pollInterval: const Duration(milliseconds: 100),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('2.30'), findsOneWidget);
    });

    test('거리가 없는 임시 기록은 올릴 기록이 되지 않고, 깨진 저장값은 무시한다', () {
      final empty = RunDraft(
        activityId: 'x',
        startedAt: DateTime.utc(2026, 11, 10, 6),
        savedAt: DateTime.utc(2026, 11, 10, 6, 1),
        movingSeconds: 60,
        distanceKm: 0,
      );
      expect(empty.toPendingRun(), isNull);
      expect(RunDraft.decode('{깨짐'), isNull);
      expect(RunDraft.decode(null), isNull);
      expect(RunDraft.decode(empty.encode())?.activityId, 'x');
    });
  });

  group('토큰이 정말 만료됐을 때만 다시 연결하게 한다', () {
    Future<(WatchAccount, _Server, MemoryStore)> setUpPaired() async {
      var now = DateTime(2026, 11, 10, 6);
      final server = _Server()..online = true;
      final store = MemoryStore();
      final account = _account(server, store, clock: () => now);
      await account.pair('482910');
      now = now.add(const Duration(hours: 2)); // ID 토큰은 만료, 갱신 토큰으로 새로 받아야 한다
      return (account, server, store);
    }

    test('만료·폐기를 뜻하는 오류(TOKEN_EXPIRED 등)면 연결을 지우고 다시 연결하게 한다', () async {
      for (final name in ['TOKEN_EXPIRED', 'USER_DISABLED', 'USER_NOT_FOUND', 'INVALID_REFRESH_TOKEN']) {
        final (account, server, store) = await setUpPaired();
        server.securetoken = HttpReply(400, {
          'error': {'code': 400, 'message': name},
        });
        expect(await account.idToken(), isNull, reason: name);
        expect(account.isPaired, isFalse, reason: name);
        expect(account.reconnectNeeded, isTrue, reason: name);
        expect(store.values['watch.reconnect_needed'], '1');
      }
    });

    test('키 제한·잘못된 요청 같은 다른 400·401은 연결을 그대로 둔다', () async {
      for (final reply in [
        const HttpReply(400, {'error': {'code': 400, 'message': 'API_KEY_INVALID'}}),
        const HttpReply(400, {'error': {'code': 400, 'message': 'INVALID_GRANT_TYPE'}}),
        const HttpReply(401, {'error': {'code': 401, 'message': 'UNAUTHENTICATED'}}),
      ]) {
        final (account, server, _) = await setUpPaired();
        server.securetoken = reply;
        expect(await account.idToken(), isNull);
        expect(account.isPaired, isTrue, reason: '${reply.body}');
        expect(account.reconnectNeeded, isFalse);
      }
    });

    test('네트워크 오류·5xx·429는 연결을 그대로 둔다', () async {
      final (account, server, _) = await setUpPaired();
      for (final status in [429, 500, 503]) {
        server.securetoken = HttpReply(status, const {});
        expect(await account.idToken(), isNull);
        expect(account.isPaired, isTrue, reason: '$status');
      }
      server.online = false; // 오프라인(예외)
      expect(await account.idToken(), isNull);
      expect(account.isPaired, isTrue);
      expect(account.reconnectNeeded, isFalse);
    });

    test('다시 연결하면 표시가 지워지고, 앱을 다시 켜도 표시는 남아 있다', () async {
      final (account, server, store) = await setUpPaired();
      server.securetoken = const HttpReply(400, {'error': {'code': 400, 'message': 'TOKEN_EXPIRED'}});
      await account.idToken();
      final reopened = _account(server, store);
      await reopened.load();
      expect(reopened.isPaired, isFalse);
      expect(reopened.reconnectNeeded, isTrue);
      await reopened.pair('111222');
      expect(reopened.isPaired, isTrue);
      expect(reopened.reconnectNeeded, isFalse);
      expect(store.values.containsKey('watch.reconnect_needed'), isFalse);
    });

    testWidgets('연결이 정말 만료되면 시작 화면 대신 "다시 연결" 안내가 뜨고, 나중에를 누르면 사라진다',
        (tester) async {
      final (account, server, _) = await setUpPaired();
      server.securetoken = const HttpReply(400, {'error': {'code': 400, 'message': 'TOKEN_EXPIRED'}});
      await account.idToken();
      await tester.pumpWidget(MaterialApp(home: RunFlow(account: account, queue: SyncQueue())));
      expect(find.byKey(PairingFace.codeKey), findsOneWidget);
      expect(find.text('연결이 만료됐어요. 다시 연결해 주세요'), findsOneWidget);
      await tester.tap(find.byKey(PairingFace.skipKey));
      await tester.pump();
      expect(find.byKey(StartFace.buttonKey), findsOneWidget);
      expect(account.reconnectNeeded, isFalse);
    });

    testWidgets('연결이 멀쩡하면 다시 연결 안내가 뜨지 않는다(한 번 연결하면 다시 묻지 않는다)',
        (tester) async {
      final (account, server, _) = await setUpPaired();
      server.securetoken = const HttpReply(500, {});
      await account.idToken();
      await tester.pumpWidget(MaterialApp(home: RunFlow(account: account, queue: SyncQueue())));
      expect(find.byKey(PairingFace.codeKey), findsNothing);
      expect(find.byKey(StartFace.buttonKey), findsOneWidget);
    });
  });
}
