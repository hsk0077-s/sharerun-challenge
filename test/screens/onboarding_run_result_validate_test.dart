import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/screens/onboarding_run_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('unconfirmed finish does not show a fake reward', (tester) async {
    await _pump(
      tester,
      const OnboardingRunResultScreen(),
    );

    expect(find.text(AppStrings.runResultUnconfirmed), findsOneWidget);
    expect(find.text(AppStrings.runResultTitle), findsNothing);
    expect(find.text('+200'), findsNothing);
    expect(find.text('+100'), findsNothing);
    expect(find.text('8.35'), findsNothing);
    expect(find.text('52:14'), findsNothing);
  });

  testWidgets('confirmed finish shows the server distance, time, and VALUE', (
    tester,
  ) async {
    await _pump(
      tester,
      const OnboardingRunResultScreen(
        distanceKm: 1,
        durationSeconds: 600,
        valueTokenReward: 10,
        serverConfirmed: true,
      ),
    );

    expect(find.text('1.00'), findsWidgets);
    expect(find.text('거리: 1.00 km'), findsOneWidget);
    expect(find.text('최종 시간: 10:00'), findsOneWidget);
    expect(find.text('평균 페이스: 10:00 /km'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('VALUE 획득'), findsOneWidget);
    expect(find.text(AppStrings.runResultValueReward(10)), findsOneWidget);
    expect(find.text('+200'), findsNothing);
    expect(find.text('+100'), findsNothing);
    expect(find.text(AppStrings.runResultDonatePending), findsOneWidget);
    expect(find.text(AppStrings.runResultDonate), findsNothing);

    await tester.tap(find.text(AppStrings.runResultDonatePending));
    await tester.pump();
    expect(find.text('기부가 성공적으로 완료되었습니다!'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: SrcTheme.light,
        home: home,
      ),
    ),
  );
  await tester.pump();
}
