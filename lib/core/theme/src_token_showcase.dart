import 'package:flutter/material.dart';

import '../widgets/src_button.dart';
import 'app_shadows.dart';
import 'app_text_styles.dart';
import 'src_surface_card.dart';
import 'src_tokens.dart';

/// Compact visual catalog so tokens are exercised without restyling product
/// screens. Used by widget tests; not mounted in the app navigator.
class SrcTokenShowcase extends StatelessWidget {
  const SrcTokenShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return ColoredBox(
      color: tokens.colors.canvas,
      child: ListView(
        padding: EdgeInsets.all(tokens.spacing.page),
        children: [
          const Text('SRC tokens', style: AppTextStyles.headline),
          SizedBox(height: tokens.spacing.xxs),
          const Text(
            'Primary mint · accent teal · donation gold',
            style: AppTextStyles.caption,
          ),
          SizedBox(height: tokens.spacing.md),
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              _Swatch(label: 'primary', color: tokens.colors.primary),
              _Swatch(label: 'accent', color: tokens.colors.accent),
              _Swatch(label: 'donation', color: tokens.colors.donation),
              _Swatch(label: 'ink', color: tokens.colors.ink),
              _Swatch(label: 'muted', color: tokens.colors.muted),
              _Swatch(label: 'outline', color: tokens.colors.outline),
            ],
          ),
          SizedBox(height: tokens.spacing.lg),
          SrcSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Surface card', style: AppTextStyles.titleSm),
                SizedBox(height: tokens.spacing.xs),
                const Text(
                  'spacing.md · radii.md · shadows.card',
                  style: AppTextStyles.caption,
                ),
                SizedBox(height: tokens.spacing.md),
                SRCButton(
                  label: 'Primary CTA',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colors.surface,
              borderRadius: tokens.radii.panel,
              boxShadow: AppShadows.raised,
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.md),
              child: Text(
                'Donation moment',
                style: AppTextStyles.agreementLabel.copyWith(
                  color: tokens.colors.donation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.srcTokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(tokens.radii.sm),
            border: Border.all(color: tokens.colors.outline),
          ),
        ),
        SizedBox(height: tokens.spacing.xxs),
        Text(label, style: AppTextStyles.overline),
      ],
    );
  }
}
