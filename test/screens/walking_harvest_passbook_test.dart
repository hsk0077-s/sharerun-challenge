import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/wallet/debug_local_wallet_store.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:share_run_challenge/screens/solo_pedometer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = WalletModel(
  shareBalance: 970000,
  diamondBalance: 1000000,
  valueTokenBalance: 1000000,
  totalDonationValue: 0,
);

class _SeededWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => WalletState.fromModel(_wallet);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DebugLocalWalletStore.clearCacheForTest();
    SharedPreferences.setMockInitialValues({
      'is_pedometer_reset_v3_done': true,
    });
  });

  testWidgets(
      '누적 통장 follows walletProvider after harvest credit',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserModel.dashboardDefault(uid: 'uid-1');
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

    expect(find.text('내 누적 셰어 통장 🏦'), findsOneWidget);
    expect(find.text('970000 SHARE'), findsOneWidget);

    final element = tester.element(find.byType(SoloPedometerScreen));
    final container = ProviderScope.containerOf(element);
    container.read(walletProvider.notifier).applyShareFromServer(
          shareCredited: 18,
        );
    await tester.pump();

    expect(find.text('970018 SHARE'), findsOneWidget);
    expect(find.text('970000 SHARE'), findsNothing);
    expect(container.read(walletProvider).shareBalance, 970018);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    final prefs = await SharedPreferences.getInstance();
    await DebugLocalWalletStore.recordHarvestCredit(
      prefs: prefs,
      uid: 'uid-1',
      shareBalanceAfter: container.read(walletProvider).shareBalance,
      credited: 18,
    );
    expect(prefs.getInt(DebugLocalWalletStore.shareKey('uid-1')), 970018);

    container.read(walletProvider.notifier).replaceFromRemote(_wallet);
    await tester.pump();
    expect(find.text('970018 SHARE'), findsOneWidget);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });
}
