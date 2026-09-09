import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/economy_constants.dart';
import '../../../data/models/economy_state_model.dart';

class EconomyStatusCard extends StatelessWidget {
  const EconomyStatusCard({
    super.key,
    required this.economy,
  });

  final EconomyStateModel economy;

  @override
  Widget build(BuildContext context) {
    final daily = economy.dailyMining;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonLime.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '온보딩 & 채굴 현황',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _RewardRow(
            icon: Icons.card_giftcard_rounded,
            label: '신규 가입 보상',
            value: economy.signupRewardClaimed
                ? '${EconomyConstants.signupRewardSrv} SRV 지급 완료'
                : '가입 후 ${EconomyConstants.signupRewardSrv} SRV 대기',
            done: economy.signupRewardClaimed,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            icon: Icons.directions_run_rounded,
            label: '예비 러닝',
            detail:
                '${economy.trialRunCount}/${EconomyConstants.trialRunsRequired}회 · 완료 시 ${EconomyConstants.trialCompletionRewardSrv} SRV',
            progress: economy.trialProgress,
            color: AppColors.electricBlue,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            icon: Icons.bolt_rounded,
            label: '일일 채굴 캡',
            detail:
                '${daily.earnedKm.toStringAsFixed(1)}/${EconomyConstants.dailyCapKm}km · ${daily.earnedSrvTokens}/${EconomyConstants.dailyCapSrvTokens} SRV',
            progress: daily.tokenProgress,
            color: AppColors.neonLime,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            icon: Icons.people_alt_rounded,
            label: '추천인 보상 (지연 지급)',
            detail:
                '${economy.referralPayoutCount}/${EconomyConstants.maxReferralPayouts}명 · 지인 5회 예비 완료 시 ${EconomyConstants.referralRewardSrv} SRV',
            progress: economy.referralProgress,
            color: Colors.purpleAccent,
          ),
          if (economy.referralCode != null) ...[
            const SizedBox(height: 14),
            Text(
              '내 추천 코드: ${economy.referralCode}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.done,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: done ? AppColors.neonLime : AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: done ? AppColors.neonLime : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.progress,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String detail;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(detail, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: Colors.white12,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}
