import '../models/jena_validation_result.dart';
import 'jena_pending_gate.dart';

/// Stand-in Jena validator for local MVP testing before GCP integration.
class MockJenaValidationService {
  const MockJenaValidationService({
    JenaPendingGate pendingGate = const JenaPendingGate(),
  }) : _pendingGate = pendingGate;

  final JenaPendingGate _pendingGate;

  static const pureEffortValueReward = 100;

  Future<JenaValidationResult> validateSubmission(
    Map<String, dynamic> payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final session = payload['session'] as Map<String, dynamic>? ?? const {};
    final distanceKm = (session['distance_km'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (session['duration_seconds'] as num?)?.toInt() ?? 0;
    final device = payload['device'] as Map<String, dynamic>? ?? const {};
    final watchTypeCode = device['watch_type'] as String? ?? 'none';

    final cadence = _extractIntSeries(
      payload,
      biometricKey: 'cadence_spm_series',
      packetKey: 'cadence_series',
      movementKey: 'cadence_spm_series',
    );
    final heartRates = _extractIntSeries(
      payload,
      biometricKey: 'heart_rate_bpm_series',
      packetKey: 'heart_rate_series',
    );
    final gpsPoints = _extractGps(payload);

    final gated = _pendingGate.evaluate(
      cadenceSpm: cadence,
      heartRates: heartRates,
      gpsPoints: gpsPoints,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      watchTypeCode: watchTypeCode,
    );
    if (gated != null) return gated;

    if (distanceKm <= 0 || gpsPoints.isEmpty) {
      return const JenaValidationResult(
        verified: false,
        decision: JenaDecision.rejectedUnknown,
        reason: 'GPS 궤적 또는 거리 데이터가 부족합니다.',
        valueTokenReward: 0,
      );
    }

    return const JenaValidationResult(
      verified: true,
      decision: JenaDecision.verified,
      reason: '순수 노력 러닝으로 Jena AI 검증이 완료되었습니다.',
      valueTokenReward: pureEffortValueReward,
    );
  }

  List<int> _extractIntSeries(
    Map<String, dynamic> payload, {
    required String biometricKey,
    required String packetKey,
    String? movementKey,
  }) {
    final values = <int>[];
    final biometrics = payload['biometrics'] as Map<String, dynamic>?;
    _appendInts(values, biometrics?[biometricKey]);
    final movement = payload['movement'] as Map<String, dynamic>?;
    if (movementKey != null) {
      _appendInts(values, movement?[movementKey]);
    }
    final packet = payload['activity_packet'] as Map<String, dynamic>?;
    _appendTimed(values, packet?[packetKey]);
    return values;
  }

  void _appendInts(List<int> out, Object? raw) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is num) out.add(item.round());
    }
  }

  void _appendTimed(List<int> out, Object? raw) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is Map) {
        final value = item['value'];
        if (value is num) out.add(value.round());
      } else if (item is num) {
        out.add(item.round());
      }
    }
  }

  List<({double lat, double lng, DateTime at})> _extractGps(
    Map<String, dynamic> payload,
  ) {
    final points = <({double lat, double lng, DateTime at})>[];
    final track = payload['gps_track'];
    if (track is List) {
      for (final item in track) {
        final parsed = _parseGpsItem(item);
        if (parsed != null) points.add(parsed);
      }
    }
    if (points.isNotEmpty) return points;
    final packet = payload['activity_packet'] as Map<String, dynamic>?;
    final trajectory = packet?['gps_trajectory'];
    if (trajectory is List) {
      for (final item in trajectory) {
        final parsed = _parseGpsItem(item);
        if (parsed != null) points.add(parsed);
      }
    }
    return points;
  }

  ({double lat, double lng, DateTime at})? _parseGpsItem(Object? item) {
    if (item is! Map) return null;
    final lat = (item['latitude'] as num?)?.toDouble();
    final lng = (item['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final rawAt = item['recorded_at'];
    DateTime at;
    if (rawAt is String) {
      at = DateTime.tryParse(rawAt) ?? DateTime.now();
    } else {
      at = DateTime.now();
    }
    return (lat: lat, lng: lng, at: at);
  }
}
