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
  var _highHeartRateArmed = true;
  var _highHeartRateSpoken = false;
  var _recoveryDue = false;
  var _recoveryClaimed = false;
  var _steadyHeartRateArmed = true;
  var _steadyHeartRateClaimed = false;
  var _heartRateClaim = _HeartRateClaim.none;

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

  /// One heart-rate line for this sample, or null.
  ///
  /// Plausible band only. Null and out-of-range BPM leave every latch
  /// alone. The slow-down is claimed so two ticks cannot both take it.
  /// [releaseHeartRateCue] gives a claim back when the gate does not speak.
  /// [confirmHeartRateCueSpoken] is what arms the recovered line — a
  /// slow-down that stayed silent does not say the heart rate came down.
  VoiceCue? claimHeartRateCue(int? bpm) {
    if (bpm == null ||
        bpm < VoiceCoachingCues.minPlausibleHeartRateBpm ||
        bpm > VoiceCoachingCues.maxPlausibleHeartRateBpm) {
      return null;
    }

    if (bpm >= VoiceCoachingCues.highHeartRateBpm) {
      _recoveryDue = false;
      _recoveryClaimed = false;
      _steadyHeartRateArmed = false;
      if (!_highHeartRateArmed) return null;
      _highHeartRateArmed = false;
      _heartRateClaim = _HeartRateClaim.high;
      return VoiceCoachingCues.runHighHeartRate;
    }

    if (bpm <= VoiceCoachingCues.highHeartRateRearmBpm) {
      _highHeartRateArmed = true;
      if (_highHeartRateSpoken) {
        _highHeartRateSpoken = false;
        _recoveryDue = true;
      }
    } else if (_recoveryDue) {
      // Climbed out of the rearm band before the recovered line spoke.
      _recoveryDue = false;
      _recoveryClaimed = false;
    }

    if (_recoveryDue && !_recoveryClaimed) {
      _recoveryClaimed = true;
      _heartRateClaim = _HeartRateClaim.recovered;
      return VoiceCoachingCues.runHeartRateRecovered;
    }

    final inHighEpisode = !_highHeartRateArmed;
    if (!inHighEpisode &&
        !_recoveryDue &&
        bpm <= VoiceCoachingCues.steadyHeartRateRearmBpm) {
      _steadyHeartRateArmed = true;
      _steadyHeartRateClaimed = false;
    }

    if (!inHighEpisode &&
        !_recoveryDue &&
        bpm >= VoiceCoachingCues.steadyHeartRateBpm &&
        _steadyHeartRateArmed &&
        !_steadyHeartRateClaimed) {
      _steadyHeartRateClaimed = true;
      _heartRateClaim = _HeartRateClaim.steady;
      return VoiceCoachingCues.runHeartRateSteady;
    }
    return null;
  }

  /// The gate spoke [claimHeartRateCue]'s last cue.
  void confirmHeartRateCueSpoken() {
    switch (_heartRateClaim) {
      case _HeartRateClaim.high:
        _highHeartRateSpoken = true;
        _steadyHeartRateArmed = false;
      case _HeartRateClaim.recovered:
        _recoveryDue = false;
        _recoveryClaimed = false;
        _steadyHeartRateArmed = false;
      case _HeartRateClaim.steady:
        _steadyHeartRateArmed = false;
        _steadyHeartRateClaimed = false;
      case _HeartRateClaim.none:
        break;
    }
    _heartRateClaim = _HeartRateClaim.none;
  }

  /// The gate did not speak the last claim. The same band can try again.
  void releaseHeartRateCue() {
    switch (_heartRateClaim) {
      case _HeartRateClaim.high:
        _highHeartRateArmed = true;
        _highHeartRateSpoken = false;
      case _HeartRateClaim.recovered:
        _recoveryClaimed = false;
      case _HeartRateClaim.steady:
        _steadyHeartRateClaimed = false;
      case _HeartRateClaim.none:
        break;
    }
    _heartRateClaim = _HeartRateClaim.none;
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
    _highHeartRateArmed = true;
    _highHeartRateSpoken = false;
    _recoveryDue = false;
    _recoveryClaimed = false;
    _steadyHeartRateArmed = true;
    _steadyHeartRateClaimed = false;
    _heartRateClaim = _HeartRateClaim.none;
  }
}

enum _HeartRateClaim { none, high, steady, recovered }
