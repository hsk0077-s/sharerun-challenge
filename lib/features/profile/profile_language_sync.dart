import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_locale.dart';
import '../../l10n/app_localizations.dart';

/// Tells the server which language and country this phone uses, so the admin can
/// sort runners by language. It runs after sign-in and again when the runner
/// picks another language in Settings. A failure is ignored and tried again next
/// time, because nothing in the app depends on it.
abstract final class ProfileLanguageSync {
  static const prefsKey = 'profile_language_sent_v1';

  /// The shipped language the app shows: the runner's choice, else the phone's.
  static String effectiveLanguage({Locale? chosen, required Locale device}) {
    return resolveAppLocale(
      chosen ?? device,
      ShareRunLocalizations.supportedLocales,
    ).languageCode;
  }

  /// Two capital letters, or null when the phone does not say.
  static String? countryOf(Locale device) {
    final code = device.countryCode?.toUpperCase();
    if (code == null || !RegExp(r'^[A-Z]{2}$').hasMatch(code)) return null;
    return code;
  }

  /// Sends the pair unless the server already has it for this account. Returns
  /// whether it sent. The saved stamp includes [uid], so a second account on the
  /// same phone is sent too.
  static Future<bool> sync({
    required String uid,
    required Future<void> Function(String language, String? countryCode) send,
    required Locale device,
    Locale? chosen,
    SharedPreferences? prefs,
  }) async {
    final language = effectiveLanguage(chosen: chosen, device: device);
    final country = countryOf(device);
    final stamp = '$uid|$language|${country ?? ''}';
    try {
      final store = prefs ?? await SharedPreferences.getInstance();
      if (store.getString(prefsKey) == stamp) return false;
      await send(language, country);
      await store.setString(prefsKey, stamp);
      return true;
    } catch (_) {
      return false;
    }
  }
}
