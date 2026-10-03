import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/pedometer/kst_calendar.dart';
import 'package:share_run_challenge/features/pedometer/pedometer_harvest_ledger.dart';
import 'package:share_run_challenge/features/pedometer/walking_look.dart';
import 'package:share_run_challenge/features/profile/widgets/retention_widgets.dart';
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

class _Steps2950 extends PedometerNotifier {
  _Steps2950(super.ref) {
    state = const PedometerData(steps: 2950, km: 2.21, isMoving: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    final today = KstCalendar.dateKey();
    PedometerHarvestLedger.commitSession(dateKey: today, claimed: 0);
  });

  testWidgets(
    'remount keeps a picked-up floor from showing SHARE 줍기',
    (tester) async {
      final today = KstCalendar.dateKey();
      PedometerHarvestLedger.commitSession(dateKey: today, claimed: 2900);
      SharedPreferences.setMockInitialValues({
        'is_pedometer_reset_v3_done': true,
        'lastSavedDate': today,
        '${today}_steps': 2950,
        '${today}_km': 2.21,
      });

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
            debugShowCheckedModeBanner: false,
            theme: SrcTheme.light,
            home: const SoloPedometerScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage(WalkingLook.snailWalkingAsset),
          tester.element(find.byType(SoloPedometerScreen)),
        );
      });

      var sawSteps = false;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('2,950').evaluate().isNotEmpty) {
          sawSteps = true;
          break;
        }
      }
      expect(sawSteps, isTrue, reason: 'today steps should restore');
      expect(find.text('29 SHARE 줍기'), findsNothing);
      expect(find.text('코인 쌓이는 중...'), findsOneWidget);
      expect(find.textContaining('오늘의 채굴 : 0 / 60'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'home CTA does not offer 줍기 for a sub-100 remainder',
    (tester) async {
      final today = KstCalendar.dateKey();
      PedometerHarvestLedger.commitSession(dateKey: today, claimed: 2900);
      SharedPreferences.setMockInitialValues({
        '${today}_steps': 2950,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pedometerStateProvider.overrideWith(_Steps2950.new),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: SrcTheme.light,
            home: Scaffold(
              body: SoloQuickStartBanner(onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('워킹챌린지 코인줍기'), findsNothing);
      expect(find.text('워킹 챌린지 시작'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
