import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

import 'support/watch_helpers.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localeTestValue =
        const Locale('ko');
  });

  testWidgets('start, run, swipe to pause, stop, and the run is queued',
      (tester) async {
    final queue = SyncQueue();
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(queue: queue, newId: () => 'watch_test'),
    ));

    expect(find.byKey(StartFace.buttonKey), findsOneWidget);
    await startRun(tester);
    expect(find.byKey(RunningFace.distanceKey), findsOneWidget);

    // 옆으로 밀면 조작 화면: 종료·재개 버튼과 "일시정지됨".
    await swipeToControls(tester);
    expect(find.text('일시정지됨'), findsOneWidget);
    expect(find.byKey(ControlsFace.resumeKey), findsOneWidget);

    await holdToStop(tester);
    expect(find.text('러닝 종료'), findsOneWidget);
    // 거리가 0이라 올릴 기록은 없다.
    expect(queue.length, 0);
  });
}
