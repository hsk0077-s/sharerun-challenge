import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../strings/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 메인 대시보드 하단 네비게이션 바 (5대 탭).
class DashboardBottomNav extends ConsumerWidget {
  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.walletTabSelected = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 나의 지갑 화면 — 상점 슬롯을 지갑 라인 아이콘으로 바꾸고 활성 처리.
  final bool walletTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPageDot = ref.watch(hasPendingJenaAppealProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: AppStrings.dashboardNavHome,
                selected: !walletTabSelected && currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: walletTabSelected
                    ? Icons.account_balance_wallet_outlined
                    : Icons.shopping_bag_rounded,
                label: walletTabSelected
                    ? AppStrings.dashboardNavWallet
                    : AppStrings.dashboardNavStore,
                selected: walletTabSelected || currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: AppStrings.dashboardNavChallenge,
                selected: !walletTabSelected && currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.groups_rounded,
                label: AppStrings.dashboardNavCrew,
                selected: !walletTabSelected && currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: AppStrings.dashboardNavMyPage,
                selected: !walletTabSelected && currentIndex == 4,
                showDot: myPageDot,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryMint : AppColors.textGrey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: showDot,
              smallSize: 7,
              backgroundColor: AppColors.error,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
