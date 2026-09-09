import 'dart:convert';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/route_point.dart';
import 'ephemeral_sensor_buffer.dart';
import 'gps_tracking_service.dart';
import 'gyro_stability_service.dart';
import 'health_data_service.dart';

/// 어뷰징 방어용 센서 수집 스켈레톤.
///
/// HealthKit / Health Connect · GPS · 자이로를 비동기로 샘플링하되,
/// 민감 좌표·초단위 BPM은 [EphemeralSensorBuffer]에만 보관하고
/// 검증 직후 익명 해싱 → [destroy]로 폐기한다. Firestore에는 영구 적재하지 않는다.
class AbusingDefenseSensorSkeleton {
  AbusingDefenseSensorSkeleton({
    required GpsTrackingService gpsTrackingService,
    required HealthDataService healthDataService,
    required GyroStabilityService gyroStabilityService,
  })  : _gps = gpsTrackingService,
        _health = healthDataService,
        _gyro = gyroStabilityService;

  final GpsTrackingService _gps;
  final HealthDataService _health;
  final GyroStabilityService _gyro;

  EphemeralSensorBuffer? _buffer;
  final List<RoutePoint> _ephemeralRoute = [];

  /// 러닝 시작 — 권한 확보 후 휘발성 버퍼를 연다.
  Future<void> beginSession() async {
    await _gps.ensurePermission();
    await _health.requestRunDataAuthorization();
    _gyro.start();
    _buffer = EphemeralSensorBuffer();
    _ephemeralRoute.clear();
  }

  /// 실시간 샘플 1틱 (위도/경도·BPM) — 메모리에만 적재.
  Future<void> sampleTick() async {
    final buffer = _buffer;
    if (buffer == null) return;

    try {
      final position = await _gps.getCurrentPosition();
      _ephemeralRoute.add(
        RoutePoint(
          latitude: position.latitude,
          longitude: position.longitude,
          recordedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // GPS 일시 실패는 세션을 중단하지 않는다.
    }

    final bpm = await _health.readLatestHeartRate();
    if (bpm != null) {
      buffer.addHeartRate(bpm);
    }

    // sensors_plus 가속도는 자이로 안정성 서비스가 집계한다.
    // ignore: unused_local_variable
    final _ = accelerometerEventStream;
  }

  /// 러닝 종료 — 민감 좌표를 익명 해시한 뒤 즉시 폐기.
  /// 반환값에는 원본 Lat/Lon·BPM이 포함되지 않는다.
  Future<({double distanceKm, String anonymousRouteHash, bool sensorsCleared})>
      endSessionAndPurge({
    required double distanceKm,
  }) async {
    final anonymousRouteHash = _hashEphemeralRoute(_ephemeralRoute);
    _gyro.stop();
    _buffer?.destroy();
    _buffer = null;
    _ephemeralRoute.clear();
    return (
      distanceKm: distanceKm,
      anonymousRouteHash: anonymousRouteHash,
      sensorsCleared: true,
    );
  }

  /// 원본 좌표를 DB에 남기지 않도록 격자 양자화 후 핑거프린트만 생성.
  static String _hashEphemeralRoute(List<RoutePoint> points) {
    if (points.isEmpty) return '';
    final cells = points
        .map(
          (p) =>
              '${(p.latitude * 100).round()}:${(p.longitude * 100).round()}',
        )
        .join('|');
    return base64Url.encode(utf8.encode(cells)).hashCode.toRadixString(16);
  }

  /// `/activities` 영구 저장 허용 필드만 (Jena 플래그 + 누적 거리).
  static Map<String, dynamic> minimizedActivityDocument({
    required String activityId,
    required double distanceKm,
    required bool jenaVerified,
  }) {
    return {
      'activityId': activityId,
      'distanceKm': distanceKm,
      'Jena_Verified': jenaVerified,
    };
  }
}
