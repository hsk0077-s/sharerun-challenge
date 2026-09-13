import 'voice_coaching_cues.dart';

/// Phase 4 foundation — **not** the full pro-trainer coach.
///
/// Decides *whether* a cue may speak *now*. Cue copy, watch/HR streams,
/// course elevation, and race-lobby rank are later slices.
///
/// Existing Phase 3a [VoiceCoachingController] still speaks milestone TTS
/// without this gate. Do not bind run screens here.
enum VoiceCoachCueKind {
  /// Watch / HR: slow down if heart rate is high.
  /// Stub: no HR / watch stream is consumed in this PR.
  heartRate,

  /// Course: hill ahead — conserve.
  /// Stub: no elevation / course feed in this PR.
  hill,

  /// Race lobby ranking: place among N.
  /// Stub: no lobby rank bind in this PR.
  rank,

  /// Distance context (km split, step milestone, daily goal).
  /// Ready for a later bind onto existing Phase 3a milestone IDs.
  distance,

  /// Encouragement / start / finish / harvest. Lowest priority.
  encouragement,
}

/// Why a cue stayed silent. Callers can log this; they must not speak.
enum VoiceCoachSilenceReason {
  coachingOff,
  sessionInactive,
  deviceMuted,
  rateLimited,
  lowerPriority,
  nonePending,
}

/// Snapshot of mute / session flags at decision time.
class VoiceCoachSpeakContext {
  const VoiceCoachSpeakContext({
    required this.now,
    required this.coachingEnabled,
    required this.sessionActive,
    this.deviceMuted = false,
  });

  final DateTime now;

  /// Settings toggle. Off = never speak (same default as Phase 3a).
  final bool coachingEnabled;

  /// False on lobby / settings / idle — no situational chatter.
  final bool sessionActive;

  /// Policy-level mute (e.g. iOS silent switch known by the caller).
  /// Phase 3a TTS already uses an ambient category; this skips speak entirely.
  final bool deviceMuted;

  VoiceCoachSpeakContext copyWith({
    DateTime? now,
    bool? coachingEnabled,
    bool? sessionActive,
    bool? deviceMuted,
  }) {
    return VoiceCoachSpeakContext(
      now: now ?? this.now,
      coachingEnabled: coachingEnabled ?? this.coachingEnabled,
      sessionActive: sessionActive ?? this.sessionActive,
      deviceMuted: deviceMuted ?? this.deviceMuted,
    );
  }
}

class VoiceCoachSpeakVerdict {
  const VoiceCoachSpeakVerdict.speak(this.kind) : silence = null;

  const VoiceCoachSpeakVerdict.silence(this.silence) : kind = null;

  final VoiceCoachCueKind? kind;
  final VoiceCoachSilenceReason? silence;

  bool get shouldSpeak => kind != null;
}

/// Rate-limit, mute, and priority policy for situational voice cues.
///
/// Default gap is 45s so this is a trainer beside you, not a TTS ticker.
/// A higher-priority kind may preempt inside the gap (HR interrupts pep / km).
/// Same-or-lower priority inside the gap is [VoiceCoachSilenceReason.rateLimited].
class VoiceCoachWhenToSpeak {
  VoiceCoachWhenToSpeak({
    this.minGap = const Duration(seconds: 45),
  });

  /// Trainer-like spacing. Not a generic split-every-few-seconds TTS.
  final Duration minGap;

  DateTime? _lastSpokenAt;
  VoiceCoachCueKind? _lastSpokenKind;

  DateTime? get lastSpokenAt => _lastSpokenAt;
  VoiceCoachCueKind? get lastSpokenKind => _lastSpokenKind;

  /// Highest first: safety → course → rank → distance → pep.
  static const List<VoiceCoachCueKind> priorityOrder = [
    VoiceCoachCueKind.heartRate,
    VoiceCoachCueKind.hill,
    VoiceCoachCueKind.rank,
    VoiceCoachCueKind.distance,
    VoiceCoachCueKind.encouragement,
  ];

  static int priorityIndex(VoiceCoachCueKind kind) {
    return priorityOrder.indexOf(kind);
  }

