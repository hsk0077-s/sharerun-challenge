import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'apple_sign_in_handoff.dart';

/// Asks Apple for a credential. The default is the real Sign in with Apple
/// sheet; tests pass a fake.
typedef AppleCredentialRequest = Future<AuthorizationCredentialAppleID> Function({
  required List<AppleIDAuthorizationScopes> scopes,
  String? nonce,
});

Future<AuthorizationCredentialAppleID> _requestFromApple({
  required List<AppleIDAuthorizationScopes> scopes,
  String? nonce,
}) =>
    SignInWithApple.getAppleIDCredential(scopes: scopes, nonce: nonce);

/// Sign in with Apple on the iPhone (Apple's own sheet, no web page).
///
/// Each sign-in uses a fresh nonce: Apple gets its SHA-256, the server later
/// gets the raw value with the token (see [AppleSignInHandoff]). The name and
/// e-mail come only on the first sign-in; "Hide My Email" gives a
/// privaterelay.appleid.com address, which the server treats like any e-mail.
class AppleIdTokenFetcher {
  AppleIdTokenFetcher({
    AppleCredentialRequest? request,
    String Function()? newRawNonce,
  })  : _request = request ?? _requestFromApple,
        _newRawNonce = newRawNonce ?? AppleSignInHandoff.newRawNonce;

  final AppleCredentialRequest _request;
  final String Function() _newRawNonce;

  static const _scopes = [
    AppleIDAuthorizationScopes.email,
    AppleIDAuthorizationScopes.fullName,
  ];

  /// Apple's identity token for the server, or null when the sheet was closed.
  /// Throws [AppleTokenMissing] when Apple answered without a token.
  Future<String?> idToken() async {
    final rawNonce = _newRawNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _request(
        scopes: _scopes,
        nonce: AppleSignInHandoff.sha256Of(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
    final token = credential.identityToken;
    if (token == null || token.isEmpty) throw const AppleTokenMissing();
    AppleSignInHandoff.remember(
      token,
      AppleSignInDetails(
        rawNonce: rawNonce,
        givenName: credential.givenName,
        familyName: credential.familyName,
      ),
    );
    return token;
  }

  /// A fresh one-time code so the server can revoke the Apple grant when the
  /// account is deleted. Null when the sheet was closed or Apple sent none.
  Future<String?> authorizationCode() async {
    try {
      final credential = await _request(scopes: const []);
      final code = credential.authorizationCode;
      return code.isEmpty ? null : code;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }
}

class AppleTokenMissing implements Exception {
  const AppleTokenMissing();
}
