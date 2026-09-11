import 'package:flutter/material.dart';
import 'package:share_run_challenge/core/theme/theme.dart';

class CurrencyBadge extends StatelessWidget {
  const CurrencyBadge({
    required this.label,
    required this.amount,
    required this.color,
    super.key,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(tokens.spacing.sm),
      decoration: BoxDecoration(
        color: tokens.colors.surface,
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: tokens.radii.card,
        boxShadow: AppShadows.rest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            amount.toString(),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: tokens.colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
