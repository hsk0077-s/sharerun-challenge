import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/core/constants/debug_wallet_grant.dart';
import 'package:share_run_challenge/data/models/pedometer_harvest_result.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/wallet/debug_test_wallet_grant.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applyShareFromServer credits SHARE without zeroing DIA/VALUE', () {
    const remote = WalletModel(
      shareBalance: 0,
      diamondBalance: 7,
      valueTokenBalance: 5000,
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

    expect(container.read(walletProvider).shareBalance, 0);
    expect(container.read(walletProvider).diamondBalance, 7);
    expect(container.read(walletProvider).valueBalance, 5000);

    notifier.applyShareFromServer(shareCredited: 51);
    expect(container.read(walletProvider).shareBalance, 51);
    expect(container.read(walletProvider).diamondBalance, 7);
    expect(container.read(walletProvider).valueBalance, 5000);

    notifier.applyShareFromServer(shareBalance: 91);
    expect(container.read(walletProvider).shareBalance, 91);
    expect(container.read(walletProvider).diamondBalance, 7);
    expect(container.read(walletProvider).valueBalance, 5000);
  });

  test(
      'debug applyShareFromServer does not replace 1M grant with stale Jena SHARE',
      () {
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
    notifier.applyShareFromServer(shareBalance: 51, shareCredited: 29);
    expect(container.read(walletProvider).shareBalance, 1000029);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test(
      'debug harvest does not re-apply 1M grant over a post-join SHARE ledger',
      () {
    const remote = WalletModel(
      shareBalance: 970000,
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
    notifier.applyShareFromServer(shareBalance: 1000018, shareCredited: 18);
    expect(container.read(walletProvider).shareBalance, 970018);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test(
      'applyWalletSnapshot sets SHARE DIA VALUE together for the 1M test grant',
      () {
    const remote = WalletModel(
      shareBalance: 0,
      diamondBalance: 0,
      valueTokenBalance: 5000,
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
    notifier.applyWalletSnapshot(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );

    expect(container.read(walletProvider).shareBalance, 1000000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(WalletModel.empty());
    expect(container.read(walletProvider).shareBalance, 1000000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('harvest SHARE snapshot does not zero granted DIA/VALUE', () {
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
    notifier.applyWalletSnapshot(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    notifier.applyShareFromServer(shareCredited: 51);
    expect(container.read(walletProvider).shareBalance, 1000051);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(
      const WalletModel(
        shareBalance: 1000051,
        diamondBalance: 0,
        valueTokenBalance: 0,
        totalDonationValue: 0,
      ),
    );
    expect(container.read(walletProvider).shareBalance, 1000051);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('mergeRemote keeps local DIA/VALUE when harvest sends zeros', () {
    const current = WalletState(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const harvest = WalletState(
      shareBalance: 51,
      diamondBalance: 0,
      valueBalance: 0,
    );
    final merged = WalletNotifier.mergeRemote(current, harvest);
    expect(merged.shareBalance, 1000000);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('debug mergeRemote keeps local SHARE harvest credit above stale remote',
      () {
    const current = WalletState(
      shareBalance: 1000029,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const stale = WalletState(
      shareBalance: 1000000,
      diamondBalance: 0,
      valueBalance: 0,
    );
    final merged = WalletNotifier.mergeRemote(current, stale);
    expect(merged.shareBalance, 1000029);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('debug mergeRemote applies join SHARE debit and keeps DIA/VALUE', () {
    const current = WalletState(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const afterJoin = WalletState(
      shareBalance: 970000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    final merged = WalletNotifier.mergeRemote(current, afterJoin);
    expect(merged.shareBalance, 970000);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('debug harvest slack does not preserve a 30k join debit', () {
    expect(
      WalletNotifier.shouldPreserveDebugShare(
        currentShare: 1000000,
        incomingShare: 51,
        incomingDiamond: 0,
        incomingValue: 0,
      ),
      isTrue,
    );
    expect(
      WalletNotifier.shouldPreserveDebugShare(
        currentShare: 1000029,
        incomingShare: 1000000,
      ),
      isTrue,
    );
    expect(
      WalletNotifier.shouldPreserveDebugShare(
        currentShare: 1000000,
        incomingShare: 970000,
        incomingDiamond: 1000000,
        incomingValue: 1000000,
      ),
      isFalse,
    );
    expect(
      WalletNotifier.shouldPreserveDebugShare(
        currentShare: 1000000,
        incomingShare: 970000,
        incomingDiamond: 0,
        incomingValue: 0,
      ),
      isFalse,
    );
    expect(
      WalletNotifier.shouldPreserveDebugShare(
        currentShare: 1000000,
        incomingShare: 950000,
        incomingDiamond: 0,
        incomingValue: 0,
      ),
      isFalse,
    );
  });

  test('debug mergeRemote applies join-sized SHARE drop when DIA/VALUE are 0',
      () {
    const current = WalletState(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const afterJoinShareOnly = WalletState(
      shareBalance: 970000,
      diamondBalance: 0,
      valueBalance: 0,
    );
    final merged = WalletNotifier.mergeRemote(current, afterJoinShareOnly);
    expect(merged.shareBalance, 970000);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('applyEntryFeeDebit drops SHARE once and leaves DIA/VALUE', () {
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
    notifier.applyEntryFeeDebit(30000);

    expect(container.read(walletProvider).shareBalance, 970000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.applyEntryFeeDebit(0);
    expect(container.read(walletProvider).shareBalance, 970000);

    // Sponsorship contrast: 50k SHARE spend also leaves DIA/VALUE.
    notifier.applyEntryFeeDebit(50000);
    expect(container.read(walletProvider).shareBalance, 920000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('mergeRemote after join debit does not restore pre-join SHARE', () {
    const current = WalletState(
      shareBalance: 970000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const postJoin = WalletState(
      shareBalance: 970000,
      diamondBalance: 0,
      valueBalance: 0,
    );
    final merged = WalletNotifier.mergeRemote(current, postJoin);
    expect(merged.shareBalance, 970000);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('hydrate of stale 1M cannot wipe an in-session 30k join debit', () {
    const current = WalletState(
      shareBalance: 970000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const staleGrant = WalletState(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    final merged = WalletNotifier.mergeRemote(current, staleGrant);
    expect(merged.shareBalance, 970000);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('durable SHARE ceiling wins over stale grant hydrate on cold start', () {
    const empty = WalletState();
    const staleGrant = WalletState(
      shareBalance: 1000000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    final merged = WalletNotifier.mergeRemote(
      empty,
      staleGrant,
      durableShare: 970000,
    );
    expect(merged.shareBalance, 970000);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('applyShareFromServer harvest stays on Home after stale grant merge', () {
    const remote = WalletModel(
      shareBalance: 970000,
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
    notifier.rememberDurableDebugShare(970000);

    notifier.applyShareFromServer(shareCredited: 18);
    expect(container.read(walletProvider).shareBalance, 970018);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(remote);
    expect(container.read(walletProvider).shareBalance, 970018);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(
      const WalletModel(
        shareBalance: 1000000,
        diamondBalance: 1000000,
        valueTokenBalance: 1000000,
        totalDonationValue: 0,
      ),
    );
    expect(container.read(walletProvider).shareBalance, 970018);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('mergeRemote keeps durable harvest when Firestore is still pre-credit',
      () {
    const current = WalletState(
      shareBalance: 970018,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const stale = WalletState(
      shareBalance: 970000,
      diamondBalance: 0,
      valueBalance: 0,
    );
    final merged = WalletNotifier.mergeRemote(
      current,
      stale,
      durableShare: 970018,
    );
    expect(merged.shareBalance, 970018);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('cold start keeps durable harvest when Firestore is still pre-credit',
      () {
    const empty = WalletState();
    const stale = WalletState(
      shareBalance: 970000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    final merged = WalletNotifier.mergeRemote(
      empty,
      stale,
      durableShare: 970018,
    );
    expect(merged.shareBalance, 970018);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('durable SHARE still allows a small harvest bump', () {
    const current = WalletState(
      shareBalance: 970000,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    const harvest = WalletState(
      shareBalance: 970051,
      diamondBalance: 1000000,
      valueBalance: 1000000,
    );
    final merged = WalletNotifier.mergeRemote(
      current,
      harvest,
      durableShare: 970000,
    );
    expect(merged.shareBalance, 970051);
    expect(merged.diamondBalance, 1000000);
    expect(merged.valueBalance, 1000000);
  });

  test('mergeRemote still hydrates first VALUE when local is 0', () {
    const current = WalletState();
    const incoming = WalletState(
      shareBalance: 0,
      diamondBalance: 7,
      valueBalance: 5000,
    );
    final merged = WalletNotifier.mergeRemote(current, incoming);
    expect(merged.shareBalance, 0);
    expect(merged.diamondBalance, 7);
    expect(merged.valueBalance, 5000);
  });

  test('applyValueDebit drops VALUE once and leaves SHARE/DIA', () {
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
    notifier.applyValueDebit(500);

    expect(container.read(walletProvider).shareBalance, 1000000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 999500);

    notifier.applyValueDebit(0);
    expect(container.read(walletProvider).valueBalance, 999500);
  });

  test('applyValueDebit then stale remote merge keeps the 500 VALUE debit', () {
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
    notifier.applyValueDebit(500);
    expect(container.read(walletProvider).valueBalance, 999500);

    notifier.replaceFromRemote(remote);
    expect(container.read(walletProvider).shareBalance, 1000000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 999500);
  });

  test('applyEntryFeeDebit then stale remote merge keeps the debit', () {
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
    notifier.applyEntryFeeDebit(30000);
    expect(container.read(walletProvider).shareBalance, 970000);

    notifier.replaceFromRemote(remote);
    expect(container.read(walletProvider).shareBalance, 970000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('debug 1M grant is one-shot keyed and one million', () {
    expect(DebugTestWalletGrantHost.amount, 1000000);
    expect(DebugTestWalletGrantHost.prefsKey, 'testGrant1mDone');
    expect(
      DebugTestWalletGrantHost.prefsKeyForUid('uid-1'),
      'testGrant1mDone_uid-1',
    );
  });

  test('debug client bakes a grant secret; release path stays empty-gated', () {
    expect(DebugTestWalletGrantHost.debugClientSecret, isNotEmpty);
    expect(
      DebugTestWalletGrantHost.debugClientSecret,
      'sharerun-debug-test-grant-1m',
    );
    // flutter test runs in kDebugMode, so flutter run would send this secret.
    expect(DebugTestWalletGrantHost.grantSecret(), isNotEmpty);
  });

  test('grant prefs lock only after granted or non-zero already_granted', () {
    expect(
      DebugTestWalletGrantHost.shouldMarkGrantConsumed(
        const PedometerHarvestResult(status: 'granted', shareBalance: 1000000),
      ),
      isTrue,
    );
    expect(
      DebugTestWalletGrantHost.shouldMarkGrantConsumed(
        const PedometerHarvestResult(status: 'already_granted'),
      ),
      isFalse,
    );
    expect(
      DebugTestWalletGrantHost.shouldMarkGrantConsumed(
        const PedometerHarvestResult(
          status: 'already_granted',
          shareBalance: 1000000,
          diamondBalance: 1000000,
          valueTokenBalance: 1000000,
        ),
      ),
      isTrue,
    );
  });

  test('stale prefs lock stays one-shot even while Home wallet is still empty',
      () {
    expect(
      DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
        prefsMarkedDone: true,
        walletEmpty: true,
      ),
      isTrue,
    );
    expect(
      DebugTestWalletGrantHost.shouldHonorLocalGrantLock(
        prefsMarkedDone: true,
        walletEmpty: false,
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

  test('grant retries user-not-found and undeployed 403', () {
    expect(
      DebugTestWalletGrantHost.shouldRetryGrant(
        const ApiException(statusCode: 404, detail: 'User not found.'),
      ),
      isTrue,
    );
    expect(
      DebugTestWalletGrantHost.shouldRetryGrant(
        const ApiException(
          statusCode: 403,
          detail: 'Not eligible for debug test grant.',
        ),
      ),
      isTrue,
    );
  });
}
