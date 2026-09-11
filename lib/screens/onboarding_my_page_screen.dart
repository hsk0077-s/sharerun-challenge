import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/onboarding/widgets/chibi_tier_avatar.dart';
import '../features/profile/widgets/activity_list_card.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/profile/widgets/retention_widgets.dart';
import 'settings_screen.dart';
import 'snail_to_cheetah_book_page.dart';
import 'subscription_management_screen.dart';

/// 온보딩 마이페이지 · 캘린더 · 러닝 일지 (Screen 12).
class OnboardingMyPageScreen extends StatefulWidget {
  const OnboardingMyPageScreen({super.key});

  @override
  State<OnboardingMyPageScreen> createState() => _OnboardingMyPageScreenState();
}

class _OnboardingMyPageScreenState extends State<OnboardingMyPageScreen> {
  static const _currentNavIndex = DashboardTabNavigation.myPage;

  static const _activeDays = {1, 2, 3, 4, 9, 12, 13, 14};
  static const _crownDay = 10;
  static const _chartKm = [5.0, 7.0, 6.0, 8.0, 5.0, 9.0, 6.0];

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    DashboardTabNavigation.go(context, index);
  }

  void _onSettings() {
    AppRouteNav.push<void>(
      context,
      RouteNames.settings,
      materialBuilder: (_) => const SettingsScreen(),
    );
  }

  void _onSubscriptionManage() {
    AppRouteNav.push<void>(
      context,
      RouteNames.subscriptionManagement,
      materialBuilder: (_) => const SubscriptionManagementScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Scaffold(
      backgroundColor: tokens.colors.canvas,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spacing.page,
                    tokens.spacing.sm,
                    tokens.spacing.page,
                    tokens.spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MyPageHeader(
                        onSettings: _onSettings,
                        onSubscriptionManage: _onSubscriptionManage,
                      ),
                      SizedBox(height: tokens.spacing.md),
                      const _ProfileCard(),
                      const SizedBox(height: 14),
                      const AngelChronicleCard(),
                      const SizedBox(height: 14),
                      const DailyStreakCard(),
                      const SizedBox(height: 14),
                      const _CalendarCard(
                        activeDays: _activeDays,
                        crownDay: _crownDay,
                      ),
                      const SizedBox(height: 14),
                      const ActivityListCard(),
                      const SizedBox(height: 14),
                      const _StatsChartCard(kmValues: _chartKm),
                    ],
                  ),
                ),
              ),
            ],
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
            tabIndex: DashboardTabNavigation.myPage,
            child: scaffold,
          )
        : scaffold;
  }
}

class _MyPageHeader extends StatelessWidget {
  const _MyPageHeader({
    required this.onSettings,
    required this.onSubscriptionManage,
  });

