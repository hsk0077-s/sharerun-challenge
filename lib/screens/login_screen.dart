import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/router/route_names.dart';
import '../core/auth/local_auth_session.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/apple_login_button.dart';
import '../core/widgets/google_signin_button.dart';
import '../core/widgets/kakao_login_button.dart';
import '../core/widgets/naver_login_button.dart';
import '../core/widgets/src_gradient_background.dart';
import '../core/widgets/src_logo_header.dart';
import '../core/widgets/src_text_field.dart';
import '../data/api/identity_api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../features/auth/login_connection_providers.dart';
import '../features/auth/new_social_account_notice.dart';

/// 로그인 화면 (Screen 1) — src-1 목업 정합 UI.
/// 버튼 순서: Google → Apple → Naver → Kakao.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _referralController = TextEditingController();
  var _kakaoBusy = false;
  var _naverBusy = false;
  var _referralFieldVisible = false;

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _rememberLogin({String? uid}) async {
    final resolved = (uid != null && uid.isNotEmpty)
        ? uid
        : (ref.read(firebaseAuthProvider).currentUser?.uid ?? '');
    if (resolved.isEmpty) return;
    await ref.read(localAuthStoreProvider).saveSession(
          uid: resolved,
          isGuest: false,
        );
    ref.read(persistedAuthSessionProvider.notifier).replace(
          LocalAuthSession(uid: resolved, isGuest: false),
        );
  }

  /// Signup/login still succeeds when redeem fails.
  Future<void> _redeemEnteredReferral() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.referralRedeemFailed)),
        );
        return;
      }
      await ref.read(userRepositoryProvider).ensureUserDocument(uid: uid);
      await ref
          .read(securedActionApiClientProvider)
          .redeemReferralCode(code)
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.referralRedeemSuccess)),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.referralRedeemFailed)),
      );
    } catch (e, st) {
      debugPrint('redeemReferralCode: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorMessage.from(e))),
      );
    }
  }

  /// 카카오·네이버 공통. 새 계정이면 닉네임 전에 안내하고, 취소하면 로그아웃한다.
  /// 이메일로 기존 계정과 합치지는 않는다. 연결은 설정 > 로그인 연결의
  /// /kakao/link, /naver/link 를 쓴다.
  Future<void> _finishSocialLogin({
    required ProviderLoginResult result,
    required String uid,
    required String providerName,
    required String successMessage,
  }) async {
    await _rememberLogin(uid: uid);
    if (!mounted) return;
    if (result.newAccount && uid.isNotEmpty) {
      await NewSocialAccountNoticeStore.mark(
        uid: uid,
        providerName: providerName,
      );
      if (!mounted) return;
      final proceed = await showNewSocialAccountNotice(
        context,
        providerName: providerName,
      );
      if (!mounted) return;
      if (!proceed) {
        await signOutAfterNewSocialAccountCancel(ref);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.newSocialAccountSignedOut)),
        );
        return;
      }
      await NewSocialAccountNoticeStore.clear();
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        duration: const Duration(milliseconds: 1300),
      ),
    );
    await _redeemEnteredReferral();
    if (!mounted) return;
    final termsAccepted =
        ref.read(activeUserProfileProvider).value?.termsAccepted ?? false;
    Navigator.of(context).pushReplacementNamed(
      !result.newAccount && termsAccepted
          ? RouteNames.home
          : RouteNames.termsAgreement,
    );
  }

  Future<void> _onGoogle() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userCredential = await authRepo.signInWithGoogle();

      if (userCredential != null && mounted) {
        await _rememberLogin(uid: userCredential.user?.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구글 로그인에 성공했습니다!'),
            duration: Duration(milliseconds: 1300),
          ),
        );
        await _redeemEnteredReferral();
        if (!mounted) return;
        final termsAccepted =
            ref.read(activeUserProfileProvider).value?.termsAccepted ?? false;
        Navigator.of(context).pushReplacementNamed(
          termsAccepted ? RouteNames.home : RouteNames.termsAgreement,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  }

  Future<void> _onNaver() async {
    if (_naverBusy) return;
    setState(() => _naverBusy = true);
    try {
      final token = await ref.read(naverAccessTokenProvider)();
      if (token == null || !mounted) return; // 사용자가 창을 닫음

      // 서버가 네이버 토큰을 확인하고 우리 계정과 짝지어 로그인 열쇠를 준다.
      final result =
          await ref.read(identityApiClientProvider).naverLogin(token);
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithCustomToken(result.customToken);
      if (!mounted) return;
      await _finishSocialLogin(
        result: result,
        uid: credential.user?.uid ?? '',
        providerName: '네이버',
        successMessage: '네이버 로그인에 성공했습니다!',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네이버 로그인 실패: ${ApiErrorMessage.from(e)}')),
      );
    } finally {
      if (mounted) setState(() => _naverBusy = false);
    }
  }

  Future<void> _onKakao() async {
    if (_kakaoBusy) return;
    setState(() => _kakaoBusy = true);
    try {
      final token = await ref.read(kakaoAccessTokenProvider)();
      if (token == null || !mounted) return; // 사용자가 창을 닫음

      // 서버가 카카오 토큰을 확인하고 우리 계정과 짝지어 로그인 열쇠를 준다.
      final result =
          await ref.read(identityApiClientProvider).kakaoLogin(token);
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithCustomToken(result.customToken);
      if (!mounted) return;
      await _finishSocialLogin(
        result: result,
        uid: credential.user?.uid ?? '',
        providerName: '카카오',
        successMessage: '카카오 로그인에 성공했습니다!',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 실패: ${ApiErrorMessage.from(e)}')),
      );
    } finally {
      if (mounted) setState(() => _kakaoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth * AppShapes.loginContentWidthFactor;

    return Scaffold(
      body: SRCGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: (screenWidth - contentWidth) / 2,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: contentWidth,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SRCLogoHeader(),
                        const Spacer(flex: 3),

                        // 1) Google — 구글 공식 규격 버튼(글자만 한국어)
                        GoogleSignInButton(
                            onPressed: _onGoogle, fullWidth: true),
                        const SizedBox(height: AppShapes.loginButtonSpacing),

                        // 2) Apple (구글 아래 유지) — 준비 중
                        AppleLoginButton(
                          label: AppStrings.loginApple,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.loginComingSoon('Apple'),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppShapes.loginButtonSpacing),

                        // 3) Kakao — 카카오 공식 버튼 이미지
                        KakaoLoginButton(
                          busy: _kakaoBusy,
                          maxWidth: contentWidth,
                          onPressed: _onKakao,
                        ),
                        const SizedBox(height: AppShapes.loginButtonSpacing),

                        // 4) Naver — 네이버 공식 버튼 이미지
                        NaverLoginButton(
                          busy: _naverBusy,
                          maxWidth: contentWidth,
                          onPressed: _onNaver,
                        ),

                        const Spacer(flex: 2),

                        if (_referralFieldVisible)
                          SRCTextField(
                            label: AppStrings.loginReferralLabel,
                            hintText: AppStrings.loginReferralHint,
                            controller: _referralController,
                          )
                        else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: AppColors.primaryMint,
                              ),
                              onPressed: () => setState(
                                () => _referralFieldVisible = true,
                              ),
                              child: const Text(
                                '초대 코드가 있으신가요?',
                                style: AppTextStyles.link,
                              ),
                            ),
                          ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
