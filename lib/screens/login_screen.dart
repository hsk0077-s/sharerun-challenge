import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/auth/local_auth_session.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/widgets/social_brand_icons.dart';
import '../core/widgets/src_button.dart';
import '../core/widgets/src_gradient_background.dart';
import '../core/widgets/src_logo_header.dart';
import '../core/widgets/src_text_field.dart';
import '../data/repositories/auth_repository.dart';

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

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  String? _socialAccountUid(Object? result, {required String prefix}) {
    if (result == null) return null;
    try {
      final dynamic value = result;
      final id = value.account?.id ?? value.id ?? value.userId;
      final text = '$id';
      if (text.isEmpty || text == 'null') return null;
      return '${prefix}_$text';
    } catch (_) {
      return null;
    }
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
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithNaver();

      if (result != null && mounted) {
        await _rememberLogin(uid: _socialAccountUid(result, prefix: 'naver'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네이버 로그인에 성공했습니다!')),
        );
        Navigator.of(context).pushReplacementNamed(RouteNames.termsAgreement);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네이버 로그인 실패: $e')),
      );
    }
  }

  Future<void> _onKakao() async {
    if (_kakaoBusy) return;
    setState(() => _kakaoBusy = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithKakao();

      if (result != null && mounted) {
        await _rememberLogin(uid: _socialAccountUid(result, prefix: 'kakao'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 로그인에 성공했습니다!')),
        );
        Navigator.of(context).pushReplacementNamed(RouteNames.termsAgreement);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 실패: $e')),
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

                        // 1) Google — 흰 배경 + 회색 테두리 + 컬러 G
                        SRCButton.google(
                          label: AppStrings.loginGoogle,
                          leading: Image.asset(
                            'assets/images/google_logo.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) =>
                                const GoogleIcon(size: 22),
                          ),
                          onPressed: _onGoogle,
                        ),
                        const SizedBox(height: AppShapes.loginButtonSpacing),

                        // 2) Apple (구글 아래 유지)
                        SRCButton.apple(
                          label: AppStrings.loginApple,
                          leading: const Icon(
                            Icons.apple,
                            color: AppColors.textWhite,
                            size: 26,
                          ),
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

                        // 3) Naver
                        SRCButton.naver(
                          label: AppStrings.loginNaver,
                          leading: const NaverIcon(size: 20),
                          onPressed: _onNaver,
                        ),
                        const SizedBox(height: AppShapes.loginButtonSpacing),

                        // 4) Kakao — 직전 벡터 말풍선 로고 유지
                        SRCButton.kakao(
                          label: AppStrings.loginKakao,
                          leading: const KakaoIcon(size: 22),
                          enabled: !_kakaoBusy,
                          isLoading: _kakaoBusy,
                          onPressed: _onKakao,
                        ),

                        const Spacer(flex: 2),

                        SRCTextField(
                          label: AppStrings.loginReferralLabel,
                          hintText: AppStrings.loginReferralHint,
                          controller: _referralController,
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
