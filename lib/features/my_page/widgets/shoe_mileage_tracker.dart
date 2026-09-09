import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/impact_constants.dart';

class ShoeMileageTracker extends StatelessWidget {
  const ShoeMileageTracker({
    required this.totalDistanceKm,
    super.key,
  });

  final double totalDistanceKm;

  @override
  Widget build(BuildContext context) {
    final goal = ImpactConstants.shoeMileageGoalKm;
    final progress = (totalDistanceKm / goal).clamp(0.0, 1.0);
    final needsReplacement = totalDistanceKm >= goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_run_rounded, color: AppColors.electricBlue),
            const SizedBox(width: 8),
            Text(
              '러닝화 마일리지 트래커',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          color: needsReplacement ? AppColors.dangerRed : AppColors.electricBlue,
          backgroundColor: Colors.white12,
          minHeight: 12,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 10),
        Text(
          '${totalDistanceKm.toStringAsFixed(1)} km / $goal km',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (needsReplacement)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.4)),
            ),
            child: const Text(
              '⚠️ 500km 도달! 쿠셔닝 성능 저하 위험 — 러닝화 교체를 권장합니다.',
              style: TextStyle(color: AppColors.dangerRed, height: 1.4),
            ),
          )
        else
          Text(
            '교체 알림: ${(goal - totalDistanceKm).toStringAsFixed(1)} km 남음',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}
