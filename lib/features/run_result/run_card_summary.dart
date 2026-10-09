import 'dart:math' as math;

import '../run_tracking/models/route_point.dart';

/// 공유 카드용 요약. 좌표나 센서 원본은 담지 않고, 기기 안에서만 쓴다.

/// 1km씩 끊은 구간 페이스(초/km). 끝에 남은 1km 미만은 넣지 않는다.
List<int> kmSplitPaceSeconds(List<RoutePoint> points) {
  if (points.length < 2) return const [];
  final splits = <int>[];
  var distance = 0.0;
  var nextBoundary = 1000.0;
  var lastBoundaryElapsed = 0.0;
  final start = points.first.recordedAt;
  for (var i = 1; i < points.length; i++) {
    final from = points[i - 1];
    final to = points[i];
    final step = _meters(from, to);
    if (step <= 0) continue;
    final elapsedFrom =
        from.recordedAt.difference(start).inMilliseconds / 1000.0;
    final elapsedTo = to.recordedAt.difference(start).inMilliseconds / 1000.0;
    while (distance + step >= nextBoundary) {
      final ratio = (nextBoundary - distance) / step;
      final elapsed = elapsedFrom + (elapsedTo - elapsedFrom) * ratio;
      final pace = elapsed - lastBoundaryElapsed;
      if (pace > 0) splits.add(pace.round());
      lastBoundaryElapsed = elapsed;
      nextBoundary += 1000.0;
    }
    distance += step;
  }
  return splits;
}

/// 막대가 너무 많아지지 않게 [maxBars]개 이하로 묶는다(묶음 평균).
List<int> bucketSplitPaces(List<int> paces, {int maxBars = 12}) {
  if (paces.length <= maxBars) return paces;
  final out = <int>[];
  for (var b = 0; b < maxBars; b++) {
    final from = (b * paces.length / maxBars).floor();
    final to = ((b + 1) * paces.length / maxBars).floor();
    final slice = paces.sublist(from, math.max(to, from + 1));
    out.add((slice.reduce((a, c) => a + c) / slice.length).round());
  }
  return out;
}

/// 평균 심박. 사람의 범위를 벗어난 값은 버리고, 남은 값이 없으면 null.
int? averageHeartRateOf(List<int> samples) {
  final valid = samples.where((bpm) => bpm >= 30 && bpm <= 230).toList();
  if (valid.isEmpty) return null;
  return (valid.reduce((a, b) => a + b) / valid.length).round();
}

double _meters(RoutePoint a, RoutePoint b) {
  const radius = 6371000.0;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLat = lat2 - lat1;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return 2 * radius * math.asin(math.min(1.0, math.sqrt(h)));
}
