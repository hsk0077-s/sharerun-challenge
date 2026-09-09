import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/watch_link/services/garmin_cloud_oauth_adapter.dart';

/// src-4 Garmin Connect 클라우드 OAuth 로그인 웹뷰 위젯.
class ExternalOauthWebview extends ConsumerStatefulWidget {
  const ExternalOauthWebview({super.key});

  @override
  ConsumerState<ExternalOauthWebview> createState() =>
      _ExternalOauthWebviewState();
}

class _ExternalOauthWebviewState extends ConsumerState<ExternalOauthWebview> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textBlack,
                    iconSize: 26,
                    onPressed: _busy ? null : _close,
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.garminAuthTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.termsTitle.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: _OAuthSecurityPill()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _GarminOfficialMark(),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: _validateEmail,
                        decoration: _fieldDecoration(AppStrings.garminEmailHint),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_busy,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                        validator: _validatePassword,
                        decoration:
                            _fieldDecoration(AppStrings.garminPasswordHint),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 58,
                        child: Material(
                          color: AppColors.garminAuthButton,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _busy ? null : _signIn,
                            child: Center(
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.textWhite,
                                      ),
                                    )
                                  : Text(
                                      '${AppStrings.garminSignInAuthorize}\n${AppStrings.garminSignInAuthorizeKo}',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.buttonText.copyWith(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _busy ? null : _close,
                        child: Text(
                          AppStrings.garminCancelAndReturn,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.link.copyWith(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint,
      filled: true,
      fillColor: AppColors.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: AppShapes.inputBorder,
      enabledBorder: AppShapes.inputBorder,
      focusedBorder: AppShapes.inputFocusedBorder,
      errorBorder: AppShapes.inputBorder,
    );
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '이메일 아이디를 입력해 주세요.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요.';
    if (value.length < 4) return '비밀번호가 너무 짧습니다.';
    return null;
  }

  Future<void> _signIn() async {
    if (_busy) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _busy = true);
    try {
      final session = await ref.read(garminCloudOAuthAdapterProvider).authorize(
            email: _emailController.text,
            password: _passwordController.text,
          );
      await ref.read(srcOnboardingControllerProvider.notifier).markGarminConnected(
            watchApiToken: session.accessToken,
          );
      if (!mounted) return;
      _close();
    } on GarminOAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error, stackTrace) {
      debugPrint('Garmin OAuth mock failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연동 중 오류가 발생했습니다. 앱으로 돌아가 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close() {
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop();
      }
    } catch (_) {}
  }
}

class _OAuthSecurityPill extends StatelessWidget {
  const _OAuthSecurityPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            AppStrings.garminAuthSubtitle,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textGrey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _GarminOfficialMark extends StatelessWidget {
  const _GarminOfficialMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.textBlack.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.watch_later_outlined,
            size: 40,
            color: AppColors.garminAuthButton,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'GARMIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
            color: AppColors.textBlack,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CONNECT',
          style: AppTextStyles.caption.copyWith(
            letterSpacing: 4,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
