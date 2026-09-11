import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(speaker.spoken, [VoiceCoachingCues.enabledConfirm.ko]);
    speaker.spoken.clear();

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
}
