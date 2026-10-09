import '../../jena_validation/models/jena_validation_request.dart';
import '../../run_result/run_card_summary.dart';

/// In-memory-only buffer for heart-rate and cadence samples.
///
/// Legal/ephemeral rule: contents must be destroyed after Jena validation.
/// Never serialize this buffer to Firestore or local durable storage.
class EphemeralSensorBuffer {  final List<int> _heartRates = [];
  final List<int> _cadenceSpm = [];

  void addHeartRate(int bpm) {
    _heartRates.add(bpm);
  }

  /// 공유 카드용 평균 심박 한 개. 샘플은 밖으로 내보내지 않는다.
  int? get averageHeartRate => averageHeartRateOf(_heartRates);

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
