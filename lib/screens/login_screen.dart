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
import '../features/auth/existing_account_question.dart';
import '../features/auth/login_connection_providers.dart';

enum _LinkStep { linked, pickAgain, stopped }

/// 로그인 화면 (Screen 1) — src-1 목업 정합 UI.
/// 버튼 순서: Google → Apple → Naver → Kakao.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _referralController = TextEditingController();
  var _socialBusy = false;
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

  /// 구글·카카오·네이버. 서버가 확인된 이메일이면 기존 계정의 맞춤 토큰을 주고,
  /// 아니면 계정을 만들기 전에 예전에 쓰던 방법을 묻는다.
  Future<void> _startProvider({
    required String provider,
    required String providerName,
    required String successMessage,
    required String failureMessage,
    required Future<String?> Function() askToken,
  }) async {
    if (_socialBusy) return;
    setState(() => _socialBusy = true);
    try {
      final token = await askToken();
      if (token == null || !mounted) return;
      await _loginProvider(
        provider: provider,
        token: token,
        providerName: providerName,
        successMessage: successMessage,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failureMessage${ApiErrorMessage.from(e)}')),
      );
    } finally {
      if (mounted) setState(() => _socialBusy = false);
    }
  }

  Future<void> _onGoogle() => _startProvider(
        provider: 'google',
        providerName: '구글',
        successMessage: '구글 로그인에 성공했습니다!',
        failureMessage: '로그인 실패: ',
        askToken: () => ref.read(googleIdTokenProvider)(),
      );

  Future<void> _onNaver() => _startProvider(
        provider: 'naver',
        providerName: '네이버',
        successMessage: '네이버 로그인에 성공했습니다!',
        failureMessage: '네이버 로그인 실패: ',
        askToken: () => ref.read(naverAccessTokenProvider)(),
      );

  Future<void> _onKakao() => _startProvider(
        provider: 'kakao',
        providerName: '카카오',
        successMessage: '카카오 로그인에 성공했습니다!',
        failureMessage: '카카오 로그인 실패: ',
        askToken: () => ref.read(kakaoAccessTokenProvider)(),
      );

  /// 연결에 성공하면 false(앱으로 들어감). 다시 고르면 true.
  Future<bool> _loginProvider({
    required String provider,
    required String token,
    required String providerName,
    required String successMessage,
    bool createAccount = false,
    bool offerChoice = true,
    String? linkProvider,
    String? linkToken,
  }) async {
    final api = ref.read(identityApiClientProvider);
    final ProviderLoginResult result = switch (provider) {
      'kakao' => await api.kakaoLogin(token, createAccount: createAccount),
      'naver' => await api.naverLogin(token, createAccount: createAccount),
      'google' => await api.googleLogin(token, createAccount: createAccount),
      _ => throw StateError(provider),
    };
    if (!mounted) return false;
    if (result.needsAccountChoice || result.customToken.isEmpty) {
      if (!offerChoice) {
        _say(AppStrings.existingAccountEmpty);
        return true;
      }
      while (mounted) {
        final answer = await showExistingAccountQuestion(
          context,
          provider: provider,
          providerName: providerName,
        );
        if (!mounted) return false;
        switch (answer) {
          case ExistingAccountAnswer.cancel:
            return false;
          case ExistingAccountAnswer.create:
            // 구글은 Firebase가 예전에 만든 구글 계정을 그대로 연다.
            // 서버에서 빈 사용자를 만들면 그 계정과 갈라진다.
            if (provider == 'google') {
              await _enterWithExistingGoogleAccount(token, successMessage);
              return false;
            }
            await _loginProvider(
              provider: provider,
              token: token,
              providerName: providerName,
              successMessage: successMessage,
              createAccount: true,
              offerChoice: false,
            );
            return false;
          case ExistingAccountAnswer.google:
          case ExistingAccountAnswer.kakao:
          case ExistingAccountAnswer.naver:
            final next = answer.name;
            final nextToken = await _tokenFor(next);
            if (nextToken == null || !mounted) return false;
            final again = await _loginProvider(
              provider: next,
              token: nextToken,
              providerName: _providerName(next),
              successMessage: AppStrings.linkAttached(providerName),
              offerChoice: false,
              linkProvider: provider,
              linkToken: token,
            );
            if (!again || !mounted) return false;
        }
      }
      return false;
    }

    final credential = await ref
        .read(authRepositoryProvider)
        .signInWithCustomToken(result.customToken);
    if (!mounted) return false;
    if (linkProvider != null && (linkToken ?? '').isNotEmpty) {
      final attached = await _confirmAndLink(
        api: api,
        linkProvider: linkProvider,
        linkToken: linkToken!,
        methodName: _providerName(linkProvider),
      );
      if (!mounted) return false;
      if (attached == _LinkStep.pickAgain) return true;
      if (attached != _LinkStep.linked) return false;
    }
    await _enterApp(
      uid: credential.user?.uid ?? '',
      newAccount: result.newAccount,
      successMessage: successMessage,
    );
    return false;
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<_LinkStep> _confirmAndLink({
    required IdentityApiClient api,
    required String linkProvider,
    required String linkToken,
    required String methodName,
  }) async {
    final AccountLinkPreview preview;
    try {
      preview = await api.fetchLinkPreview();
    } catch (e) {
      if (mounted) _say(ApiErrorMessage.from(e));
      await _leaveSignedInAccount();
      return _LinkStep.stopped;
    }
    if (!mounted) return _LinkStep.stopped;
    if (!preview.canLink || preview.nickname.trim().isEmpty) {
      await _leaveSignedInAccount();
      if (mounted) _say(AppStrings.existingAccountEmpty);
      return _LinkStep.pickAgain;
    }
    final ok = await showAccountLinkConfirm(
      context,
      methodName: methodName,
      nickname: preview.nickname,
      shareBalance: preview.shareBalance,
    );
    if (!mounted) return _LinkStep.stopped;
    if (!ok) {
      await _leaveSignedInAccount();
      return _LinkStep.pickAgain;
    }
    try {
      switch (linkProvider) {
        case 'kakao':
          await api.linkKakao(linkToken);
        case 'naver':
          await api.linkNaver(linkToken);
        case 'google':
          await api.linkGoogle(linkToken);
        default:
          throw StateError(linkProvider);
      }
    } on ApiException catch (e) {
      await _leaveSignedInAccount();
      if (!mounted) return _LinkStep.stopped;
      _say(
        e.detail == 'empty_account'
            ? AppStrings.existingAccountEmpty
            : e.userMessage,
      );
      return e.detail == 'empty_account'
          ? _LinkStep.pickAgain
          : _LinkStep.stopped;
    } catch (e) {
      await _leaveSignedInAccount();
      if (mounted) _say(ApiErrorMessage.from(e));
      return _LinkStep.stopped;
    }
    return _LinkStep.linked;
  }

  Future<void> _leaveSignedInAccount() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    ref.read(persistedAuthSessionProvider.notifier).replace(null);
  }

  Future<void> _enterWithExistingGoogleAccount(
    String idToken,
    String successMessage,
  ) async {
    final credential = await ref
        .read(authRepositoryProvider)
        .signInWithGoogleIdToken(idToken);
    if (!mounted) return;
    try {
      await ref.read(identityApiClientProvider).linkGoogle(idToken);
    } on ApiException catch (e) {
      // 닉네임 전 첫 로그인은 빈 계정 연결이 아니다. 안내만 건너뛴다.
      if (e.detail != 'empty_account' && mounted) {
        _say(e.userMessage);
      }
    } catch (e) {
      if (mounted) _say(ApiErrorMessage.from(e));
    }
    if (!mounted) return;
    await _enterApp(
      uid: credential.user?.uid ?? '',
      newAccount: credential.additionalUserInfo?.isNewUser ?? false,
      successMessage: successMessage,
    );
  }

  Future<String?> _tokenFor(String provider) {
    return switch (provider) {
      'google' => ref.read(googleIdTokenProvider)(),
      'kakao' => ref.read(kakaoAccessTokenProvider)(),
      'naver' => ref.read(naverAccessTokenProvider)(),
      _ => Future<String?>.value(null),
    };
  }

  String _providerName(String provider) {
    return switch (provider) {
      'google' => '구글',
      'kakao' => '카카오',
      'naver' => '네이버',
      _ => provider,
    };
  }

  Future<void> _enterApp({
    required String uid,
    required bool newAccount,
    required String successMessage,
  }) async {
    await _rememberLogin(uid: uid);
    if (!mounted) return;
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
      !newAccount && termsAccepted ? RouteNames.home : RouteNames.termsAgreement,
    );
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
                          busy: _socialBusy,
                          maxWidth: contentWidth,
                          onPressed: _onKakao,
                        ),
                        const SizedBox(height: AppShapes.loginButtonSpacing),

                        // 4) Naver — 네이버 공식 버튼 이미지
                        NaverLoginButton(
                          busy: _socialBusy,
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
