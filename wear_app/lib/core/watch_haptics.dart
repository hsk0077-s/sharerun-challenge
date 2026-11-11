import 'package:flutter/services.dart';

import 'watch_platform.dart';

/// 워치 진동. 시간 목록은 밀리초이고 `[기다림, 진동, 쉼, 진동 …]` 순서다.
abstract class WatchHaptics {
  Future<void> pattern(List<int> millis);

  /// 1km를 지났을 때: 긴 진동 1회.
  static const kmPassed = [0, 700];

  /// 일시정지·재개: 짧은 진동 1회.
  static const tick = [0, 120];

  /// 카운트다운 시작(3·2·1): 아주 짧은 진동.
  static const countdown = [0, 80];

  /// 달리기 시작: 한 번 길게.
  static const go = [0, 450];

  /// 종료: 진동 2회.
  static const finished = [0, 180, 120, 180];
}

/// `MainActivity.kt`의 `vibrate` 호출(같은 `sharerun/watch_sensors` 채널).
class MethodChannelWatchHaptics implements WatchHaptics {
  MethodChannelWatchHaptics([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(watchSensorsChannel);

  final MethodChannel _channel;

  @override
  Future<void> pattern(List<int> millis) async {
    try {
      await _channel.invokeMethod<void>('vibrate', {'pattern': millis});
    } catch (_) {
      // 진동을 못 내도 달리기에는 영향이 없다.
    }
  }
}
