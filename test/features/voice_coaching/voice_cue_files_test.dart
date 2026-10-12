import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_cues.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_cue_files.dart';

void main() {
  test('the file name comes from the text with a fixed hash', () {
    // FNV-1a 64비트의 알려진 값: "a" → af63dc4c8601ec8c
    expect(voiceFileNameFor('a'), 'af63dc4c8601ec8c.mp3');
    // 앞뒤·연속 공백은 같은 문구로 본다.
    expect(voiceFileNameFor('  좋아요.  페이스 좋아요  '),
        voiceFileNameFor('좋아요. 페이스 좋아요'));
    expect(voiceFileNameFor('좋아요'), isNot(voiceFileNameFor('좋아요!')));
  });

  test('every coach line has one file name and no two lines share one', () {
    final texts = coachCueTexts();
    expect(texts.toSet(), hasLength(texts.length));
    final names = {for (final t in texts) voiceFileNameFor(t)};
    expect(names, hasLength(texts.length));
    for (final name in names) {
      expect(name, matches(RegExp(r'^[0-9a-f]{16}\.mp3$')));
    }
  });

  test('the list covers the fixed lines, step lines and every kilometer', () {
    final texts = coachCueTexts().toSet();
    for (final cue in [
      VoiceCoachingCues.enabledConfirm,
      VoiceCoachingCues.walkStart,
      VoiceCoachingCues.walkHarvest,
      VoiceCoachingCues.walkGoal,
      VoiceCoachingCues.runStart,
      VoiceCoachingCues.runFinish,
      VoiceCoachingCues.runNearFinish,
      VoiceCoachingCues.runEncourage,
      VoiceCoachingCues.runHighHeartRate,
      VoiceCoachingCues.runHeartRateSteady,
      VoiceCoachingCues.runHeartRateRecovered,
    ]) {
      expect(texts, contains(cue.ko), reason: cue.id);
    }
    for (final steps in VoiceCoachingCues.walkStepMilestones) {
      expect(texts, contains(VoiceCoachingCues.walkSteps(steps).ko));
    }
    for (var km = 1; km <= coachCueMaxKm; km++) {
      expect(texts, contains(VoiceCoachingCues.runKm(km).ko), reason: '$km');
      expect(
        texts,
        contains(VoiceCoachingCues.runKm(km, coachPlus: true).ko),
        reason: '$km plus',
      );
    }
    expect(texts.length, greaterThanOrEqualTo(100));
  });
}
