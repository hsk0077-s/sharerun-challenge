import 'voice_coaching_cues.dart';
import 'voice_coaching_session.dart';
import 'voice_coaching_speaker.dart';

/// Gates every cue on the user toggle. When off: no audio, no TTS warmup.
class VoiceCoachingController {
  VoiceCoachingController({
    required bool Function() isEnabled,
    required VoiceCoachingSpeaker speaker,
    VoiceCoachingSession? session,
  })  : _isEnabled = isEnabled,
        _speaker = speaker,
        session = session ?? VoiceCoachingSession();

  final bool Function() _isEnabled;
  final VoiceCoachingSpeaker _speaker;
  final VoiceCoachingSession session;

  bool get enabled => _isEnabled();

  Future<void> speakCue(VoiceCue? cue, {String languageCode = 'ko'}) async {
    if (cue == null || !_isEnabled()) return;
    await _speaker.speak(cue.text(languageCode: languageCode));
  }

  Future<void> onEnabledChanged(bool enabled) async {
    if (!enabled) {
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
