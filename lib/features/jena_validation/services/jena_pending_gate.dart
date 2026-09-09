import 'dart:math' as math;

import '../../../data/models/activity_model.dart';
import '../models/jena_validation_result.dart';

/// Jena AI 어뷰징 1차 게이트 — cadence / HR / GPS 텔레포트.
class JenaPendingGate {
  const JenaPendingGate();

  static const double _runningMaxMps = 8.0;
  static const double _vehicleMps = 15.0;
  static const double _hrFlatCv = 0.035;
  static const int _hrFlatRangeBpm = 3;

  JenaValidationResult? evaluate({
    required List<int> cadenceSpm,
    required List<int> heartRates,
    required List<({double lat, double lng, DateTime at})> gpsPoints,
    required double distanceKm,
    required int durationSeconds,
    String watchTypeCode = 'none',
  }) {
    if (_cadenceMissingOrZero(cadenceSpm, watchTypeCode: watchTypeCode)) {
      return const JenaValidationResult(
        verified: false,
        decision: JenaDecision.pending,
        reason: '케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다.',
        valueTokenReward: 0,
      );
    }

    if (_heartRateFlatAgainstPace(
      heartRates: heartRates,
      gpsPoints: gpsPoints,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
    )) {
      return const JenaValidationResult(
        verified: false,
        decision: JenaDecision.pending,
        reason: '심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다.',
        valueTokenReward: 0,
      );
    }

    final gpsVerdict = _gpsTeleportVerdict(gpsPoints);
    if (gpsVerdict == ActivityStatus.failed) {
      return const JenaValidationResult(
        verified: false,
        decision: JenaDecision.rejectedUnknown,
        reason: 'GPS 오차 범위를 넘는 순간 이동 속도가 검출되어 기록이 거절되었습니다.',
        valueTokenReward: 0,
      );
    }
    if (gpsVerdict == ActivityStatus.pending) {
      return const JenaValidationResult(
        verified: false,
        decision: JenaDecision.pending,
        reason: '비정상적인 GPS 순간 속도가 검출되어 기록이 보류되었습니다.',
        valueTokenReward: 0,
      );
    }

    return null;
  }

  bool _cadenceMissingOrZero(
    List<int> cadenceSpm, {
    required String watchTypeCode,
  }) {
    if (cadenceSpm.isEmpty) return true;
    if (watchTypeCode == 'none' && cadenceSpm.every((v) => v <= 0)) {
      return true;
    }
    return cadenceSpm.every((v) => v <= 0);
  }

  bool _heartRateFlatAgainstPace({
    required List<int> heartRates,
    required List<({double lat, double lng, DateTime at})> gpsPoints,
    required double distanceKm,
    required int durationSeconds,
  }) {
    final moving = distanceKm >= 0.4 || durationSeconds >= 60;
    if (!moving) return false;

    if (heartRates.isEmpty) return true;
    final positive = heartRates.where((v) => v > 0).toList();
    if (positive.length < 3) return true;

    final mean = positive.reduce((a, b) => a + b) / positive.length;
    if (mean <= 0) return true;
    var variance = 0.0;
    for (final v in positive) {
      final d = v - mean;
      variance += d * d;
    }
    variance /= positive.length;
    final stddev = math.sqrt(variance);
    final cv = stddev / mean;
    final range = (positive.reduce(math.max) - positive.reduce(math.min)).abs();
    final hrFlat = cv < _hrFlatCv || range <= _hrFlatRangeBpm;
    if (!hrFlat) return false;

    final paceIncreased = _paceIncreased(gpsPoints) || distanceKm >= 0.8;
    return paceIncreased;
  }

  bool _paceIncreased(List<({double lat, double lng, DateTime at})> gpsPoints) {
    if (gpsPoints.length < 4) return false;
    final mid = gpsPoints.length ~/ 2;
    final first = _meanSpeedMps(gpsPoints.sublist(0, mid));
    final second = _meanSpeedMps(gpsPoints.sublist(mid));
    if (first <= 0) return second > 1.5;
    return second >= first * 1.2;
  }

  double _meanSpeedMps(List<({double lat, double lng, DateTime at})> points) {
    if (points.length < 2) return 0;
    var totalMeters = 0.0;
    var totalSeconds = 0.0;
    for (var i = 1; i < points.length; i++) {
      final dt = points[i].at.difference(points[i - 1].at).inMilliseconds / 1000;
      if (dt <= 0) continue;
      totalMeters += _haversineMeters(
        points[i - 1].lat,
        points[i - 1].lng,
        points[i].lat,
        points[i].lng,
      );
      totalSeconds += dt;
    }
    if (totalSeconds <= 0) return 0;
    return totalMeters / totalSeconds;
  }

  ActivityStatus? _gpsTeleportVerdict(
    List<({double lat, double lng, DateTime at})> gpsPoints,
  ) {
    if (gpsPoints.length < 2) return null;
    var sawPending = false;
    for (var i = 1; i < gpsPoints.length; i++) {
      final dt = gpsPoints[i].at.difference(gpsPoints[i - 1].at).inMilliseconds /
          1000;
      if (dt <= 0.2) continue;
      final meters = _haversineMeters(
        gpsPoints[i - 1].lat,
        gpsPoints[i - 1].lng,
        gpsPoints[i].lat,
        gpsPoints[i].lng,
      );
      final mps = meters / dt;
      if (mps >= _vehicleMps) return ActivityStatus.failed;
      if (mps >= _runningMaxMps) sawPending = true;
    }
    return sawPending ? ActivityStatus.pending : null;
  }

  double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earth = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earth * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  double _rad(double deg) => deg * math.pi / 180;
}
