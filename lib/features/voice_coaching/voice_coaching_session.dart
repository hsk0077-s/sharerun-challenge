import 'voice_coaching_cues.dart';

/// Pure session logic: speak only when a threshold is *crossed*.
///
/// Restoring an already-high step count does not replay past cues.
class VoiceCoachingSession {
  var _walkWelcomeSpoken = false;
  var _runWelcomeSpoken = false;
  var _harvestSpoken = false;

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

  VoiceCue? runFinished() => VoiceCoachingCues.runFinish;

  void resetWalkDay() {
    _walkWelcomeSpoken = false;
    _harvestSpoken = false;
  }

  void resetRun() {
    _runWelcomeSpoken = false;
  }
}
