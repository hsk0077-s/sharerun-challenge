import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/app_env.dart';
import '../../l10n/remaining_surface.dart';

class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  var _googleInitialized = false;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    final serverClientId = AppEnv.googleWebClientId.trim();
    await _googleSignIn.initialize(
      serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    );
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return _firebaseAuth.signInWithCredential(oauthCredential);
  }

  /// 애플 로그인 창을 띄워 서버가 확인할 ID 토큰만 받는다. 닫으면 null.
  ///
  /// iOS/macOS는 애플이 준 identityToken을 그대로 쓴다. 안드로이드에는 애플 앱이
  /// 없어서 Firebase의 웹 로그인(signInWithProvider)을 거치고, 그 Firebase ID 토큰을
  /// 보낸다. 서버는 두 토큰 모두 `sub`가 같은 애플 사용자 번호로 확인한다.
  Future<String?> obtainAppleIdToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        final token = credential.identityToken;
        if (token == null || token.isEmpty) {
          throw Exception(
            RemainingSurface.trNow(
              'auth_service.body',
              '애플 로그인 토큰을 가져오지 못했습니다.',
            ),
          );
        }
        return token;
      }
      final provider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      final credential = await _firebaseAuth.signInWithProvider(provider);
      final token = await credential.user?.getIdToken();
      if (token == null || token.isEmpty) {
        throw Exception(
          RemainingSurface.trNow(
            'auth_service.body',
            '애플 로그인 토큰을 가져오지 못했습니다.',
          ),
        );
      }
      return token;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' ||
          e.code == 'canceled' ||
          e.code == 'popup-closed-by-user') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError(
        RemainingSurface.trNow('auth_service.body.2', '로그인된 계정이 없습니다.'),
      );
    }
    await user.sendEmailVerification();
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError(
        RemainingSurface.trNow('auth_service.body.2', '로그인된 계정이 없습니다.'),
      );
    }
    await user.delete();
  }

  Future<User?> ensureAnonymousSession() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    final credential = await _firebaseAuth.signInAnonymously();
    return credential.user;
  }

  /// Creates a Firebase anonymous session used for guest (test) login.
  Future<User> signInAsGuest() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError(
        RemainingSurface.trNow('auth_service.body.3', '게스트 로그인에 실패했습니다.'),
      );
    }
    return user;
  }

  bool get isGuestUser => _firebaseAuth.currentUser?.isAnonymous ?? false;
}
