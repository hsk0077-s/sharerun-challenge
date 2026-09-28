/// Phase 3a ships the free coach only. Later DIA/paid tiers can extend this
/// without a second on/off toggle.
enum VoiceCoachPlan { free }

/// Short coaching lines. Korean is the spoken default; [en] is for later l10n.
class VoiceCue {
  const VoiceCue({
    required this.id,
    required this.ko,
    required this.en,
  });

  final String id;
  final String ko;
  final String en;

  String text({String languageCode = 'ko'}) {
    return languageCode.toLowerCase().startsWith('ko') ? ko : en;
  }
}

/// Nike Run Club / Runday-style light cues — keep each line short.
abstract final class VoiceCoachingCues {
  static const enabledConfirm = VoiceCue(
    id: 'pref.enabled',
    ko: '보이스 코칭을 켤게요.',
    en: 'Voice coaching is on.',
  );

  static const walkStart = VoiceCue(
    id: 'walk.start',
    ko: '워킹 챌린지 시작이에요. 천천히 걸어볼까요?',
    en: 'Walking challenge started. Easy steps.',
  );

  static const walkHarvest = VoiceCue(
    id: 'walk.harvest',
    ko: '셰어를 수확했어요. 수고했어요.',
    en: 'SHARE harvested. Nice work.',
  );

  static const walkGoal = VoiceCue(
    id: 'walk.goal',
    ko: '오늘의 목표 거리를 채웠어요. 대단해요!',
    en: 'Daily distance goal done. Amazing!',
  );

  static const runStart = VoiceCue(
    id: 'run.start',
    ko: '러닝을 시작해요. 호흡을 맞춰볼까요?',
    en: 'Run started. Match your breath.',
  );

  static const runFinish = VoiceCue(
    id: 'run.finish',
    ko: '러닝 종료. 오늘도 잘 달렸어요.',
    en: 'Run finished. Well done today.',
  );

  /// Remaining distance that counts as "almost there" on a known race target.
  static const runNearFinishRemainingKm = 0.2;

  static const runNearFinish = VoiceCue(
    id: 'run.near_finish',
    ko: '200미터 남았어요.',
    en: '200 meters to go.',
  );

  /// Wall-clock spacing for the mid-run pep. The 45s gate still applies.
  static const runEncourageEverySeconds = 180;

  static const runEncourage = VoiceCue(
    id: 'run.encourage',
    ko: '좋아요. 호흡 유지해요.',
    en: 'Nice. Keep your breath.',
  );

  /// Age-agnostic BPM bands for the challenge-tracker reading.
  ///
  /// There is no age, resting HR, or max HR on the coach, so these are fixed
  /// bounds — not a percent-of-max zone. Only a plausible
  /// [minPlausibleHeartRateBpm]–[maxPlausibleHeartRateBpm] sample counts.
  ///
  /// * **Steady** [steadyHeartRateBpm]–169: one keep-pace line per entry.
  ///   Rearm at or below [steadyHeartRateRearmBpm] so a 154/156 flutter
  ///   does not repeat it. Encouragement priority (45s gate, loses to km).
  /// * **High** ≥ [highHeartRateBpm]: one slow-down. Heart-rate priority, so
  ///   it can interrupt. Rearm at or below [highHeartRateRearmBpm].
  /// * **Recovered**: after that slow-down was spoken, the next sample at or
  ///   below [highHeartRateRearmBpm] says the heart rate came down. Once per
  ///   episode, encouragement priority, so it waits out the slow-down gap.
  ///   146–154 is a silent deadband.
  static const minPlausibleHeartRateBpm = 30;
  static const steadyHeartRateRearmBpm = 145;
  static const steadyHeartRateBpm = 155;
  static const highHeartRateRearmBpm = 160;
  static const highHeartRateBpm = 170;
  static const maxPlausibleHeartRateBpm = 220;

  static const runHighHeartRate = VoiceCue(
    id: 'run.hr.high',
    ko: '심박이 높아요. 속도를 줄여요.',
    en: 'Heart rate is high. Ease off.',
  );

  static const runHeartRateSteady = VoiceCue(
    id: 'run.hr.steady',
    ko: '심박이 좋아요. 이 페이스 유지해요.',
    en: 'Heart rate looks good. Hold this pace.',
  );

  static const runHeartRateRecovered = VoiceCue(
    id: 'run.hr.recovered',
    ko: '심박이 내려왔어요. 페이스 유지해요.',
    en: 'Heart rate came down. Hold this pace.',
  );

  static const walkStepMilestones = <int>[1000, 3000, 5000, 8000, 10000];

  static VoiceCue walkSteps(int steps) {
    return switch (steps) {
      1000 => const VoiceCue(
          id: 'walk.steps.1000',
          ko: '천 보 달성! 좋아요.',
          en: 'One thousand steps. Nice.',
        ),
      3000 => const VoiceCue(
          id: 'walk.steps.3000',
          ko: '삼천 보예요. 페이스 잘 유지하고 있어요.',
          en: 'Three thousand steps. Steady pace.',
        ),
      5000 => const VoiceCue(
          id: 'walk.steps.5000',
          ko: '오천 보! 잘하고 있어요.',
          en: 'Five thousand steps. You are doing great.',
        ),
      8000 => const VoiceCue(
          id: 'walk.steps.8000',
          ko: '팔천 보. 거의 다 왔어요.',
          en: 'Eight thousand steps. Almost there.',
        ),
      10000 => const VoiceCue(
          id: 'walk.steps.10000',
          ko: '만 보 달성! 오늘 정말 잘했어요.',
          en: 'Ten thousand steps. Fantastic today.',
        ),
      _ => VoiceCue(
          id: 'walk.steps.$steps',
          ko: '$steps보 달성! 좋아요.',
          en: '$steps steps. Nice.',
        ),
    };
  }

  /// Free kilometer line. [coachPlus] is one short tone on the same event —
  /// still a single sentence, not a guided-run script.
  static VoiceCue runKm(int km, {bool coachPlus = false}) {
    if (coachPlus) {
      return VoiceCue(
        id: 'run.km.$km',
        ko: km == 1 ? '1킬로미터. 호흡 유지하고 가요.' : '$km킬로미터. 이 페이스 유지해요.',
        en: km == 1
            ? 'One kilometer. Keep your breath.'
            : '$km kilometers. Hold this pace.',
      );
    }
    return VoiceCue(
      id: 'run.km.$km',
      ko: km == 1 ? '1킬로미터. 페이스 좋아요.' : '$km킬로미터 통과. 잘하고 있어요.',
      en: km == 1 ? 'One kilometer. Good pace.' : '$km kilometers. Keep it up.',
    );
  }

  /// Coach+ keeps the free cue id so the priority gate still sees distance.
  static VoiceCue? coachPlusDistanceTone(
    VoiceCue? cue, {
    required bool coachPlus,
  }) {
    if (!coachPlus || cue == null || !cue.id.startsWith('run.km.')) return cue;
    final km = int.tryParse(cue.id.substring('run.km.'.length));
    if (km == null || km < 1) return cue;
    return runKm(km, coachPlus: true);
  }
}
