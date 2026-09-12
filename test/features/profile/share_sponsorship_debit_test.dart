import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/features/onboarding/src_onboarding_controller.dart';
import 'package:share_run_challenge/features/profile/user_profile_notifier.dart';
import 'package:share_run_challenge/features/wallet/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const staleRemote = WalletModel(
    shareBalance: 840000,
    diamondBalance: 1000000,
    valueTokenBalance: 1000000,
    totalDonationValue: 0,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('50k SHARE sponsor debit survives a stale remote merge', () {
    final container = ProviderContainer(
      overrides: [
        activeWalletProvider.overrideWith(
          (ref) => Stream<WalletModel>.value(staleRemote),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(walletProvider.notifier);
    notifier.replaceFromRemote(staleRemote);
    expect(container.read(walletProvider).shareBalance, 840000);

    notifier.applyEntryFeeDebit(50000);
    expect(container.read(walletProvider).shareBalance, 790000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);

    notifier.replaceFromRemote(staleRemote);
    expect(container.read(walletProvider).shareBalance, 790000);
    expect(container.read(walletProvider).diamondBalance, 1000000);
    expect(container.read(walletProvider).valueBalance, 1000000);
  });

  test('stale cloud profile does not snap donation totals back down', () {
    final local = UserModel.dashboardDefault(uid: 'u1').copyWith(
      donationCount: 1,
      cumulativeDonationAmount: 50000,
      isSponsored: true,
    );
    final remote = UserModel.dashboardDefault(uid: 'u1');

    final merged = UserProfileNotifier.retainOptimisticDonationTotals(
      local: local,
      remote: remote,
    );
    expect(merged.donationCount, 1);
    expect(merged.cumulativeDonationAmount, 50000);
    expect(merged.isSponsored, isTrue);
    expect(merged.angelTier, isNot(remote.angelTier));
  });

  test('higher remote donation totals still win', () {
    final local = UserModel.dashboardDefault(uid: 'u1').copyWith(
      donationCount: 1,
      cumulativeDonationAmount: 50000,
      isSponsored: true,
    );
    final remote = UserModel.dashboardDefault(uid: 'u1').copyWith(
      donationCount: 3,
      cumulativeDonationAmount: 150000,
      isSponsored: true,
    );

    final merged = UserProfileNotifier.retainOptimisticDonationTotals(
      local: local,
      remote: remote,
    );
    expect(merged.donationCount, 3);
    expect(merged.cumulativeDonationAmount, 150000);
  });
}
