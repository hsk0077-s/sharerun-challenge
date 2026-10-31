import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/data/local/mock_demo_data.dart';
import 'package:share_run_challenge/features/mini_bot/mini_bot_intent.dart';
import 'package:share_run_challenge/l10n/remaining_surface.dart';

/// 기부처(수혜 단체)는 아직 정해지지 않았다(결정: 정해질 때까지 화면에 이름을 쓰지 않는다).
/// 유니세프한국위원회가 명칭·로고 사용을 불허했다(2026-10-31 회신). 다른 공익
/// 단체 이름도 수혜처로 확정되지 않았으니 같은 이유로 화면에 쓰지 않는다.
const _forbiddenBeneficiaryNames = <String>[
  '유니세프',
  'UNICEF',
  '사랑의열매',
  '굿네이버스',
  '적십자',
  '월드비전',
  '세이브더칠드런',
  '해피빈',
  '같이가치',
];

/// mini_bot_intent.dart의 사용자 입력 단어 인식(`text.contains('유니세프')`)과
/// 짝지어진 카탈로그 항목이다. 화면에 그려지지 않고 트리거 매칭에만 쓰이므로
/// 제외 대상에 넣는다(위치만 보고 그대로 둔다).
const _wordRecognitionCatalogKey = 'mini_bot.mini_bot_intent.body.76';

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
      for (final name in _forbiddenBeneficiaryNames) {
        expect(text, isNot(contains(name)), reason: text);
      }
    }
  });

  test('the demo tournament data names no beneficiary', () {
    final texts = <String>[];
    for (final tournament in MockDemoData.tournaments()) {
      texts
        ..add(tournament.title)
        ..add(tournament.sponsorName)
        ..addAll(tournament.sponsorBillboardMessages);
    }
    for (final text in texts) {
      for (final name in _forbiddenBeneficiaryNames) {
        expect(text, isNot(contains(name)), reason: text);
      }
    }
  });

  test('the remaining-surface translation table names no beneficiary', () {
    for (final key in RemainingSurface.keys) {
      if (key == _wordRecognitionCatalogKey) continue;
      for (final languageCode in RemainingSurface.appLanguageOf.values) {
        final text = RemainingSurface.text(Locale(languageCode), key);
        for (final name in _forbiddenBeneficiaryNames) {
          expect(
            text,
            isNot(contains(name)),
            reason: '$key ($languageCode): $text',
          );
        }
      }
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
    expect(AppStrings.personalSponsorDonationDesc, contains('운영자 이름'));
  });

  // 소유자가 정한 이름이다(2026-10-17). 소유자의 폰에서 계속 쓰는 크루명이라 바꾸지 않는다.
  test('the one sample crew is the owner\'s crew, named the same everywhere', () {
    expect(AppStrings.runningCrewMyCrewName, '인천 논현 최강 크루');
    expect(AppStrings.crewManagerCrewName, '인천 논현 최강 크루');
  });
}
