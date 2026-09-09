import 'package:flutter/material.dart';

import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';
import 'running_crew_screen.dart';

/// 러닝 기어 & 프로 툴 화면 (Screen 15).
class ProToolsScreen extends StatefulWidget {
  const ProToolsScreen({super.key});

  @override
  State<ProToolsScreen> createState() => _ProToolsScreenState();
}

class _ProToolsScreenState extends State<ProToolsScreen> {
  static const _currentNavIndex = DashboardTabNavigation.myPage;

  static const _mileageProgress = 0.84;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  void _onMenuTap() {
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
                    8,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProToolsHeader(onBack: () => Navigator.pop(context)),
                      const SizedBox(height: 20),
                      const _ShoeMileageCard(progress: _mileageProgress),
                      const SizedBox(height: 14),
                      _ProToolMenuTile(
                        icon: Icons.access_time_rounded,
                        label: AppStrings.proToolsMenuPaceCalc,
                        onTap: _onMenuTap,
                      ),
                      const SizedBox(height: 10),
                      _ProToolMenuTile(
                        icon: Icons.bar_chart_rounded,
                        label: AppStrings.proToolsMenuAiReport,
                        onTap: _onMenuTap,
                      ),
                      const SizedBox(height: 10),
                      _ProToolMenuTile(
                        icon: Icons.shield_outlined,
                        label: AppStrings.proToolsMenuCrewRanking,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const RunningCrewScreen(),
                            ),
                          );
                        },
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

class _ProToolsHeader extends StatelessWidget {
  const _ProToolsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textBlack,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                Text(
                  AppStrings.proToolsTitle,
                  style: AppTextStyles.header1.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.proToolsSubtitle,
                  style: AppTextStyles.termsSubtitle.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoeMileageCard extends StatelessWidget {
  const _ShoeMileageCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_run_rounded,
                color: AppColors.primaryMint,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.proToolsRegisteredShoe,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * progress;
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    children: [
                      Container(color: AppColors.borderLight),
                      Container(
                        width: barWidth,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryMint,
                              AppColors.warningOrange,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppStrings.proToolsMileageStats,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: AppColors.textGrey,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.proToolsCushionWarning,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warningOrange,
                    height: 1.45,
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

class _ProToolMenuTile extends StatelessWidget {
  const _ProToolMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(icon, size: 20, color: AppColors.textGrey),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.agreementLabel.copyWith(fontSize: 14),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGreyLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
