import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/run_session.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/core/watch_haptics.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/l10n/watch_copy.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

import 'support/watch_helpers.dart';

/// 원형 워치(갤럭시 워치5: 40mm 396px, 44mm 450px)용 화면 5개.
const _sizes = [Size(396, 396), Size(450, 450), Size(300, 300)];

RunSession _runningSession({double km = 1.37, int seconds = 600}) {
  var now = DateTime.utc(2026, 11, 10, 6);
  final session = RunSession(clock: () => now);
  session.start();
  now = now.add(Duration(seconds: seconds));
  session.addDistance(km);
  return session;
}

Future<void> _pumpFace(WidgetTester tester, Widget face, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: face));
  await tester.pump();
}

/// 글자·아이콘·버튼이 모두 원 안에 있는지. 네 모서리가 지름 s인 원(여유 1px) 안이어야 한다.
void _expectInsideCircle(WidgetTester tester, Size size) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2 + 1;
  final finders = [
    find.byType(Text),
    find.byType(Icon),
    find.byType(Image),
    find.byType(TextButton),
    find.byType(InkWell),
  ];
  var checked = 0;
  for (final finder in finders) {
    for (final element in finder.evaluate()) {
      final box = element.renderObject;
      if (box is! RenderBox || !box.hasSize || box.size.isEmpty) continue;
      // FittedBox가 줄인 만큼(변환)까지 반영한 실제 화면상의 사각형.
      final rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
      // 화면 밖에 있는 다른 페이지(옆으로 미는 쪽)는 보지 않는다.
      if (rect.right <= 0 || rect.left >= size.width) continue;
      for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
        expect((corner - center).distance, lessThanOrEqualTo(radius),
            reason: '${element.widget} 가 원 밖으로 나갔다: $rect, 화면 $size');
      }
      checked++;
    }
  }
  expect(checked, greaterThan(0));
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localeTestValue =
        const Locale('ko');
  });

  group('원형 화면에서 가장자리가 잘리지 않는다', () {
    for (final size in _sizes) {
      final label = '${size.width.toInt()}px';

      testWidgets('① 페어링 $label', (tester) async {
        await _pumpFace(tester, PairingFace(onSubmit: (_) async => null, onSkip: () {}), size);
        _expectInsideCircle(tester, size);
        expect(find.text('폰에서 코드 입력'), findsOneWidget);
        expect(find.text('••• •••'), findsOneWidget);
      });

      testWidgets('① 페어링(오류 문구·입력 중) $label', (tester) async {
        await _pumpFace(
          tester,
          PairingFace(onSubmit: (_) async => 'bad_code', onSkip: () {}),
          size,
        );
        for (final d in '123456'.split('')) {
          await tester.tap(find.byKey(PairingFace.digitKey(int.parse(d))));
          await tester.pump();
        }
        await tester.pump();
        expect(find.text('코드가 맞지 않거나 만료됐어요.'), findsOneWidget);
        _expectInsideCircle(tester, size);
      });

      testWidgets('② 대기·시작 $label', (tester) async {
        await _pumpFace(
          tester,
          StartFace(onStart: () {}, tierName: '치타 골드', tierCode: 'cheetah'),
          size,
        );
        _expectInsideCircle(tester, size);
      });

      testWidgets('③ 달리는 중 $label', (tester) async {
        await _pumpFace(
          tester,
          RunningFace(session: _runningSession(km: 12.34, seconds: 4000), now: DateTime(2026, 11, 10, 15, 7)),
          size,
        );
        _expectInsideCircle(tester, size);
        expect(find.text('12.3'), findsOneWidget);
        expect(find.text('15:07'), findsOneWidget);
      });

      testWidgets('③ 달리는 중(1km 안내) $label', (tester) async {
        await _pumpFace(
          tester,
          RunningFace(session: _runningSession(km: 2.01), now: DateTime(2026, 11, 10, 15, 7), passedKm: 2),
          size,
        );
        _expectInsideCircle(tester, size);
        expect(find.text('2km 통과'), findsOneWidget);
        expect(find.text('200원 기부 예정'), findsOneWidget);
      });

      testWidgets('④ 일시정지·조작 $label', (tester) async {
        await _pumpFace(tester, ControlsFace(onResume: () {}, onFinish: () {}), size);
        _expectInsideCircle(tester, size);
        expect(find.text('일시정지됨'), findsOneWidget);
      });

      testWidgets('② 대기·시작(올릴 기록 표시) $label', (tester) async {
        await _pumpFace(
          tester,
          StartFace(onStart: () {}, tierName: '치타 골드', tierCode: 'cheetah', pendingCount: 12),
          size,
        );
        _expectInsideCircle(tester, size);
        expect(find.text('올릴 기록 12'), findsOneWidget);
      });

      testWidgets('3·2·1 카운트다운 $label', (tester) async {
        await _pumpFace(tester, CountdownFace(count: 3, onCancel: () {}), size);
        _expectInsideCircle(tester, size);
      });

      testWidgets('③ 달리는 중(시간·페이스가 큰 숫자일 때) $label', (tester) async {
        for (final focus in [1, 2]) {
          await _pumpFace(
            tester,
            RunningFace(
              session: _runningSession(km: 12.34, seconds: 4000),
              now: DateTime(2026, 11, 10, 15, 7),
              focus: focus,
            ),
            size,
          );
          _expectInsideCircle(tester, size);
        }
      });

      testWidgets('경로 화면(선·GPS 대기) $label', (tester) async {
        final session = _runningSession(km: 1.2);
        await _pumpFace(tester, RouteFace(session: session), size);
        expect(find.byKey(RouteFace.waitingKey), findsOneWidget);
        _expectInsideCircle(tester, size);
        // 대각선으로 달린 경로(모서리까지 닿기 쉬운 모양)도 원 안에 그려진다.
        session.replaceRoute([
          for (var i = 0; i < 40; i++)
            GpsFix(
              latitude: 37.5 + i * 0.0001,
              longitude: 127.0 + i * 0.00013,
              recordedAt: DateTime.utc(2026, 11, 10, 6, 0, i).toIso8601String(),
            ),
        ]);
        await _pumpFace(tester, RouteFace(session: session), size);
        expect(find.byKey(RouteFace.paintKey), findsOneWidget);
        final box = tester.getRect(find.byKey(RouteFace.paintKey));
        final pts = RoutePainter.project(routePoints(session.route), box.size);
        final center = Offset(size.width / 2, size.height / 2);
        for (final p in pts) {
          expect((box.topLeft + p - center).distance, lessThanOrEqualTo(size.width / 2));
        }
      });

      testWidgets('⑤ 결과 요약 $label', (tester) async {
        await _pumpFace(
          tester,
          SummaryFace(session: _runningSession(km: 5.43), onDone: () {}),
          size,
        );
        _expectInsideCircle(tester, size);
        expect(find.text('러닝 종료'), findsOneWidget);
        // 경로 썸네일까지 있는 요약도 원 안에 든다.
        final withRoute = _runningSession(km: 5.43)..replaceRoute(fakeRoute(50));
        await _pumpFace(tester, SummaryFace(session: withRoute, onDone: () {}), size);
        expect(find.byKey(SummaryFace.thumbKey), findsOneWidget);
        _expectInsideCircle(tester, size);
        expect(find.byKey(SummaryFace.confirmKey), findsOneWidget);
      });
    }
  });

  group('화면 구성', () {
    testWidgets('검은 배경에 흰 글자, 보조는 밝은 회색', (tester) async {
      await _pumpFace(tester, ControlsFace(onResume: () {}, onFinish: () {}), const Size(396, 396));
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, const Color(0xFF000000));
      expect(watchInk, const Color(0xFFFFFFFF));
      expect(watchMuted.computeLuminance(), greaterThan(0.4));
    });

    testWidgets('START 버튼은 화면 지름의 40% 이상이고 누르면 시작한다', (tester) async {
      var started = 0;
      await _pumpFace(tester, StartFace(onStart: () => started++), const Size(396, 396));
      final size = tester.getSize(find.byKey(StartFace.buttonKey));
      expect(size.width, greaterThanOrEqualTo(396 * 0.4));
      expect(size.height, size.width);
      expect(find.text('START'), findsOneWidget);
      await tester.tap(find.byKey(StartFace.buttonKey));
      expect(started, 1);
    });

    testWidgets('티어 값이 없으면 아래 줄을 숨기고, 있으면 이름을 보여 준다', (tester) async {
      await _pumpFace(tester, StartFace(onStart: () {}), const Size(396, 396));
      expect(find.byKey(StartFace.tierKey), findsNothing);
      await _pumpFace(tester, StartFace(onStart: () {}, tierName: '   '), const Size(396, 396));
      expect(find.byKey(StartFace.tierKey), findsNothing);
      await _pumpFace(
        tester,
        StartFace(onStart: () {}, tierName: '비글 실버', tierCode: 'beagle'),
        const Size(396, 396),
      );
      expect(find.byKey(StartFace.tierKey), findsOneWidget);
      expect(find.text('비글 실버'), findsOneWidget);
    });

    testWidgets('그림이 없으면 아이콘 자리표시가 그려진다', (tester) async {
      await _pumpFace(
        tester,
        StartFace(onStart: () {}, tierName: '늑대 브론즈', tierCode: 'wolf'),
        const Size(396, 396),
      );
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });

    testWidgets('조작 화면: 종료는 빨강, 재개는 초록, 페이지 점 두 개', (tester) async {
      var resumed = 0;
      var stopped = 0;
      await _pumpFace(
        tester,
        ControlsFace(onResume: () => resumed++, onFinish: () => stopped++),
        const Size(396, 396),
      );
      expect(tester.widget<Material>(find.byKey(ControlsFace.stopKey)).color, watchRed);
      expect(tester.widget<Material>(find.byKey(ControlsFace.resumeKey)).color, watchGreen);
      expect(find.byKey(ControlsFace.dotsKey), findsOneWidget);
      await tester.tap(find.byKey(ControlsFace.resumeKey));
      // 종료는 한 번 탭해서는 끝나지 않고, 길게 눌러야 끝난다.
      await tester.tap(find.byKey(ControlsFace.stopKey));
      expect(stopped, 0);
      await tester.longPress(find.byKey(ControlsFace.stopKey));
      expect((resumed, stopped), (1, 1));
    });

    test('다음 1km까지의 진행과 시간 표시', () {
      expect(RunningFace.kmProgress(0), 0);
      expect(RunningFace.kmProgress(1.37), closeTo(0.37, 1e-9));
      expect(RunningFace.kmProgress(2.0), 0);
      expect(RunningFace.kmProgress(double.nan), 0);
      expect(formatElapsed(const Duration(seconds: 65)), '1:05');
      expect(formatElapsed(const Duration(seconds: 3723)), '1:02:03');
      expect(formatElapsed(const Duration(seconds: -5)), '0:00');
      expect(RunningFace.clockText(DateTime(2026, 1, 1, 7, 5)), '07:05');
    });
  });

  group('기부 예정 문구는 서버 규칙(인증된 1km당 100원)을 따른다', () {
    test('계산', () {
      expect(verifiedRunDonationKrwPerKm, 100);
      expect(plannedDonationWon(1), 100);
      expect(plannedDonationWon(5.43), 543);
      expect(plannedDonationWon(0), 0);
      expect(plannedDonationWon(-1), 0);
      expect(plannedDonationWon(double.infinity), 0);
    });

    testWidgets('거리가 없는 결과 화면도 깨지지 않는다', (tester) async {
      await _pumpFace(
        tester,
        SummaryFace(session: RunSession(), onDone: () {}),
        const Size(396, 396),
      );
      expect(find.text('0.00'), findsOneWidget);
      expect(find.byKey(SummaryFace.thumbKey), findsNothing);
    });

    testWidgets('결과 화면에는 기부·다이아 문구가 없다(거리·시간·페이스·경로·폰 안내만)', (tester) async {
      await _pumpFace(
        tester,
        SummaryFace(session: _runningSession(km: 3), onDone: () {}),
        const Size(396, 396),
      );
      expect(find.textContaining('기부'), findsNothing);
      expect(find.textContaining('다이아'), findsNothing);
      expect(find.textContaining('DIA'), findsNothing);
      expect(find.text('자세한 건 폰에서 보기'), findsOneWidget);
    });
  });

  group('진동', () {
    test('패턴: 1km 긴 진동 1회, 일시정지·재개 짧은 진동 1회, 종료 2회', () {
      expect(WatchHaptics.kmPassed, [0, 700]);
      expect(WatchHaptics.tick, [0, 120]);
      expect(WatchHaptics.finished, [0, 180, 120, 180]);
      // 진동 횟수 = 켜는 구간 수.
      int pulses(List<int> p) => [for (var i = 1; i < p.length; i += 2) p[i]].length;
      expect(pulses(WatchHaptics.kmPassed), 1);
      expect(pulses(WatchHaptics.tick), 1);
      expect(pulses(WatchHaptics.finished), 2);
      expect(WatchHaptics.kmPassed[1], greaterThan(WatchHaptics.tick[1] * 3));
    });

    testWidgets('1km를 지나면 긴 진동과 안내, 일시정지·재개·종료 때 진동', (tester) async {
      final haptics = FakeHaptics();
      final sensors = FakeSensors();
      var now = DateTime.utc(2026, 11, 10, 6);
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          queue: SyncQueue(),
          sensors: sensors,
          haptics: haptics,
          clock: () => now,
          pollInterval: const Duration(milliseconds: 100),
          newId: () => 'haptics_test',
        ),
      ));
      await startRun(tester);
      // 카운트다운 3번 짧게, 시작할 때 한 번 길게.
      const start = [
        WatchHaptics.countdown,
        WatchHaptics.countdown,
        WatchHaptics.countdown,
        WatchHaptics.go,
      ];
      expect(haptics.patterns, start);

      sensors.snapshot = const SensorSnapshot(distanceKm: 0.6);
      await tester.pump(const Duration(milliseconds: 150));
      expect(haptics.patterns, start);

      sensors.snapshot = const SensorSnapshot(distanceKm: 1.05);
      await tester.pump(const Duration(milliseconds: 150));
      expect(haptics.patterns, [...start, WatchHaptics.kmPassed]);
      expect(find.text('1km 통과'), findsOneWidget);
      expect(find.text('100원 기부 예정'), findsOneWidget);

      // 같은 km에서는 다시 울리지 않는다.
      sensors.snapshot = const SensorSnapshot(distanceKm: 1.4);
      await tester.pump(const Duration(milliseconds: 150));
      expect(haptics.patterns, [...start, WatchHaptics.kmPassed]);

      // 안내는 몇 초 뒤 사라지고 현재 시각이 돌아온다.
      now = now.add(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1km 통과'), findsNothing);
      expect(find.byKey(RunningFace.timeKey), findsOneWidget);

      await swipeToControls(tester);
      expect(haptics.patterns.last, WatchHaptics.tick);
      expect(haptics.patterns.length, start.length + 2);

      await tester.tap(find.byKey(ControlsFace.resumeKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(haptics.patterns.length, start.length + 3);
      expect(haptics.patterns.last, WatchHaptics.tick);
      expect(find.byKey(RunningFace.distanceKey), findsOneWidget);

      await swipeToControls(tester);
      await holdToStop(tester);
      expect(haptics.patterns.last, WatchHaptics.finished);
      expect(find.byKey(SummaryFace.confirmKey), findsOneWidget);
      expect(find.text('1.40'), findsOneWidget);
    });

    testWidgets('재개 버튼을 누르면 달리는 화면으로 돌아간다', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RunFlow(queue: SyncQueue())));
      await startRun(tester);
      await swipeToControls(tester);
      await tester.tap(find.byKey(ControlsFace.resumeKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(RunningFace.distanceKey), findsOneWidget);
      // 정리: 끝낸다.
      await swipeToControls(tester);
      await holdToStop(tester);
    });
  });

  group('문구', () {
    test('새 화면 문구는 11개 언어에 다 있다', () {
      expect(missingWatchCopyKeys(), isEmpty);
      for (final entry in watchUiRows.entries) {
        expect(entry.value.length, watchLanguageOrder.length, reason: entry.key);
      }
    });

    test('{n} 자리와 언어별 문장', () {
      expect(watchUi(const Locale('ko'), 'kmPassed', n: 3), '3km 통과');
      expect(watchUi(const Locale('en'), 'kmPassed', n: 3), '3 km passed');
      expect(watchUi(const Locale('ja'), 'donationPlanned', n: 100), '100ウォン寄付予定');
      expect(watchUi(const Locale('xx'), 'stop'), 'Stop');
    });

    test('문구에 쉐어런 이름이나 금지어를 넣지 않았다', () {
      const banned = ['월드컵', '올림픽', 'FIFA', 'Olympic', 'AI'];
      for (final row in watchUiRows.values) {
        for (final text in row) {
          for (final word in banned) {
            expect(text.contains(word), isFalse, reason: text);
          }
        }
      }
    });
  });
}
