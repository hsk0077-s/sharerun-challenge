import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/voice_coaching/recorded_voice_speaker.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_coaching_speaker.dart';
import 'package:share_run_challenge/features/voice_coaching/voice_cue_files.dart';

class _PhoneVoice implements VoiceCoachingSpeaker {
  final spoken = <String>[];
  var stops = 0;
  var disposed = false;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;
}

class _Player implements CoachAudioPlayer {
  _Player({this.fails = false});

  final bool fails;
  final played = <String>[];
  var stops = 0;
  var disposed = false;

  @override
  Future<void> play(String assetPath) async {
    if (fails) throw StateError('no audio');
    played.add(assetPath);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);

  final String? text;

  @override
  Future<ByteData> load(String key) async {
    final value = text;
    if (value == null) throw FlutterError('missing $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const text = '러닝을 시작해요. 호흡을 맞춰볼까요?';
  final file = voiceFileNameFor(text);

  RecordedVoiceCoachingSpeaker speaker(
    _PhoneVoice phone,
    _Player player, {
    Set<String> files = const {},
  }) =>
      RecordedVoiceCoachingSpeaker(
        fallback: phone,
        player: player,
        loadManifest: () async => files,
      );

  test('a line with a recorded file plays the file, not the phone voice',
      () async {
    final phone = _PhoneVoice();
    final player = _Player();
    await speaker(phone, player, files: {file}).speak(text);
    expect(player.played, ['voice/$file']);
    expect(phone.spoken, isEmpty);
    expect(phone.stops, 1, reason: 'the phone voice must not talk over it');
  });

  test('a line without a file falls back to the phone voice', () async {
    final phone = _PhoneVoice();
    final player = _Player();
    await speaker(phone, player).speak(text);
    expect(player.played, isEmpty);
    expect(phone.spoken, [text]);
  });

  test('if the file cannot be played the phone voice still reads it',
      () async {
    final phone = _PhoneVoice();
    await speaker(phone, _Player(fails: true), files: {file}).speak(text);
    expect(phone.spoken, [text]);
  });

  test('a manifest that cannot be read means the phone voice for everything',
      () async {
    final phone = _PhoneVoice();
    final broken = RecordedVoiceCoachingSpeaker(
      fallback: phone,
      player: _Player(),
      loadManifest: () async => throw StateError('no manifest'),
    );
    await broken.speak(text);
    expect(phone.spoken, [text]);
  });

  test('extra spaces and blank text do not break the lookup', () async {
    final phone = _PhoneVoice();
    final player = _Player();
    final s = speaker(phone, player, files: {file});
    await s.speak('  러닝을   시작해요.  호흡을 맞춰볼까요?  ');
    await s.speak('   ');
    expect(player.played, ['voice/$file']);
    expect(phone.spoken, isEmpty);
  });

  test('stop and dispose reach both the file player and the phone voice',
      () async {
    final phone = _PhoneVoice();
    final player = _Player();
    final s = speaker(phone, player);
    await s.stop();
    await s.dispose();
    expect(player.stops, 1);
    expect(phone.stops, 1);
    expect(player.disposed, isTrue);
    expect(phone.disposed, isTrue);
  });

  group('manifest', () {
    test('lists the files it names', () async {
      final files = await loadVoiceManifest(
        _Bundle('{"files": ["a.mp3", "b.mp3", "", 3]}'),
      );
      expect(files, {'a.mp3', 'b.mp3'});
    });

    test('a missing or broken manifest is empty, never an error', () async {
      expect(await loadVoiceManifest(_Bundle(null)), isEmpty);
      expect(await loadVoiceManifest(_Bundle('not json')), isEmpty);
      expect(await loadVoiceManifest(_Bundle('{"files": 5}')), isEmpty);
    });

    test('the shipped manifest only names files for current coach lines',
        () async {
      final shipped = await loadVoiceManifest();
      final current = {for (final t in coachCueTexts()) voiceFileNameFor(t)};
      expect(
        shipped.difference(current),
        isEmpty,
        reason: 'a file for a line that was changed or removed is left over',
      );
    });
  });
}
