import 'dart:math' as math;

import 'pedometer_harvest_ledger.dart';

/// Walking-challenge daily steps and the shade notification must share one
/// number. Midnight [stepOffset] applies only to raw TYPE_STEP_COUNTER, never
/// to Health-today, isolate, or already-persisted daily counters.
abstract final class PedometerStepTruth {
  static const logPrefix = '[STEP]';

  /// Old overflow / debug clamp. A real KST day cannot reach this; treat it
  /// as a stub or since-boot dump, not a step count. Never display it.
  static const overflowSentinel = 999999;

  /// Hard KST-day ceiling (~22.5 km at this app's 0.75 m stride).
  ///
  /// 100_000 (~75 km) still let an 86,626 TYPE_STEP_COUNTER since-boot dump
  /// through, and that dump then won `max()` on both the walking UI and the
  /// shade. A hard athletic day in the low tens of thousands still passes.
  static const plausibleDailyMax = 30000;

  /// Largest increase one TYPE_STEP_COUNTER sample may add.
  ///
  /// A real walk arrives as hardware batches of about 50–100 steps. One
  /// jump bigger than that off a near-zero sample is the boot counter, not
  /// steps since attach. On SM-A245N the first sample can be 0 and the next
  /// the since-boot total (~2,000–9,999), which is under the old 10,000
  /// cliff. A real day still crosses that total across many small samples.
  static const hardwareBatchMax = 100;

  /// Previous reading at or below this is a fresh/zero baseline (0, then
  /// the since-boot total), not an anchor taken at that total.
  static const nearZeroBaselineMax = 1000;

  /// Already-daily counters above [plausibleDailyMax] (or negative) are
  /// poison: the 999999 stub, or a since-boot total that was stored as today.
  static bool isPoisonDaily(int steps) =>
      steps < 0 || steps > plausibleDailyMax;

  /// Health Connect, isolate `_stepsKey`, and UI `_steps` are already daily.
  /// Poison becomes 0 so it cannot win a `max()` against a real reading.
  static int clampDaily(int steps) => isPoisonDaily(steps) ? 0 : steps;

  /// True when [raw] jumped from [baseline] like a since-boot dump.
  ///
  /// [baseline] must be the previous sample, not the start-of-session anchor.
  /// A walk from 0 to 15,000 in small samples never looks like one jump.
  static bool isSinceBootDump({required int raw, required int baseline}) {
    final jump = raw - baseline;
    if (jump <= 0) return false;
    if (jump > plausibleDailyMax) return true;
    return baseline <= nearZeroBaselineMax && jump > hardwareBatchMax;
  }

  /// One TYPE_STEP_COUNTER sample.
  ///
  /// [delta] is `raw - baseline` when that distance is a real walk (already
  /// clamped). [rebase] means [raw] is a since-boot dump: keep [delta] at 0
  /// and move the caller's baseline to [raw] so the next sample can count.
  /// [previousRaw] defaults to [baseline] (the first counted sample).
  static ({int delta, bool rebase}) acceptSensorDelta({
    required int raw,
    required int baseline,
    int? previousRaw,
  }) {
    final previous = previousRaw ?? baseline;
    if (isSinceBootDump(raw: raw, baseline: previous)) {
      return (delta: 0, rebase: true);
    }
    final session = raw - baseline;
    if (session <= 0) return (delta: 0, rebase: false);
    return (delta: clampDaily(session), rebase: false);
  }

  /// Highest *plausible* daily reading wins. Do not subtract a sensor offset
  /// here. Clamp each source first so a 999999 stub or an 86,626 since-boot
  /// dump cannot outrank a real day. Poison (clamped to 0) loses to a sane
  /// lower total; a real same-day count still only moves upward.
  static int dailyFromSources({
    required int liveDaily,
    int persistedToday = 0,
    int isolateDaily = 0,
  }) {
    return math.max(
      clampDaily(liveDaily),
      math.max(clampDaily(persistedToday), clampDaily(isolateDaily)),
    );
  }

  /// Pedometer event → today's steps.
  ///
  /// * `healthBase + sessionDelta` is the historical shake/debug path
  ///   (Samsung TYPE_STEP_COUNTER increments on a light shake).
  /// * `raw - stepOffset` is used only when midnight (or QA init) snapshotted
  ///   the cumulative sensor. Offset `0` must not dump since-boot totals.
  ///   A small positive offset (yesterday's daily, QA init, or a rollover
  ///   that stored a step count instead of the hardware counter) is not that
  ///   snapshot: `raw - offset` then sits more than one hardware batch above
  ///   session / Health and is dropped.
  ///
  /// When [floorDayKey] and [todayKey] are both set and they differ, the
  /// floor, session, and offset still belong to the previous KST day.
  /// `max(yesterday, raw - oldOffset)` is yesterday's total (the
  /// 5377 → 0 → 5377 flash). Drop that sample; the next event after the
  /// new offset is snapshotted is today.
  static int fromSensorEvent({
    required int raw,
    required int healthBase,
    required int sessionDelta,
    required int stepOffset,
    String? floorDayKey,
    String? todayKey,
  }) {
    final staleDay =
        floorDayKey != null && todayKey != null && floorDayKey != todayKey;
    final base = staleDay ? 0 : healthBase;
    final delta = staleDay ? 0 : sessionDelta;
    final offset = staleDay ? 0 : stepOffset;
    final fromSession = clampDaily(base + delta);
    final fromRaw = _dailyFromHardwareOffset(
      raw: raw,
      offset: offset,
      sessionToday: base + delta,
    );
    return math.max(fromSession, fromRaw);
  }

