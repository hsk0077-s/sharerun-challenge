import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/main.dart';
import 'package:share_run_wear/screens/watch_screens.dart';

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
    await tester.tap(find.byKey(StartFace.buttonKey));
    await tester.pump();
    expect(find.byKey(RunningFace.distanceKey), findsOneWidget);

    // 옆으로 밀면 조작 화면: 종료·재개 버튼과 "일시정지됨".
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 2000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('일시정지됨'), findsOneWidget);
    expect(find.byKey(ControlsFace.resumeKey), findsOneWidget);

    await tester.tap(find.byKey(ControlsFace.stopKey));
    await tester.pump();
    expect(find.text('러닝 종료'), findsOneWidget);
    // 거리가 0이라 올릴 기록은 없다.
    expect(queue.length, 0);
    expect(find.textContaining('올릴 기록 없음'), findsOneWidget);
  });
}
