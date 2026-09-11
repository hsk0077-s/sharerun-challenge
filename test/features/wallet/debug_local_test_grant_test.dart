import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/constants/debug_wallet_grant.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/wallet/debug_test_wallet_grant.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local debug grant is debug-only and only when Home wallet is empty', () {
    expect(
      DebugWalletGrant.shouldApplyLocalGrant(
        debugMode: true,
        walletEmpty: true,
      ),
      isTrue,
    );
    expect(
      DebugWalletGrant.shouldApplyLocalGrant(
        debugMode: true,
        walletEmpty: false,
      ),
      isFalse,
    );
    expect(
      DebugWalletGrant.shouldApplyLocalGrant(
        debugMode: false,
        walletEmpty: true,
      ),
      isFalse,
    );
    expect(
      DebugTestWalletGrantHost.shouldApplyLocalGrant(
        debugMode: false,
        walletEmpty: true,
      ),
      isFalse,
    );
  });

  test('local grant payload writes 1M wallet and testGrant1mDone', () {
    expect(DebugWalletGrant.amount, 1000000);
    expect(DebugWalletGrant.prefsKey, 'testGrant1mDone');
    expect(
      DebugWalletGrant.firestoreMergeFields(),
      {
        'testGrant1mDone': true,
        'wallet': {
          'shareBalance': 1000000,
          'diamondBalance': 1000000,
          'valueTokenBalance': 1000000,
          'totalDonationValue': 0,
        },
      },
    );
    expect(
      DebugTestWalletGrantHost.localGrantFirestoreFields(),
      DebugWalletGrant.firestoreMergeFields(),
    );
    final result = DebugTestWalletGrantHost.localGrantedResult();
    expect(result.status, 'granted');
    expect(result.shareBalance, 1000000);
    expect(result.diamondBalance, 1000000);
    expect(result.valueTokenBalance, 1000000);
    expect(
      DebugTestWalletGrantHost.shouldMarkGrantConsumed(result),
      isTrue,
    );
  });

  test('local debug grant fills Home walletProvider without Jena', () {
    const remote = WalletModel(
      shareBalance: 0,
      diamondBalance: 0,
      valueTokenBalance: 0,
      totalDonationValue: 0,
    );
    final container = ProviderContainer(
      overrides: [
        activeWalletProvider.overrideWith(
          (ref) => Stream<WalletModel>.value(remote),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(walletProvider.notifier);
    notifier.replaceFromRemote(remote);
    expect(container.read(walletProvider).isEmpty, isTrue);
    expect(
      DebugTestWalletGrantHost.shouldApplyLocalGrant(
        debugMode: true,
        walletEmpty: container.read(walletProvider).isEmpty,
      ),
      isTrue,
    );

    DebugTestWalletGrantHost.applyLocalGrantToNotifier(notifier);

    expect(container.read(walletProvider).shareBalance, 1000000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(WalletModel.empty());
    expect(container.read(walletProvider).shareBalance, 1000000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('stale prefs lock still allows local grant while Home is 0', () {
    expect(
      DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
        prefsMarkedDone: true,
        walletEmpty: true,
      ),
      isFalse,
    );
    expect(
      DebugWalletGrant.shouldApplyLocalGrant(
        debugMode: true,
        walletEmpty: true,
      ),
      isTrue,
    );
  });
}
