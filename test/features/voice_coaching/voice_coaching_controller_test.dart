import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/iap/providers/coach_plus_providers.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coach_output_mute.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coach_when_to_speak.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_controller.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_cues.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_providers.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_speaker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSpeaker implements VoiceCoachingSpeaker {
  final spoken = <String>[];
  var stopCount = 0;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingSpeaker speaker;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    speaker = _RecordingSpeaker();
    container = ProviderContainer(
      overrides: [
        voiceCoachingSpeakerProvider.overrideWithValue(speaker),
        coachPlusFromProfileProvider.overrideWithValue(false),
        coachPlusServerGrantProvider.overrideWithValue((_) async {}),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('preference survives a new container (app restart)', () async {
    await container.read(voiceCoachingEnabledProvider.notifier).ensureLoaded();
    expect(container.read(voiceCoachingEnabledProvider), isFalse);

    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(true);
    expect(container.read(voiceCoachingEnabledProvider), isTrue);

    final restarted = ProviderContainer(
      overrides: [
        voiceCoachingSpeakerProvider.overrideWithValue(_RecordingSpeaker()),
      ],
    );
    addTearDown(restarted.dispose);

    await restarted.read(voiceCoachingEnabledProvider.notifier).ensureLoaded();
    expect(restarted.read(voiceCoachingEnabledProvider), isTrue);
  });

  test('when coaching is off the speaker never talks', () async {
    await container.read(voiceCoachingEnabledProvider.notifier).ensureLoaded();
    final coach = container.read(voiceCoachingControllerProvider);

    await coach.onWalkingOpened();
    await coach.onWalkingProgress(
      previousSteps: 999,
      currentSteps: 1000,
      previousKm: 0.7,
      currentKm: 0.75,
      targetKm: 3,
    );
    await coach.onHarvestCompleted();
    await coach.onRunStarted();
    await coach.onRunProgress(previousKm: 0.9, currentKm: 1.1);
    await coach.onRunFinished();

    expect(speaker.spoken, isEmpty);
    expect(container.read(voiceCoachingEnabledProvider), isFalse);
  });

  test('when coaching is on, crossed milestones speak Korean cues', () async {
    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(true);
    expect(speaker.spoken, isEmpty);

    final coach = container.read(voiceCoachingControllerProvider);
    await coach.onWalkingProgress(
      previousSteps: 999,
      currentSteps: 1000,
      previousKm: 0.7,
      currentKm: 0.75,
      targetKm: 3,
    );
    expect(speaker.spoken, [VoiceCoachingCues.walkSteps(1000).ko]);

    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(false);
    expect(speaker.stopCount, greaterThan(0));
    speaker.spoken.clear();

    await coach.onWalkingProgress(
      previousSteps: 2999,
      currentSteps: 3000,
      previousKm: 2.2,
      currentKm: 2.25,
      targetKm: 3,
    );
    expect(speaker.spoken, isEmpty);
  });

  VoiceCoachingController gatedCoach({
    bool enabled = true,
    bool sessionActive = true,
    bool deviceMuted = false,
    bool coachPlus = true,
    void Function()? onCoachPlusUpsell,
    required DateTime Function() now,
  }) {
    return VoiceCoachingController(
      isEnabled: () => enabled,
      speaker: speaker,
      now: now,
      isSessionActive: () => sessionActive,
      isDeviceMuted: () => deviceMuted,
      isCoachPlusActive: () => coachPlus,
      onCoachPlusUpsell: onCoachPlusUpsell,
    );
  }

  test('inactive session or device mute never reaches the speaker', () async {
    final now = DateTime.utc(2026, 9, 13, 7);
    final inactive = gatedCoach(sessionActive: false, now: () => now);
    await inactive.onWalkingOpened();
    await inactive.onWalkingProgress(
      previousSteps: 999,
      currentSteps: 1000,
      previousKm: 0.7,
      currentKm: 0.75,
      targetKm: 3,
    );
    expect(speaker.spoken, isEmpty);

    final muted = gatedCoach(deviceMuted: true, now: () => now);
    await muted.onRunStarted();
    await muted.onRunProgress(previousKm: 0.9, currentKm: 1.1);
    expect(speaker.spoken, isEmpty);
  });

  test('45s rate-limit suppresses rapid distance spam; gap allows the next',
      () async {
    var now = DateTime.utc(2026, 9, 13, 7);
    final coach = gatedCoach(now: () => now);

    await coach.onWalkingProgress(
      previousSteps: 999,
      currentSteps: 1000,
      previousKm: 0.7,
      currentKm: 0.75,
      targetKm: 3,
    );
    expect(speaker.spoken, [VoiceCoachingCues.walkSteps(1000).ko]);

    now = now.add(const Duration(seconds: 10));
    await coach.onWalkingProgress(
      previousSteps: 2999,
      currentSteps: 3000,
      previousKm: 2.2,
      currentKm: 2.25,
      targetKm: 3,
    );
    expect(speaker.spoken, [VoiceCoachingCues.walkSteps(1000).ko]);
    expect(coach.whenToSpeak.lastSpokenKind, VoiceCoachCueKind.distance);

    now = now.add(const Duration(seconds: 45));
    await coach.onWalkingProgress(
      previousSteps: 4999,
      currentSteps: 5000,
      previousKm: 3.6,
      currentKm: 3.7,
      targetKm: 5,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.walkSteps(1000).ko,
      VoiceCoachingCues.walkSteps(5000).ko,
    ]);
  });

  test('higher-priority distance may interrupt encouragement inside the gap',
      () async {
    var now = DateTime.utc(2026, 9, 13, 7);
    final coach = gatedCoach(now: () => now);

    await coach.onWalkingOpened();
    expect(speaker.spoken, [VoiceCoachingCues.walkStart.ko]);
    expect(coach.whenToSpeak.lastSpokenKind, VoiceCoachCueKind.encouragement);

    now = now.add(const Duration(seconds: 8));
    await coach.onWalkingProgress(
      previousSteps: 999,
      currentSteps: 1000,
      previousKm: 0.7,
      currentKm: 0.75,
      targetKm: 3,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.walkStart.ko,
      VoiceCoachingCues.walkSteps(1000).ko,
    ]);
    expect(coach.whenToSpeak.lastSpokenKind, VoiceCoachCueKind.distance);
  });

  test('near-finish preempts start; the next distance cue waits out 45s',
      () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunStarted();
    expect(speaker.spoken, [VoiceCoachingCues.runStart.ko]);

    now = now.add(const Duration(seconds: 20));
    await coach.onRunProgress(
      previousKm: 0.7,
      currentKm: 0.85,
      elapsedSeconds: 20,
      targetKm: 1,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runNearFinish.ko,
    ]);

    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.95,
      currentKm: 1.02,
      elapsedSeconds: 30,
      targetKm: 1,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runNearFinish.ko,
    ]);
    expect(coach.whenToSpeak.lastSpokenKind, VoiceCoachCueKind.distance);
  });

  test('sparse encourage is silent inside 45s and speaks on the next bucket',
      () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);
    await coach.onRunStarted();

    now = now.add(const Duration(seconds: 30));
    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.15,
      elapsedSeconds: 180,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runStart.ko]);

    now = now.add(const Duration(minutes: 3));
    await coach.onRunProgress(
      previousKm: 0.4,
      currentKm: 0.5,
      elapsedSeconds: 360,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runEncourage.ko,
    ]);
  });

  test('free run without a target does not invent a near-finish cue', () async {
    final coach = gatedCoach(now: () => DateTime.utc(2026, 9, 27, 8));
    await coach.onRunProgress(
      previousKm: 0.7,
      currentKm: 0.85,
      elapsedSeconds: 40,
    );
    expect(speaker.spoken, isEmpty);
  });

  test('device mute blocks near-finish and encouragement', () async {
    final coach = gatedCoach(
      deviceMuted: true,
      now: () => DateTime.utc(2026, 9, 27, 8),
    );
    await coach.onRunStarted();
    await coach.onRunProgress(
      previousKm: 0.7,
      currentKm: 0.85,
      elapsedSeconds: 180,
      targetKm: 1,
    );
    expect(speaker.spoken, isEmpty);
  });

  test('high heart rate interrupts start and does not repeat while still high',
      () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunStarted();
    now = now.add(const Duration(seconds: 8));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      elapsedSeconds: 8,
      heartRateBpm: 174,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runHighHeartRate.ko,
    ]);
    expect(coach.whenToSpeak.lastSpokenKind, VoiceCoachCueKind.heartRate);

    now = now.add(const Duration(seconds: 50));
    await coach.onRunProgress(
      previousKm: 0.4,
      currentKm: 0.5,
      elapsedSeconds: 58,
      heartRateBpm: 188,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runHighHeartRate.ko,
    ]);
  });

  test('high heart rate owns the sample, so a simultaneous km cue waits',
      () async {
    final coach = gatedCoach(now: () => DateTime.utc(2026, 9, 27, 8));
    await coach.onRunProgress(
      previousKm: 0.9,
      currentKm: 1.1,
      heartRateBpm: 170,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runHighHeartRate.ko]);
  });

  test('heart rate re-arms after a drop to 160 and can speak past the gap',
      () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 171,
    );
    now = now.add(const Duration(seconds: 20));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 160,
    );
    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.35,
      heartRateBpm: 176,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runHighHeartRate.ko]);

    now = now.add(const Duration(seconds: 20));
    await coach.onRunProgress(
      previousKm: 0.35,
      currentKm: 0.4,
      heartRateBpm: 176,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runHighHeartRate.ko,
      VoiceCoachingCues.runHighHeartRate.ko,
    ]);
  });

  test('mute or coaching off does not consume the heart-rate cue', () async {
    var enabled = false;
    var muted = false;
    final coach = VoiceCoachingController(
      isEnabled: () => enabled,
      speaker: speaker,
      now: () => DateTime.utc(2026, 9, 27, 9),
      isSessionActive: () => true,
      isDeviceMuted: () => muted,
      isCoachPlusActive: () => true,
    );

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 180,
    );
    expect(speaker.spoken, isEmpty);

    enabled = true;
    muted = true;
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 180,
    );
    expect(speaker.spoken, isEmpty);

    muted = false;
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 180,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runHighHeartRate.ko]);
  });

  test('missing or low BPM does not invent a heart-rate line', () async {
    final coach = gatedCoach(now: () => DateTime.utc(2026, 9, 27, 8));
    await coach.onRunProgress(previousKm: 0.1, currentKm: 0.2);
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 140,
    );
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 150,
    );
    await coach.onRunProgress(
      previousKm: 0.4,
      currentKm: 0.5,
      heartRateBpm: 250,
    );
    expect(speaker.spoken, isEmpty);
  });

  test('steady heart rate speaks once and loses to a kilometer cue', () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunProgress(
      previousKm: 0.9,
      currentKm: 1.1,
      heartRateBpm: 158,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runKm(1, coachPlus: true).ko]);

    now = now.add(const Duration(seconds: 46));
    await coach.onRunProgress(
      previousKm: 1.1,
      currentKm: 1.2,
      heartRateBpm: 162,
    );
    now = now.add(const Duration(seconds: 50));
    await coach.onRunProgress(
      previousKm: 1.2,
      currentKm: 1.3,
      heartRateBpm: 164,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runKm(1, coachPlus: true).ko,
      VoiceCoachingCues.runHeartRateSteady.ko,
    ]);
  });

  test('steady heart rate waits out the 45s gate and does not repeat',
      () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunStarted();
    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 160,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runStart.ko]);

    now = now.add(const Duration(seconds: 40));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 163,
    );
    now = now.add(const Duration(seconds: 50));
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 168,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runHeartRateSteady.ko,
    ]);
  });

  test('high heart rate interrupts a steady line', () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 158,
    );
    now = now.add(const Duration(seconds: 8));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 174,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runHeartRateSteady.ko,
      VoiceCoachingCues.runHighHeartRate.ko,
    ]);
    expect(coach.whenToSpeak.lastSpokenKind, VoiceCoachCueKind.heartRate);
  });

  test('recovered line speaks once after the slow-down gap', () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 174,
    );
    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 158,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runHighHeartRate.ko]);

    now = now.add(const Duration(seconds: 40));
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 152,
    );
    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.4,
      currentKm: 0.5,
      heartRateBpm: 152,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runHighHeartRate.ko,
      VoiceCoachingCues.runHeartRateRecovered.ko,
    ]);
  });

  test('recovered line is dropped if BPM rises before the gate opens',
      () async {
    var now = DateTime.utc(2026, 9, 27, 8);
    final coach = gatedCoach(now: () => now);

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 174,
    );
    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 150,
    );
    now = now.add(const Duration(seconds: 10));
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 166,
    );
    now = now.add(const Duration(seconds: 40));
    await coach.onRunProgress(
      previousKm: 0.4,
      currentKm: 0.5,
      heartRateBpm: 166,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runHighHeartRate.ko]);
  });

  test('a silenced slow-down does not later say heart rate came down',
      () async {
    var enabled = false;
    final coach = VoiceCoachingController(
      isEnabled: () => enabled,
      speaker: speaker,
      now: () => DateTime.utc(2026, 9, 27, 9),
      isSessionActive: () => true,
      isCoachPlusActive: () => true,
    );

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 180,
    );
    enabled = true;
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 150,
    );
    expect(speaker.spoken, isEmpty);

    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 180,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runHighHeartRate.ko]);
  });

  test('unmapped Phase 3a ids (future hill/rank) stay silent', () async {
    final coach = gatedCoach(now: () => DateTime.utc(2026, 9, 13, 7));
    await coach.speakCue(
      const VoiceCue(id: 'hr.high', ko: '심박이 높아요.', en: 'Heart rate is high.'),
    );
    await coach.speakCue(
      const VoiceCue(id: 'course.hill', ko: '오르막이에요.', en: 'Hill ahead.'),
    );
    await coach.speakCue(
      const VoiceCue(id: 'lobby.rank', ko: '3위예요.', en: 'You are third.'),
    );
    expect(speaker.spoken, isEmpty);
    expect(coach.whenToSpeak.lastSpokenKind, isNull);
  });

  test('without Coach+ heart-rate lines stay silent and free cues still speak',
      () async {
    var upsells = 0;
    var now = DateTime.utc(2026, 9, 28, 8);
    final coach = gatedCoach(
      coachPlus: false,
      onCoachPlusUpsell: () => upsells += 1,
      now: () => now,
    );

    await coach.onRunStarted();
    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 174,
    );
    now = now.add(const Duration(seconds: 46));
    await coach.onRunProgress(
      previousKm: 0.9,
      currentKm: 1.1,
      elapsedSeconds: 180,
      heartRateBpm: 158,
    );
    await coach.onRunProgress(
      previousKm: 1.1,
      currentKm: 1.2,
      heartRateBpm: 152,
    );
    now = now.add(const Duration(seconds: 46));
    await coach.onRunFinished();

    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runKm(1).ko,
      VoiceCoachingCues.runFinish.ko,
    ]);
    expect(upsells, 1);
  });

  test('coaching off or mute does not raise the Coach+ upsell', () async {
    var upsells = 0;
    final off = gatedCoach(
      enabled: false,
      coachPlus: false,
      onCoachPlusUpsell: () => upsells += 1,
      now: () => DateTime.utc(2026, 9, 28, 8),
    );
    await off.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 180,
    );

    final muted = gatedCoach(
      deviceMuted: true,
      coachPlus: false,
      onCoachPlusUpsell: () => upsells += 1,
      now: () => DateTime.utc(2026, 9, 28, 8),
    );
    await muted.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 180,
    );

    expect(speaker.spoken, isEmpty);
    expect(upsells, 0);
  });

  test('provider keeps heart-rate lines silent until Coach+ is granted',
      () async {
    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(true);
    final coach = container.read(voiceCoachingControllerProvider);
    await coach.onRunStarted();

    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 175,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runStart.ko]);
    expect(container.read(coachPlusUpsellCountProvider), 1);

    await container
        .read(coachPlusActiveProvider.notifier)
        .grant('coach_plus_monthly');
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 175,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runHighHeartRate.ko,
    ]);
  });

  test('Coach+ kilometer tone is one short line on the same cue id', () {
    final free = VoiceCoachingCues.runKm(2);
    final plus = VoiceCoachingCues.runKm(2, coachPlus: true);
    expect(free.ko, '2킬로미터 통과. 잘하고 있어요.');
    expect(plus.ko, '2킬로미터. 이 페이스 유지해요.');
    expect(plus.id, free.id);
    expect(
      VoiceCoachingCues.coachPlusDistanceTone(free, coachPlus: true)?.ko,
      plus.ko,
    );
    expect(
      VoiceCoachingCues.coachPlusDistanceTone(free, coachPlus: false)?.ko,
      free.ko,
    );
  });

  test('live session is silent until the run starts and after it ends',
      () async {
    var now = DateTime.utc(2026, 9, 28, 9);
    final coach = VoiceCoachingController(
      isEnabled: () => true,
      speaker: speaker,
      now: () => now,
      isCoachPlusActive: () => true,
    );

    await coach.onRunProgress(
      previousKm: 0.9,
      currentKm: 1.1,
      heartRateBpm: 176,
    );
    expect(speaker.spoken, isEmpty);

    await coach.onRunStarted();
    expect(speaker.spoken, [VoiceCoachingCues.runStart.ko]);

    now = now.add(const Duration(seconds: 8));
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 174,
    );
    expect(speaker.spoken, [
      VoiceCoachingCues.runStart.ko,
      VoiceCoachingCues.runHighHeartRate.ko,
    ]);

    now = now.add(const Duration(seconds: 40));
    await coach.onRunProgress(
      previousKm: 0.3,
      currentKm: 0.4,
      heartRateBpm: 190,
    );
    expect(
      speaker.spoken
          .where((line) => line == VoiceCoachingCues.runHighHeartRate.ko),
      hasLength(1),
    );

    now = now.add(const Duration(seconds: 5));
    await coach.onRunProgress(
      previousKm: 0.4,
      currentKm: 0.45,
      heartRateBpm: 160,
    );
    now = now.add(const Duration(seconds: 20));
    await coach.onRunProgress(
      previousKm: 0.45,
      currentKm: 0.5,
      heartRateBpm: 176,
    );
    expect(
      speaker.spoken
          .where((line) => line == VoiceCoachingCues.runHighHeartRate.ko),
      hasLength(2),
    );

    now = now.add(const Duration(seconds: 46));
    await coach.onRunFinished();
    expect(speaker.spoken.last, VoiceCoachingCues.runFinish.ko);

    final afterFinish = speaker.spoken.length;
    now = now.add(const Duration(seconds: 46));
    await coach.onRunProgress(
      previousKm: 1.9,
      currentKm: 2.2,
      heartRateBpm: 182,
    );
    expect(speaker.spoken, hasLength(afterFinish));
  });

  test('a stale walk epoch cannot dismiss the run that replaced it', () async {
    final coach = VoiceCoachingController(
      isEnabled: () => true,
      speaker: speaker,
      now: () => DateTime.utc(2026, 9, 28, 10),
      isCoachPlusActive: () => false,
    );
    final walk = coach.onWalkingOpened();
    final walkEpoch = coach.liveSessionEpoch;
    await walk;

    final run = coach.onRunStarted();
    final runEpoch = coach.liveSessionEpoch;
    await run;
    expect(runEpoch, isNot(walkEpoch));

    await coach.onSessionDismissed(walkEpoch);
    expect(speaker.stopCount, 0);

    await coach.onRunProgress(previousKm: 0.9, currentKm: 1.05);
    expect(speaker.spoken.last, VoiceCoachingCues.runKm(1).ko);

    await coach.onSessionDismissed(runEpoch);
    expect(speaker.stopCount, 1);
    await coach.onRunProgress(previousKm: 1.9, currentKm: 2.1);
    expect(speaker.spoken.last, VoiceCoachingCues.runKm(1).ko);
  });

  test('media volume 0 and coaching off never speak on a live session',
      () async {
    var enabled = true;
    var volume = 0;
    var upsells = 0;
    final coach = VoiceCoachingController(
      isEnabled: () => enabled,
      speaker: speaker,
      now: () => DateTime.utc(2026, 9, 28, 11),
      isCoachPlusActive: () => false,
      onCoachPlusUpsell: () => upsells += 1,
      refreshDeviceMuted: () async =>
          voiceCoachOutputMuted(mediaVolume: volume),
    );

    await coach.onRunStarted();
    await coach.onRunProgress(
      previousKm: 0.1,
      currentKm: 0.2,
      heartRateBpm: 180,
    );
    expect(speaker.spoken, isEmpty);
    expect(upsells, 0);

    volume = 8;
    enabled = false;
    await coach.onRunProgress(
      previousKm: 0.2,
      currentKm: 0.3,
      heartRateBpm: 180,
    );
    expect(speaker.spoken, isEmpty);
    expect(upsells, 0);

    enabled = true;
    await coach.onRunProgress(
      previousKm: 0.9,
      currentKm: 1.1,
    );
    expect(speaker.spoken, [VoiceCoachingCues.runKm(1).ko]);
  });
}
