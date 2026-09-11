import 'dart:math' as math;

/// Walking-challenge daily steps and the shade notification must share one
/// number. Midnight [stepOffset] applies only to raw TYPE_STEP_COUNTER, never
/// to Health-today, isolate, or already-persisted daily counters.
abstract final class PedometerStepTruth {
  static const logPrefix = '[STEP]';

  /// Health Connect, isolate `_stepsKey`, and UI `_steps` are already daily.
  static int clampDaily(int steps) => steps.clamp(0, 999999);

  /// Highest daily reading wins. Do not subtract a sensor offset here.
  static int dailyFromSources({
    required int liveDaily,
    int persistedToday = 0,
    int isolateDaily = 0,
  }) {
    return clampDaily(
      math.max(liveDaily, math.max(persistedToday, isolateDaily)),
    );
  }

  /// Pedometer event → today's steps.
  ///
  /// * `healthBase + sessionDelta` is the historical shake/debug path
  ///   (Samsung TYPE_STEP_COUNTER increments on a light shake).
  /// * `raw - stepOffset` is used only when midnight (or QA init) snapshotted
  ///   the cumulative sensor. Offset `0` must not dump since-boot totals.
  static int fromSensorEvent({
    required int raw,
    required int healthBase,
    required int sessionDelta,
    required int stepOffset,
  }) {
    final fromSession = clampDaily(healthBase + sessionDelta);
    final fromRaw =
        stepOffset > 0 ? clampDaily(raw - stepOffset) : 0;
    return math.max(fromSession, fromRaw);
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
abstract final class WalkingChallengeNotificationCopy {
  static const dailyGoal = 4500;
  static const bonusGoal = 10000;

  static ({String title, String body}) fromDailySteps(int dailySteps) {
    final currentSteps = PedometerStepTruth.clampDaily(dailySteps);
    if (currentSteps >= dailyGoal) {
      return (
        title: '챌린지 완주 성공! 🎉',
        body:
            '60 SHARE 획득 완료! 만보 보너스(+20 SHARE)를 향해 전진 중 (${_comma(currentSteps)}/$_bonusGoalComma보)',
      );
    }
    if (currentSteps >= 1500) {
      return (
        title: '숲길 걷는 중 👟',
        body:
            '현재 ${_comma(currentSteps)}보 · 마일스톤 진행 중 (다음 목표: ${_comma(dailyGoal)}보)',
      );
    }
    return (
      title: '셰어런 챌린지 대기 중 🎯',
      body:
          '오늘의 숲길 산책을 시작해 보세요! (${_comma(currentSteps)} / ${_comma(dailyGoal)}보)',
    );
  }

  static const _bonusGoalComma = '10,000';

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