  /// `raw - offset` when [offset] is today's TYPE_STEP_COUNTER snapshot.
  ///
  /// A gap of more than [hardwareBatchMax] above the session/Health floor
  /// means the offset is not that snapshot, or [raw] is a since-boot dump.
  /// The corroborated floor wins; a real Health day that already matches
  /// still does.
  static int _dailyFromHardwareOffset({
    required int raw,
    required int offset,
    required int sessionToday,
  }) {
    if (offset <= 0 || raw < offset) return 0;
    final candidate = raw - offset;
    if (candidate - sessionToday > hardwareBatchMax) return 0;
    return clampDaily(candidate);
  }

  /// Isolate / prefs cache stamped on [cachedDayKey]. A missing stamp keeps
  /// the value (legacy store). A previous KST day must not be merged back
  /// onto today after the midnight zero.
  static int cachedDailyIfSameDay({
    required int cachedSteps,
    required String? cachedDayKey,
    required String todayKey,
  }) {
    if (cachedDayKey != null &&
        cachedDayKey.isNotEmpty &&
        cachedDayKey != todayKey) {
      return 0;
    }
    return clampDaily(cachedSteps);
  }

  /// In-memory walking total stamped on [memoryDayKey].
  ///
  /// Unlike [cachedDailyIfSameDay], a missing stamp is not today. After KST
  /// midnight the hero must not keep yesterday (39) just because it is larger
  /// than today's pedometer (0). The notification isolate already baselines
  /// today; this is the UI side of that rule.
  static int inMemoryDailyIfSameDay({
    required int inMemorySteps,
    required String memoryDayKey,
    required String todayKey,
  }) {
    if (memoryDayKey.isEmpty || memoryDayKey != todayKey) return 0;
    return clampDaily(inMemorySteps);
  }

  /// Prefs for [todayKey] win, except a same-day in-memory count that is
  /// already ahead of disk. A previous KST day's memory must not win.
  static int mergeStoredDaily({
    required int storedToday,
    required int inMemorySteps,
    required String memoryDayKey,
    required String todayKey,
  }) {
    final stored = clampDaily(storedToday);
    final memory = inMemoryDailyIfSameDay(
      inMemorySteps: inMemorySteps,
      memoryDayKey: memoryDayKey,
      todayKey: todayKey,
    );
    return memory > stored ? memory : stored;
  }

  /// After `FlutterJNI was detached` / EventChannel `step_count` death,
  /// resume and init always rebind; error/done paths honor a short cooldown.
  static bool shouldRebindSensor({
    required DateTime now,
    DateTime? lastRebindAt,
    required bool force,
    Duration cooldown = const Duration(seconds: 2),
  }) {
    if (force) return true;
    if (lastRebindAt == null) return true;
    return now.difference(lastRebindAt) >= cooldown;
  }

  static String sourceLog({
    required String source,
    required int daily,
    int? raw,
    int? offset,
    int? healthBase,
    int? sessionDelta,
    int? ui,
  }) {
    final buf = StringBuffer('$logPrefix source=$source daily=$daily');
    if (raw != null) buf.write(' raw=$raw');
    if (offset != null) buf.write(' offset=$offset');
    if (healthBase != null) buf.write(' healthBase=$healthBase');
    if (sessionDelta != null) buf.write(' sessionDelta=$sessionDelta');
    if (ui != null) buf.write(' ui=$ui');
    return buf.toString();
  }
}

/// Foreground shade copy. [dailySteps] is the same counter as the walking UI.
///
/// SHARE here is harvestable, not already credited: 1 per 100 steps, daily
/// cap [PedometerHarvestLedger.dailyShareCap]. Never say it was acquired
/// before a harvest.
abstract final class WalkingChallengeNotificationCopy {
  static const dailyGoal = 4500;

  static const harvestRule = '(100걸음당 1, 하루 최대 60)';

  /// Approximate unharvested SHARE for [dailySteps]. Already-claimed steps
  /// are excluded when [claimedSteps] is known; otherwise this is the
  /// upper bound ("약").
  static String harvestHint(int dailySteps, {int claimedSteps = 0}) {
    final currentSteps = PedometerStepTruth.clampDaily(dailySteps);
    final approx = PedometerHarvestLedger.pendingShareFloor(
      steps: currentSteps,
      claimedSteps: claimedSteps,
    );
    return '${_comma(currentSteps)}보 · 줍기 가능 약 $approx SHARE $harvestRule';
  }

  static ({String title, String body}) fromDailySteps(
    int dailySteps, {
    int claimedSteps = 0,
  }) {
    final currentSteps = PedometerStepTruth.clampDaily(dailySteps);
    final body = harvestHint(currentSteps, claimedSteps: claimedSteps);
    if (currentSteps >= dailyGoal) {
      return (title: '오늘 걸음 이어가는 중 🚶', body: body);
    }
    if (currentSteps >= 1500) {
      return (title: '숲길 걷는 중 👟', body: body);
    }
    return (title: '셰어런 챌린지 대기 중 🎯', body: body);
  }

  /// Morning, lunch, and evening alarms repeat every day at the same clock
  /// time, so they must not freeze a pending total captured when scheduled.
  static String goldenMorningBody() =>
      '오늘 걸음은 100걸음당 1 SHARE, 하루 최대 60까지 주울 수 있어요.';

  static String goldenLunchBody() =>
      '아직 안 주운 SHARE가 있으면 걷기 화면에서 주울 수 있어요. 100걸음당 1, 하루 최대 60.';

  static String goldenEveningBody() =>
      '아직 안 주운 SHARE는 자정에 초기화돼요. 이미 지갑에 넣은 잔액은 그대로예요.';

  static String _comma(int n) {
    final raw = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    return n < 0 ? '-$buf' : '$buf';
  }
}
