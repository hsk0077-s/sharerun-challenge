import 'dart:async';

import 'package:flutter/foundation.dart';

/// 앱 안에서 처리되지 않은 오류를 서버로 보낸다(서버 로그에서 확인).
///
/// 로그인한 뒤에만 보낼 수 있다(`sender`가 연결돼 있어야 함). 한 번 실행하는 동안
/// 같은 오류는 한 번만, 전체 [maxPerSession]건까지만 보낸다. 보내다 실패해도 앱에는 영향이 없다.
abstract final class ClientErrorReporter {
  static const maxPerSession = 10;

  static Future<void> Function({
    required String message,
    required String stack,
    required bool fatal,
  })? sender;

  /// 개발 빌드에서는 서버로 보내지 않는다. 테스트에서만 켠다.
  @visibleForTesting
  static var debugEnabled = false;

  static final _seen = <String>{};
  static var _sent = 0;

  @visibleForTesting
  static void debugReset() {
    sender = null;
    debugEnabled = false;
    _seen.clear();
    _sent = 0;
  }

  static bool get _enabled => debugEnabled || !kDebugMode;

  static Future<void> report(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    final send = sender;
    if (send == null || !_enabled || _sent >= maxPerSession) return;
    final message = error.toString();
    final text = (stack ?? StackTrace.empty).toString();
    final key = '${message.length > 200 ? message.substring(0, 200) : message}'
        '|${text.split('\n').first}';
    if (!_seen.add(key)) return;
    _sent += 1;
    try {
      await send(message: message, stack: text, fatal: fatal);
    } catch (_) {
      // 오류를 보고하다 난 오류는 다시 보고하지 않는다.
    }
  }
}
