import 'voice_coach_when_to_speak.dart';
import 'voice_coaching_cues.dart';
import 'voice_coaching_session.dart';
import 'voice_coaching_speaker.dart';

/// Gates every cue on [VoiceCoachWhenToSpeak] (toggle, session, mute, 45s).
class VoiceCoachingController {
  VoiceCoachingController({
    required bool Function() isEnabled,
    required VoiceCoachingSpeaker speaker,
    VoiceCoachingSession? session,
    VoiceCoachWhenToSpeak? whenToSpeak,
    DateTime Function()? now,
    bool Function()? isSessionActive,
    bool Function()? isDeviceMuted,
  })  : _isEnabled = isEnabled,
        _speaker = speaker,
        session = session ?? VoiceCoachingSession(),
        whenToSpeak = whenToSpeak ?? VoiceCoachWhenToSpeak(),
        _now = now ?? DateTime.now,
        _isSessionActive = isSessionActive ?? _alwaysActive,
        _isDeviceMuted = isDeviceMuted ?? _neverMuted;

  static bool _alwaysActive() => true;
  static bool _neverMuted() => false;

  final bool Function() _isEnabled;
  final VoiceCoachingSpeaker _speaker;
  final DateTime Function() _now;
  final bool Function() _isSessionActive;
  final bool Function() _isDeviceMuted;
  final VoiceCoachingSession session;
  final VoiceCoachWhenToSpeak whenToSpeak;

  bool get enabled => _isEnabled();

  VoiceCoachSpeakContext _speakContext() {
    return VoiceCoachSpeakContext(
      now: _now(),
      coachingEnabled: _isEnabled(),
      sessionActive: _isSessionActive(),
      deviceMuted: _isDeviceMuted(),
    );
  }

  Future<void> speakCue(VoiceCue? cue, {String languageCode = 'ko'}) async {
    if (cue == null) return;
    final kind = voiceCoachCueKindForPhase3aId(cue.id);
    if (kind == null) return;
    final verdict = whenToSpeak.consider(kind: kind, context: _speakContext());
    if (!verdict.shouldSpeak) return;
    await _speaker.speak(cue.text(languageCode: languageCode));
  }

  Future<void> onEnabledChanged(bool enabled) async {
    if (!enabled) {
      whenToSpeak.resetSession();
      await _speaker.stop();
    }
  }

  Future<void> onWalkingOpened() => speakCue(session.walkingOpened());

  Future<void> onWalkingProgress({
    required int previousSteps,
    required int currentSteps,
    required double previousKm,
    required double currentKm,
    required double targetKm,
  }) async {
    if (!_isEnabled()) return;
    final goal = session.crossedDistanceGoal(
      previousKm: previousKm,
      currentKm: currentKm,
      targetKm: targetKm,
    );
    if (goal != null) {
      await speakCue(goal);
      return;
    }
    await speakCue(
      session.crossedStepMilestone(
        previous: previousSteps,
        current: currentSteps,
      ),
    );
  }

  Future<void> onHarvestCompleted() => speakCue(session.harvestCompleted());

  Future<void> onRunStarted() => speakCue(session.runStarted());

  Future<void> onRunProgress({
    required double previousKm,
    required double currentKm,
  }) {
    return speakCue(
      session.crossedRunKilometer(
        previousKm: previousKm,
        currentKm: currentKm,
      ),
    );
  }

  Future<void> onRunFinished() => speakCue(session.runFinished());

  Future<void> stop() => _speaker.stop();
}
