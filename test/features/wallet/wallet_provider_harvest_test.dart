import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
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

  test('applyWalletSnapshot sets SHARE DIA VALUE together for the 1M test grant',
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
  });

  test('debug 1M grant is one-shot keyed and one million', () {
    expect(DebugTestWalletGrantHost.amount, 1000000);
    expect(DebugTestWalletGrantHost.prefsKey, 'testGrant1mDone');
    expect(DebugTestWalletGrantHost.allowlistUids, isEmpty);
    expect(DebugTestWalletGrantHost.isAllowlisted(''), isFalse);
    expect(DebugTestWalletGrantHost.isAllowlisted('some-other-uid'), isFalse);
  });
}
