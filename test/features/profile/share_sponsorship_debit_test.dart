import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/providers/app_providers.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/data/models/personal_sponsor_donation.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/data/models/wallet_model.dart';
import 'package:share_run_challenge/screens/personal_sponsor_screen.dart';
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

  test('donation totals on screen are the server profile', () {
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
    expect(merged.donationCount, remote.donationCount);
    expect(merged.cumulativeDonationAmount, remote.cumulativeDonationAmount);
    expect(merged.isSponsored, remote.isSponsored);
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

  test('phone donation prefs do not raise a blank server profile', () {
    final blank = UserModel.dashboardDefault(uid: 'u1');
    final merged = UserProfileNotifier.retainOptimisticDonationTotals(
      local: blank,
      remote: blank,
      durableDonationCount: 1,
      durableDonationAmount: 50000,
      durableSponsored: true,
    );
    expect(merged.donationCount, 0);
    expect(merged.cumulativeDonationAmount, 0);
    expect(merged.isSponsored, isFalse);
  });

  test('sponsor donation does not change totals before the server confirms', () async {
    final container = ProviderContainer(
      overrides: [
        activeUserProfileProvider.overrideWith(
          (ref) => Stream.value(UserModel.dashboardDefault(uid: '')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(userProfileNotifierProvider.notifier);
    expect(container.read(userProfileProvider).donationCount, 0);
    expect(container.read(userProfileProvider).safeCumulativeDonationAmount, 0);

    await expectLater(
      notifier.processDonation(50000),
      throwsA(isA<StateError>()),
    );

    final after = container.read(userProfileProvider);
    expect(after.donationCount, 0);
    expect(after.cumulativeDonationAmount, 0);
    expect(after.isSponsored, isFalse);
    expect(after.angelTier, AngelTier.preAngel);
  });

  test('server confirmation updates angel count and tier', () {
    final confirmed = UserProfileNotifier.confirmedSponsorshipProfile(
      local: UserModel.dashboardDefault(uid: 'u1'),
      confirmed: const PersonalSponsorDonation(
        status: 'sponsored',
        shareSpent: 50000,
        donationCount: 1,
        cumulativeDonationAmount: 50000,
        angelTierCode: 'guardian',
        isSponsored: true,
        shareBalance: 30000,
      ),
    );
    expect(confirmed.donationCount, 1);
    expect(confirmed.cumulativeDonationAmount, 50000);
    expect(confirmed.isSponsored, isTrue);
    expect(confirmed.angelTier, AngelTier.guardian);
  });

  test('sponsor failure is SHARE or a generic Korean error, never DIA', () {
    expect(
      personalSponsorFailureMessage(
        const ApiException(
          statusCode: 400,
          detail: 'Insufficient Share balance.',
        ),
      ),
      'SHARE가 부족합니다.',
    );
    expect(
      personalSponsorFailureMessage(
        const ApiException(
          statusCode: 400,
          detail: 'Insufficient Diamond balance.',
        ),
      ),
      '후원에 실패했습니다. 잠시 후 다시 시도해 주세요.',
    );
    expect(
      personalSponsorFailureMessage(
        const ApiException(statusCode: 500, detail: 'Internal Server Error'),
      ),
      '후원에 실패했습니다. 잠시 후 다시 시도해 주세요.',
    );
  });
}
