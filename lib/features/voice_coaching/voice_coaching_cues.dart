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

  static VoiceCue runKm(int km) {
    return VoiceCue(
      id: 'run.km.$km',
      ko: km == 1 ? '1킬로미터. 페이스 좋아요.' : '$km킬로미터 통과. 잘하고 있어요.',
      en: km == 1 ? 'One kilometer. Good pace.' : '$km kilometers. Keep it up.',
    );
  }
}
