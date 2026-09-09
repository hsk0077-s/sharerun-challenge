import '../../run_tracking/models/route_point.dart';

/// Unified SRC running payload (src.running.v1) for Jena validation.
class SrcRunningPayload {
  const SrcRunningPayload({
    required this.schemaVersion,
    required this.activityId,
    required this.userId,
    required this.session,
    required this.gpsTrack,
    required this.biometrics,
    required this.device,
  });

  static const schemaVersionValue = 'src.running.v1';

  final String schemaVersion;
  final String activityId;
  final String userId;
  final SrcRunningSession session;
  final List<SrcGpsPoint> gpsTrack;

  /// EPHEMERAL — discard after in-memory Jena validation.
  final SrcRunningBiometrics biometrics;
  final SrcRunningDevice device;

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'activity_id': activityId,
      'user_id': userId,
      'session': session.toJson(),
      'gps_track': gpsTrack.map((point) => point.toJson()).toList(),
      'biometrics': biometrics.toJson(),
      'device': device.toJson(),
    };
  }
}

class SrcRunningSession {
  const SrcRunningSession({
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.durationSeconds,
  });

  final DateTime? startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final int durationSeconds;

  Map<String, dynamic> toJson() {
    return {
      'started_at': startedAt?.toUtc().toIso8601String(),
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
    };
  }
}

class SrcGpsPoint {
  const SrcGpsPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  factory SrcGpsPoint.fromRoutePoint(RoutePoint point) {
    return SrcGpsPoint(
      latitude: point.latitude,
      longitude: point.longitude,
      recordedAt: point.recordedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    };
  }
}

/// Raw biometric time-series. Never persist to database.
class SrcRunningBiometrics {
  const SrcRunningBiometrics({
    required this.heartRateBpmSeries,
    required this.cadenceSpmSeries,
  });

  final List<int> heartRateBpmSeries;
  final List<int> cadenceSpmSeries;

  Map<String, dynamic> toJson() {
    return {
      'heart_rate_bpm_series': heartRateBpmSeries,
      'cadence_spm_series': cadenceSpmSeries,
      'ephemeral': true,
    };
  }
}

class SrcRunningDevice {
  const SrcRunningDevice({
    required this.watchTypeCode,
    required this.gyroStabilityScore,
    required this.integrationTrack,
  });

  final String watchTypeCode;
  final double gyroStabilityScore;
  final String integrationTrack;

  Map<String, dynamic> toJson() {
    return {
      'watch_type': watchTypeCode,
      'gyro_stability_score': gyroStabilityScore,
      'integration_track': integrationTrack,
    };
  }
}
