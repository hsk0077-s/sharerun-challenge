import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_point.dart';

/// 목표 페이스 기준 고스트 위치를 유저 경로 위에 보간.
abstract final class GhostPaceMatcher {
  static LatLng? positionAt({
    required List<RoutePoint> routePoints,
    required int elapsedSeconds,
    required double ghostPaceSecPerKm,
  }) {
    if (routePoints.isEmpty || elapsedSeconds <= 0 || ghostPaceSecPerKm <= 0) {
      return null;
    }
    final ghostMeters = (elapsedSeconds / ghostPaceSecPerKm) * 1000.0;
    return _interpolate(routePoints, ghostMeters);
  }

  static LatLng? _interpolate(List<RoutePoint> points, double targetMeters) {
    if (targetMeters <= 0) {
      final first = points.first;
      return LatLng(first.latitude, first.longitude);
    }
    var acc = 0.0;
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final seg = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
      if (seg <= 0) continue;
      if (acc + seg >= targetMeters) {
        final t = (targetMeters - acc) / seg;
        return LatLng(
          prev.latitude + (curr.latitude - prev.latitude) * t,
          prev.longitude + (curr.longitude - prev.longitude) * t,
        );
      }
      acc += seg;
    }
    final last = points.last;
    return LatLng(last.latitude, last.longitude);
  }
}
