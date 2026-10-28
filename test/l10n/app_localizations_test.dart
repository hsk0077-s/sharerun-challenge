import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';

void main() {
  test('supports all 11 global running & challenge locales with non-empty strings', () {
    expect(ShareRunLocalizations.supportedLocales, hasLength(11));
    for (final locale in ShareRunLocalizations.supportedLocales) {
      final s = ShareRunLocalizations.ofLocale(locale);
      expect(s.appTitle, isNotEmpty, reason: locale.toLanguageTag());
      expect(s.slogan, isNotEmpty, reason: locale.toLanguageTag());
      expect(s.deviceConnectionTitle, isNotEmpty, reason: locale.toLanguageTag());
      expect(s.bleHrSectionTitle, isNotEmpty, reason: locale.toLanguageTag());
      expect(s.pedometerRuleSummary, contains('100'), reason: locale.toLanguageTag());
      expect(s.charityDisclosure, isNotEmpty, reason: locale.toLanguageTag());
      expect(s.charityDisclosure.toLowerCase(), isNot(contains('unicef')));
    }
    // Unknown locale falls back to English cleanly
    expect(
      ShareRunLocalizations.ofLocale(const Locale('pl')).localeCode,
      'en-US',
    );
  });

  test('store_listings pack exists for all 11 target markets', () {
    const locales = [
      'ko-KR',
      'en-US',
      'ja-JP',
      'zh-TW',
      'es-ES',
      'pt-BR',
      'de-DE',
      'fr-FR',
      'vi-VN',
      'th-TH',
      'id-ID',
    ];
    for (final loc in locales) {
      final file = File('store_listings/$loc/store-listing.md');
      expect(file.existsSync(), isTrue, reason: 'Missing store_listings/$loc/store-listing.md');
      final content = file.readAsStringSync();
      expect(content, contains('10 SHARE'), reason: loc);
      expect(content, contains('0x180D'), reason: loc);
      expect(content, contains('https://share-run-challenge.web.app/privacy.html'), reason: loc);
    }
  });
}
