import 'package:flutter/material.dart';

import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';

/// 등급 심사 혼자 뛰기 화면 (Screen 6).
class LevelTestRunningScreen extends StatefulWidget {
  const LevelTestRunningScreen({super.key});

  @override
  State<LevelTestRunningScreen> createState() => _LevelTestRunningScreenState();
}

class _LevelTestRunningScreenState extends State<LevelTestRunningScreen> {
  static const _currentNavIndex = DashboardTabNavigation.home;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  void _onStartRun() {
    debugPrint('버튼 클릭됨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    4,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: AppColors.textBlack,
                          iconSize: 22,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        AppStrings.levelTestTitle,
                        style: AppTextStyles.header1.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.levelTestSubtitle,
                        style: AppTextStyles.termsSubtitle,
                      ),
                      const SizedBox(height: 20),
                      const _StatsProgressCard(),
                      const SizedBox(height: 20),
                      const Center(child: _MiniMapCard()),
                      const SizedBox(height: 20),
                      Material(
                        color: AppColors.primaryMint,
                        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _onStartRun,
                          child: SizedBox(
                            width: double.infinity,
                            height: AppShapes.buttonHeight,
                            child: Center(
                              child: Text(
                                AppStrings.levelTestStartRun,
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.textWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _StatsProgressCard extends StatelessWidget {
  const _StatsProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
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
          Row(
            children: const [
              Expanded(child: _StatColumn(
                label: AppStrings.levelTestStatDistance,
                value: AppStrings.levelTestStatDistanceValue,
              )),
              Expanded(child: _StatColumn(
                label: AppStrings.levelTestStatTime,
                value: AppStrings.levelTestStatTimeValue,
              )),
              Expanded(child: _StatColumn(
                label: AppStrings.levelTestStatPace,
                value: AppStrings.levelTestStatPaceValue,
              )),
            ],
          ),
          const SizedBox(height: 20),
          const _ChevronProgressBar(activeSteps: 3, totalSteps: 5),
          const SizedBox(height: 12),
          Text(
            AppStrings.levelTestChallengeProgress,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.agreementLabel.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChevronProgressBar extends StatelessWidget {
  const _ChevronProgressBar({
    required this.activeSteps,
    required this.totalSteps,
  });

  final int activeSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index < activeSteps;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 2),
              child: _ChevronStep(
                isActive: isActive,
                isFirst: index == 0,
                isLast: index == totalSteps - 1,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChevronStep extends StatelessWidget {
  const _ChevronStep({
    required this.isActive,
    required this.isFirst,
    required this.isLast,
  });

  final bool isActive;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryMint : AppColors.borderLight;

    return CustomPaint(
      painter: _ChevronPainter(
        color: color,
        isFirst: isFirst,
        isLast: isLast,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final h = size.height;
    final w = size.width;
    const notch = 8.0;

    if (isFirst) {
      path.moveTo(0, 0);
      path.lineTo(w - notch, 0);
      path.lineTo(w, h / 2);
      path.lineTo(w - notch, h);
      path.lineTo(0, h);
      path.close();
    } else if (isLast) {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(notch, h / 2);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(w - notch, 0);
      path.lineTo(w, h / 2);
      path.lineTo(w - notch, h);
      path.lineTo(0, h);
      path.lineTo(notch, h / 2);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast;
  }
}

class _MiniMapCard extends StatelessWidget {
  const _MiniMapCard();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.9,
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              children: [
                Container(
                  color: AppColors.bgGradientMid,
                  child: CustomPaint(
                    painter: _MapPathPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 36,
                  child: _MapMarker(
                    label: AppStrings.levelTestGhostPace,
                    color: AppColors.textGrey,
                  ),
                ),
                Positioned(
                  right: 40,
                  top: 48,
                  child: _MapMarker(
                    label: AppStrings.levelTestMyLocation,
                    color: AppColors.primaryMint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.32,
        size.width * 0.88,
        size.height * 0.28,
      );

    final paint = Paint()
      ..color = AppColors.primaryMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceWhite, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.textBlack.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppColors.textBlack.withValues(alpha: 0.08),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
        ),
      ],
    );
  }
}