  final VoidCallback onSettings;
  final VoidCallback onSubscriptionManage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.myPageTitle,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: tokens.colors.ink,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              key: const Key('my-page-subscription'),
              onTap: onSubscriptionManage,
              borderRadius: BorderRadius.circular(tokens.radii.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.xxs,
                  vertical: tokens.spacing.xxs,
                ),
                child: Text(
                  AppStrings.myPageSubscriptionManage,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    color: tokens.colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            InkWell(
              key: const Key('my-page-settings'),
              onTap: onSettings,
              borderRadius: BorderRadius.circular(tokens.radii.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.xxs,
                  vertical: tokens.spacing.xxs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: tokens.colors.ink,
                    ),
                    SizedBox(width: tokens.spacing.xxs),
                    Text(
                      AppStrings.myPageSettings,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        color: tokens.colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void _openTierBook(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    try {
      context.pushNamed(RouteNames.tierBook);
      return;
    } catch (_) {
      context.push(RouteNames.tierBook);
      return;
    }
  }
  AppRouteNav.push<void>(
    context,
    RouteNames.tierBook,
    materialBuilder: (_) => const SnailToCheetahBookPage(),
  );
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final nickname = ref.watch(userNicknameProvider);
    final displayName = SrcOnboardingController.isUnsetNickname(nickname)
        ? AppStrings.myPageNickname
        : nickname;
    final tier =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;

    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Row(
        children: [
          InkWell(
            onTap: () => _openTierBook(context),
            borderRadius: BorderRadius.circular(tokens.radii.md),
            child: _TierCharacterAvatar(tier: tier),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: tokens.colors.ink,
                  ),
                ),
                SizedBox(height: tokens.spacing.xxs + 2),
                InkWell(
                  onTap: () => _openTierBook(context),
                  borderRadius: BorderRadius.circular(tokens.radii.xs + 2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Text(
                      '[${tier.koreanName}]',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: tokens.colors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCharacterAvatar extends StatelessWidget {
  const _TierCharacterAvatar({required this.tier});

  final UserTier tier;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: tokens.colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radii.md),
        border: Border.all(
          color: tokens.colors.accent.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        tier.avatarAssetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => ChibiTierAvatar(tier: tier, size: 72),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.activeDays,
    required this.crownDay,
  });

  final Set<int> activeDays;
  final int crownDay;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: tokens.spacing.sm - 2,
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: tokens.colors.primary.withValues(alpha: 0.14),
              borderRadius: tokens.radii.capsule,
            ),
            child: Text(
              AppStrings.myPageStreak,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: tokens.colors.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final day = index + 1;
              return _CalendarDayCell(
                day: day,
                isActive: activeDays.contains(day),
                hasCrown: day == crownDay,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isActive,
    required this.hasCrown,
  });

  final int day;
  final bool isActive;
  final bool hasCrown;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isActive && !hasCrown)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.colors.primary, width: 1.5),
            ),
          ),
        if (hasCrown)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 14)),
              Text(
                '$day',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: tokens.colors.muted,
                ),
              ),
            ],
          ),
        if (!hasCrown)
          Text(
            '$day',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: tokens.colors.muted,
            ),
          ),
      ],
    );
  }
}

class _StatsChartCard extends StatelessWidget {
  const _StatsChartCard({required this.kmValues});

  final List<double> kmValues;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return SrcSurfaceCard(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _RunningChartPainter(
                kmValues: kmValues,
                lineColor: tokens.colors.primary,
                fillTop: tokens.colors.primary.withValues(alpha: 0.35),
                fillBottom: tokens.colors.primary.withValues(alpha: 0.02),
                labelColor: tokens.colors.muted,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          Divider(color: tokens.colors.outline, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myPageMonthlyDistanceLabel,
                      style: textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                    SizedBox(height: tokens.spacing.xxs),
                    Text(
                      AppStrings.myPageMonthlyDistanceValue,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: tokens.colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: tokens.colors.outline),
              Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: tokens.spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.myPageAvgPaceLabel,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                      SizedBox(height: tokens.spacing.xxs),
                      Text(
                        AppStrings.myPageAvgPaceValue,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: tokens.colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunningChartPainter extends CustomPainter {
  _RunningChartPainter({
    required this.kmValues,
    required this.lineColor,
    required this.fillTop,
    required this.fillBottom,
    required this.labelColor,
  });

  final List<double> kmValues;
  final Color lineColor;
  final Color fillTop;
  final Color fillBottom;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (kmValues.isEmpty) return;

    final maxKm = kmValues.reduce((a, b) => a > b ? a : b);
    final minKm = kmValues.reduce((a, b) => a < b ? a : b);
    final range = (maxKm - minKm).clamp(1.0, double.infinity);
    final chartBottom = size.height - 24;
    final chartTop = 20.0;
    final chartHeight = chartBottom - chartTop;
    final stepX = size.width / (kmValues.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < kmValues.length; i++) {
      final x = i * stepX;
      final normalized = (kmValues[i] - minKm) / range;
      final y = chartBottom - normalized * chartHeight;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, chartBottom);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = lineColor);

      final label = '${kmValues[i].toInt()}km';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RunningChartPainter oldDelegate) {
    return oldDelegate.kmValues != kmValues ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillTop != fillTop ||
        oldDelegate.fillBottom != fillBottom ||
        oldDelegate.labelColor != labelColor;
  }
}
