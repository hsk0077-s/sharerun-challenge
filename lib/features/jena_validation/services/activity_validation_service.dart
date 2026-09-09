import '../../../data/api/secured_action_api_client.dart';
import '../../../data/models/user_model.dart';
import '../../run_tracking/models/route_point.dart';
import '../../run_tracking/services/ephemeral_sensor_buffer.dart';
import '../models/jena_validation_result.dart';
import '../schema/src_running_payload_normalizer.dart';

class ActivityValidationService {
  ActivityValidationService({
    required SecuredActionApiClient securedActionApiClient,
    SrcRunningPayloadNormalizer? payloadNormalizer,
  })  : _securedActionApiClient = securedActionApiClient,
        _payloadNormalizer = payloadNormalizer ?? SrcRunningPayloadNormalizer();

  final SecuredActionApiClient _securedActionApiClient;
  final SrcRunningPayloadNormalizer _payloadNormalizer;

  /// Validates a run via Jena using the SRC standard payload middleware.
  ///
  /// Ephemeral policy: heart-rate/cadence arrays exist only inside
  /// [SrcRunningPayload.biometrics] during this call. [sensorBuffer.destroy]
  /// clears local copies in the `finally` block — they are never written to DB.
  Future<JenaValidationResult> validateAndPersistResult({
    required String activityId,
    required String userId,
    required double distanceKm,
    required int durationSeconds,
    required double gyroStabilityScore,
    required List<RoutePoint> routePoints,
    required EphemeralSensorBuffer sensorBuffer,
    WatchType watchType = WatchType.none,
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    final payload = _payloadNormalizer.normalize(
      activityId: activityId,
      userId: userId,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      gyroStabilityScore: gyroStabilityScore,
      routePoints: routePoints,
      sensorBuffer: sensorBuffer,
      watchType: watchType,
      startedAt: startedAt,
      endedAt: endedAt,
    );

    // Only summary fields without biometric arrays may be logged/persisted.
    final _ = _payloadNormalizer.toPersistableSummary(payload);

    final request = _payloadNormalizer.toJenaRequest(payload);

    try {
      return _securedActionApiClient.validateRun(
        request: request,
        routePoints: routePoints,
      );
    } finally {
      sensorBuffer.destroy();
    }
  }
}
