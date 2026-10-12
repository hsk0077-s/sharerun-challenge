import 'dart:convert';

import 'voice_coaching_cues.dart';

/// 미리 만든 음성 파일(mp3)을 문구와 이어 주는 규칙.
///
/// 파일 이름은 문구 글자에서 정해서, 문구가 바뀌면 옛 파일은 저절로 쓰이지 않고
/// 폰 음성으로 대신한다. 순수 Dart라서 음성 파일을 만드는 도구(`tool/build_coach_voice.dart`)와
/// 앱이 같은 코드를 쓴다.

/// 문구 한 줄로 만들어 두는 킬로미터 상한. 이보다 먼 거리는 폰 음성이 읽는다.
const coachCueMaxKm = 42;

/// 앞뒤 공백을 지우고 연속된 공백을 하나로 줄인다.
String normalizeCueText(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ');

/// 문구의 음성 파일 이름. FNV-1a 64비트 해시(16자리 16진수) + `.mp3`.
String voiceFileNameFor(String text) {
  // 64비트 정수가 음수로 돌아가도 같은 16자리가 나오게 32비트씩 나눠 적는다.
  const offset = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  var hash = offset;
  for (final byte in utf8.encode(normalizeCueText(text))) {
    hash ^= byte;
    hash *= prime;
  }
  String half(int value) =>
      (value & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return '${half(hash >> 32)}${half(hash)}.mp3';
}

/// 음성 파일로 만들어 둘 모든 코치 문구(중복 없이, 나오는 순서대로).
List<String> coachCueTexts() {
  final cues = <VoiceCue>[
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
    for (final steps in VoiceCoachingCues.walkStepMilestones)
      VoiceCoachingCues.walkSteps(steps),
    for (var km = 1; km <= coachCueMaxKm; km++) ...[
      VoiceCoachingCues.runKm(km),
      VoiceCoachingCues.runKm(km, coachPlus: true),
    ],
  ];
  final seen = <String>{};
  final out = <String>[];
  for (final cue in cues) {
    final text = normalizeCueText(cue.ko);
    if (text.isNotEmpty && seen.add(text)) out.add(text);
  }
  return out;
}
