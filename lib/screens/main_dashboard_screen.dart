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
import '../features/home/home_cards.dart';
import '../features/home/home_wallet_card.dart';
import '../features/mini_bot/mini_bot_sheet.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/nickname_setup_sheet.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/profile/widgets/retention_widgets.dart';
import '../features/stamp/providers/stamp_tour_enabled_provider.dart';
import 'donation_settlement_screen.dart';
import 'notification_center_screen.dart';
import 'personal_sponsor_screen.dart';
import 'preliminary_eval_screen.dart';
import 'stamp_tour_screen.dart';
import '../core/config/app_env.dart';

/// 메인 대시보드 화면 (Screen 5). 검정 바탕 + 라임 포인트 새 디자인.
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
    _openNicknameSheet();
  }

  Future<void> _openNicknameSheet() async {
    await NicknameSetupSheet.show(context);
    if (!mounted) return;
    setState(() => _nicknameSheetOpen = false);
    _maybeShowNicknameSheet();
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

  void _onOpenDonationSettlement() {
    AppRouteNav.push<void>(
      context,
      RouteNames.donationSettlement,
      materialBuilder: (_) => const DonationSettlementScreen(),
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
    final nickname = ref.watch(userNicknameProvider);
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final showStamp = ref.watch(stampTourEnabledProvider).asData?.value == true;

    return Theme(
      data: SrcTheme.night,
      child: Builder(
        builder: (context) {
          final tokens = context.srcTokens;
          final textTheme = Theme.of(context).textTheme;
          final scaffold = Scaffold(
            backgroundColor: tokens.colors.canvas,
            body: AbsorbPointer(
              absorbing: nicknameUnset,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: tokens.spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHero(
                      onNotificationTap: _onOpenNotificationCenter,
                      onStampTour: _onOpenStampTour,
                      showStampTour: showStamp,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spacing.page,
                        tokens.spacing.md,
                        tokens.spacing.page,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Greeting(
                            nickname: SrcOnboardingController.isUnsetNickname(
                              nickname,
                            )
                                ? null
                                : nickname,
                          ),
                          SizedBox(height: tokens.spacing.sm),
                          SoloQuickStartBanner(
                            onTap: _onOpenSoloQuickStart,
                          ),
                          if (!onboardingDone) ...[
                            SizedBox(height: tokens.spacing.sm),
                            HomeGradeEvalBanner(
                              completedCount: trialDone,
                              onTap: _onOpenPreliminaryEval,
                            ),
                          ],
                          SizedBox(height: tokens.spacing.sm),
                          HomeDonationCard(
                            onOpenSettlement: _onOpenDonationSettlement,
                          ),
                          if (AppEnv.sponsorPaymentsVisible) ...[
                            SizedBox(height: tokens.spacing.sm),
                            AngelSponsorBanner(onTap: _onOpenPersonalSponsor),
                          ],
                          SizedBox(height: tokens.spacing.lg),
                          Text(
                            AppStrings.dashboardOngoingChallenges,
                            style: textTheme.titleLarge,
                          ),
                          SizedBox(height: tokens.spacing.xxs),
                          Text(
                            '상품은 다이아예요 · ${AppStrings.noCashPrizePool}',
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.colors.muted,
                            ),
                          ),
                          SizedBox(height: tokens.spacing.sm),
                          _ChallengeCard(
                            title: AppStrings.dashboardChallenge1Title,
                            subtitle: AppStrings.dashboardChallenge1Sub,
                            onViewRoom: () => _openRoom(
                              context,
                              RouteNames.beginner1kmRoomId,
                            ),
                          ),
                          SizedBox(height: tokens.spacing.sm),
                          _ChallengeCard(
                            title: AppStrings.dashboardChallenge2Title,
                            subtitle: AppStrings.dashboardChallenge2Sub,
                            onViewRoom: () => _openRoom(
                              context,
                              RouteNames.intermediate3kmRoomId,
                            ),
                          ),
                          // 달팽이봇 버튼과 하단 탭 바에 가리지 않도록 아래를 비운다.
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton:
                embedNav ? miniBotEntryForTab(_currentNavIndex) : null,
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
        },
      ),
    );
  }

  void _openRoom(BuildContext context, String roomId) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.push(RouteNames.challengeDetailForRoom(roomId));
      return;
    }
    Navigator.of(context).pushNamed(
      RouteNames.challengeDetail,
      arguments: roomId,
    );
  }
}

/// 위쪽 큰 사진. 날짜와 알림, 스탬프 투어(켜져 있을 때)가 사진 위에 얹힌다.
class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.onNotificationTap,
    required this.onStampTour,
    required this.showStampTour,
  });

  final VoidCallback onNotificationTap;
  final VoidCallback onStampTour;
  final bool showStampTour;

  static const _photo = 'assets/images/splash_morning_run.jpg';
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final now = DateTime.now();
    final date = 'TODAY · ${now.month.toString().padLeft(2, '0')}.'
        '${now.day.toString().padLeft(2, '0')} ${_weekdays[now.weekday - 1]}';
    // 사진 비율에 맞춰 폭의 1.5배. 러너·강아지와 앞쪽 길이 모두 보이는 높이다.
    final height = MediaQuery.sizeOf(context).width * 1.5;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _photo,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.2),
              errorBuilder: (_, __, ___) => ColoredBox(
                color: tokens.colors.surface,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB8000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.2, 0.5, 1],
                ),
              ),
            ),
            // 앱 대표 슬로건. 시작 화면과 같은 문장이다. 길 위(강아지 아래)에 둔다.
            Positioned(
              left: tokens.spacing.page + 2,
              right: tokens.spacing.page,
              bottom: 30,
              child: const Text(
                AppStrings.slogan,
                key: Key('home-slogan'),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                  // 흐린(블러) 그림자는 일부 폰에서 글자 한 자가 엉뚱한 자리에
                  // 흐릿한 얼룩으로 그려져서, 번지지 않는 그림자만 쓴다.
                  // 글자 대비는 아래쪽 어두운 그라데이션이 맡는다.
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1.5),
                      blurRadius: 0,
                      color: Color(0x99000000),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.page,
                  tokens.spacing.xs,
                  tokens.spacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                    ),
                    if (showStampTour)
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        color: Colors.white,
                        tooltip: AppStrings.dashboardStampMapTooltip,
                        onPressed: onStampTour,
                      ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: Colors.white,
                      onPressed: onNotificationTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간대별 인사말. 닉네임을 아직 안 정했으면 이름 없이 인사만 한다.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.nickname});

  final String? nickname;

  static String _hello(int hour) {
    if (hour < 11) return '좋은 아침이에요';
    if (hour < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final text = nickname == null
        ? _hello(DateTime.now().hour)
        : '${_hello(DateTime.now().hour)}, $nickname님';
    return Text(
      text,
      key: const Key('home-greeting'),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.colors.muted,
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
