import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invite_link.dart';

/// Reads the invite code a friend's brag card link left in the Play Install
/// Referrer, once, on the first launch after install.
///
/// This only fills the invite code field. Linking the accounts and any reward
/// still go through the existing referral flow and its abuse rules.
abstract final class InstallReferrer {
  static const channel = MethodChannel('share_run/install_referrer');
  static const consumedKey = 'install_referrer_consumed_v1';

  /// Test hook. Null asks the Android Play Install Referrer service.
  @visibleForTesting
  static Future<String?> Function()? debugReadOverride;

  /// `invite=ABCD2345` or `utm_source=x&invite=ABCD2345` -> `ABCD2345`.
  /// Empty, missing, or malformed values give null.
  static String? parseInviteCode(String? referrer) {
    final raw = referrer?.trim() ?? '';
    if (raw.isEmpty || raw.length > 512) return null;
    var text = raw;
    // A double-encoded value (`invite%3DABC`) still has no `=`.
    if (!text.contains('=') && text.contains('%')) {
      try {
        text = Uri.decodeComponent(text);
      } catch (_) {
        return null;
      }
    }
    Map<String, String> query;
    try {
      query = Uri.splitQueryString(text);
    } catch (_) {
      return null;
    }
    return normalizeInviteCode(query['invite']);
  }

  /// The invite code from the install referrer, or null. Asks Play at most
  /// once per install: the answer (code or none) is remembered so a later
  /// launch, or logging out and in again, never re-fills an old code.
  static Future<String?> takeInviteCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(consumedKey) == true) return null;
      final hook = debugReadOverride;
      final raw = hook != null
          ? await hook()
          : await channel.invokeMethod<String>('getInstallReferrer');
      await prefs.setBool(consumedKey, true);
      return parseInviteCode(raw);
    } catch (e) {
      debugPrint('InstallReferrer.takeInviteCode: $e');
      return null; // not consumed: try again next launch
    }
  }
}
