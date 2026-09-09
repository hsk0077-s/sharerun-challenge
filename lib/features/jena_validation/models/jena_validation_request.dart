class JenaValidationRequest {
  const JenaValidationRequest({
    required this.activityId,
    required this.userId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.heartRates,
    required this.cadenceSpm,
    required this.gyroStabilityScore,
  });

  final String activityId;
  final String userId;
  final double distanceKm;
  final int durationSeconds;
  final List<int> heartRates;
  final List<int> cadenceSpm;
  final double gyroStabilityScore;

  Map<String, dynamic> toJson() {
    return {
      'activity_id': activityId,
      'user_id': userId,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'heart_rates': heartRates,
      'cadence_spm': cadenceSpm,
      'gyro_stability_score': gyroStabilityScore,
    };
  }
}
