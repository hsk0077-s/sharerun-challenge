import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../voice_coaching_providers.dart';

/// Walking-challenge row matching the existing benefit-notification banner.
class VoiceCoachingWalkBanner extends ConsumerWidget {
  const VoiceCoachingWalkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;
    final enabled = ref.watch(voiceCoachingEnabledProvider);

    return SrcSurfaceCard(
      color: tokens.colors.surface,
      borderColor: tokens.colors.outline.withValues(alpha: 0.7),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.sm,
        tokens.spacing.sm,
        tokens.spacing.xs,
        tokens.spacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.record_voice_over : Icons.voice_over_off,
            size: 18,
            color: enabled ? tokens.colors.accent : tokens.colors.muted,
          ),
          SizedBox(width: tokens.spacing.xs),
          Expanded(
            child: Text(
              enabled
                  ? AppStrings.voiceCoachingWalkOn
                  : AppStrings.voiceCoachingWalkOff,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: enabled ? tokens.colors.ink : tokens.colors.muted,
              ),
            ),
          ),
          GestureDetector(
            key: const Key('voice-coaching-walk-toggle'),
            onTap: () {
              ref
                  .read(voiceCoachingEnabledProvider.notifier)
                  .setEnabled(!enabled);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.sm,
                vertical: tokens.spacing.xxs + 2,
              ),
              decoration: BoxDecoration(
                color: enabled ? tokens.colors.surface : tokens.colors.primary,
                borderRadius: tokens.radii.capsule,
                border: Border.all(
                  color: enabled ? tokens.colors.accent : tokens.colors.primary,
                ),
              ),
              child: Text(
                enabled
                    ? AppStrings.voiceCoachingDisable
                    : AppStrings.voiceCoachingEnable,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: enabled
                      ? tokens.colors.accent
                      : tokens.colors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
