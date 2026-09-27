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

  test('near-finish speaks once when 200m remains on a known target', () {
    final session = VoiceCoachingSession();
    expect(
      session.approachingFinish(
        previousKm: 0.7,
        currentKm: 0.85,
        targetKm: null,
      ),
      isNull,
    );
    expect(
      session.approachingFinish(
        previousKm: 0.7,
        currentKm: 0.85,
        targetKm: 1,
      )?.id,
      VoiceCoachingCues.runNearFinish.id,
    );
    expect(
      session.approachingFinish(
        previousKm: 0.85,
        currentKm: 0.9,
        targetKm: 1,
      ),
      isNull,
    );
  });

  test('near-finish stays silent if the sample already passed the line', () {
    final session = VoiceCoachingSession();
    expect(
      session.approachingFinish(
        previousKm: 0.5,
        currentKm: 1.05,
        targetKm: 1,
      ),
      isNull,
    );
    expect(
      session.approachingFinish(
        previousKm: 0.85,
        currentKm: 0.9,
        targetKm: 1,
      ),
      isNull,
    );
  });

  test('sparse encouragement is one line per 3 minute bucket', () {
    final session = VoiceCoachingSession();
    expect(session.crossedSparseEncouragement(179), isNull);
    expect(
      session.crossedSparseEncouragement(180)?.id,
      VoiceCoachingCues.runEncourage.id,
    );
    expect(session.crossedSparseEncouragement(200), isNull);
    expect(
      session.crossedSparseEncouragement(360)?.ko,
      VoiceCoachingCues.runEncourage.ko,
    );
  });

  test('resetRun lets the next race say start and near-finish again', () {
    final session = VoiceCoachingSession();
    expect(session.runStarted()?.id, VoiceCoachingCues.runStart.id);
    session.approachingFinish(
      previousKm: 2.7,
      currentKm: 2.85,
      targetKm: 3,
    );
    session.crossedSparseEncouragement(180);
    session.resetRun();
    expect(session.runStarted()?.id, VoiceCoachingCues.runStart.id);
    expect(
      session.approachingFinish(
        previousKm: 0.7,
        currentKm: 0.85,
        targetKm: 1,
      )?.ko,
      '200미터 남았어요.',
    );
    expect(session.crossedSparseEncouragement(180)?.ko, '좋아요. 호흡 유지해요.');
    session.claimHeartRateCue(180);
    session.resetRun();
    expect(session.claimHeartRateCue(180)?.id, VoiceCoachingCues.runHighHeartRate.id);
  });

  test('high heart rate speaks once when BPM crosses 170', () {
    final session = VoiceCoachingSession();
    expect(session.claimHeartRateCue(null), isNull);
    expect(session.claimHeartRateCue(154), isNull);
    expect(session.claimHeartRateCue(29), isNull);
    expect(session.claimHeartRateCue(221), isNull);
    expect(session.claimHeartRateCue(170)?.id, VoiceCoachingCues.runHighHeartRate.id);
    expect(session.claimHeartRateCue(185), isNull);
  });

  test('heart rate re-arms only after a plausible drop to 160', () {
    final session = VoiceCoachingSession();
    expect(session.claimHeartRateCue(175)?.ko, '심박이 높아요. 속도를 줄여요.');
    expect(session.claimHeartRateCue(165), isNull);
    expect(session.claimHeartRateCue(175), isNull);
    expect(session.claimHeartRateCue(160), isNull);
    expect(session.claimHeartRateCue(170)?.id, VoiceCoachingCues.runHighHeartRate.id);
  });

  test('releasing an unspoken heart-rate claim lets the next sample take it', () {
    final session = VoiceCoachingSession();
    expect(session.claimHeartRateCue(180), isNotNull);
    session.releaseHeartRateCue();
    expect(session.claimHeartRateCue(180)?.en, VoiceCoachingCues.runHighHeartRate.en);
  });

  test('steady band speaks once from 155 and rearms only at 145', () {
    final session = VoiceCoachingSession();
    expect(session.claimHeartRateCue(154), isNull);
    expect(session.claimHeartRateCue(155)?.ko, '심박이 좋아요. 이 페이스 유지해요.');
    session.confirmHeartRateCueSpoken();
    expect(session.claimHeartRateCue(168), isNull);
    expect(session.claimHeartRateCue(146), isNull);
    expect(session.claimHeartRateCue(145), isNull);
    expect(session.claimHeartRateCue(155)?.id, VoiceCoachingCues.runHeartRateSteady.id);
  });

  test('recovered line waits until the slow-down was spoken', () {
    final unspoken = VoiceCoachingSession();
    expect(unspoken.claimHeartRateCue(172)?.id, VoiceCoachingCues.runHighHeartRate.id);
    expect(unspoken.claimHeartRateCue(158), isNull);
    expect(unspoken.claimHeartRateCue(172)?.id, VoiceCoachingCues.runHighHeartRate.id);

    final session = VoiceCoachingSession();
    expect(session.claimHeartRateCue(172)?.id, VoiceCoachingCues.runHighHeartRate.id);
    session.confirmHeartRateCueSpoken();
    expect(session.claimHeartRateCue(161), isNull);
    expect(session.claimHeartRateCue(160)?.ko, '심박이 내려왔어요. 페이스 유지해요.');
    session.confirmHeartRateCueSpoken();
    expect(session.claimHeartRateCue(150), isNull);
    expect(session.claimHeartRateCue(170)?.id, VoiceCoachingCues.runHighHeartRate.id);
  });

  test('recovered cue is cancelled if BPM climbs before it is spoken', () {
    final session = VoiceCoachingSession();
    session.claimHeartRateCue(174);
    session.confirmHeartRateCueSpoken();
    expect(
      session.claimHeartRateCue(150)?.id,
      VoiceCoachingCues.runHeartRateRecovered.id,
    );
    session.releaseHeartRateCue();
    expect(session.claimHeartRateCue(166), isNull);
    expect(session.claimHeartRateCue(150), isNull);
    expect(session.claimHeartRateCue(140), isNull);
    expect(session.claimHeartRateCue(156)?.id, VoiceCoachingCues.runHeartRateSteady.id);
  });

  test('a high episode does not offer the steady line on the way down', () {
    final session = VoiceCoachingSession();
    session.claimHeartRateCue(180);
    session.confirmHeartRateCueSpoken();
    expect(session.claimHeartRateCue(165), isNull);
    expect(
      session.claimHeartRateCue(155)?.id,
      VoiceCoachingCues.runHeartRateRecovered.id,
    );
  });

  test('implausible BPM does not rearm or speak a recovered line', () {
    final session = VoiceCoachingSession();
    session.claimHeartRateCue(180);
    session.confirmHeartRateCueSpoken();
    expect(session.claimHeartRateCue(null), isNull);
    expect(session.claimHeartRateCue(250), isNull);
    expect(session.claimHeartRateCue(175), isNull);
    expect(
      session.claimHeartRateCue(160)?.id,
      VoiceCoachingCues.runHeartRateRecovered.id,
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
