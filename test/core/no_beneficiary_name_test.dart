import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_intent.dart';

/// 기부처(수혜 단체)는 아직 정해지지 않았다(결정: 정해질 때까지 화면에 이름을 쓰지 않는다).
void main() {
  test('screens that name no beneficiary stay that way', () {
    final texts = <String>[
      AppStrings.challengeDetailDonation,
      AppStrings.challengeDetailDonationTarget,
      AppStrings.storeFundingTitle,
      AppStrings.storeDonateHistoryTitle,
      AppStrings.personalSponsorDonationTitle,
      AppStrings.personalSponsorDonationDesc,
      AppStrings.brandSponsorDonationPledge,
      AppStrings.brandSponsorBenevolentFailure,
      MiniBotCopy.donate,
    ];
    for (final text in texts) {
      expect(text, isNot(contains('유니세프')), reason: text);
      expect(text, isNot(contains('UNICEF')), reason: text);
    }
  });

  test('sponsorship is donated in the company\'s name, never the winner\'s', () {
    for (final text in [
      AppStrings.personalSponsorDonationTitle,
      AppStrings.personalSponsorDonationDesc,
      AppStrings.brandSponsorDonationPledge,
      AppStrings.brandSponsorBenevolentFailure,
    ]) {
      expect(text, isNot(contains('우승자')), reason: text);
      expect(text, isNot(contains('1등 러너의 이름')), reason: text);
    }
    expect(AppStrings.personalSponsorDonationDesc, contains('회사 이름'));
  });

  // 소유자가 정한 이름이다(2026-10-17). 소유자의 폰에서 계속 쓰는 크루명이라 바꾸지 않는다.
  test('the one sample crew is the owner\'s crew, named the same everywhere', () {
    expect(AppStrings.runningCrewMyCrewName, '인천 논현 최강 크루');
    expect(AppStrings.crewManagerCrewName, '인천 논현 최강 크루');
  });
}
