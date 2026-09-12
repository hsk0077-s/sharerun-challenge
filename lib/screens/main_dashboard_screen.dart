import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_run_challenge/core/theme/theme.dart';

import '../app/router/route_names.dart';
import '../core/constants/economy_constants.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
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
import '../features/wallet/widgets/wallet_inventory_section.dart';
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowNicknameSheet());
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
    final onboardingDone = onboarding.currentStep == OnboardingStep.completed;
    final trialDone = onboarding.preliminaryPaceSeconds.length
        .clamp(0, EconomyConstants.trialRunsRequired);
    final nicknameUnset = ref.watch(needsNicknameSetupProvider);
    final dailyKm = ref.watch(retentionDailyKmProvider);
    final wallet = ref.watch(walletProvider);
    final shop = ref.watch(shopTabProvider);
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final scaffold = Scaffold(
      backgroundColor: tokens.colors.canvas,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: AbsorbPointer(
            absorbing: nicknameUnset,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.page,
                tokens.spacing.sm,
                tokens.spacing.page,
                tokens.spacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(
                    onNotificationTap: _onOpenNotificationCenter,
                    onStampTour: _onOpenStampTour,
                  ),
                  SizedBox(height: tokens.spacing.md),
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
                    shop: shop,
                  ),
                  SizedBox(height: tokens.spacing.sm),
                  SoloQuickStartBanner(onTap: _onOpenSoloQuickStart),
                  SizedBox(height: tokens.spacing.sm),
                  AngelSponsorBanner(onTap: _onOpenPersonalSponsor),
                  SizedBox(height: tokens.spacing.lg),
                  Text(
                    AppStrings.dashboardOngoingChallenges,
                    style: textTheme.titleLarge,
                  ),
                  SizedBox(height: tokens.spacing.sm),
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
                  SizedBox(height: tokens.spacing.sm),
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
    final tokens = context.srcTokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: HomeUserIdentityHeader()),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              color: tokens.colors.accent,
              tooltip: AppStrings.dashboardStampMapTooltip,
              onPressed: onStampTour,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              color: tokens.colors.ink,
              onPressed: onNotificationTap,
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
    required this.shop,
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
  final ShopTabState shop;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    const total = EconomyConstants.trialRunsRequired;
    final progress = (gradeCompletedCount / total).clamp(0.0, 1.0);
    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.lg),
      borderColor: tokens.colors.accent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: tokens.colors.accent,
                size: 22,
              ),
              SizedBox(width: tokens.spacing.xs),
              Text(
                AppStrings.dashboardMyWallet,
                style: textTheme.titleMedium?.copyWith(
                  color: tokens.colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          _WalletTapSegment(
            onTap: onShareTap,
            child: Text(
              AppStrings.dashboardShareBalanceOf(
                _comma(share),
                _comma(share),
              ),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.colors.accent,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          _WalletTapSegment(
            onTap: onDiamondTap,
            child: Text(
              AppStrings.dashboardDiamondBalanceOf(diamond),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.colors.primary,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          _WalletTapSegment(
            onTap: onValueTap,
            child: Text(
              AppStrings.dashboardValueBalanceOf(_comma(value)),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.colors.donation,
              ),
            ),
          ),
          if (shop.hasOwnedItems) ...[
            SizedBox(height: tokens.spacing.sm),
            WalletInventorySection(shop: shop, compact: true),
          ],
          SizedBox(height: tokens.spacing.sm),
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
                    padding: EdgeInsets.only(top: tokens.spacing.md),
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: tokens.colors.accent.withValues(alpha: 0.10),
      borderRadius: tokens.radii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: tokens.radii.card,
        splashColor: tokens.colors.accent.withValues(alpha: 0.15),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.sm,
            tokens.spacing.sm,
            tokens.spacing.sm,
            tokens.spacing.sm - 2,
          ),
          decoration: BoxDecoration(
            borderRadius: tokens.radii.card,
            border: Border.all(
              color: tokens.colors.accent.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GradeProgressBar(progress: progress),
              SizedBox(height: tokens.spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.dashboardGradeRunLabel,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.colors.accent,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/$totalCount회 완료 >',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.colors.ink,
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
    final tokens = context.srcTokens;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radii.sm),
        splashColor: tokens.colors.accent.withValues(alpha: 0.15),
        highlightColor: tokens.colors.accent.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spacing.xs - 2,
            horizontal: tokens.spacing.xxs,
          ),
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
    final tokens = context.srcTokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radii.xs),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: tokens.colors.outline),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tokens.colors.donation,
                      tokens.colors.primary,
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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.colors.ink,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.colors.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spacing.sm),
          Material(
            color: tokens.colors.primary,
            borderRadius: tokens.radii.capsule,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onViewRoom,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacing.sm,
                    vertical: tokens.spacing.xs,
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.dashboardViewRoom,
                      style: textTheme.labelLarge?.copyWith(
                        color: tokens.colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
