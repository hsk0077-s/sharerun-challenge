import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'voice_coaching_speaker.dart';
import 'voice_cue_files.dart';

/// 앱에 들어 있는 음성 파일 목록(`assets/voice/manifest.json`)을 읽는다.
/// 파일이 없거나 형식이 틀리면 빈 목록이라서 모두 폰 음성으로 대신한다.
Future<Set<String>> loadVoiceManifest([AssetBundle? bundle]) async {
  try {
    final raw = await (bundle ?? rootBundle)
        .loadString(RecordedVoiceCoachingSpeaker.manifestAsset);
    final json = jsonDecode(raw);
    final files = json is Map ? json['files'] : null;
    if (files is! List) return <String>{};
    return {
      for (final file in files)
        if (file is String && file.isNotEmpty) file,
    };
  } catch (_) {
    return <String>{};
  }
}

/// mp3 한 개를 재생한다. 시험에서는 가짜로 바꿔 끼운다.
abstract class CoachAudioPlayer {
  Future<void> play(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

/// 다른 앱 소리를 끊지 않고 작게 섞어 읽는다(길 안내 음성처럼 잠깐 낮춤).
class AudioplayersCoachPlayer implements CoachAudioPlayer {
  AudioPlayer? _player;

  Future<AudioPlayer> _ensure() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _player = player;
    try {
      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.assistanceNavigationGuidance,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.stop);
    } catch (error, stack) {
      debugPrint('coach audio context: $error\n$stack');
    }
    return player;
  }

  @override
  Future<void> play(String assetPath) async {
    final player = await _ensure();
    await player.stop();
    // AssetSource는 `assets/` 아래 경로를 받는다.
    await player.play(AssetSource(assetPath));
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (error, stack) {
      debugPrint('coach audio stop: $error\n$stack');
    }
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }
}

/// 미리 만든 음성 파일이 있는 문구는 파일로, 없거나 재생에 실패하면 [fallback](폰 음성)으로 읽는다.
class RecordedVoiceCoachingSpeaker implements VoiceCoachingSpeaker {
  RecordedVoiceCoachingSpeaker({
    required this.fallback,
    CoachAudioPlayer? player,
    Future<Set<String>> Function()? loadManifest,
  })  : _player = player ?? AudioplayersCoachPlayer(),
        _loadManifest = loadManifest ?? loadVoiceManifest;

  static const manifestAsset = 'assets/voice/manifest.json';

  final VoiceCoachingSpeaker fallback;
  final CoachAudioPlayer _player;
  final Future<Set<String>> Function() _loadManifest;
  Future<Set<String>>? _manifest;

  /// 이 문구의 음성 파일 경로(`voice/…mp3`). 파일이 없으면 null.
  Future<String?> _assetFor(String text) async {
    final files = await (_manifest ??= _loadManifest());
    final name = voiceFileNameFor(text);
    return files.contains(name) ? 'voice/$name' : null;
  }

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    String? asset;
    try {
      asset = await _assetFor(trimmed);
    } catch (_) {
      asset = null;
    }
    if (asset == null) {
      await fallback.speak(trimmed);
      return;
    }
    try {
      // 두 소리가 겹치지 않게 폰 음성은 먼저 멈춘다.
      await fallback.stop();
      await _player.play(asset);
    } catch (error, stack) {
      debugPrint('coach voice file: $error\n$stack');
      await fallback.speak(trimmed);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await fallback.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await fallback.dispose();
  }
}
