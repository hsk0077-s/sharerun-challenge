import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/home/home_cards.dart';
import 'package:share_run_challenge/features/iap/widgets/dia_notice.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
import 'package:share_run_challenge/l10n/guidance_copy.dart';
import 'package:share_run_challenge/l10n/guide_chrome.dart';
import 'package:share_run_challenge/screens/donation_settlement_screen.dart';

void main() {
  test('every supported locale has native wearable brand steps', () {
    final missing = GuideChrome.missingKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
    expect(GuideChrome.missingKeys().length, 0);
    for (final locale in ShareRunLocalizations.supportedLocales) {
      final chrome = GuideChrome.of(locale);
      expect(chrome.brands.keys, containsAll(GuideChrome.brandIds));
      for (final id in GuideChrome.brandIds) {
        expect(chrome.brands[id]!.steps, hasLength(3), reason: '${locale.languageCode}.$id');
      }
    }
  });

  test('donation, shop funding, and DIA notice exist in every locale', () {
    final missing = missingGuidanceKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('Korean guidance matches the strings the screens already shipped', () {
    const ko = Locale('ko', 'KR');
    final donation = DonationGuidance.of(ko);
    final shop = ShopFundingGuidance.of(ko);
    final dia = DiaNoticeGuidance.of(ko);
    expect(donation.intro, DonationSettlementScreen.intro);
    expect(donation.capReachedSettlement, DonationSettlementScreen.capReachedLine);
    expect(donation.disclaimer, DonationSettlementScreen.disclaimer);
    expect(donation.rule, HomeDonationCard.rule);
    expect(donation.budget, HomeDonationCard.budget);
    expect(donation.capReachedHome, HomeDonationCard.capReachedLine);
    expect(shop.title, AppStrings.storeFundingTitle);
    expect(shop.preparing, AppStrings.storeFundingPreparing);
    expect(shop.preparingNote, AppStrings.storeFundingPreparingNote);
    expect(shop.monthLabel, AppStrings.storeFundingMonthLabel);
    expect(shop.note, AppStrings.storeFundingNote);
    expect(shop.allReached, AppStrings.storeFundingAllReached);
    expect(shop.capReached, AppStrings.storeFundingCapReached);
    expect(dia.lines, DiaNoticeCard.lines);
    expect(dia.lines.first, contains('100'));
    expect(dia.lines.last, contains('7'));
    expect(dia.lines.last, contains('100'));
  });

  test('a locale with no entry falls back to English, not to a blank sheet', () {
    final chrome = GuideChrome.of(const Locale('sv', 'SE'));
    expect(chrome.brands['garmin']!.steps, hasLength(3));
    expect(chrome.brands['garmin']!.steps.first, contains('Garmin Connect'));
  });
}
