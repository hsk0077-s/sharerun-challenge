import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coach_output_mute.dart';

void main() {
  test('media volume 0 is muted and a missing reading is not', () {
    expect(voiceCoachOutputMuted(mediaVolume: 0), isTrue);
    expect(voiceCoachOutputMuted(mediaVolume: -1), isTrue);
    expect(voiceCoachOutputMuted(mediaVolume: 1), isFalse);
    expect(voiceCoachOutputMuted(mediaVolume: null), isFalse);
  });

  test('probe uses the injected volume and treats a throw as not muted',
      () async {
    final silent = VoiceCoachMuteProbe(readMediaVolume: () async => 0);
    final audible = VoiceCoachMuteProbe(readMediaVolume: () async => 4);
    final unknown = VoiceCoachMuteProbe(readMediaVolume: () async => null);
    final failed = VoiceCoachMuteProbe(
      readMediaVolume: () async => throw StateError('no audio'),
    );

    expect(await silent.isMuted(), isTrue);
    expect(await audible.isMuted(), isFalse);
    expect(await unknown.isMuted(), isFalse);
    expect(await failed.isMuted(), isFalse);
  });
}
