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
      MiniBotCopy.donate,
    ];
    for (final text in texts) {
      expect(text, isNot(contains('유니세프')), reason: text);
      expect(text, isNot(contains('UNICEF')), reason: text);
    }
  });

  test('the one sample crew is the owner\'s crew, named the same everywhere', () {
    expect(AppStrings.runningCrewMyCrewName, startsWith('서울 나이트 러너스'));
    expect(AppStrings.crewManagerCrewName, startsWith('서울 나이트 러너스'));
  });
}
