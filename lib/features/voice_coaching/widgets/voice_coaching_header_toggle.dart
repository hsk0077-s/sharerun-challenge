import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../voice_coaching_providers.dart';

/// Compact in-run / in-walk header control for the persisted coaching toggle.
class VoiceCoachingHeaderToggle extends ConsumerWidget {
  const VoiceCoachingHeaderToggle({
    super.key,
    this.color = AppColors.textWhite,
  });

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(voiceCoachingEnabledProvider);
    return IconButton(
      key: const Key('voice-coaching-header-toggle'),
      tooltip: enabled
          ? AppStrings.voiceCoachingOnTooltip
          : AppStrings.voiceCoachingOffTooltip,
      icon: Icon(
        enabled ? Icons.record_voice_over : Icons.voice_over_off,
        color: color,
      ),
      onPressed: () {
        ref.read(voiceCoachingEnabledProvider.notifier).setEnabled(!enabled);
      },
    );
  }
}
