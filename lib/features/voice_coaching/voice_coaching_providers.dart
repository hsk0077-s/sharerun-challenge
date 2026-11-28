import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recorded_voice_speaker.dart';
import 'voice_coach_output_mute.dart';
import 'voice_coaching_controller.dart';
import 'voice_coaching_cues.dart';
import 'voice_coaching_preference_store.dart';
import 'voice_coaching_speaker.dart';

/// Start, kilometer, pep, and heart-rate lines. Coaching is free for everyone.
final voiceCoachPlanProvider = Provider<VoiceCoachPlan>(
  (ref) => VoiceCoachPlan.free,
);

final voiceCoachingPreferenceStoreProvider =
    Provider<VoiceCoachingPreferenceStore>(
  (ref) => const VoiceCoachingPreferenceStore(),
);

final voiceCoachMuteProbeProvider = Provider<VoiceCoachMuteProbe>(
  (ref) => const VoiceCoachMuteProbe(),
);

final voiceCoachingSpeakerProvider = Provider<VoiceCoachingSpeaker>((ref) {
  // 미리 만든 음성 파일이 있는 문구는 파일로, 나머지는 폰 음성으로 읽는다.
  final speaker = RecordedVoiceCoachingSpeaker(
    fallback: FlutterTtsVoiceCoachingSpeaker(),
  );
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
      refreshDeviceMuted: () => ref.read(voiceCoachMuteProbeProvider).isMuted(),
    );
  },
);
