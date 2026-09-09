import '../../../data/models/user_model.dart';
import '../../run_tracking/services/run_session_service.dart';
import '../schema/src_running_payload_normalizer.dart';

/// Packages a completed run into the SRC `src.running.v1` JSON for Jena AI.
class JenaRunSubmissionPackager {
  JenaRunSubmissionPackager({
    SrcRunningPayloadNormalizer? normalizer,
  }) : _normalizer = normalizer ?? SrcRunningPayloadNormalizer();

  final SrcRunningPayloadNormalizer _normalizer;

  Map<String, dynamic> package({
    required String activityId,
    required String userId,
    required CompletedRunSession session,
    WatchType watchType = WatchType.none,
  }) {
    final payload = _normalizer.normalize(
      activityId: activityId,
      userId: userId,
      distanceKm: session.telemetry.distanceKm,
      durationSeconds: session.telemetry.durationSeconds,
      gyroStabilityScore: session.telemetry.gyroStabilityScore,
      routePoints: session.routePoints,
      sensorBuffer: session.sensorBuffer,
      watchType: watchType,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
    );

    final json = payload.toJson();
    json['activity_packet'] = session.activityPacket.toJson();
    json['anonymous_route_hash'] = session.activityPacket.anonymousRouteHash;
    json['movement'] = {
      'total_steps': session.totalSteps,
      'cadence_spm_series': payload.biometrics.cadenceSpmSeries,
    };
    return json;
  }
}
