import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

/// Outcome of one in-sheet listen. [MiniBotInterpreter.interpret] only runs
/// for [MiniBotListenKind.heard].
enum MiniBotListenKind { heard, denied, unavailable, empty, cancelled }

class MiniBotListen {
  const MiniBotListen.heard(this.text) : kind = MiniBotListenKind.heard;

  const MiniBotListen.denied()
      : kind = MiniBotListenKind.denied,
        text = null;

  const MiniBotListen.unavailable()
      : kind = MiniBotListenKind.unavailable,
        text = null;

  const MiniBotListen.empty()
      : kind = MiniBotListenKind.empty,
        text = null;

  const MiniBotListen.cancelled()
      : kind = MiniBotListenKind.cancelled,
        text = null;

  final MiniBotListenKind kind;
  final String? text;
}

/// Prefer an installed Korean recognizer id. Falls back to `ko_KR` when the
/// device list is empty or has no Korean locale.
String miniBotKoreanLocaleId(Iterable<String> localeIds) {
  for (final id in localeIds) {
    final normalized = id.toLowerCase().replaceAll('-', '_');
    if (normalized == 'ko_kr' || normalized.startsWith('ko_')) return id;
  }
  return 'ko_KR';
}

/// In-sheet speech recognition. [listen] is called only when the user taps
/// 말하기, which is also when the microphone / speech permission is requested.
abstract class MiniBotSpeechToText {
  const MiniBotSpeechToText();

  Future<MiniBotListen> listen();

  Future<void> stop() async {}
}

/// Device recognizer via `speech_to_text`. One instance, because the plugin
/// keeps the first [SpeechToText.initialize] callbacks for the process.
class MiniBotSpeechToTextHook extends MiniBotSpeechToText {
  factory MiniBotSpeechToTextHook() => _instance;

  MiniBotSpeechToTextHook._();

  static final MiniBotSpeechToTextHook _instance = MiniBotSpeechToTextHook._();

  static const _listenFor = Duration(seconds: 10);
  static const _pauseFor = Duration(seconds: 3);
  static const _sessionCap = Duration(seconds: 14);

  final SpeechToText _engine = SpeechToText();
  Completer<MiniBotListen>? _pending;
  Timer? _cap;
  var _latest = '';
  var _ready = false;
  var _accepting = false;

  /// Maps a platform error code to a sheet outcome. Permission failures stay
  /// distinct so the sheet can tell the user typing still works.
  static MiniBotListen failureFor(String errorMsg) {
    switch (errorMsg) {
      case 'error_permission':
      case 'error_speech_recognizer_request_not_authorized':
        return const MiniBotListen.denied();
      case 'error_no_match':
      case 'error_speech_timeout':
        return const MiniBotListen.empty();
      default:
        return const MiniBotListen.unavailable();
    }
  }

  bool _isCurrent(Completer<MiniBotListen> completer) =>
      identical(_pending, completer);

  void _finish(Completer<MiniBotListen> completer, MiniBotListen outcome) {
    _cap?.cancel();
    _cap = null;
    _accepting = false;
    if (!_isCurrent(completer) || completer.isCompleted) return;
    _pending = null;
    completer.complete(outcome);
    unawaited(_safeCancel());
  }

  Future<void> _safeCancel() async {
    try {
      if (_engine.isListening) await _engine.cancel();
    } catch (error) {
      debugPrint('mini-bot speech cancel: $error');
    }
  }

  Future<bool> _ensureReady() async {
    if (_ready && _engine.isAvailable) return true;
    final ok = await _engine.initialize(
      onError: _onError,
      onStatus: _onStatus,
      options: [SpeechToText.androidNoBluetooth],
    );
    _ready = ok;
    return ok;
  }

  Future<String> _koreanLocaleId() async {
    try {
      final locales = await _engine.locales();
      return miniBotKoreanLocaleId(locales.map((locale) => locale.localeId));
    } catch (error) {
      debugPrint('mini-bot locales: $error');
      return 'ko_KR';
    }
  }

  Future<MiniBotListen> _deniedOrUnavailable() async {
    try {
      final allowed = await _engine.hasPermission;
      if (!allowed) return const MiniBotListen.denied();
    } catch (error) {
      debugPrint('mini-bot speech permission: $error');
    }
    return const MiniBotListen.unavailable();
  }

  void _onError(SpeechRecognitionError error) {
    if (!_accepting) return;
    final pending = _pending;
    if (pending == null || pending.isCompleted || !error.permanent) return;
    _finish(pending, failureFor(error.errorMsg));
  }

  void _onStatus(String status) {
    if (!_accepting || status != SpeechToText.doneStatus) return;
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    final text = _latest.trim();
    if (text.isNotEmpty) {
      _finish(pending, MiniBotListen.heard(text));
      return;
    }
    // Android often emits `done` in the same burst as error_permission
    // or error_no_match. Give that error a moment to win.
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!_isCurrent(pending) || pending.isCompleted) return;
      final late = _latest.trim();
      _finish(
        pending,
        late.isEmpty ? const MiniBotListen.empty() : MiniBotListen.heard(late),
      );
    });
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!_accepting) return;
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    final words = result.recognizedWords.trim();
    if (words.isNotEmpty) _latest = words;
    if (!result.finalResult) return;
    _finish(
      pending,
      words.isEmpty ? const MiniBotListen.empty() : MiniBotListen.heard(words),
    );
  }

  @override
  Future<MiniBotListen> listen() async {
    await stop();
    final completer = Completer<MiniBotListen>();
    _pending = completer;
    _latest = '';
    try {
      final ready = await _ensureReady();
      if (!_isCurrent(completer)) return const MiniBotListen.cancelled();
      if (!ready) {
        final outcome = await _deniedOrUnavailable();
        if (!_isCurrent(completer)) return const MiniBotListen.cancelled();
        _pending = null;
        return outcome;
      }
      final localeId = await _koreanLocaleId();
      if (!_isCurrent(completer)) return const MiniBotListen.cancelled();
      _cap = Timer(_sessionCap, () {
        final text = _latest.trim();
        _finish(
          completer,
          text.isEmpty
              ? const MiniBotListen.empty()
              : MiniBotListen.heard(text),
        );
      });
      _accepting = true;
      await _engine.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: _listenFor,
          pauseFor: _pauseFor,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
      return await completer.future;
    } catch (error) {
      debugPrint('mini-bot listen: $error');
      _cap?.cancel();
      _cap = null;
      _accepting = false;
      if (_isCurrent(completer)) _pending = null;
      unawaited(_safeCancel());
      return const MiniBotListen.unavailable();
    }
  }

  @override
  Future<void> stop() async {
    final pending = _pending;
    _pending = null;
    _accepting = false;
    _cap?.cancel();
    _cap = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(const MiniBotListen.cancelled());
    }
    await _safeCancel();
  }
}
