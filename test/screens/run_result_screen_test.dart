import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/jena_validation/models/jena_validation_result.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
import 'package:share_run_challenge/screens/run_result_screen.dart';

Future<void> _open(WidgetTester tester, JenaValidationResult result) async {
  if (tester.view.physicalSize.height < 2000) {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('ko', 'KR'),
        supportedLocales: ShareRunLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RunResultScreen(
          activityId: 'a1',
          result: result,
          routePoints: const [],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('never shows the internal decision code', (tester) async {
    await _open(
      tester,
      const JenaValidationResult(
        verified: false,
        decision: JenaDecision.rejectedUnknown,
        reason: 'x',
        reasonCode: 'distance_too_short',
        valueTokenReward: 0,
      ),
    );
    expect(find.textContaining('rejectedUnknown'), findsNothing);
    expect(find.textContaining('판정'), findsNothing);
    expect(find.textContaining('VALUE 보상'), findsNothing);
    expect(find.textContaining('최소 거리'), findsOneWidget);
  });

  testWidgets('a verified run with no reward hides the reward line',
      (tester) async {
    await _open(
      tester,
      const JenaValidationResult(
        verified: true,
        decision: JenaDecision.verified,
        reason: 'ok',
        valueTokenReward: 0,
      ),
    );
    expect(find.textContaining('VALUE 보상'), findsNothing);
  });

  testWidgets('a verified run with a reward shows it', (tester) async {
    await _open(
      tester,
      const JenaValidationResult(
        verified: true,
        decision: JenaDecision.verified,
        reason: 'ok',
        valueTokenReward: 7,
      ),
    );
    expect(find.text('VALUE 보상: 7'), findsOneWidget);
  });

  testWidgets('the bottom button stays above the system navigation bar',
      (tester) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // A 3-button navigation bar reports itself as bottom view padding.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await _open(
      tester,
      const JenaValidationResult(
        verified: false,
        decision: JenaDecision.rejectedUnknown,
        reason: 'x',
        valueTokenReward: 0,
      ),
    );
    final button = find.text('홈으로 돌아가기');
    expect(button, findsOneWidget);
    // The scrolling body ends above the bar, so the last button can scroll clear of it.
    expect(tester.getBottomLeft(find.byType(ListView)).dy, lessThanOrEqualTo(3000 - 48 - 20));
  });
}
