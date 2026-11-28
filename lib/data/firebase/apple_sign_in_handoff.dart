import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// What one Sign in with Apple on the iPhone gave us besides the ID token.
class AppleSignInDetails {
  const AppleSignInDetails({
    required this.rawNonce,
    this.givenName,
    this.familyName,
  });

  /// The raw nonce. Apple got only its SHA-256; the server gets this to check
  /// that the token was made for this sign-in.
  final String rawNonce;

  /// Apple sends the name only the first time a person signs in to the app.
  final String? givenName;
  final String? familyName;
}

/// Carries the nonce and the first-time name from the Apple sheet to the
/// server call and the nickname sheet, without changing every login API.
///
/// Nothing here is saved to disk or sent anywhere by itself. The name is only
/// a suggestion the person can change before choosing a nickname.
abstract final class AppleSignInHandoff {
  static const _maxRemembered = 4;
  static final _byToken = <String, AppleSignInDetails>{};
  static String? _suggestedNickname;

  /// A random nonce (32 bytes, URL-safe). Use [sha256Of] for Apple.
  static String newRawNonce([Random? random]) {
    final source = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => source.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String sha256Of(String rawNonce) =>
      sha256.convert(utf8.encode(rawNonce)).toString();

  static void remember(String idToken, AppleSignInDetails details) {
    _byToken.remove(idToken);
    _byToken[idToken] = details;
    while (_byToken.length > _maxRemembered) {
      _byToken.remove(_byToken.keys.first);
    }
    final suggestion = nicknameFrom(details.givenName, details.familyName);
    if (suggestion != null) _suggestedNickname = suggestion;
  }

  /// The raw nonce used for [idToken], or null (older flow, or Android).
  static String? nonceFor(String idToken) => _byToken[idToken]?.rawNonce;

  /// The name Apple gave on the first sign-in, once, as a nickname suggestion.
  static String? takeSuggestedNickname() {
    final value = _suggestedNickname;
    _suggestedNickname = null;
    return value;
  }

  /// Given name first, else family name. No spaces, at most 12 characters.
  /// Null when Apple sent no name (every sign-in after the first).
  static String? nicknameFrom(String? givenName, String? familyName) {
    for (final part in [givenName, familyName]) {
      final compact = (part ?? '').replaceAll(RegExp(r'\s+'), '');
      if (compact.isNotEmpty) {
        return compact.length > 12 ? compact.substring(0, 12) : compact;
      }
    }
    return null;
  }

  /// Tests only.
  static void debugReset() {
    _byToken.clear();
    _suggestedNickname = null;
  }
}
