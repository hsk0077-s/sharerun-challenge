import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/solo_pedometer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 90000,
  diamondBalance: 5,
  valueTokenBalance: 5200,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WalkingChallengeShare.debugShareOverride = null;
    SharedPreferences.setMockInitialValues({
      'is_pedometer_reset_v3_done': true,
    });
  });

  tearDown(() {
    WalkingChallengeShare.debugShareOverride = null;
  });

  test('promo text is Korean walking invite, not a brag card', () {
    expect(WalkingChallengeShare.promoText, contains('워킹챌린지'));
    expect(WalkingChallengeShare.promoText, contains('SHARE'));
    expect(WalkingChallengeShare.promoText, contains('SRC'));
    expect(WalkingChallengeShare.promoText, contains(RegExp(r'[가-힣]')));
    expect(WalkingChallengeShare.promoText.toLowerCase(), isNot(contains('kakao sdk')));
    expect(WalkingChallengeShare.promoText, isNot(contains('오늘의 목표 달성')));
    expect(WalkingChallengeShare.subject, 'SRC 워킹챌린지');
    expect(WalkingChallengeShare.buttonTooltip, '공유');
  });

  test('daily-goal brag text is short Korean achievement copy', () {
    expect(WalkingChallengeShare.dailyGoalBragText, contains('오늘의 목표 달성'));
    expect(WalkingChallengeShare.dailyGoalBragText, contains('워킹챌린지'));
    expect(WalkingChallengeShare.dailyGoalBragText, contains('SHARE'));
    expect(WalkingChallengeShare.dailyGoalBragText, contains('SRC'));
    expect(WalkingChallengeShare.dailyGoalBragText, contains(RegExp(r'[가-힣]')));
    expect(
      WalkingChallengeShare.dailyGoalBragText.toLowerCase(),
      isNot(contains('kakao sdk')),
    );
    expect(
      WalkingChallengeShare.dailyGoalBragText,
      isNot(equals(WalkingChallengeShare.promoText)),
    );
    expect(WalkingChallengeShare.dailyGoalBragSubject, 'SRC 오늘의 목표 달성');
    expect(WalkingChallengeShare.dailyGoalBragButtonLabel, '자랑하기');
  });

  test('openSystemSheet sends promo text to the OS sheet', () async {
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    await WalkingChallengeShare.openSystemSheet();

    expect(sent, isNotNull);
    expect(sent!.text, WalkingChallengeShare.promoText);
    expect(sent!.subject, WalkingChallengeShare.subject);
    expect(sent!.title, WalkingChallengeShare.subject);
    expect(sent!.files, isNull);
  });

  testWidgets('Walking Challenge header share opens the system sheet',
      (tester) async {
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserModel.dashboardDefault(uid: '');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          needsNicknameSetupProvider.overrideWith((ref) => false),
          userNicknameProvider.overrideWith((ref) => '테스트워커'),
          activeUserProfileProvider.overrideWith(
            (ref) => Stream<UserModel>.value(profile),
          ),
          activeWalletProvider.overrideWith(
            (ref) => Stream<WalletModel>.value(_wallet),
          ),
          walletProvider.overrideWith(_SeededWalletNotifier.new),
          activeUserTierProvider.overrideWith((ref) => Stream<int>.value(0)),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const SoloPedometerScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(WalkingChallengeShare.buttonKey), findsOneWidget);
    expect(find.byTooltip(WalkingChallengeShare.buttonTooltip), findsOneWidget);

    await tester.tap(find.byKey(WalkingChallengeShare.buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(sent, isNotNull);
    expect(sent!.text, WalkingChallengeShare.promoText);
    expect(sent!.files, isNull);
  });

  test('openDailyGoalBrag sends brag text, not the header promo', () async {
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    await WalkingChallengeShare.openDailyGoalBrag();

    expect(sent, isNotNull);
    expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    expect(sent!.subject, WalkingChallengeShare.dailyGoalBragSubject);
    expect(sent!.title, WalkingChallengeShare.dailyGoalBragSubject);
    expect(sent!.files, isNull);
    expect(sent!.text, isNot(WalkingChallengeShare.promoText));
  });

  testWidgets('daily-goal card 자랑하기 opens the system sheet with brag text',
      (tester) async {
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: WalkingDailyGoalCompleteCard(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('오늘의 목표 달성!'), findsOneWidget);
    expect(find.byKey(WalkingDailyGoalCompleteCard.cardKey), findsOneWidget);
    expect(find.byKey(WalkingChallengeShare.dailyGoalBragKey), findsOneWidget);
    expect(
      find.text(WalkingChallengeShare.dailyGoalBragButtonLabel),
      findsOneWidget,
    );

    await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(sent, isNotNull);
    expect(sent!.text, WalkingChallengeShare.dailyGoalBragText);
    expect(sent!.subject, WalkingChallengeShare.dailyGoalBragSubject);
    expect(sent!.files, isNull);
  });

  testWidgets('daily-goal brag card golden', (tester) async {
    tester.view.physicalSize = const Size(390, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SrcTheme.light,
        home: const Scaffold(
          backgroundColor: Color(0xFFF3F7F5),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: WalkingDailyGoalCompleteCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(WalkingDailyGoalCompleteCard.cardKey),
      matchesGoldenFile('goldens/walking_daily_goal_brag.png'),
    );
  });

  testWidgets('자랑하기 is hidden until the daily SHARE cap is reached',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserModel.dashboardDefault(uid: '');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          needsNicknameSetupProvider.overrideWith((ref) => false),
          userNicknameProvider.overrideWith((ref) => '테스트워커'),
          activeUserProfileProvider.overrideWith(
            (ref) => Stream<UserModel>.value(profile),
          ),
          activeWalletProvider.overrideWith(
            (ref) => Stream<WalletModel>.value(_wallet),
          ),
          walletProvider.overrideWith(_SeededWalletNotifier.new),
          activeUserTierProvider.overrideWith((ref) => Stream<int>.value(0)),
        ],
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const SoloPedometerScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(WalkingChallengeShare.dailyGoalBragKey), findsNothing);
    expect(find.text('오늘의 목표 달성!'), findsNothing);
    expect(find.byKey(WalkingChallengeShare.buttonKey), findsOneWidget);
  });
}
