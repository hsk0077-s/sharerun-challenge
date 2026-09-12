import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks a short coaching line. Implementations must no-op when unused.
abstract class VoiceCoachingSpeaker {
  Future<void> speak(String text);

  Future<void> stop();

  Future<void> dispose();
}

/// System TTS. Ambient iOS category respects the mute switch; we never raise
/// system volume or take exclusive audio focus.
class FlutterTtsVoiceCoachingSpeaker implements VoiceCoachingSpeaker {
  FlutterTts? _tts;
  var _ready = false;

  Future<FlutterTts> _ensureEngine() async {
    final existing = _tts;
    if (existing != null && _ready) return existing;

    final tts = existing ?? FlutterTts();
    _tts = tts;
    try {
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    } catch (error, stack) {
      debugPrint('voice coaching iOS audio category: $error\n$stack');
    }
    try {
      final languages = await tts.getLanguages;
      final available = languages is List
          ? languages.map((item) => item.toString()).toList()
          : const <String>[];
      final korean = available.where((code) {
        final lower = code.toLowerCase();
        return lower.startsWith('ko');
      });
      if (korean.isNotEmpty) {
        await tts.setLanguage(korean.first);
      } else {
        await tts.setLanguage('ko-KR');
      }
    } catch (error, stack) {
      debugPrint('voice coaching language: $error\n$stack');
    }
    try {
      await tts.setSpeechRate(0.46);
      await tts.setPitch(1.0);
      // Engine gain only — does not unmute the device or raise ringer volume.
      await tts.setVolume(0.8);
      await tts.awaitSpeakCompletion(false);
    } catch (error, stack) {
      debugPrint('voice coaching tts config: $error\n$stack');
    }
    _ready = true;
    return tts;
  }

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      final tts = await _ensureEngine();
      await tts.stop();
      await tts.speak(trimmed);
    } catch (error, stack) {
      debugPrint('voice coaching speak: $error\n$stack');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (error, stack) {
      debugPrint('voice coaching stop: $error\n$stack');
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _tts = null;
    _ready = false;
  }
}

class SilentVoiceCoachingSpeaker implements VoiceCoachingSpeaker {
  const SilentVoiceCoachingSpeaker();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
