import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_cues.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_session.dart';

void main() {
  test('restored high step counts do not replay past milestones', () {
    final session = VoiceCoachingSession();
    expect(
      session.crossedStepMilestone(previous: 5000, current: 5000),
      isNull,
    );
    expect(
      session.crossedStepMilestone(previous: 4999, current: 5000)?.id,
      VoiceCoachingCues.walkSteps(5000).id,
    );
  });

  test('jumping past several milestones speaks only the highest', () {
    final session = VoiceCoachingSession();
    expect(
      session.crossedStepMilestone(previous: 0, current: 8200)?.id,
      VoiceCoachingCues.walkSteps(8000).id,
    );
  });

  test('distance goal fires once when crossing the target', () {
    final session = VoiceCoachingSession();
    expect(
      session.crossedDistanceGoal(
        previousKm: 2.9,
        currentKm: 3.0,
        targetKm: 3.0,
      )?.id,
      VoiceCoachingCues.walkGoal.id,
    );
    expect(
      session.crossedDistanceGoal(
        previousKm: 3.0,
        currentKm: 3.2,
        targetKm: 3.0,
      ),
      isNull,
    );
  });

  test('run kilometer cue uses the newly crossed whole km', () {
    final session = VoiceCoachingSession();
    expect(
      session.crossedRunKilometer(previousKm: 0.98, currentKm: 1.02)?.id,
      VoiceCoachingCues.runKm(1).id,
    );
    expect(
      session.crossedRunKilometer(previousKm: 1.02, currentKm: 1.40),
      isNull,
    );
  });

  test('welcome and harvest cues speak once per session', () {
    final session = VoiceCoachingSession();
    expect(session.walkingOpened()?.id, VoiceCoachingCues.walkStart.id);
    expect(session.walkingOpened(), isNull);
    expect(session.harvestCompleted()?.id, VoiceCoachingCues.walkHarvest.id);
    expect(session.harvestCompleted(), isNull);
  });
}
