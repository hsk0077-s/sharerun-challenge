import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/features/home/home_cards.dart';
import 'package:share_run_challenge/features/iap/widgets/dia_notice.dart';
import 'package:share_run_challenge/features/profile/invite_copy.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
import 'package:share_run_challenge/features/accessories/accessory_catalog.dart';
import 'package:share_run_challenge/features/accessories/accessory_names.dart';
import 'package:share_run_challenge/features/shop/donation_match_line.dart';
import 'package:share_run_challenge/l10n/commerce_copy.dart';
import 'package:share_run_challenge/l10n/dia_refund_copy.dart';
import 'package:share_run_challenge/l10n/guidance_copy.dart';
import 'package:share_run_challenge/l10n/shop_catalog_copy.dart';
import 'package:share_run_challenge/l10n/guide_chrome.dart';
import 'package:share_run_challenge/l10n/surface_copy.dart';
import 'package:share_run_challenge/screens/donation_settlement_screen.dart';
import 'package:share_run_challenge/screens/fair_earning_policy_screen.dart';

void main() {
  test('every supported locale has native wearable brand steps', () {
    final missing = GuideChrome.missingKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
    expect(GuideChrome.missingKeys().length, 0);
    for (final locale in ShareRunLocalizations.supportedLocales) {
      final chrome = GuideChrome.of(locale);
      expect(chrome.brands.keys, containsAll(GuideChrome.brandIds));
      for (final id in GuideChrome.brandIds) {
        expect(chrome.brands[id]!.steps, hasLength(3),
            reason: '${locale.languageCode}.$id');
      }
    }
  });

  test('donation, shop funding, and DIA notice exist in every locale', () {
    final missing = missingGuidanceKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test(
      'shop items, refund sheet, accessories, and donation match exist in every locale',
      () {
    final missing = missingCommerceKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('fair earning, shop chrome, and grade guide exist in every locale', () {
    final missing = missingSurfaceKeys();
    expect(missing, isEmpty, reason: missing.join('\n'));
    expect(FairEarningCopy.of(const Locale('ko')).screenTitle, '공정한 적립 정책');
    expect(
      FairEarningPolicyScreen.sections.map((block) => block.title),
      contains('검증 기준'),
    );
  });

  test('core phrases and invite copy exist in every locale', () {
    final missing = [...missingCoreLocaleKeys(), ...missingInviteKeys()];
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('watchOS copy files carry the same 11 language codes and pairing errors',
      () {
    const codes = [
      'ko',
      'en',
      'ja',
      'zh',
      'es',
      'pt',
      'de',
      'fr',
      'vi',
      'th',
      'id'
    ];
    const pairing = [
      'no_server',
      'need_six_digits',
      'bad_url',
      'rate_limited',
      'watch_limit',
      'bad_code',
      'auth_url',
      'sign_in_failed',
      'offline',
    ];
    for (final path in [
      'watchos_app/ShareRunWatch/WatchCopy.swift',
      'ios/ShareRunWatch Watch App/WatchCopy.swift',
    ]) {
      final text = File(path).readAsStringSync();
      for (final code in codes) {
        expect(text.contains('"$code"'), isTrue, reason: '$path $code');
      }
      for (final key in pairing) {
        expect(text.contains('"$key"'), isTrue, reason: '$path $key');
      }
      expect(text.contains('원어민 검수 전'), isTrue, reason: path);
    }
  });

  test('Korean guidance matches the strings the screens already shipped', () {
    const ko = Locale('ko', 'KR');
    final donation = DonationGuidance.of(ko);
    final shop = ShopFundingGuidance.of(ko);
    final dia = DiaNoticeGuidance.of(ko);
    expect(donation.intro, DonationSettlementScreen.intro);
    expect(
        donation.capReachedSettlement, DonationSettlementScreen.capReachedLine);
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

  test('refund, donation match, shop items, and accessory names cover 11 locales', () {
    expect(koreanOnlyGuidanceSurfaces, isEmpty);
    const ko = Locale('ko');
    expect(
      donationMatchContributionLine(
        sponsorName: 'SRC',
        contributorName: '러너상',
        companyWon: 1000,
        locale: ko,
      ),
      'SRC 명의 1,000원 · 러너상 기여',
    );
    for (final locale in ShareRunLocalizations.supportedLocales) {
      final refund = DiaRefundCopy.of(locale);
      expect(refund.sheetTitle, isNotEmpty);
      expect(refund.window(7), isNotEmpty);
      expect(refund.openButton, isNotEmpty);
      final shop = ShopCatalogCopy.of(locale);
      for (final id in ShopCatalogCopy.itemIds) {
        expect(shop.storeName(id), isNotEmpty, reason: '${locale.languageCode}.$id');
        expect(shop.title(id), isNotEmpty);
        expect(shop.description(id), isNotEmpty);
      }
      expect(shop.pass('title'), isNotEmpty);
      expect(shop.pass('cosmeticNote'), isNotEmpty);
      if (locale.languageCode != 'en') {
        expect(shop.pass('title'), isNot(ShopCatalogCopy.of(const Locale('en')).pass('title')));
      }
      final line = donationMatchContributionLine(
        sponsorName: 'SRC',
        contributorName: 'Ada',
        companyWon: 1000,
        locale: locale,
      );
      expect(line, contains('1,000'));
      expect(line, contains('Ada'));
    }
    expect(accessoryCatalog, hasLength(46));
    for (final item in accessoryCatalog) {
      expect(item.displayName(ko), item.nameKo);
      for (final code in accessoryNameLanguages) {
        final name = item.displayName(Locale(code));
        expect(name, isNotEmpty, reason: '${item.id}.$code');
        expect(name, isNot(item.nameKo), reason: '${item.id}.$code');
      }
    }
  });

  test('a locale with no entry falls back to English, not to a blank sheet', () {
    final chrome = GuideChrome.of(const Locale('sv', 'SE'));
    expect(chrome.brands['garmin']!.steps, hasLength(3));
    expect(chrome.brands['garmin']!.steps.first, contains('Garmin Connect'));
  });
}
