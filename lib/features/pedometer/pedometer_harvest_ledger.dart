/// KST-day harvest watermark helpers.
///
/// Pending SHARE is 1 per 100 unclaimed steps (floor). The claimed-step
/// watermark must survive screen dispose/re-enter so the same floor amount
/// cannot be harvested twice.
abstract final class PedometerHarvestLedger {
  static const stepsPerShare = 100;

  static String todayClaimedKey(String dateKey) => '${dateKey}_claimed_steps';

  static String prefix({required String uid, required String dateKey}) =>
      'solo_pedo_${uid}_$dateKey';

  static int pendingShareFloor({
    required int steps,
    required int claimedSteps,
  }) {
    final diff = steps - claimedSteps;
    if (diff <= 0) return 0;
    return diff ~/ stepsPerShare;
  }

  static double pendingShareExact({
    required int steps,
    required int claimedSteps,
  }) {
    final diff = steps - claimedSteps;
    return diff > 0 ? diff / stepsPerShare : 0.0;
  }

  /// Merge watermarks. Never drop a stored claim to 0 just because steps
  /// have not been restored yet (`steps == 0`).
  static int coalesceClaimed({
    required int current,
    required int fromTodayKey,
    required int fromPrefix,
    int steps = 0,
  }) {
    var claimed = current;
    if (fromTodayKey > claimed) claimed = fromTodayKey;
    if (fromPrefix > claimed) claimed = fromPrefix;
    if (claimed < 0) claimed = 0;
    if (steps > 0 && claimed > steps) claimed = steps;
    return claimed;
  }
}
