import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class WinnerRewardDialog extends StatelessWidget {
  const WinnerRewardDialog({
    required this.rewardValueToken,
    required this.onClaimAll,
    required this.onDonateHalf,
    required this.onDonateAll,
    super.key,
  });

  final int rewardValueToken;
  final VoidCallback onClaimAll;
  final VoidCallback onDonateHalf;
  final VoidCallback onDonateAll;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBlack,
      title: const Text('Victory Impact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('축하합니다! 검증된 러닝으로 우승 상금을 획득했습니다.'),
          const SizedBox(height: 16),
          Text(
            '+$rewardValueToken Value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.neonLime,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppColors.neonLime.withValues(alpha: 0.2),
                  AppColors.electricBlue.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.neonLime,
              size: 56,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClaimAll,
          child: const Text('우승 상금 수령하기'),
        ),
        TextButton(
          onPressed: onDonateHalf,
          child: const Text('우승 상금 50% 기부하기'),
        ),
        FilledButton(
          onPressed: onDonateAll,
          child: const Text('100% 전액 기부하기'),
        ),
      ],
    );
  }
}
