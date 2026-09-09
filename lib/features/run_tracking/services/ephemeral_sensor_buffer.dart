import '../../jena_validation/models/jena_validation_request.dart';

/// In-memory-only buffer for heart-rate and cadence samples.
///
/// Legal/ephemeral rule: contents must be destroyed after Jena validation.
/// Never serialize this buffer to Firestore or local durable storage.
class EphemeralSensorBuffer {  final List<int> _heartRates = [];
  final List<int> _cadenceSpm = [];

  void addHeartRate(int bpm) {
    _heartRates.add(bpm);
  }

  void addCadence(int spm) {
    _cadenceSpm.add(spm);
  }

  JenaValidationRequest buildRequest({
    required String activityId,
    required String userId,
    required double distanceKm,
    required int durationSeconds,
    required double gyroStabilityScore,
  }) {
    return JenaValidationRequest(
      activityId: activityId,
      userId: userId,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      heartRates: List.unmodifiable(_heartRates),
      cadenceSpm: List.unmodifiable(_cadenceSpm),
      gyroStabilityScore: gyroStabilityScore,
    );
  }

  /// Irreversibly clears biometric arrays from memory.
  void destroy() {    _heartRates.clear();
    _cadenceSpm.clear();
  }
}
