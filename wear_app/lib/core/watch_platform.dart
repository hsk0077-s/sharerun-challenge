import 'package:flutter/services.dart';

/// 센서가 한 번 읽어 준 값. 없는 값은 0이다(만들어 내지 않는다).
class SensorSnapshot {
  const SensorSnapshot({
    this.heartRate = 0,
    this.steps = 0,
    this.distanceKm = 0,
    this.hasGps = false,
  });

  final int heartRate;
  final int steps;
  final double distanceKm;
  final bool hasGps;

  factory SensorSnapshot.fromMap(Map<Object?, Object?> map) => SensorSnapshot(
        heartRate: (map['heartRate'] as num?)?.toInt() ?? 0,
        steps: (map['steps'] as num?)?.toInt() ?? 0,
        distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
        hasGps: map['hasGps'] == true,
      );
}

/// 심박·걸음·GPS를 모으는 쪽. 실제 구현은 안드로이드(Kotlin), 시험에서는 가짜.
abstract class WatchSensors {
  /// 권한을 묻고, 허용된 센서 이름(`heartRate`, `steps`, `gps`)을 돌려준다.
  Future<Set<String>> requestPermissions();
  Future<void> start();
  Future<void> stop();
  Future<SensorSnapshot> read();
}

/// `MainActivity.kt`의 `sharerun/watch_sensors` 채널.
class MethodChannelWatchSensors implements WatchSensors {
  MethodChannelWatchSensors([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(watchSensorsChannel);

  final MethodChannel _channel;

  @override
  Future<Set<String>> requestPermissions() async {
    final granted = await _channel.invokeListMethod<String>('requestPermissions');
    return {...?granted};
  }

  @override
  Future<void> start() => _channel.invokeMethod<void>('startTracking');

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stopTracking');

  @override
  Future<SensorSnapshot> read() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('readSnapshot');
    return map == null ? const SensorSnapshot() : SensorSnapshot.fromMap(map);
  }
}

const watchSensorsChannel = 'sharerun/watch_sensors';

/// 로그인 토큰과 기록 대기열을 앱 전용 저장소에 둔다.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MethodChannelStore implements KeyValueStore {
  MethodChannelStore([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(watchSensorsChannel);

  final MethodChannel _channel;

  @override
  Future<String?> read(String key) =>
      _channel.invokeMethod<String>('getString', {'key': key});

  @override
  Future<void> write(String key, String value) =>
      _channel.invokeMethod<void>('putString', {'key': key, 'value': value});

  @override
  Future<void> delete(String key) =>
      _channel.invokeMethod<void>('remove', {'key': key});
}

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
