/// KST-day harvest watermark helpers.
///
/// Pending SHARE is 10 per 100 unclaimed steps (floor), capped at the daily
/// walking benefit ([dailyShareCap]). The claimed-step watermark must survive
/// screen dispose/re-enter so the same floor amount cannot be harvested twice.
abstract final class PedometerHarvestLedger {
  /// 10 steps = 1 SHARE, so 100 steps = 10 SHARE.
  static const stepsPerShare = 10;

  /// Snail 3km promo / walking UI denominator. Harvest and "오늘의 채굴"
  /// must never exceed this, even when the step source overflows.
  static const dailyShareCap = 600;

  static const stepsForDailyCap = dailyShareCap * stepsPerShare;

  static const globalClaimedKey = 'solo_pedo_claimed_steps';
  static const globalClaimedDateKey = 'solo_pedo_claimed_date';

  /// Process-lifetime copy of today's watermark. The walking screen's
  /// `_claimedSteps` dies on dispose; this is what a remount reads before
  /// prefs, and what survives a stale prefs read of 0.
  static String _sessionDate = '';
  static int _sessionClaimed = 0;

  static String todayClaimedKey(String dateKey) => '${dateKey}_claimed_steps';

  static void commitSession({required String dateKey, required int claimed}) {
    _sessionDate = dateKey;
    final next = claimed < 0 ? 0 : claimed;
    _sessionClaimed = next > stepsForDailyCap ? stepsForDailyCap : next;
  }

  static int sessionClaimed(String dateKey) {
    if (dateKey.isEmpty || _sessionDate != dateKey) return 0;
    return _sessionClaimed;
  }

  /// True when at least one full SHARE (10 steps) is still unclaimed.
  /// A leftover under 10 steps is not another 줍기.
  static bool pickupReady({required int steps, required int claimedSteps}) {
    return pendingShareFloor(steps: steps, claimedSteps: claimedSteps) >= 1;
  }

  static String prefix({required String uid, required String dateKey}) =>
      'solo_pedo_${uid}_$dateKey';

  /// Today's mined SHARE from the server harvest doc, not local steps.
  static int displayHarvestedShare({
    required String dateKey,
    required int harvestedShare,
    required String todayKey,
  }) {
    if (dateKey.isEmpty || dateKey != todayKey) return 0;
    if (harvestedShare <= 0) return 0;
    return harvestedShare > dailyShareCap ? dailyShareCap : harvestedShare;
  }

  /// SHARE already counted toward today's walking benefit.
  static int todayMinedShare({required int claimedSteps}) {
    if (claimedSteps <= 0) return 0;
    final mined = claimedSteps ~/ stepsPerShare;
    return mined > dailyShareCap ? dailyShareCap : mined;
  }

  static int _remainingShare(int claimedSteps) =>
      dailyShareCap - todayMinedShare(claimedSteps: claimedSteps);

  static int pendingShareFloor({
    required int steps,
    required int claimedSteps,
  }) {
    final remaining = _remainingShare(claimedSteps);
    if (remaining <= 0) return 0;
    final diff = steps - claimedSteps;
    if (diff <= 0) return 0;
    final raw = diff ~/ stepsPerShare;
    return raw > remaining ? remaining : raw;
  }

  static double pendingShareExact({
    required int steps,
    required int claimedSteps,
  }) {
    final remaining = _remainingShare(claimedSteps);
    if (remaining <= 0) return 0.0;
    final diff = steps - claimedSteps;
    if (diff <= 0) return 0.0;
    final raw = diff / stepsPerShare;
    return raw > remaining ? remaining.toDouble() : raw;
  }

  /// Advance the watermark only through the steps that fill today's cap.
  /// Overflow (e.g. 999999) must not be stored or sent as claimed_steps.
  static int claimedAfterHarvest({
    required int steps,
    required int claimedSteps,
  }) {
    final toClaim = pendingShareFloor(
      steps: steps,
      claimedSteps: claimedSteps,
    );
    if (toClaim <= 0) {
      return claimedSteps < 0 ? 0 : claimedSteps;
    }
    final next = claimedSteps + toClaim * stepsPerShare;
    if (next < 0) return 0;
    if (next > stepsForDailyCap) return stepsForDailyCap;
    return next > steps ? steps : next;
  }

  /// Merge watermarks. Never drop a stored claim to 0 just because steps
  /// have not been restored yet (`steps == 0`).
  static int coalesceClaimed({
    required int current,
    required int fromTodayKey,
    required int fromPrefix,
    int fromGlobal = 0,
    int fromSession = 0,
    int steps = 0,
  }) {
    var claimed = current;
    if (fromTodayKey > claimed) claimed = fromTodayKey;
    if (fromPrefix > claimed) claimed = fromPrefix;
    if (fromGlobal > claimed) claimed = fromGlobal;
    if (fromSession > claimed) claimed = fromSession;
    if (claimed < 0) claimed = 0;
    if (steps > 0 && claimed > steps) claimed = steps;
    if (claimed > stepsForDailyCap) claimed = stepsForDailyCap;
    return claimed;
  }

  static int claimedFromGlobal({
    required String? storedDate,
    required int storedClaimed,
    required String todayKey,
  }) {
    if (storedDate != todayKey) return 0;
    return storedClaimed < 0 ? 0 : storedClaimed;
  }
}
