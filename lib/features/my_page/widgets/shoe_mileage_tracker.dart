import 'package:flutter/material.dart';

import '../../../core/constants/impact_constants.dart';
import '../../../core/theme/theme.dart';

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
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_run_rounded, color: tokens.colors.accent),
            SizedBox(width: tokens.spacing.xs),
            Text(
              '러닝화 마일리지 트래커',
              style: textTheme.titleMedium?.copyWith(color: tokens.colors.ink),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        LinearProgressIndicator(
          value: progress,
          color: needsReplacement ? tokens.colors.danger : tokens.colors.accent,
          backgroundColor: tokens.colors.outline,
          minHeight: 12,
          borderRadius: BorderRadius.circular(tokens.radii.sm),
        ),
        SizedBox(height: tokens.spacing.sm),
        Text(
          '${totalDistanceKm.toStringAsFixed(1)} km / $goal km',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: tokens.spacing.xs),
        if (needsReplacement)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(tokens.spacing.sm),
            decoration: BoxDecoration(
              color: tokens.colors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(tokens.radii.md),
              border: Border.all(
                color: tokens.colors.danger.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '⚠️ 500km 도달! 쿠셔닝 성능 저하 위험 — 러닝화 교체를 권장합니다.',
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.colors.danger,
                height: 1.4,
              ),
            ),
          )
        else
          Text(
            '교체 알림: ${(goal - totalDistanceKm).toStringAsFixed(1)} km 남음',
            style: textTheme.bodyMedium?.copyWith(color: tokens.colors.muted),
          ),
      ],
    );
  }
}
