import 'dart:math' as math;

import 'models/route_point.dart';

/// Live pace labels. Average pace is time divided by distance. Current pace
/// uses only the GPS points already on the telemetry. Nothing here is sent
/// to verification.
abstract final class RunLivePace {
  /// Under this distance the average is not a pace yet.
  static const minAverageDistanceKm = 0.05;

  static const currentWindow = Duration(seconds: 20);
  static const minCurrentSpan = Duration(seconds: 10);
  static const minCurrentMeters = 30.0;
  static const minCurrentPoints = 3;

  /// A segment this long and faster than [maxSegmentMps] is a GPS glitch.
  static const minSegmentMeters = 8.0;
  static const maxSegmentMps = 8.0;

  static const unavailable = '--';

  static String averageLabel({
    required double distanceKm,
    required int durationSeconds,
  }) {
    final seconds = averageSecondsPerKm(
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
    );
    if (seconds == null) return unavailable;
    return formatSecondsPerKm(seconds);
  }

  /// Whole seconds per kilometre, or null when the distance is under
  /// [minAverageDistanceKm] or the clock has not moved.
  static int? averageSecondsPerKm({
    required double distanceKm,
    required int durationSeconds,
  }) {
    if (distanceKm < minAverageDistanceKm || durationSeconds <= 0) {
      return null;
    }
    final sec = durationSeconds / distanceKm;
    if (!sec.isFinite || sec <= 0) return null;
    final rounded = sec.round();
    if (rounded <= 0) return null;
    return rounded;
  }

  /// `5'30"/km`. Minutes are not padded. Seconds are.
  static String formatSecondsPerKm(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safe ~/ 60;
    final seconds = safe % 60;
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"/km";
  }

  static String currentLabel(List<RoutePoint> points) {
    final seconds = currentSecondsPerKm(points);
    if (seconds == null) return unavailable;
    return formatSecondsPerKm(seconds);
  }

  /// Pace over the last [currentWindow] of [points], or null when that
  /// window is too short, too still, or contains a GPS jump.
  static int? currentSecondsPerKm(List<RoutePoint> points) {
    if (points.length < minCurrentPoints) return null;
    final sorted = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final end = sorted.last.recordedAt;
    final windowStart = end.subtract(currentWindow);
    final window = [
      for (final point in sorted)
        if (!point.recordedAt.isBefore(windowStart)) point,
    ];
    if (window.length < minCurrentPoints) return null;
    final span = window.last.recordedAt.difference(window.first.recordedAt);
    if (span < minCurrentSpan) return null;

    var meters = 0.0;
    for (var i = 1; i < window.length; i++) {
      final dt = window[i]
              .recordedAt
              .difference(window[i - 1].recordedAt)
              .inMilliseconds /
          1000.0;
      final segment = haversineMeters(
        window[i - 1].latitude,
        window[i - 1].longitude,
        window[i].latitude,
        window[i].longitude,
      );
      if (dt <= 0) {
        if (segment >= minSegmentMeters) return null;
        continue;
      }
      if (segment >= minSegmentMeters && segment / dt > maxSegmentMps) {
        return null;
      }
      meters += segment;
    }
    if (meters < minCurrentMeters) return null;
    final seconds = span.inMilliseconds / 1000.0;
    if (seconds <= 0) return null;
    final secPerKm = seconds / (meters / 1000.0);
    if (!secPerKm.isFinite || secPerKm <= 0) return null;
    final rounded = secPerKm.round();
    if (rounded <= 0) return null;
    return rounded;
  }

  static double haversineMeters(
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

  static double _rad(double deg) => deg * math.pi / 180;
}

/// `00:12`, or `1:01:05` once an hour has passed. Same shape the run
/// screen has always used for the first hour.
String formatRunClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final remaining = safe % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = remaining.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$mm:$ss';
  return '$mm:$ss';
}
