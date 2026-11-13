import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/watch_platform.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

import 'support/watch_helpers.dart';

class _FakeReturn implements RunReturnControl {
  final calls = <bool>[];

  @override
  Future<void> setActive(bool active) async => calls.add(active);
}

void main() {
  group('달리는 중에 시계 화면으로 나가면 돌아오게 하는 신호', () {
    testWidgets('달리는 중에만 켜고, 일시정지·종료에서는 끈다', (tester) async {
      final control = _FakeReturn();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          queue: null,
          sensors: FakeSensors(),
          returnControl: control,
          pollInterval: const Duration(milliseconds: 100),
        ),
      ));
      await tester.pump();
      // 대기 중에는 켜지 않는다.
      expect(control.calls.where((on) => on), isEmpty);

      await startRun(tester);
      expect(control.calls.last, isTrue);

      await swipeToControls(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(control.calls.last, isFalse, reason: '일시정지면 돌아오지 않는다');

      await tester.tap(find.byKey(ControlsFace.resumeKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(control.calls.last, isTrue);

      await swipeToControls(tester);
      await holdToStop(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(SummaryFace.confirmKey), findsOneWidget);
      expect(control.calls.last, isFalse, reason: '종료되면 돌아오지 않는다');
    });

    testWidgets('같은 상태에서는 다시 알리지 않는다', (tester) async {
      final control = _FakeReturn();
      await tester.pumpWidget(MaterialApp(
        home: RunFlow(
          sensors: FakeSensors(),
          returnControl: control,
          pollInterval: const Duration(milliseconds: 100),
        ),
      ));
      await startRun(tester);
      final before = control.calls.length;
      await tester.pump(const Duration(seconds: 3));
      expect(control.calls.length, before);
    });
  });
}
