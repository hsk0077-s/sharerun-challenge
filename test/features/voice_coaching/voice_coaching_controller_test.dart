import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      ],
    );
  });

  tearDown(() => container.dispose());

  test('preference survives a new container (app restart)', () async {
    await container.read(voiceCoachingEnabledProvider.notifier).ensureLoaded();
    expect(container.read(voiceCoachingEnabledProvider), isFalse);

    await container.read(voiceCoachingEnabledProvider.notifier).setEnabled(true);
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
    await container.read(voiceCoachingEnabledProvider.notifier).setEnabled(true);
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

    await container.read(voiceCoachingEnabledProvider.notifier).setEnabled(false);
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
    required DateTime Function() now,
  }) {
    return VoiceCoachingController(
      isEnabled: () => enabled,
      speaker: speaker,
      now: now,
      isSessionActive: () => sessionActive,
      isDeviceMuted: () => deviceMuted,
    );
  }

  test('inactive session or device mute never reaches the speaker', () async {
    var now = DateTime.utc(2026, 9, 13, 7);
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

  test('unmapped Phase 3a ids (future HR/hill/rank) stay silent', () async {
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
}
