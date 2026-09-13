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
    expect(WalkingChallengeShare.subject, 'SRC 워킹챌린지');
    expect(WalkingChallengeShare.buttonTooltip, '공유');
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
}
