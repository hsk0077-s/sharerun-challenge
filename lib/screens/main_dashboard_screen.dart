import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router/route_names.dart';
import '../core/constants/economy_constants.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/nickname_setup_sheet.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/profile/widgets/gender_profile_avatar.dart';
import '../features/profile/widgets/retention_widgets.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import 'in_app_billing_screen.dart';
import 'notification_center_screen.dart';
import 'personal_sponsor_screen.dart';
import 'preliminary_eval_screen.dart';
import 'stamp_tour_screen.dart';
import 'store_screen.dart';

/// 메인 대시보드 화면 (Screen 5).
class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  static const _currentNavIndex = DashboardTabNavigation.home;
  var _nicknameSheetOpen = false;
  var _openingSolo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNicknameSheet());
  }

  void _maybeShowNicknameSheet() {
    if (!mounted || _nicknameSheetOpen) return;
    if (!ref.read(needsNicknameSetupProvider)) return;
    _nicknameSheetOpen = true;
    NicknameSetupSheet.show(context).whenComplete(() {
      if (mounted) {
        setState(() => _nicknameSheetOpen = false);
        _maybeShowNicknameSheet();
      }
    });
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    DashboardTabNavigation.go(context, index);
  }

  void _onOpenStampTour() {
    AppRouteNav.push<void>(
      context,
      RouteNames.stampTour,
      materialBuilder: (_) => const StampTourScreen(),
    );
  }

  void _onOpenPreliminaryEval() {
    _pushSoloRoute(
      name: RouteNames.preliminaryEvalName,
      path: RouteNames.preliminaryRuns,
      materialBuilder: (_) => const PreliminaryEvalScreen(),
    );
  }

  void _onOpenSoloQuickStart() {
    if (_openingSolo) return;
    _openingSolo = true;
    if (GoRouter.maybeOf(context) != null) {
      context.pushNamed(RouteNames.soloPedometer);
    } else {
      Navigator.of(context).pushNamed(RouteNames.soloPedometerPath);
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _openingSolo = false;
    });
  }

  void _pushSoloRoute({
    required String name,
    required String path,
    required WidgetBuilder materialBuilder,
  }) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(name);
        return;
      } catch (_) {
        context.push(path);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      path,
      materialBuilder: materialBuilder,
    );
  }

  void _onOpenNotificationCenter() {
    AppRouteNav.push<void>(
      context,
      RouteNames.notificationCenter,
      materialBuilder: (_) => const NotificationCenterScreen(),
    );
  }

  void _onOpenInAppBilling() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.inAppBilling);
        return;
      } catch (_) {
        context.push(RouteNames.inAppBilling);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  void _onOpenPersonalSponsor() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(RouteNames.personalSponsor);
        return;
      } catch (_) {
        context.push(RouteNames.personalSponsor);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.personalSponsor,
      materialBuilder: (_) => const PersonalSponsorScreen(),
    );
  }

  void _onOpenStore({required StoreFocus focus}) {
    ref.read(storeFocusProvider.notifier).setFocus(focus);
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      try {
        context.pushNamed(
          RouteNames.store,
          queryParameters: {'focus': focus.name},
        );
        return;
      } catch (_) {
        DashboardTabNavigation.go(context, DashboardTabNavigation.shop);
        return;
      }
    }
    AppRouteNav.push<void>(
      context,
      RouteNames.storeWithFocus(focus.name),
      extra: focus,
      materialBuilder: (_) => StoreScreen(initialFocus: focus),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(needsNicknameSetupProvider, (prev, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowNicknameSheet();
        });
      }
    });
    final onboarding = ref.watch(onboardingProvider);
    final onboardingDone =
        onboarding.currentStep == OnboardingStep.completed;
    final trialDone = onboarding.preliminaryPaceSeconds.length
        .clamp(0, EconomyConstants.trialRunsRequired);
    final nicknameUnset = ref.watch(needsNicknameSetupProvider);
    final dailyKm = ref.watch(retentionDailyKmProvider);
    final wallet = ref.watch(walletProvider);
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: AbsorbPointer(
            absorbing: nicknameUnset,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppShapes.termsHorizontalPadding,
                12,
                AppShapes.termsHorizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _DashboardHeader(
                  onNotificationTap: _onOpenNotificationCenter,
                  onStampTour: _onOpenStampTour,
                ),
                const SizedBox(height: 16),
                _WalletCard(
                  share: wallet.shareBalance,
                  diamond: wallet.diamondBalance,
                  value: wallet.valueBalance,
                  onShareTap: _onOpenInAppBilling,
                  onDiamondTap: () => _onOpenStore(focus: StoreFocus.items),
                  onValueTap: () => _onOpenStore(focus: StoreFocus.donate),
                  showGradeEval: !onboardingDone,
                  gradeCompletedCount: trialDone,
                  onGradeEval: _onOpenPreliminaryEval,
                  dailyKm: dailyKm,
                ),
                const SizedBox(height: 12),
                SoloQuickStartBanner(onTap: _onOpenSoloQuickStart),
                const SizedBox(height: 12),
                AngelSponsorBanner(onTap: _onOpenPersonalSponsor),
                const SizedBox(height: 20),
                Text(
                  AppStrings.dashboardOngoingChallenges,
                  style: AppTextStyles.header1.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 14),
                _ChallengeCard(
                  title: AppStrings.dashboardChallenge1Title,
                  subtitle: AppStrings.dashboardChallenge1Sub,
                  onViewRoom: () {
                    final router = GoRouter.maybeOf(context);
                    if (router != null) {
                      context.push(
                        RouteNames.challengeDetailForRoom(
                          RouteNames.beginner1kmRoomId,
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pushNamed(
                      RouteNames.challengeDetail,
                      arguments: RouteNames.beginner1kmRoomId,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ChallengeCard(
                  title: AppStrings.dashboardChallenge2Title,
                  subtitle: AppStrings.dashboardChallenge2Sub,
                  onViewRoom: () {
                    final router = GoRouter.maybeOf(context);
                    if (router != null) {
                      context.push(
                        RouteNames.challengeDetailForRoom(
                          RouteNames.intermediate3kmRoomId,
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pushNamed(
                      RouteNames.challengeDetail,
                      arguments: RouteNames.intermediate3kmRoomId,
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        ),
      ),
      bottomNavigationBar: embedNav
          ? DashboardBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            )
          : null,
    );
    return embedNav
        ? SrcExitGuard(
            tabIndex: DashboardTabNavigation.home,
            child: scaffold,
          )
        : scaffold;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onNotificationTap,
    required this.onStampTour,
  });

  final VoidCallback onNotificationTap;
  final VoidCallback onStampTour;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: HomeUserIdentityHeader()),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              color: AppColors.tealAccent,
              tooltip: AppStrings.dashboardStampMapTooltip,
              onPressed: onStampTour,
            ),
            IconButton(
              icon: Icon(Icons.notifications_none_rounded),
              color: AppColors.textBlack,
              onPressed: onNotificationTap,
            ),
            IconButton(
              icon: const Icon(Icons.mail_outline_rounded),
              color: AppColors.textBlack,
              onPressed: () => debugPrint('버튼 클릭됨'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.share,
    required this.diamond,
    required this.value,
    required this.onShareTap,
    required this.onDiamondTap,
    required this.onValueTap,
    required this.showGradeEval,
    required this.gradeCompletedCount,
    required this.onGradeEval,
    required this.dailyKm,
  });

  final int share;
  final int diamond;
  final int value;
  final VoidCallback onShareTap;
  final VoidCallback onDiamondTap;
  final VoidCallback onValueTap;
  final bool showGradeEval;
  final int gradeCompletedCount;
  final VoidCallback onGradeEval;
  final double dailyKm;

  @override
  Widget build(BuildContext context) {
    const total = EconomyConstants.trialRunsRequired;
    final progress = (gradeCompletedCount / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.walletCardFill,
        borderRadius: BorderRadius.circular(AppShapes.oauthCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.tealAccent,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                AppStrings.dashboardMyWallet,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: AppColors.textBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WalletTapSegment(
            onTap: onShareTap,
            child: Text(
              AppStrings.dashboardShareBalanceOf(
                _comma(share),
                _comma(share),
              ),
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _WalletTapSegment(
            onTap: onDiamondTap,
            child: Text(
              AppStrings.dashboardDiamondBalanceOf(diamond),
              style: AppTextStyles.agreementLabel,
            ),
          ),
          const SizedBox(height: 8),
          _WalletTapSegment(
            onTap: onValueTap,
            child: Text(
              AppStrings.dashboardValueBalanceOf(_comma(value)),
              style: AppTextStyles.agreementLabel,
            ),
          ),
          const SizedBox(height: 14),
          DailyCapGauge(dailyKm: dailyKm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              );
            },
            child: showGradeEval
                ? Padding(
                    key: const ValueKey('grade-eval-banner'),
                    padding: const EdgeInsets.only(top: 18),
                    child: _GradeEvalBanner(
                      completedCount: gradeCompletedCount,
                      totalCount: total,
                      progress: progress,
                      onTap: onGradeEval,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('grade-eval-gone')),
          ),
        ],
      ),
    );
  }
}

class _GradeEvalBanner extends StatelessWidget {
  const _GradeEvalBanner({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.onTap,
  });

  final int completedCount;
  final int totalCount;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tealAccent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.tealAccent.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.tealAccent.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GradeProgressBar(progress: progress),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.dashboardGradeRunLabel,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealAccent,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/$totalCount회 완료 >',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTapSegment extends StatelessWidget {
  const _WalletTapSegment({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.tealAccent.withValues(alpha: 0.15),
        highlightColor: AppColors.tealAccent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: child,
        ),
      ),
    );
  }
}

class _GradeProgressBar extends StatelessWidget {
  const _GradeProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.borderLight),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.progressYellow,
                      AppColors.primaryMint,
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
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.onViewRoom,
  });

  final String title;
  final String subtitle;
  final VoidCallback onViewRoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.primaryMint,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onViewRoom,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  AppStrings.dashboardViewRoom,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _comma(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final formatted = buffer.toString();
  return value < 0 ? '-$formatted' : formatted;
}
