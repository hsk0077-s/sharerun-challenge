import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/jena_validation/models/jena_validation_result.dart';
import 'package:share_run_challenge/features/run_result/run_finish_share_card.dart';
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
    expect(find.text('이번 달리기는 기부에 포함되지 않았어요.'), findsOneWidget);
    expect(find.textContaining('100원'), findsNothing);
    expect(find.text(AppStrings.runResultDonate), findsNothing);
    expect(find.textContaining('내 이름으로 기부'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('finish shows the server won and does not multiply kilometres', (
    tester,
  ) async {
    await _pump(
      tester,
      const OnboardingRunResultScreen(
        distanceKm: 2.4,
        durationSeconds: 720,
        valueTokenReward: 20,
        serverConfirmed: true,
        serverAnswered: true,
        companyDonationWon: 200,
        donationCounted: true,
      ),
    );

    expect(find.text('이번 달리기로 회사가 200원을 기부해요'), findsWidgets);
    expect(find.textContaining('240원'), findsNothing);
    expect(find.textContaining('내 이름으로'), findsNothing);
  });

  testWidgets('unverified finish shows that no donation was counted', (
    tester,
  ) async {
    await _pump(
      tester,
      const OnboardingRunResultScreen(
        distanceKm: 3,
        durationSeconds: 900,
        serverAnswered: true,
        donationReason: '케이던스가 범위 밖입니다.',
      ),
    );

    expect(
      find.text('이번 달리기는 기부에 포함되지 않았어요. 케이던스가 범위 밖입니다.'),
      findsOneWidget,
    );
    expect(find.text('거리: 3.00 km'), findsOneWidget);
    expect(find.text(AppStrings.runResultTitle), findsNothing);
    expect(find.textContaining('300원'), findsNothing);
    expect(find.text('VALUE 획득'), findsNothing);
  });

  test('validate response donation fields are read as sent', () {
    final result = JenaValidationResult.fromJson({
      'verified': true,
      'decision': 'verified',
      'reason': 'ok',
      'value_token_reward': 10,
      'company_donation_won': 350,
      'donation_counted': true,
      'donation_reason': '',
    });

    expect(result.companyDonationWon, 350);
    expect(result.donationCounted, isTrue);
    expect(runFinishDonationLine(result.companyDonationWon),
        '이번 달리기로 회사가 350원을 기부해요');

    final skipped = JenaValidationResult.fromJson({
      'verified': false,
      'decision': 'rejected_unknown',
      'reason': '케이던스가 범위 밖입니다.',
      'value_token_reward': 0,
      'donation_counted': false,
      'donation_reason': '케이던스가 범위 밖입니다.',
    });
    expect(skipped.companyDonationWon, 0);
    expect(skipped.donationCounted, isFalse);
    expect(
      runFinishDonationSkippedLine(skipped.donationReason),
      '이번 달리기는 기부에 포함되지 않았어요. 케이던스가 범위 밖입니다.',
    );
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
