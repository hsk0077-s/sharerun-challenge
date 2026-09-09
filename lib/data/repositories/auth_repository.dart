import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

import '../../core/config/app_env.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn.instance,
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
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

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // 2. [v7 API 대규모 변경점] signIn()이 삭제되고 authenticate()로 교체되었습니다.
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) {
        return null; // 사용자가 로그인 창을 닫은 경우
      }

      // 3. 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. [v7 API 대규모 변경점] accessToken이 분리되었으므로, Firebase 통신에 필수적인 idToken만 주입합니다.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
      
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw Exception('구글 로그인 설정 오류: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase 로그인 실패: ${e.message}');
    } catch (e) {
      throw Exception('구글 로그인 중 알 수 없는 오류 발생: $e');
    }
  }

  Future<Object?> signInWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.loggedOut) {
        return null; // 사용자가 로그인 창을 닫은 경우
      }
      if (result.status != NaverLoginStatus.loggedIn) {
        throw Exception(result.errorMessage ?? '네이버 로그인 실패');
      }

      // 앱 전환 후에도 토큰이 유지되는지 재확인
      final token = result.accessToken ??
          await FlutterNaverLogin.getCurrentAccessToken();
      if (token.accessToken.isEmpty) {
        throw Exception('네이버 액세스 토큰을 가져오지 못했습니다.');
      }

      return result;
    } catch (e) {
      throw Exception('네이버 로그인 중 오류 발생: $e');
    }
  }

  /// Kakao Account interactive login → token.
  ///
  /// KakaoTalk SSO can return a token with no UI ("prepass").
  /// Always clear local tokens and use Account login with [Prompt.login]
  /// so the official Kakao consent / account UI is shown.
  Future<Object?> signInWithKakao() async {
    try {
      try {
        await kakao.TokenManagerProvider.instance.manager.clear();
      } catch (_) {}
      try {
        if (await kakao.AuthApi.instance.hasToken()) {
          await kakao.UserApi.instance.logout();
        }
      } catch (_) {}

      await kakao.UserApi.instance.loginWithKakaoAccount(
        prompts: [kakao.Prompt.login],
      );

      return kakao.UserApi.instance.me();
    } on kakao.KakaoClientException catch (e) {
      if (e.reason == kakao.ClientErrorCause.cancelled) {
        return null;
      }
      throw Exception('카카오 로그인 실패: ${e.message}');
    } catch (e) {
      throw Exception('카카오 로그인 중 오류 발생: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('로그아웃 실패: $e');
    }
  }
}