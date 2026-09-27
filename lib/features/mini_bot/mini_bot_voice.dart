import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks mini-bot lines. Separate from run voice-coaching so that path stays
/// untouched. Failures are swallowed — typed chat still works without audio.
abstract class MiniBotVoice {
  Future<void> speak(String text);

  Future<void> stop();

  Future<void> dispose();
}

class FlutterTtsMiniBotVoice implements MiniBotVoice {
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
        [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    } catch (error, stack) {
      debugPrint('mini-bot iOS audio category: $error\n$stack');
    }
    try {
      await tts.setLanguage('ko-KR');
      await tts.setSpeechRate(0.48);
      await tts.setVolume(0.85);
      await tts.awaitSpeakCompletion(false);
    } catch (error, stack) {
      debugPrint('mini-bot tts config: $error\n$stack');
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
      debugPrint('mini-bot speak: $error\n$stack');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (error, stack) {
      debugPrint('mini-bot stop: $error\n$stack');
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _tts = null;
    _ready = false;
  }
}

class SilentMiniBotVoice implements MiniBotVoice {
  const SilentMiniBotVoice();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Follow-up hook for `speech_to_text`.
///
/// The project already has `flutter_tts` and no recognizer package. Return the
/// recognized Korean utterance from [listen]; [MiniBotInterpreter.interpret]
/// already accepts that string. Null means STT is not connected yet.
abstract class MiniBotSpeechToText {
  const MiniBotSpeechToText();

  Future<String?> listen();
}

class MiniBotSpeechToTextHook extends MiniBotSpeechToText {
  const MiniBotSpeechToTextHook();

  @override
  Future<String?> listen() async => null;
}
