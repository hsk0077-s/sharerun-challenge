import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

/// SharedPreferences key for the language the user picked inside the app.
/// Absent = follow the phone's language.
const appLocalePrefsKey = 'app_locale_choice_v1';

/// Language names written in their own language, in the order shown in the
/// picker. The codes match [ShareRunLocalizations.supportedLocales].
const appLocaleChoices = <({String code, String name})>[
  (code: 'ko', name: '한국어'),
  (code: 'en', name: 'English'),
  (code: 'ja', name: '日本語'),
  (code: 'zh', name: '中文'),
  (code: 'es', name: 'Español'),
  (code: 'pt', name: 'Português'),
  (code: 'de', name: 'Deutsch'),
  (code: 'fr', name: 'Français'),
  (code: 'vi', name: 'Tiếng Việt'),
  (code: 'th', name: 'ไทย'),
  (code: 'id', name: 'Bahasa Indonesia'),
];

/// Picks the shipped locale for [wanted] by language code; anything we do not
/// ship (or no locale at all) falls back to English instead of Korean.
Locale resolveAppLocale(
  Locale? wanted,
  Iterable<Locale> supported,
) {
  if (wanted != null) {
    for (final l in supported) {
      if (l.languageCode == wanted.languageCode) return l;
    }
  }
  for (final l in supported) {
    if (l.languageCode == 'en') return l;
  }
  return supported.first;
}

Locale? _fromCode(String? code) {
  if (code == null) return null;
  for (final l in ShareRunLocalizations.supportedLocales) {
    if (l.languageCode == code) return l;
  }
  return null;
}

/// Reads the saved choice; null when the user never chose.
Future<Locale?> loadSavedAppLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return _fromCode(prefs.getString(appLocalePrefsKey));
  } catch (_) {
    return null;
  }
}

/// The language the user picked in the app, or null to follow the phone.
final appLocaleProvider =
    NotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);

/// Starting value, overridden in `main.dart` after loading the saved choice.
final initialAppLocaleProvider = Provider<Locale?>((ref) => null);

class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => ref.read(initialAppLocaleProvider);

  Future<void> choose(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(appLocalePrefsKey);
      } else {
        await prefs.setString(appLocalePrefsKey, locale.languageCode);
      }
    } catch (_) {
      // The choice still applies for this run.
    }
  }
}
