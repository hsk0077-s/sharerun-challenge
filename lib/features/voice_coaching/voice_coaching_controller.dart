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
    bool Function()? isCoachPlusActive,
    void Function()? onCoachPlusUpsell,
  })  : _isEnabled = isEnabled,
        _speaker = speaker,
        session = session ?? VoiceCoachingSession(),
        whenToSpeak = whenToSpeak ?? VoiceCoachWhenToSpeak(),
        _now = now ?? DateTime.now,
        _isSessionActive = isSessionActive ?? _alwaysActive,
        _isDeviceMuted = isDeviceMuted ?? _neverMuted,
        _isCoachPlusActive = isCoachPlusActive ?? _coachPlusInactive,
        _onCoachPlusUpsell = onCoachPlusUpsell;

  static bool _alwaysActive() => true;
  static bool _neverMuted() => false;
  static bool _coachPlusInactive() => false;

  final bool Function() _isEnabled;
  final VoiceCoachingSpeaker _speaker;
  final DateTime Function() _now;
  final bool Function() _isSessionActive;
  final bool Function() _isDeviceMuted;
  final bool Function() _isCoachPlusActive;
  final void Function()? _onCoachPlusUpsell;
  var _coachPlusUpsellShown = false;
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
    await _trySpeak(cue, languageCode: languageCode);
  }

  Future<bool> _trySpeak(VoiceCue? cue, {String languageCode = 'ko'}) async {
    if (cue == null) return false;
    final kind = voiceCoachCueKindForPhase3aId(cue.id);
    if (kind == null) return false;
    final verdict = whenToSpeak.consider(kind: kind, context: _speakContext());
    if (!verdict.shouldSpeak) return false;
    await _speaker.speak(cue.text(languageCode: languageCode));
    return true;
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

  Future<void> onRunStarted() {
    session.resetRun();
    return speakCue(session.runStarted());
  }

  /// [targetKm] is the race distance already shown in the room (1km / 3km).
  /// Omit it on a free run — no invented finish line.
  /// [elapsedSeconds] drives the sparse pep. Omit it and that cue stays off.
  /// [heartRateBpm] is the challenge-tracker BPM. Omit it when the screen
  /// has no heart-rate reading. The live GPS room does not pass one.
  Future<void> onRunProgress({
    required double previousKm,
    required double currentKm,
    int? elapsedSeconds,
    double? targetKm,
    int? heartRateBpm,
  }) async {
    final heart = session.claimHeartRateCue(heartRateBpm);
    final coachPlus = _isCoachPlusActive();
    if (heart != null && !coachPlus) {
      session.releaseHeartRateCue();
      _requestCoachPlusUpsell();
    }
    if (coachPlus &&
        heart != null &&
        heart.id == VoiceCoachingCues.runHighHeartRate.id) {
      await _finishHeartRateCue(heart);
      return;
    }
    final kilometer = session.crossedRunKilometer(
      previousKm: previousKm,
      currentKm: currentKm,
    );
    final nearFinish = session.approachingFinish(
      previousKm: previousKm,
      currentKm: currentKm,
      targetKm: targetKm,
    );
    if (kilometer != null || nearFinish != null) {
      if (coachPlus && heart != null) session.releaseHeartRateCue();
      await speakCue(kilometer ?? nearFinish);
      return;
    }
    if (coachPlus && heart != null) {
      await _finishHeartRateCue(heart);
      return;
    }
    final encouragement = elapsedSeconds == null
        ? null
        : session.crossedSparseEncouragement(elapsedSeconds);
    await speakCue(encouragement);
  }

  void _requestCoachPlusUpsell() {
    if (_coachPlusUpsellShown) return;
    if (!_isEnabled() || !_isSessionActive() || _isDeviceMuted()) return;
    _coachPlusUpsellShown = true;
    _onCoachPlusUpsell?.call();
  }

  Future<void> _finishHeartRateCue(VoiceCue cue) async {
    if (await _trySpeak(cue)) {
      session.confirmHeartRateCueSpoken();
    } else {
      session.releaseHeartRateCue();
    }
  }

  Future<void> onRunFinished() => speakCue(session.runFinished());

  Future<void> stop() => _speaker.stop();
}
