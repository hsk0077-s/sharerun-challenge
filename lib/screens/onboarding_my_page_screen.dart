import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router/route_names.dart';
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
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final scaffold = Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    12,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MyPageHeader(
                        onSettings: _onSettings,
                        onSubscriptionManage: _onSubscriptionManage,
                      ),
                      const SizedBox(height: 16),
                      const _ProfileCard(),
                      const SizedBox(height: 14),
                      const AngelChronicleCard(),
                      const SizedBox(height: 14),
                      const DailyStreakCard(),
                      const SizedBox(height: 14),
                      _CalendarCard(
                        activeDays: _activeDays,
                        crownDay: _crownDay,
                      ),
                      const SizedBox(height: 14),
                      const ActivityListCard(),
                      const SizedBox(height: 14),
                      _StatsChartCard(kmValues: _chartKm),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.myPageTitle,
          style: AppTextStyles.header1.copyWith(fontSize: 24),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onTap: onSubscriptionManage,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  AppStrings.myPageSubscriptionManage,
                  style: AppTextStyles.agreementLabel.copyWith(fontSize: 14),
                ),
              ),
            ),
            InkWell(
              onTap: onSettings,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppColors.textBlack,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.myPageSettings,
                      style: AppTextStyles.agreementLabel.copyWith(fontSize: 14),
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
    final nickname = ref.watch(userNicknameProvider);
    final displayName = SrcOnboardingController.isUnsetNickname(nickname)
        ? AppStrings.myPageNickname
        : nickname;
    final tier =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;

    return _WhiteCard(
      child: Row(
        children: [
          InkWell(
            onTap: () => _openTierBook(context),
            borderRadius: BorderRadius.circular(12),
            child: _TierCharacterAvatar(tier: tier),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _openTierBook(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Text(
                      '[${tier.koreanName}]',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.tealAccent,
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
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.agreementBoxFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.tealAccent.withValues(alpha: 0.35),
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
    return _WhiteCard(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.agreementBoxFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppStrings.myPageStreak,
              style: AppTextStyles.agreementLabel.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isActive && !hasCrown)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryMint, width: 1.5),
            ),
          ),
        if (hasCrown)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 14)),
              Text(
                '$day',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textGreyLight,
                ),
              ),
            ],
          ),
        if (!hasCrown)
          Text(
            '$day',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textGreyLight,
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
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _RunningChartPainter(kmValues: kmValues),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myPageMonthlyDistanceLabel,
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.myPageMonthlyDistanceValue,
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.borderLight),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.myPageAvgPaceLabel,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.myPageAvgPaceValue,
                        style: AppTextStyles.agreementLabel.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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
  _RunningChartPainter({required this.kmValues});

  final List<double> kmValues;

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
        colors: [
          AppColors.primaryMint.withValues(alpha: 0.35),
          AppColors.primaryMint.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = AppColors.primaryMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = AppColors.primaryMint);

      final label = '${kmValues[i].toInt()}km';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
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
    return oldDelegate.kmValues != kmValues;
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}
