import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accessories/accessory_inventory.dart';
import '../app/router/route_names.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/my_page_activity_stats.dart';
import '../features/profile/widgets/activity_list_card.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';
import '../features/profile/widgets/my_dashboard_sections.dart';
import '../features/profile/widgets/my_page_invite_code_card.dart';
import '../features/profile/widgets/my_page_referral_code_entry.dart';
import '../features/profile/widgets/my_village_hero.dart';
import '../features/profile/widgets/retention_widgets.dart';
import '../features/profile/village_scene.dart';
import 'donation_settlement_screen.dart';
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

  void _onDonationSettlement() {
    AppRouteNav.push<void>(
      context,
      RouteNames.donationSettlement,
      materialBuilder: (_) => const DonationSettlementScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SrcTokens.night;
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Theme(
      data: SrcTheme.night,
      child: Scaffold(
        backgroundColor: tokens.colors.canvas,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer(
                  builder: (context, ref, _) => MyVillageHero(
                    tier: ref.watch(activeUserTierStructProvider) ??
                        UserTier.unratedFallback,
                    onSettings: _onSettings,
                    worn: ref.watch(wornAccessoriesProvider),
                    scene: ref.watch(villageSceneProvider),
                    onChangeVillage: () => VillagePicker.show(context),
                  ),
                ),
                const MyIdentityRow(),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: tokens.spacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PromotionProgressCard(),
                      const MyWalletChips(),
                      const SizedBox(height: 8),
                      MyQuickSection(
                        onDonation: _onDonationSettlement,
                        onTierBook: () => _openTierBook(context),
                        onSettings: _onSettings,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SubscriptionLink(
                          onTap: _onSubscriptionManage,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const MyPageInviteCodeCard(),
                      const MyPageReferralCodeEntry(),
                      const SizedBox(height: 14),
                      const AngelChronicleCard(),
                      const SizedBox(height: 14),
                      const DailyStreakCard(),
                      const SizedBox(height: 14),
                      const _CalendarCard(),
                      const SizedBox(height: 14),
                      const ActivityListCard(),
                      const SizedBox(height: 14),
                      const _StatsChartCard(),
                    ],
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
      ),
    );
    return embedNav
        ? SrcExitGuard(
            tabIndex: DashboardTabNavigation.myPage,
            child: scaffold,
          )
        : scaffold;
  }
}

class _SubscriptionLink extends StatelessWidget {
  const _SubscriptionLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return InkWell(
      key: const Key('my-page-subscription'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          AppStrings.myPageSubscriptionManage,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                color: tokens.colors.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
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

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(myPageActivityStatsProvider);
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
              '🔥 현재 연속 출석(Streak): ${stats.streakDays}일',
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
            itemCount: stats.daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              return _CalendarDayCell(
                day: day,
                isActive: stats.activeMonthDays.contains(day),
                hasCrown: day == stats.crownDay,
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

class _StatsChartCard extends ConsumerWidget {
  const _StatsChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(myPageActivityStatsProvider);
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
                kmValues: stats.weekKm,
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
                      stats.monthDistanceLabel,
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
                        stats.paceLabel,
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

String _chartKmLabel(double km) {
  if (km <= 0) return '0km';
  final rounded = km.roundToDouble();
  if (km >= 10 || (km - rounded).abs() < 0.05) {
    return '${km.round()}km';
  }
  return '${km.toStringAsFixed(1)}km';
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

    var maxKm = 0.0;
    for (final value in kmValues) {
      if (value > maxKm) maxKm = value;
    }
    final top = maxKm <= 0 ? 1.0 : maxKm;
    final chartBottom = size.height - 24;
    final chartTop = 20.0;
    final chartHeight = chartBottom - chartTop;
    final stepX =
        kmValues.length <= 1 ? size.width : size.width / (kmValues.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < kmValues.length; i++) {
      final x = i * stepX;
      final normalized = (kmValues[i] <= 0 ? 0.0 : kmValues[i]) / top;
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
      if (kmValues[i] <= 0) continue;

      final label = _chartKmLabel(kmValues[i]);
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
