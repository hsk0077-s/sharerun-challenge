import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coach_when_to_speak.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_cues.dart';

void main() {
  final t0 = VoiceCoachSpeakContext(
    now: DateTime.utc(2026, 9, 13, 6, 30),
    coachingEnabled: true,
    sessionActive: true,
  );

  VoiceCoachWhenToSpeak policy() => VoiceCoachWhenToSpeak();

  test('mute: coaching off never speaks', () {
    final verdict = policy().consider(
      kind: VoiceCoachCueKind.distance,
      context: t0.copyWith(coachingEnabled: false),
    );
    expect(verdict.shouldSpeak, isFalse);
    expect(verdict.silence, VoiceCoachSilenceReason.coachingOff);
  });

  test('mute: inactive session (lobby / settings) never speaks', () {
    final verdict = policy().consider(
      kind: VoiceCoachCueKind.encouragement,
      context: t0.copyWith(sessionActive: false),
    );
    expect(verdict.shouldSpeak, isFalse);
    expect(verdict.silence, VoiceCoachSilenceReason.sessionInactive);
  });

  test('mute: device muted skips speak', () {
    final verdict = policy().consider(
      kind: VoiceCoachCueKind.hill,
      context: t0.copyWith(deviceMuted: true),
    );
    expect(verdict.shouldSpeak, isFalse);
    expect(verdict.silence, VoiceCoachSilenceReason.deviceMuted);
  });

  test('first cue of a session is allowed', () {
    final gate = policy();
    final verdict = gate.consider(
      kind: VoiceCoachCueKind.encouragement,
      context: t0,
    );
    expect(verdict.shouldSpeak, isTrue);
    expect(verdict.kind, VoiceCoachCueKind.encouragement);
    expect(gate.lastSpokenKind, VoiceCoachCueKind.encouragement);
  });

  test('same or lower priority inside 45s is rate-limited', () {
    final gate = policy();
    expect(
      gate.consider(kind: VoiceCoachCueKind.distance, context: t0).shouldSpeak,
      isTrue,
    );

    final tenSecondsLater = t0.copyWith(
      now: t0.now.add(const Duration(seconds: 10)),
    );
    final again = gate.consider(
      kind: VoiceCoachCueKind.distance,
      context: tenSecondsLater,
    );
    expect(again.shouldSpeak, isFalse);
    expect(again.silence, VoiceCoachSilenceReason.rateLimited);

    final pep = gate.consider(
      kind: VoiceCoachCueKind.encouragement,
      context: tenSecondsLater,
    );
    expect(pep.shouldSpeak, isFalse);
    expect(pep.silence, VoiceCoachSilenceReason.rateLimited);
  });

  test('after the 45s gap the same kind may speak again', () {
    final gate = policy();
    gate.consider(kind: VoiceCoachCueKind.distance, context: t0);

    final stillInside = t0.copyWith(
      now: t0.now.add(const Duration(seconds: 45)),
    );
    expect(
      gate.consider(kind: VoiceCoachCueKind.distance, context: stillInside).silence,
      VoiceCoachSilenceReason.rateLimited,
    );

    final afterGap = t0.copyWith(
      now: t0.now.add(const Duration(seconds: 45, milliseconds: 1)),
    );
    expect(
      gate.consider(kind: VoiceCoachCueKind.distance, context: afterGap).kind,
      VoiceCoachCueKind.distance,
    );
  });

  test('higher priority preempts inside the gap (trainer interrupt)', () {
    final gate = policy();
    gate.consider(kind: VoiceCoachCueKind.encouragement, context: t0);

    final soon = t0.copyWith(now: t0.now.add(const Duration(seconds: 8)));
    expect(
      gate.consider(kind: VoiceCoachCueKind.hill, context: soon).kind,
      VoiceCoachCueKind.hill,
    );
    expect(
      gate.consider(
        kind: VoiceCoachCueKind.heartRate,
        context: soon.copyWith(now: soon.now.add(const Duration(seconds: 2))),
      ).kind,
      VoiceCoachCueKind.heartRate,
    );
  });

  test('heart-rate safety does not preempt itself inside the gap', () {
    final gate = policy();
    gate.consider(kind: VoiceCoachCueKind.heartRate, context: t0);
    final soon = t0.copyWith(now: t0.now.add(const Duration(seconds: 5)));
    expect(
      gate.consider(kind: VoiceCoachCueKind.heartRate, context: soon).silence,
      VoiceCoachSilenceReason.rateLimited,
    );
  });

  test('pick speaks the highest pending kind and drops the rest', () {
    final gate = policy();
    final verdict = gate.pick(
      pending: const [
        VoiceCoachCueKind.encouragement,
        VoiceCoachCueKind.rank,
        VoiceCoachCueKind.distance,
      ],
      context: t0,
    );
    expect(verdict.kind, VoiceCoachCueKind.rank);
    expect(gate.lastSpokenKind, VoiceCoachCueKind.rank);
  });

  test('encouragement yields when a higher kind is also pending', () {
    final verdict = policy().consider(
      kind: VoiceCoachCueKind.encouragement,
      context: t0,
      alsoPending: const [VoiceCoachCueKind.heartRate],
    );
    expect(verdict.shouldSpeak, isFalse);
    expect(verdict.silence, VoiceCoachSilenceReason.lowerPriority);
  });

  test('empty pending is silent', () {
    expect(
      policy().pick(pending: const [], context: t0).silence,
      VoiceCoachSilenceReason.nonePending,
    );
  });

  test('resetSession clears the rate-limit clock', () {
    final gate = policy();
    gate.consider(kind: VoiceCoachCueKind.distance, context: t0);
    gate.resetSession();
    expect(
      gate
          .consider(
            kind: VoiceCoachCueKind.distance,
            context: t0.copyWith(now: t0.now.add(const Duration(seconds: 1))),
          )
          .kind,
      VoiceCoachCueKind.distance,
    );
  });

  test('priority order is HR > hill > rank > distance > encouragement', () {
    expect(VoiceCoachWhenToSpeak.priorityOrder, const [
      VoiceCoachCueKind.heartRate,
      VoiceCoachCueKind.hill,
      VoiceCoachCueKind.rank,
      VoiceCoachCueKind.distance,
      VoiceCoachCueKind.encouragement,
    ]);
  });

  test('Phase 3a ids map to distance or encouragement; HR/hill/rank stay stubbed', () {
    expect(
      voiceCoachCueKindForPhase3aId(VoiceCoachingCues.runKm(3).id),
      VoiceCoachCueKind.distance,
    );
    expect(
      voiceCoachCueKindForPhase3aId(VoiceCoachingCues.walkSteps(5000).id),
      VoiceCoachCueKind.distance,
    );
    expect(
      voiceCoachCueKindForPhase3aId(VoiceCoachingCues.walkGoal.id),
      VoiceCoachCueKind.distance,
    );
    expect(
      voiceCoachCueKindForPhase3aId(VoiceCoachingCues.walkStart.id),
      VoiceCoachCueKind.encouragement,
    );
    expect(
      voiceCoachCueKindForPhase3aId(VoiceCoachingCues.runFinish.id),
      VoiceCoachCueKind.encouragement,
    );
    expect(voiceCoachCueKindForPhase3aId('hr.high'), isNull);
    expect(voiceCoachCueKindForPhase3aId('course.hill'), isNull);
    expect(voiceCoachCueKindForPhase3aId('lobby.rank'), isNull);
  });
}
