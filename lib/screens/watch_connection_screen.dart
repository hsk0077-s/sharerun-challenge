import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_sync_button.dart';
import '../data/models/user_model.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/run_tracking/services/health_data_service.dart';
import 'external_oauth_webview.dart';

/// src-3 스마트워치 네이티브 연동 가이드.
class WatchConnectionScreen extends ConsumerStatefulWidget {
  const WatchConnectionScreen({super.key});

  @override
  ConsumerState<WatchConnectionScreen> createState() =>
      _WatchConnectionScreenState();
}

class _WatchConnectionScreenState extends ConsumerState<WatchConnectionScreen> {
  var _busy = false;
  var _softPromptShowing = false;

  bool get _isIosTarget {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(srcOnboardingControllerProvider);
    final nativeLinked = onboarding.nativeWatchLinked;
    final garminLinked = onboarding.isGarminConnected;
    final canStart = onboarding.canCompleteWatchLink;
    final actionLoading = onboarding.actionStatus.isLoading;

    ref.listen<bool>(onboardingSoftPromptVisibleProvider, (previous, next) {
      if (next && previous != true) {
        unawaited(_presentSoftPrompt());
      }
    });
    ref.listen<OnboardingPhase>(
      srcOnboardingControllerProvider.select((s) => s.phase),
      (previous, next) {
        if (next == OnboardingPhase.preliminaryEval) {
          unawaited(_goPreliminaryEval());
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.textBlack,
                      onPressed: _busy ? null : _safeBack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _GlowingWatchHero(),
                  const SizedBox(height: 28),
                  Text(
                    AppStrings.watchSyncTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.header1.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.watchSyncSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.termsSubtitle.copyWith(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (_isIosTarget)
                    SRCSyncButton(
                      label: AppStrings.watchSyncApple,
                      leading: const AppleHealthIcon(),
                      connected: nativeLinked,
                      onPressed: _busy ? null : _connectNativeHealth,
                    )
                  else
                    SRCSyncButton(
                      label: AppStrings.watchSyncGoogle,
                      leading: const GoogleHealthConnectIcon(),
                      connected: nativeLinked,
                      onPressed: _busy ? null : _connectNativeHealth,
                    ),
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _openExternalOauth,
                      child: Text(
                        AppStrings.watchSyncExternalDevices,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.link.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.tealAccent,
                        ),
                      ),
                    ),
                  ),
                  if (garminLinked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.tealAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Garmin Connect 연동 완료',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.tealAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: SizedBox(
                    height: AppShapes.buttonHeight,
                    child: FilledButton(
                      onPressed: (!canStart || _busy || actionLoading)
                          ? null
                          : _completeAndStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tealAccent,
                        disabledBackgroundColor: AppColors.buttonDisabled,
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: (_busy || actionLoading)
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.textWhite,
                              ),
                            )
                          : Text(
                              AppStrings.watchSyncComplete,
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectNativeHealth() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(healthDataServiceProvider)
          .requestWatchLinkAuthorization();
      if (!mounted) return;

      if (!result.granted) {
        await _showPermissionDeniedFeedback(result);
        return;
      }

      final watchType =
          _isIosTarget ? WatchType.appleWatch : WatchType.galaxyWatch;
      await ref
          .read(srcOnboardingControllerProvider.notifier)
          .recordNativeWatchAuthorization(watchType: watchType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${watchType.displayLabel} 연동이 완료되었습니다.'),
          backgroundColor: AppColors.tealAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PlatformException catch (error) {
      debugPrint('Native watch auth PlatformException: $error');
      if (mounted) await _showPermissionDeniedFeedback(null);
    } catch (error, stackTrace) {
      debugPrint('Native watch auth error: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연동 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPermissionDeniedFeedback(
    HealthAuthorizationResult? result,
  ) async {
    if (!mounted) return;
    final openedInstall = result?.openedInstall ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          openedInstall
              ? 'Health Connect 설치 화면으로 이동했습니다. 설치 후 다시 연동해 주세요.'
              : '권한이 거부되었습니다. 설정에서 건강 데이터 접근을 허용해 주세요.',
        ),
      ),
    );
  }

  Future<void> _openExternalOauth() async {
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        await context.push(RouteNames.garminAuth);
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const ExternalOauthWebview(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('External OAuth navigation failed: $error\n$stackTrace');
      if (!mounted) return;
      try {
        await Navigator.of(context).pushNamed(RouteNames.garminAuth);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('외부 기기 연동 화면을 열 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _completeAndStart() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final preferred = ref.read(srcOnboardingControllerProvider).nativeWatchLinked
          ? (_isIosTarget ? WatchType.appleWatch : WatchType.galaxyWatch)
          : WatchType.garmin;
      await ref
          .read(srcOnboardingControllerProvider.notifier)
          .completeWatchLinkAndStart(preferredWatchType: preferred);
    } catch (error, stackTrace) {
      debugPrint('Watch link complete failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('온보딩 상태 갱신에 실패했습니다. $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _presentSoftPrompt() async {
    if (!mounted || _softPromptShowing) return;
    _softPromptShowing = true;
    try {
      final approved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surfaceWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  OnboardingSoftPromptCopy.title,
                  style: AppTextStyles.header1.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),
                for (final benefit in OnboardingSoftPromptCopy.benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: AppTextStyles.termsSubtitle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.tealAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('알림 허용하고 계속'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: const Text('나중에'),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted) return;
      final notifier = ref.read(srcOnboardingControllerProvider.notifier);
      if (approved == true) {
        await notifier.approvePushSoftPrompt();
      } else {
        await notifier.declinePushSoftPrompt();
      }
    } catch (error, stackTrace) {
      debugPrint('Soft-prompt failed: $error\n$stackTrace');
      try {
        await ref
            .read(srcOnboardingControllerProvider.notifier)
            .declinePushSoftPrompt();
      } catch (_) {}
    } finally {
      _softPromptShowing = false;
    }
  }

  Future<void> _goPreliminaryEval() async {
    if (!mounted) return;
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go(RouteNames.preliminaryEval);
        return;
      }
      await Navigator.of(context)
          .pushReplacementNamed(RouteNames.preliminaryEval);
    } catch (error) {
      debugPrint('Preliminary eval navigation failed: $error');
    }
  }

  void _safeBack() {
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

class _GlowingWatchHero extends StatelessWidget {
  const _GlowingWatchHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealAccent.withValues(alpha: 0.22),
                    AppColors.primaryMint.withValues(alpha: 0.08),
                    AppColors.bgGradientEnd.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tealAccent.withValues(alpha: 0.28),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.watch_rounded,
                size: 56,
                color: AppColors.tealAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
