import 'route_point.dart';

class RunTelemetry {
  const RunTelemetry({
    required this.distanceKm,
    required this.durationSeconds,
    required this.currentHeartRate,
    required this.currentCadenceSpm,
    required this.gyroStabilityScore,
    this.routePoints = const [],
  });

  final double distanceKm;
  final int durationSeconds;
  final int? currentHeartRate;
  final int? currentCadenceSpm;
  final double gyroStabilityScore;
  final List<RoutePoint> routePoints;

  RunTelemetry copyWith({
    double? distanceKm,
    int? durationSeconds,
    int? currentHeartRate,
    int? currentCadenceSpm,
    double? gyroStabilityScore,
    List<RoutePoint>? routePoints,
  }) {
    return RunTelemetry(
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      currentCadenceSpm: currentCadenceSpm ?? this.currentCadenceSpm,
      gyroStabilityScore: gyroStabilityScore ?? this.gyroStabilityScore,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  static const empty = RunTelemetry(
    distanceKm: 0,
    durationSeconds: 0,
    currentHeartRate: null,
    currentCadenceSpm: null,
    gyroStabilityScore: 0,
    routePoints: [],
  );
}
