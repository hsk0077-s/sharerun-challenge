import '../../../data/models/user_model.dart';
import '../../run_tracking/models/route_point.dart';
import '../../run_tracking/services/ephemeral_sensor_buffer.dart';
import '../models/jena_validation_request.dart';
import 'src_running_payload.dart';

/// Normalizes device raw samples into the SRC standard running JSON schema.
///
/// Ephemeral validation flow:
/// 1. Build [SrcRunningPayload] in memory (includes HR/cadence arrays).
/// 2. Derive API request for Jena secured endpoint.
/// 3. Caller must invoke [EphemeralSensorBuffer.destroy] after validation.
class SrcRunningPayloadNormalizer {
  SrcRunningPayload normalize({
    required String activityId,
    required String userId,
    required double distanceKm,
    required int durationSeconds,
    required double gyroStabilityScore,
    required List<RoutePoint> routePoints,
    required EphemeralSensorBuffer sensorBuffer,
    required WatchType watchType,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    final request = sensorBuffer.buildRequest(
      activityId: activityId,
      userId: userId,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      gyroStabilityScore: gyroStabilityScore,
    );

    return SrcRunningPayload(
      schemaVersion: SrcRunningPayload.schemaVersionValue,
      activityId: activityId,
      userId: userId,
      session: SrcRunningSession(
        startedAt: startedAt,
        endedAt: endedAt,
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
      ),
      gpsTrack: routePoints.map(SrcGpsPoint.fromRoutePoint).toList(),
      biometrics: SrcRunningBiometrics(
        heartRateBpmSeries: request.heartRates,
        cadenceSpmSeries: request.cadenceSpm,
      ),
      device: SrcRunningDevice(
        watchTypeCode: watchType.code,
        gyroStabilityScore: gyroStabilityScore,
        integrationTrack: watchType.isApiTrack ? 'api_oauth' : 'os_health_direct',
      ),
    );
  }

  JenaValidationRequest toJenaRequest(SrcRunningPayload payload) {
    return JenaValidationRequest(
      activityId: payload.activityId,
      userId: payload.userId,
      distanceKm: payload.session.distanceKm,
      durationSeconds: payload.session.durationSeconds,
      heartRates: List<int>.from(payload.biometrics.heartRateBpmSeries),
      cadenceSpm: List<int>.from(payload.biometrics.cadenceSpmSeries),
      gyroStabilityScore: payload.device.gyroStabilityScore,
    );
  }

  /// 데이터 최소화: Lat/Lon·BPM 배열은 영구 적재하지 않는다.
  /// `/activities`에는 누적 거리 + Jena 검증 플래그만 남긴다.
  Map<String, dynamic> toPersistableSummary(
    SrcRunningPayload payload, {
    bool jenaVerified = false,
  }) {
    return {
      'activity_id': payload.activityId,
      'user_id': payload.userId,
      'distanceKm': payload.session.distanceKm,
      'Jena_Verified': jenaVerified,
      'biometrics_stored': false,
      'gps_track_stored': false,
    };
  }
}
