import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/watch_app_preview_screen.dart';

void main() {
  testWidgets('watch preview lists every platform marked 예정', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: SrcTheme.night,
      home: const WatchAppPreviewScreen(),
    ));
    for (final n in ['갤럭시 워치', '안드로이드 워치 (Wear OS)', '스마트 밴드 (샤오미 등)', '가민', '애플 워치']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('예정'), findsNWidgets(5));
  });
}