  /// One candidate. When [alsoPending] has a higher-priority kind, this
  /// returns [VoiceCoachSilenceReason.lowerPriority] and does not record.
  VoiceCoachSpeakVerdict consider({
    required VoiceCoachCueKind kind,
    required VoiceCoachSpeakContext context,
    Iterable<VoiceCoachCueKind> alsoPending = const <VoiceCoachCueKind>[],
  }) {
    final mute = _muteReason(context);
    if (mute != null) {
      return VoiceCoachSpeakVerdict.silence(mute);
    }
    if (_highestOf(<VoiceCoachCueKind>{kind, ...alsoPending}) != kind) {
      return const VoiceCoachSpeakVerdict.silence(
        VoiceCoachSilenceReason.lowerPriority,
      );
    }
    return pick(pending: <VoiceCoachCueKind>[kind], context: context);
  }

  /// Speak at most one of [pending]: highest priority that is not muted.
  VoiceCoachSpeakVerdict pick({
    required Iterable<VoiceCoachCueKind> pending,
    required VoiceCoachSpeakContext context,
  }) {
    final mute = _muteReason(context);
    if (mute != null) {
      return VoiceCoachSpeakVerdict.silence(mute);
    }

    final unique = pending.toSet();
    if (unique.isEmpty) {
      return const VoiceCoachSpeakVerdict.silence(
        VoiceCoachSilenceReason.nonePending,
      );
    }

    final best = _highestOf(unique);
    if (best == null) {
      return const VoiceCoachSpeakVerdict.silence(
        VoiceCoachSilenceReason.nonePending,
      );
    }

    if (_isBlockedByGap(best, context.now)) {
      return const VoiceCoachSpeakVerdict.silence(
        VoiceCoachSilenceReason.rateLimited,
      );
    }

    _lastSpokenAt = context.now;
    _lastSpokenKind = best;
    return VoiceCoachSpeakVerdict.speak(best);
  }

  VoiceCoachSilenceReason? _muteReason(VoiceCoachSpeakContext context) {
    if (!context.coachingEnabled) {
      return VoiceCoachSilenceReason.coachingOff;
    }
    if (!context.sessionActive) {
      return VoiceCoachSilenceReason.sessionInactive;
    }
    if (context.deviceMuted) {
      return VoiceCoachSilenceReason.deviceMuted;
    }
    return null;
  }

  VoiceCoachCueKind? _highestOf(Set<VoiceCoachCueKind> kinds) {
    for (final kind in priorityOrder) {
      if (kinds.contains(kind)) return kind;
    }
    return null;
  }

  /// Clears the gap clock. Call when a walk/run session ends.
  void resetSession() {
    _lastSpokenAt = null;
    _lastSpokenKind = null;
  }

  bool _isBlockedByGap(VoiceCoachCueKind kind, DateTime now) {
    final lastAt = _lastSpokenAt;
    final lastKind = _lastSpokenKind;
    if (lastAt == null || lastKind == null) return false;
    if (now.isAfter(lastAt.add(minGap))) return false;
    // Higher priority (smaller index) may interrupt. Same/lower waits.
    return priorityIndex(kind) >= priorityIndex(lastKind);
  }
}

/// Maps existing Phase 3a cue ids so a later bind stays mechanical.
/// HR / hill / rank ids do not exist yet — those stay stubbed.
VoiceCoachCueKind? voiceCoachCueKindForPhase3aId(String id) {
  if (id.startsWith('run.km.') ||
      id.startsWith('walk.steps.') ||
      id == VoiceCoachingCues.walkGoal.id) {
    return VoiceCoachCueKind.distance;
  }
  if (id == VoiceCoachingCues.walkStart.id ||
      id == VoiceCoachingCues.walkHarvest.id ||
      id == VoiceCoachingCues.runStart.id ||
      id == VoiceCoachingCues.runFinish.id ||
      id == VoiceCoachingCues.enabledConfirm.id) {
    return VoiceCoachCueKind.encouragement;
  }
  return null;
}
