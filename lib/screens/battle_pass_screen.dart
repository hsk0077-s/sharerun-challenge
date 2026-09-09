import 'package:flutter/material.dart';

import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_gradient_background.dart';

/// 배틀런 패스 보상 화면 (Screen 24).
class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({super.key});

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen> {
  static const _currentNavIndex = DashboardTabNavigation.challenge;

  static const _screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Colors.white],
  );

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      Navigator.pop(context);
      return;
    }
    DashboardTabNavigation.go(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SRCGradientBackground(
          gradient: _screenGradient,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BattlePassHeader(
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const _PremiumStatusCard(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: const [
                      _BattlePassRewardCard(
                        level: 15,
                        state: _RewardCardState.completed,
                      ),
                      SizedBox(height: 12),
                      _BattlePassRewardCard(
                        level: 16,
                        state: _RewardCardState.current,
                      ),
                      SizedBox(height: 12),
                      _BattlePassRewardCard(
                        level: 17,
                        state: _RewardCardState.locked,
                      ),
                    ],
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
      ),
    );
  }
}

class _BattlePassHeader extends StatelessWidget {
  const _BattlePassHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
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
          Text(
            AppStrings.battlePassTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFF42A5F5),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.storeDiamondBalance,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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

class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard();

  static const _navy = Color(0xFF1A2B4A);
  static const _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.battlePassPremiumActive,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.battlePassCurrentLevel,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: _navy.withValues(alpha: 0.6)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.8,
                    child: Container(color: AppColors.primaryMint),
                  ),
                  Text(
                    AppStrings.battlePassProgressLabel,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RewardCardState { completed, current, locked }

class _BattlePassRewardCard extends StatelessWidget {
  const _BattlePassRewardCard({
    required this.level,
    required this.state,
  });

  final int level;
  final _RewardCardState state;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _RewardCardState.current;
    final isLocked = state == _RewardCardState.locked;
    final isCompleted = state == _RewardCardState.completed;

    return Opacity(
      opacity: isLocked ? 0.55 : 1,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: isCurrent ? Colors.amber : AppColors.borderLight,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _RewardColumn(
                label: AppStrings.battlePassFreeReward,
                child: _buildFreeReward(isCompleted, isLocked, isCurrent),
              ),
            ),
            Container(width: 1, height: 50, color: AppColors.borderLight),
            Expanded(
              child: _RewardColumn(
                label: '',
                child: _buildLevelColumn(isCurrent, isLocked),
              ),
            ),
            Container(width: 1, height: 50, color: AppColors.borderLight),
            Expanded(
              child: _RewardColumn(
                label: AppStrings.battlePassPremiumReward,
                child: _buildPremiumReward(isCompleted, isLocked, isCurrent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeReward(bool completed, bool locked, bool current) {
    if (completed) {
      return const Icon(Icons.check_rounded, color: AppColors.textBlack, size: 22);
    }
    if (locked) {
      return Icon(Icons.lock_outline_rounded, color: AppColors.textGreyLight, size: 22);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.progressYellow,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'S',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          AppStrings.battlePassFreeShare,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPremiumReward(bool completed, bool locked, bool current) {
    if (completed) {
      return const Icon(Icons.check_rounded, color: AppColors.textBlack, size: 22);
    }
    if (locked) {
      return Icon(Icons.lock_outline_rounded, color: AppColors.textGreyLight, size: 22);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.diamond_rounded, color: Color(0xFF42A5F5), size: 22),
        const SizedBox(height: 4),
        const Text(
          AppStrings.battlePassPremiumDia,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLevelColumn(bool current, bool locked) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (current)
          const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.amber),
        if (current) const SizedBox(height: 2),
        Text(
          'Lv. $level',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: locked ? AppColors.textGrey : AppColors.textBlack,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RewardColumn extends StatelessWidget {
  const _RewardColumn({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        if (label.isNotEmpty) const SizedBox(height: 6),
        child,
      ],
    );
  }
}
