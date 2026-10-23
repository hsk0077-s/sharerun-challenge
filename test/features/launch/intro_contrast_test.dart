import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/launch/intro_screen.dart';

void main() {
  testWidgets('every intro page has readable text on the night background',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.night,
        home: IntroScreen(onFinished: () {}),
      ),
    );
    await tester.pumpAndSettle();

    for (var page = 0; page < 3; page++) {
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      if (page < 2) {
        await tester.tap(find.byKey(IntroScreen.nextKey));
        await tester.pumpAndSettle();
      }
    }
  });
}
