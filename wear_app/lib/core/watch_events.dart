import 'dart:async';

import 'package:flutter/services.dart';

import 'watch_platform.dart';

/// 안드로이드가 앱에 알려 주는 일: 인터넷이 다시 연결됨, 시계 타일에서 바로 시작 요청.
abstract class WatchEvents {
  /// 타일로 열렸으면 한 번만 true. 그 뒤에는 false.
  Future<bool> consumeAutostart();

  /// 인터넷이 (다시) 연결될 때마다 [callback]을 부른다.
  void onNetworkAvailable(void Function() callback);

  /// 앱이 이미 떠 있는 채로 타일을 눌렀을 때 [callback]을 부른다.
  void onAutostartRequested(void Function() callback);
}

/// `MainActivity.kt`: `consumeAutostart` 호출, `networkAvailable` 알림(같은 `sharerun/watch_sensors` 채널).
class MethodChannelWatchEvents implements WatchEvents {
  MethodChannelWatchEvents([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(watchSensorsChannel);

  final MethodChannel _channel;
  void Function()? _network;
  void Function()? _autostart;

  @override
  Future<bool> consumeAutostart() async {
    try {
      return await _channel.invokeMethod<bool>('consumeAutostart') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void onNetworkAvailable(void Function() callback) {
    _network = callback;
    _listen();
  }

  @override
  void onAutostartRequested(void Function() callback) {
    _autostart = callback;
    _listen();
  }

  void _listen() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'networkAvailable') _network?.call();
      if (call.method == 'autostartRequested') _autostart?.call();
      return null;
    });
  }
}
