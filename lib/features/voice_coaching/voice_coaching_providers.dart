import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_coaching_controller.dart';
import 'voice_coaching_cues.dart';
import 'voice_coaching_preference_store.dart';
import 'voice_coaching_speaker.dart';

/// Always the free coach in this PR. Paid/DIA plans can replace this later.
final voiceCoachPlanProvider = Provider<VoiceCoachPlan>(
  (ref) => VoiceCoachPlan.free,
);

final voiceCoachingPreferenceStoreProvider =
    Provider<VoiceCoachingPreferenceStore>(
  (ref) => const VoiceCoachingPreferenceStore(),
);

final voiceCoachingSpeakerProvider = Provider<VoiceCoachingSpeaker>((ref) {
  final speaker = FlutterTtsVoiceCoachingSpeaker();
  ref.onDispose(() {
    speaker.dispose();
  });
  return speaker;
});

class VoiceCoachingEnabledNotifier extends Notifier<bool> {
  Future<void>? _load;
  var _userSet = false;

  @override
  bool build() {
    _load = _hydrate();
    return false;
  }

  Future<void> ensureLoaded() => _load ?? Future<void>.value();

  Future<void> _hydrate() async {
    final enabled =
        await ref.read(voiceCoachingPreferenceStoreProvider).readEnabled();
    if (!ref.mounted || _userSet) return;
    if (state != enabled) {
      state = enabled;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _userSet = true;
    if (state != enabled) {
      state = enabled;
    }
    await ref.read(voiceCoachingPreferenceStoreProvider).writeEnabled(enabled);
    await ref.read(voiceCoachingControllerProvider).onEnabledChanged(enabled);
  }
}

final voiceCoachingEnabledProvider =
    NotifierProvider<VoiceCoachingEnabledNotifier, bool>(
  VoiceCoachingEnabledNotifier.new,
);

final voiceCoachingControllerProvider = Provider<VoiceCoachingController>(
  (ref) {
    return VoiceCoachingController(
      isEnabled: () => ref.read(voiceCoachingEnabledProvider),
      speaker: ref.watch(voiceCoachingSpeakerProvider),
    );
  },
);
