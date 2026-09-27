import 'voice_coaching_cues.dart';

/// Pure session logic: speak only when a threshold is *crossed*.
///
/// Restoring an already-high step count does not replay past cues.
class VoiceCoachingSession {
  var _walkWelcomeSpoken = false;
  var _runWelcomeSpoken = false;
  var _harvestSpoken = false;
  var _nearFinishSpoken = false;
  var _lastRunElapsedSeconds = 0;

  VoiceCue? walkingOpened() {
    if (_walkWelcomeSpoken) return null;
    _walkWelcomeSpoken = true;
    return VoiceCoachingCues.walkStart;
  }

  VoiceCue? crossedStepMilestone({
    required int previous,
    required int current,
  }) {
    VoiceCue? cue;
    for (final milestone in VoiceCoachingCues.walkStepMilestones) {
      if (previous < milestone && current >= milestone) {
        cue = VoiceCoachingCues.walkSteps(milestone);
      }
    }
    return cue;
  }

  VoiceCue? crossedDistanceGoal({
    required double previousKm,
    required double currentKm,
    required double targetKm,
  }) {
    if (targetKm <= 0) return null;
    if (previousKm < targetKm && currentKm >= targetKm) {
      return VoiceCoachingCues.walkGoal;
    }
    return null;
  }

  VoiceCue? harvestCompleted() {
    if (_harvestSpoken) return null;
    _harvestSpoken = true;
    return VoiceCoachingCues.walkHarvest;
  }

  VoiceCue? runStarted() {
    if (_runWelcomeSpoken) return null;
    _runWelcomeSpoken = true;
    return VoiceCoachingCues.runStart;
  }

  VoiceCue? crossedRunKilometer({
    required double previousKm,
    required double currentKm,
  }) {
    final previousWhole = previousKm.floor();
    final currentWhole = currentKm.floor();
    if (currentWhole < 1 || currentWhole <= previousWhole) return null;
    return VoiceCoachingCues.runKm(currentWhole);
  }

  /// Once, when remaining distance on a known target crosses 200m.
  /// No target (free run) stays silent. Overshooting the finish stays silent.
  VoiceCue? approachingFinish({
    required double previousKm,
    required double currentKm,
    required double? targetKm,
  }) {
    final target = targetKm;
    final window = VoiceCoachingCues.runNearFinishRemainingKm;
    if (_nearFinishSpoken || target == null || target <= window) return null;
    final previousRemaining = target - previousKm;
    final currentRemaining = target - currentKm;
    if (previousRemaining > window &&
        currentRemaining <= window &&
        currentRemaining > 0) {
      _nearFinishSpoken = true;
      return VoiceCoachingCues.runNearFinish;
    }
    return null;
  }

  /// One short pep each [VoiceCoachingCues.runEncourageEverySeconds].
  /// Crossing several buckets in one sample still returns a single line.
  VoiceCue? crossedSparseEncouragement(int elapsedSeconds) {
    final previous = _lastRunElapsedSeconds;
    _lastRunElapsedSeconds = elapsedSeconds;
    final interval = VoiceCoachingCues.runEncourageEverySeconds;
    if (interval <= 0 || elapsedSeconds < previous) return null;
    final previousBucket = previous ~/ interval;
    final currentBucket = elapsedSeconds ~/ interval;
    if (currentBucket < 1 || currentBucket <= previousBucket) return null;
    return VoiceCoachingCues.runEncourage;
  }

  VoiceCue? runFinished() => VoiceCoachingCues.runFinish;

  void resetWalkDay() {
    _walkWelcomeSpoken = false;
    _harvestSpoken = false;
  }

  void resetRun() {
    _runWelcomeSpoken = false;
    _nearFinishSpoken = false;
    _lastRunElapsedSeconds = 0;
  }
}
