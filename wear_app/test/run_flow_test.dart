import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_wear/core/sync_queue.dart';
import 'package:share_run_wear/main.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localeTestValue =
        const Locale('ko');
  });

  testWidgets('start, run, pause, long press to finish, and the run is queued',
      (tester) async {
    final queue = SyncQueue();
    await tester.pumpWidget(MaterialApp(
      home: RunFlow(queue: queue, newId: () => 'watch_test'),
    ));

    expect(find.text('3km'), findsOneWidget);
    await tester.tap(find.text('탭해서 시작'));
    await tester.pump();
    expect(find.text('달리는 중'), findsOneWidget);

    await tester.tap(find.text('달리는 중'));
    await tester.pump();
    expect(find.text('탭해서 다시 시작\n길게 눌러 끝내기'), findsOneWidget);

    await tester.longPress(find.text('일시정지').first);
    await tester.pump();
    expect(find.text('끝'), findsOneWidget);
    // 거리가 0이라 올릴 기록은 없다.
    expect(queue.length, 0);
    expect(find.textContaining('올릴 기록 없음'), findsOneWidget);
  });
}
