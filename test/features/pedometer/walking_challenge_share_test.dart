import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/walking_challenge_share.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/challenge_detail_screen.dart';
import 'package:share_run_challenge/screens/onboarding_run_result_screen.dart';
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
    WalkingChallengeShare.debugKakaoShareOverride = null;
    // KakaoTalk absent: entry points keep opening the system sheet directly.
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
    SharedPreferences.setMockInitialValues({
      'is_pedometer_reset_v3_done': true,
    });
  });

  tearDown(() {
    WalkingChallengeShare.debugShareOverride = null;
    WalkingChallengeShare.debugKakaoShareOverride = null;
    WalkingChallengeShare.debugKakaoInstalledOverride = null;
  });

  test('promo text is Korean walking invite, not a brag card', () {
    expect(WalkingChallengeShare.promoText, contains('워킹챌린지'));
    expect(WalkingChallengeShare.promoText, contains('SHARE'));
    expect(WalkingChallengeShare.promoText, contains('SRC'));
    expect(WalkingChallengeShare.promoText, contains(RegExp(r'[가-힣]')));
    expect(WalkingChallengeShare.promoText.toLowerCase(),
        isNot(contains('kakao sdk')));
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

  testWidgets('finish SNS share opens the system sheet, not the clipboard',
      (tester) async {
    ShareParams? sent;
    final platformCalls = <MethodCall>[];
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const OnboardingRunResultScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.runResultShare), findsOneWidget);

    await tester.tap(find.text(AppStrings.runResultShare));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    const finishText = 'SRC 앱에서 8.35km 완주 후 기부에 동참했습니다! '
        '⏱ 기록: ${AppStrings.runResultFinalTimeValue}';
    expect(sent, isNotNull);
    expect(sent!.text, finishText);
    expect(sent!.subject, 'SRC 완주 기록');
    expect(sent!.title, 'SRC 완주 기록');
    expect(sent!.sharePositionOrigin, isNotNull);
    expect(sent!.files, isNull);
    expect(sent!.text, isNot(WalkingChallengeShare.promoText));
    expect(find.byType(SnackBar), findsNothing);
    expect(
      platformCalls.where((call) => call.method.startsWith('Clipboard')),
      isEmpty,
    );
  });

  testWidgets('room paper-plane opens the system sheet with invite text',
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

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const ChallengeDetailScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final roomTitle = AppStrings.challengeDetailTitle;
    expect(sent, isNotNull);
    expect(
      sent!.text,
      'SRC $roomTitle 방에 같이 도전해요!\n#SRC #ShareRunChallenge',
    );
    expect(sent!.subject, 'SRC 챌린지 초대');
    expect(sent!.title, 'SRC 챌린지 초대');
    expect(sent!.sharePositionOrigin, isNotNull);
    expect(sent!.files, isNull);
    expect(sent!.text, isNot(WalkingChallengeShare.promoText));
    expect(sent!.text, isNot(WalkingChallengeShare.dailyGoalBragText));
  });

  test('shareToKakao routes text to Kakao and skips the system sheet',
      () async {
    ShareParams? sent;
    String? kakaoText;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };

    final status = await WalkingChallengeShare.shareToKakao(text: '카카오 본문');

    expect(status, KakaoDirectShareStatus.sent);
    expect(kakaoText, '카카오 본문');
    expect(sent, isNull);
  });

  test('shareToKakao does nothing when KakaoTalk is not installed', () async {
    var called = false;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => false;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      called = true;
    };

    final status = await WalkingChallengeShare.shareToKakao(text: '본문');

    expect(status, KakaoDirectShareStatus.notInstalled);
    expect(called, isFalse);
  });

  test('shareToKakao reports failure without throwing', () async {
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      throw StateError('kakao down');
    };

    final status = await WalkingChallengeShare.shareToKakao();

    expect(status, KakaoDirectShareStatus.failed);
  });

  test('shareToKakao clamps text to the Kakao template limit', () async {
    String? kakaoText;
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };

    final long = '가' * (WalkingChallengeShare.kakaoTextLimit + 40);
    final status = await WalkingChallengeShare.shareToKakao(text: long);

    expect(status, KakaoDirectShareStatus.sent);
    expect(kakaoText, isNotNull);
    expect(kakaoText!.length, WalkingChallengeShare.kakaoTextLimit);
    expect(kakaoText!.endsWith('…'), isTrue);
    expect(kakaoText, isNot(long));
  });

  testWidgets('chooser offers Kakao and keeps the system sheet',
      (tester) async {
    ShareParams? sent;
    String? kakaoText;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };

    await _pumpShareChooser(tester, text: '공유 본문', subject: '공유 제목');
    await tester.tap(find.text('open-share'));
    await tester.pumpAndSettle();

    expect(find.byKey(WalkingChallengeShare.kakaoChoiceKey), findsOneWidget);
    expect(find.text(WalkingChallengeShare.kakaoChoiceLabel), findsOneWidget);
    expect(find.byKey(WalkingChallengeShare.systemChoiceKey), findsOneWidget);
    expect(
      find.text(WalkingChallengeShare.otherAppsChoiceLabel),
      findsOneWidget,
    );

    await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
    await tester.pumpAndSettle();

    expect(kakaoText, '공유 본문');
    expect(sent, isNull);
  });

  testWidgets('chooser system choice still opens the OS sheet', (tester) async {
    ShareParams? sent;
    String? kakaoText;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };

    await _pumpShareChooser(tester, text: '공유 본문', subject: '공유 제목');
    await tester.tap(find.text('open-share'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WalkingChallengeShare.systemChoiceKey));
    await tester.pumpAndSettle();

    expect(kakaoText, isNull);
    expect(sent, isNotNull);
    expect(sent!.text, '공유 본문');
    expect(sent!.subject, '공유 제목');
    expect(sent!.title, '공유 제목');
    expect(sent!.files, isNull);
  });

  testWidgets(
      'chooser hides Kakao and opens the system sheet when not installed',
      (tester) async {
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };

    await _pumpShareChooser(tester, text: '공유 본문', subject: '공유 제목');
    await tester.tap(find.text('open-share'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(WalkingChallengeShare.kakaoChoiceLabel), findsNothing);
    expect(sent, isNotNull);
    expect(sent!.text, '공유 본문');
    expect(sent!.subject, '공유 제목');
  });

  testWidgets('Kakao share failure shows a snackbar and skips the system sheet',
      (tester) async {
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      throw StateError('kakao down');
    };

    await _pumpShareChooser(tester, text: '공유 본문');
    await tester.tap(find.text('open-share'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(sent, isNull);
    expect(find.text(WalkingChallengeShare.kakaoShareFailedMessage),
        findsOneWidget);
  });

  testWidgets('Walking Challenge header offers Kakao when it is installed',
      (tester) async {
    String? kakaoText;
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
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

    await tester.tap(find.byKey(WalkingChallengeShare.buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(WalkingChallengeShare.kakaoChoiceLabel), findsOneWidget);
    expect(
      find.text(WalkingChallengeShare.otherAppsChoiceLabel),
      findsOneWidget,
    );

    await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(kakaoText, WalkingChallengeShare.promoText);
    expect(sent, isNull);
  });

  testWidgets('daily-goal 자랑하기 offers Kakao with brag text', (tester) async {
    String? kakaoText;
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
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

    await tester.tap(find.byKey(WalkingChallengeShare.dailyGoalBragKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(kakaoText, WalkingChallengeShare.dailyGoalBragText);
    expect(kakaoText, isNot(WalkingChallengeShare.promoText));
    expect(sent, isNull);
  });

  testWidgets('finish SNS share keeps Kakao and the system sheet',
      (tester) async {
    ShareParams? sent;
    String? kakaoText;
    final platformCalls = <MethodCall>[];
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const OnboardingRunResultScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text(AppStrings.runResultShare));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(WalkingChallengeShare.kakaoChoiceLabel), findsOneWidget);
    expect(
      find.text(WalkingChallengeShare.otherAppsChoiceLabel),
      findsOneWidget,
    );

    await tester.tap(find.byKey(WalkingChallengeShare.systemChoiceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    const finishText = 'SRC 앱에서 8.35km 완주 후 기부에 동참했습니다! '
        '⏱ 기록: ${AppStrings.runResultFinalTimeValue}';
    expect(kakaoText, isNull);
    expect(sent, isNotNull);
    expect(sent!.text, finishText);
    expect(sent!.subject, 'SRC 완주 기록');
    expect(sent!.files, isNull);
    expect(
      platformCalls.where((call) => call.method.startsWith('Clipboard')),
      isEmpty,
    );
  });

  testWidgets('finish SNS share sends the finish text to Kakao',
      (tester) async {
    String? kakaoText;
    ShareParams? sent;
    WalkingChallengeShare.debugShareOverride = (params) async {
      sent = params;
      return const ShareResult('', ShareResultStatus.success);
    };
    WalkingChallengeShare.debugKakaoInstalledOverride = () async => true;
    WalkingChallengeShare.debugKakaoShareOverride = (text) async {
      kakaoText = text;
    };

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SrcTheme.light,
          home: const OnboardingRunResultScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text(AppStrings.runResultShare));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(WalkingChallengeShare.kakaoChoiceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    const finishText = 'SRC 앱에서 8.35km 완주 후 기부에 동참했습니다! '
        '⏱ 기록: ${AppStrings.runResultFinalTimeValue}';
    expect(kakaoText, finishText);
    expect(kakaoText, isNot(WalkingChallengeShare.promoText));
    expect(sent, isNull);
  });
}

Future<void> _pumpShareChooser(
  WidgetTester tester, {
  required String text,
  String? subject,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await WalkingChallengeShare.openChooser(
                  context,
                  text: text,
                  subject: subject,
                );
              },
              child: const Text('open-share'),
            );
          },
        ),
      ),
    ),
  );
}
