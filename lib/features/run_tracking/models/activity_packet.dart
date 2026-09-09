import 'dart:convert';

import 'route_point.dart';

/// Jena AI 일회성 검증용 보안 패킷. 영구 DB에 적재하지 않는다.
class ActivityPacket {
  ActivityPacket({
    required this.activityId,
    required this.userId,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.durationSeconds,
    required this.gpsTrajectory,
    required this.heartRateSeries,
    required this.cadenceSeries,
    required this.accelerometerData,
    this.gyroStabilityScore = 1,
    this.anonymousRouteHash = '',
  });

  final String activityId;
  final String userId;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final int durationSeconds;
  List<GpsTrajectoryPoint> gpsTrajectory;
  List<TimedIntSample> heartRateSeries;
  List<TimedIntSample> cadenceSeries;
  List<AccelerometerSample> accelerometerData;
  final double gyroStabilityScore;
  String anonymousRouteHash;

  Map<String, dynamic> toJson() {
    return {
      'schema': 'src.activity_packet.v1',
      'activity_id': activityId,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'gyro_stability_score': gyroStabilityScore,
      'anonymous_route_hash': anonymousRouteHash,
      'gps_trajectory': gpsTrajectory.map((e) => e.toJson()).toList(),
      'heart_rate_series': heartRateSeries.map((e) => e.toJson()).toList(),
      'cadence_series': cadenceSeries.map((e) => e.toJson()).toList(),
      'accelerometer_data': accelerometerData.map((e) => e.toJson()).toList(),
    };
  }

  /// `/activities` 영구 기록 허용 필드만 — 원본 Lat/Lon·BPM 없음.
  Map<String, dynamic> toPersistableDocument({required bool jenaVerified}) {
    return {
      'activityId': activityId,
      'userId': userId,
      'distanceKm': distanceKm,
      'Jena_Verified': jenaVerified,
      'anonymous_route_hash': anonymousRouteHash,
      'gps_track_stored': false,
      'biometrics_stored': false,
    };
  }

  void anonymizeAndDiscardRawGps() {
    anonymousRouteHash = hashRoutePoints(
      gpsTrajectory
          .map(
            (p) => RoutePoint(
              latitude: p.latitude,
              longitude: p.longitude,
              recordedAt: p.recordedAt,
            ),
          )
          .toList(),
    );
    gpsTrajectory = const [];
  }

  void discard() {
    gpsTrajectory = const [];
    heartRateSeries = const [];
    cadenceSeries = const [];
    accelerometerData = const [];
  }

  static String hashRoutePoints(List<RoutePoint> points) {
    if (points.isEmpty) return '';
    final cells = points
        .map(
          (p) => '${(p.latitude * 100).round()}:${(p.longitude * 100).round()}',
        )
        .join('|');
    return base64Url.encode(utf8.encode(cells)).hashCode.toRadixString(16);
  }

  static List<GpsTrajectoryPoint> trajectoryFromRoute({
    required List<RoutePoint> routePoints,
    required DateTime startedAt,
  }) {
    return routePoints
        .map(
          (point) => GpsTrajectoryPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            recordedAt: point.recordedAt,
            elapsedSeconds:
                point.recordedAt.difference(startedAt).inSeconds.clamp(0, 86400),
          ),
        )
        .toList(growable: false);
  }
}

class GpsTrajectoryPoint {
  const GpsTrajectoryPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.elapsedSeconds,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final int elapsedSeconds;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'recorded_at': recordedAt.toIso8601String(),
        'elapsed_seconds': elapsedSeconds,
      };
}

class TimedIntSample {
  const TimedIntSample({
    required this.elapsedSeconds,
    required this.value,
  });

  final int elapsedSeconds;
  final int value;

  Map<String, dynamic> toJson() => {
        'elapsed_seconds': elapsedSeconds,
        'value': value,
      };
}

class AccelerometerSample {
  const AccelerometerSample({
    required this.x,
    required this.y,
    required this.z,
    required this.recordedAt,
    required this.elapsedSeconds,
  });

  final double x;
  final double y;
  final double z;
  final DateTime recordedAt;
  final int elapsedSeconds;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'recorded_at': recordedAt.toIso8601String(),
        'elapsed_seconds': elapsedSeconds,
      };
}
