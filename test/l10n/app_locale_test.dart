import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/l10n/app_locale.dart';
import 'package:share_run_challenge/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const supported = ShareRunLocalizations.supportedLocales;

  group('resolveAppLocale', () {
    test('matches shipped languages by language code', () {
      expect(resolveAppLocale(const Locale('ja', 'JP'), supported).languageCode,
          'ja');
      expect(resolveAppLocale(const Locale('vi'), supported).languageCode,
          'vi');
      expect(resolveAppLocale(const Locale('zh', 'CN'), supported).languageCode,
          'zh');
    });

    test('falls back to English, not Korean, for unsupported languages', () {
      expect(resolveAppLocale(const Locale('ru'), supported).languageCode, 'en');
      expect(resolveAppLocale(null, supported).languageCode, 'en');
    });
  });

  group('appLocaleProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts as follow-phone and saves a choice', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(appLocaleProvider), isNull);
      await c.read(appLocaleProvider.notifier).choose(const Locale('ja', 'JP'));
      expect(c.read(appLocaleProvider)?.languageCode, 'ja');
      expect((await loadSavedAppLocale())?.languageCode, 'ja');
    });

    test('choosing null clears the saved choice', () async {
      SharedPreferences.setMockInitialValues({appLocalePrefsKey: 'vi'});
      expect((await loadSavedAppLocale())?.languageCode, 'vi');
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(appLocaleProvider.notifier).choose(null);
      expect(await loadSavedAppLocale(), isNull);
    });

    test('every picker entry maps to a shipped locale', () {
      for (final choice in appLocaleChoices) {
        expect(
          supported.any((l) => l.languageCode == choice.code),
          isTrue,
          reason: choice.code,
        );
      }
      expect(appLocaleChoices.length, supported.length);
    });
  });
}
