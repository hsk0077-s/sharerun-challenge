import 'voice_coach_when_to_speak.dart';
import 'voice_coaching_cues.dart';
import 'voice_coaching_session.dart';
import 'voice_coaching_speaker.dart';

/// Gates every cue on [VoiceCoachWhenToSpeak] (toggle, session, mute, 45s).
///
/// When [isSessionActive] is omitted, speech waits for a walk or run method
/// and stops when that epoch is dismissed. Callers that pass [isSessionActive]
/// keep owning the flag (tests). Device mute is [isDeviceMuted] or the last
/// [refreshDeviceMuted] reading. Coaching off never speaks.
class VoiceCoachingController {
  VoiceCoachingController({
    required bool Function() isEnabled,
    required VoiceCoachingSpeaker speaker,
    VoiceCoachingSession? session,
    VoiceCoachWhenToSpeak? whenToSpeak,
    DateTime Function()? now,
    bool Function()? isSessionActive,
    bool Function()? isDeviceMuted,
    Future<bool> Function()? refreshDeviceMuted,
    bool Function()? isCoachPlusActive,
    void Function()? onCoachPlusUpsell,
  })  : _isEnabled = isEnabled,
        _speaker = speaker,
        session = session ?? VoiceCoachingSession(),
        whenToSpeak = whenToSpeak ?? VoiceCoachWhenToSpeak(),
        _now = now ?? DateTime.now,
        _isSessionActive = isSessionActive,
        _isDeviceMuted = isDeviceMuted,
        _refreshDeviceMuted = refreshDeviceMuted,
        _isCoachPlusActive = isCoachPlusActive ?? _coachPlusInactive,
        _onCoachPlusUpsell = onCoachPlusUpsell;

  static bool _coachPlusInactive() => false;

  final bool Function() _isEnabled;
  final VoiceCoachingSpeaker _speaker;
  final DateTime Function() _now;
  final bool Function()? _isSessionActive;
  final bool Function()? _isDeviceMuted;
  final Future<bool> Function()? _refreshDeviceMuted;
  final bool Function() _isCoachPlusActive;
  final void Function()? _onCoachPlusUpsell;
  var _coachPlusUpsellShown = false;
  var _internalSession = false;
  var _liveSessionEpoch = 0;
  var _cachedMuted = false;
  var _holdDismissStop = false;
  final VoiceCoachingSession session;
  final VoiceCoachWhenToSpeak whenToSpeak;

  bool get enabled => _isEnabled();

  /// Bumped when a walk or run session opens. Dismiss with this value.
  /// A newer session ignores an older screen's dismiss.
  int get liveSessionEpoch => _liveSessionEpoch;

  bool _sessionActive() => _isSessionActive?.call() ?? _internalSession;

  bool _deviceMuted() => _isDeviceMuted?.call() ?? _cachedMuted;

  Future<void> _prepareMute() async {
    if (_isDeviceMuted != null) return;
    final refresh = _refreshDeviceMuted;
    if (refresh == null) return;
    try {
      _cachedMuted = await refresh();
    } catch (_) {
      _cachedMuted = false;
    }
  }

  /// Sync. Callers read [liveSessionEpoch] before the first await.
  void _openWalk() {
    if (_isSessionActive != null || _internalSession) return;
    _internalSession = true;
    _liveSessionEpoch += 1;
    whenToSpeak.resetSession();
  }

  /// Sync. A run replaces any walk epoch so the walk screen cannot end it.
  void _openRun() {
    if (_isSessionActive != null) return;
    _internalSession = true;
    _liveSessionEpoch += 1;
    whenToSpeak.resetSession();
  }

  VoiceCoachSpeakContext _speakContext() {
    return VoiceCoachSpeakContext(
      now: _now(),
      coachingEnabled: _isEnabled(),
      sessionActive: _sessionActive(),
      deviceMuted: _deviceMuted(),
    );
  }

  Future<void> speakCue(VoiceCue? cue, {String languageCode = 'ko'}) async {
    await _prepareMute();
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

  Future<void> onWalkingOpened() {
    _openWalk();
    return speakCue(session.walkingOpened());
  }

  Future<void> onWalkingProgress({
    required int previousSteps,
    required int currentSteps,
    required double previousKm,
    required double currentKm,
    required double targetKm,
  }) async {
    if (!_isEnabled()) return;
    _openWalk();
    if (!_sessionActive()) return;
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

  Future<void> onHarvestCompleted() {
    _openWalk();
    return speakCue(session.harvestCompleted());
  }

  Future<void> onRunStarted() {
    _openRun();
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
    if (!_sessionActive()) return;
    await _prepareMute();
    if (!_sessionActive()) return;
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
    final kilometer = VoiceCoachingCues.coachPlusDistanceTone(
      session.crossedRunKilometer(
        previousKm: previousKm,
        currentKm: currentKm,
      ),
      coachPlus: coachPlus,
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
    if (!_isEnabled() || !_sessionActive() || _deviceMuted()) return;
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

  Future<void> onRunFinished() async {
    if (!_sessionActive()) return;
    _holdDismissStop = true;
    try {
      await speakCue(session.runFinished());
    } finally {
      if (_isSessionActive == null) {
        _internalSession = false;
      }
      _holdDismissStop = false;
    }
  }

  /// Screen left. [epoch] must be the [liveSessionEpoch] captured when that
  /// screen opened the session. A newer run ignores the walk screen's epoch.
  /// Finish holds this so the closing line is not cut off.
  Future<void> onSessionDismissed(int epoch) async {
    if (_isSessionActive != null) return;
    if (epoch != _liveSessionEpoch || _holdDismissStop || !_internalSession) {
      return;
    }
    _internalSession = false;
    whenToSpeak.resetSession();
    await _speaker.stop();
  }

  Future<void> stop() => _speaker.stop();
}
