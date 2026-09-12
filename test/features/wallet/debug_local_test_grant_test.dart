import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/constants/debug_wallet_grant.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/wallet/debug_test_wallet_grant.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local debug grant is debug-only and only when Home wallet is empty',
      () {
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
        debugMode: true,
        walletEmpty: true,
        prefsMarkedDone: true,
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
        },
      },
    );
    expect(
      DebugTestWalletGrantHost.localGrantFirestoreFields(),
      DebugWalletGrant.firestoreMergeFields(),
    );
    expect(
      DebugWalletGrant.shopSpendMergeFields(
        uid: 'uid-1',
        shareBalance: 1000000,
        diamondBalance: 999970,
        valueBalance: 1000000,
        hasCPR: true,
      ),
      {
        'uid': 'uid-1',
        'testGrant1mDone': true,
        'wallet.shareBalance': 1000000,
        'wallet.diamondBalance': 999970,
        'wallet.valueTokenBalance': 1000000,
        'hasCPR': true,
      },
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

    notifier.applyShareFromServer(shareCredited: 29);
    expect(container.read(walletProvider).shareBalance, 1000029);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(WalletModel.empty());
    expect(container.read(walletProvider).shareBalance, 1000029);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test(
    'prefs marked done but Home wallet is still 0 must not local re-apply',
    () {
      expect(
        DebugTestWalletGrantHost.shouldLocalReapplyBecauseWalletEmpty(
          prefsMarkedDone: true,
          walletEmpty: true,
        ),
        isFalse,
      );
      expect(
        DebugWalletGrant.shouldRunLocalGrant(
          debugMode: true,
          prefsMarkedDone: true,
          walletEmpty: true,
        ),
        isFalse,
      );
      expect(
        DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
          prefsMarkedDone: true,
          walletEmpty: true,
        ),
        isTrue,
      );
    },
  );

  test('stale prefs lock is one-shot even while Home wallet is still 0', () {
    expect(
      DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
        prefsMarkedDone: true,
        walletEmpty: true,
      ),
      isTrue,
    );
    expect(
      DebugWalletGrant.shouldRunLocalGrant(
        debugMode: true,
        prefsMarkedDone: true,
        walletEmpty: true,
      ),
      isFalse,
    );
  });

  test('grant does not re-run after sponsorship SHARE drop and relaunch', () {
    const remote = WalletModel(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueTokenBalance: 1000000,
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
    DebugTestWalletGrantHost.applyLocalGrantToNotifier(notifier);
    expect(container.read(walletProvider).shareBalance, 1000000);

    notifier.applyEntryFeeDebit(50000);
    expect(container.read(walletProvider).shareBalance, 950000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    const prefsMarkedDone = true;
    final spent = container.read(walletProvider);
    expect(
      DebugWalletGrant.shouldRunLocalGrant(
        debugMode: true,
        prefsMarkedDone: prefsMarkedDone,
        walletEmpty: spent.isEmpty,
      ),
      isFalse,
    );

    // Cold start: notifier empty until Firestore hydrates.
    expect(
      DebugWalletGrant.shouldRunLocalGrant(
        debugMode: true,
        prefsMarkedDone: true,
        walletEmpty: true,
      ),
      isFalse,
    );
    expect(
      DebugTestWalletGrantHost.shouldApplyGrantSnapshot(
        status: 'already_granted',
        localWalletEmpty: false,
      ),
      isFalse,
    );
    expect(
      DebugTestWalletGrantHost.shouldApplyGrantSnapshot(
        status: 'granted',
        localWalletEmpty: false,
      ),
      isFalse,
    );

    notifier.replaceFromRemote(
      const WalletModel(
        shareBalance: 950000,
        diamondBalance: 1000000,
        valueTokenBalance: 1000000,
        totalDonationValue: 0,
      ),
    );
    expect(container.read(walletProvider).shareBalance, 950000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('grant payload does not reset donation aggregates', () {
    final fields = DebugWalletGrant.firestoreMergeFields();
    expect(fields.containsKey('donationCount'), isFalse);
    expect(fields.containsKey('cumulativeDonationAmount'), isFalse);
    expect(fields.containsKey('isSponsored'), isFalse);
    final wallet = fields['wallet'] as Map<String, dynamic>;
    expect(wallet.containsKey('totalDonationValue'), isFalse);
    expect(
      DebugWalletGrant.donationPersistFields(
        donationCount: 1,
        cumulativeDonationAmount: 50000,
      ),
      {
        'donationCount': 1,
        'cumulativeDonationAmount': 50000,
        'isSponsored': true,
      },
    );
    expect(
      DebugWalletGrant.shareSpendMergeFields(
        uid: 'uid-1',
        shareBalanceAfter: 970000,
        diamondBalance: 1000000,
        valueBalance: 1000000,
      ),
      {
        'uid': 'uid-1',
        'testGrant1mDone': true,
        'wallet.shareBalance': 970000,
        'wallet.diamondBalance': 1000000,
        'wallet.valueTokenBalance': 1000000,
      },
    );
    expect(
      DebugWalletGrant.shareSpendMergeFields(
        uid: 'uid-1',
        shareBalanceAfter: 790000,
        diamondBalance: 1000000,
        valueBalance: 1000000,
        donationCount: 1,
        cumulativeDonationAmount: 50000,
        isSponsored: true,
      ),
      {
        'uid': 'uid-1',
        'testGrant1mDone': true,
        'wallet.shareBalance': 790000,
        'wallet.diamondBalance': 1000000,
        'wallet.valueTokenBalance': 1000000,
        'donationCount': 1,
        'cumulativeDonationAmount': 50000,
        'isSponsored': true,
      },
    );
  });
}
