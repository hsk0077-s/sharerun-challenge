import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/profile/widgets/angel_tier_widgets.dart';

/// 예비 천사 → 세라핌 6단계 천사 도감.
class AngelBookPage extends ConsumerWidget {
  const AngelBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final current = profile.angelTier;
    final count = profile.safeDonationCount;
    final amount = profile.safeCumulativeDonationAmount;

    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '천사 도감',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _AngelAchievementDash(
            tier: current,
            donationCount: count,
            amountWon: amount,
          ),
          const SizedBox(height: 22),
          Text(
            '6단계 천사 연대기',
            style: AppTextStyles.header1.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '예비 천사부터 세라핌까지 모든 천사를 열람할 수 있습니다.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: [
              for (final tier in AngelTier.values)
                _AngelChapterCard(
                  tier: tier,
                  onTap: () => _showRewardOverlay(context, tier),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _showRewardOverlay(
    BuildContext context,
    AngelTier tier,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            '${tier.emoji} ${tier.koreanName}',
            style: AppTextStyles.header1.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier.englishName,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '요건  ·  ${tier.requirementLabel}',
                style: AppTextStyles.agreementLabel.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '특전  ·  ${tier.rewardLabel}',
                style: AppTextStyles.agreementLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealAccent,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}

class _AngelAchievementDash extends StatelessWidget {
  const _AngelAchievementDash({
    required this.tier,
    required this.donationCount,
    required this.amountWon,
  });

  final AngelTier tier;
  final int donationCount;
  final int amountWon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(
          color: AppColors.angelGold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          AngelMascot(tier: tier, size: 88),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tier.emoji} ${tier.koreanName}',
                  style: AppTextStyles.header1.copyWith(fontSize: 18),
                ),
                Text(
                  tier.englishName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _TossStat(
                  label: '누적 후원 횟수',
                  value: '$donationCount회',
                ),
                const SizedBox(height: 8),
                _TossStat(
                  label: '누적 후원 SHARE',
                  value: AngelTierX.formatWon(amountWon),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TossStat extends StatelessWidget {
  const _TossStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.textGrey,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.header1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class _AngelChapterCard extends StatelessWidget {
  const _AngelChapterCard({
    required this.tier,
    required this.onTap,
  });

  final AngelTier tier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.angelGold.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 68,
                child: AngelMascot(tier: tier, size: 64),
              ),
              const SizedBox(height: 8),
              Text(
                '${tier.emoji} ${tier.koreanName}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tier.requirementLabel,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  height: 1.3,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
