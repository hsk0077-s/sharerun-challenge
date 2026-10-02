import 'dart:async';

import 'package:flutter/foundation.dart';

import 'daily_metrics_account.dart';
import 'kst_calendar.dart';
import 'pedometer_health_cap.dart';
import 'pedometer_step_truth.dart';
import 'solo_pedometer_engine.dart';
import 'solo_pedometer_foreground.dart';

/// Single owner of today's step total. Lives in the main isolate.
///
/// Screen, keepalive, and the foreground isolate only feed raw
/// TYPE_STEP_COUNTER samples and Health readings. This object keeps the one
/// baseline and is the only writer of the notification and the step stores.
class TodaySteps {
  TodaySteps();

  static final instance = TodaySteps();

  Future<void> Function(
    int steps,
    double km, {
    required String dayKey,
    required String source,
    int? lastHealth,
  })? onCommit;

  var _steps = 0;
  var _anchorFloor = 0;
  var _baseline = 0;
  var _previousRaw = 0;
  var _baselineReady = false;
  var _offset = 0;
  var _offsetDayKey = '';
  var _dayKey = '';
  int? _health;
  final _listeners = <void Function()>[];

  /// Test clock. Production uses KST.
  @visibleForTesting
  String Function()? debugTodayKey;

  int get steps => _steps;

  int? get health => _health;

  void addListener(void Function() listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  String get _today => debugTodayKey?.call() ?? KstCalendar.dateKey();

  /// Raw counter from any listener. Duplicates and older samples do not add.
  void onRaw(int raw) {
    if (_rollIfNewDay()) {
      _baselineReady = false;
    }
    var sessionDelta = 0;
    if (!_baselineReady) {
      _baseline = raw;
      _baselineReady = true;
      _previousRaw = raw;
      _anchorFloor = PedometerStepTruth.clampDaily(_steps);
    } else if (raw < _previousRaw) {
      return;
    } else {
      final sample = PedometerStepTruth.acceptSensorDelta(
        raw: raw,
        baseline: _baseline,
        previousRaw: _previousRaw,
      );
      _previousRaw = raw;
      if (sample.rebase) {
        _baseline = raw;
        _anchorFloor = PedometerStepTruth.clampDaily(_steps);
        unawaited(_accept(_steps, source: 'sensor', healthToday: _health));
        return;
      }
      sessionDelta = sample.delta;
    }
    final todayKey = _today;
    final next = PedometerStepTruth.fromSensorEvent(
      raw: raw,
      healthBase: _anchorFloor,
      sessionDelta: sessionDelta,
      stepOffset: _offset,
      floorDayKey: _offsetDayKey.isEmpty ? null : _offsetDayKey,
      todayKey: todayKey,
    );
    unawaited(_accept(next, source: 'sensor', healthToday: _health));
  }

  /// Positive Health is a measurement. Zero and null are not.
  Future<void> onHealth(int? reading) async {
    _rollIfNewDay();
    if (reading == null || reading <= 0) return;
    _health = reading;
    unawaited(_persistHealth(reading));
    final daily = PedometerStepTruth.dailyFromSources(
      liveDaily: _steps,
      persistedToday: _steps,
      healthToday: reading,
    );
    await _accept(daily, source: 'health', healthToday: reading);
  }

  /// Startup / isolate restart. A stale store cannot climb above today's cap,
  /// and it cannot replace a live total that is already inside the lead.
  void restore(int stored, {int? health}) {
    _rollIfNewDay();
    if (health != null && health > 0) _health = health;
    final capped = PedometerHealthCap.cap(stored, _health);
    final healthNow = _health;
    final inflated = healthNow != null &&
        healthNow > 0 &&
        _steps > healthNow + PedometerStepTruth.healthLeadMax;
    if (_steps == 0 && capped > 0) {
      unawaited(_accept(capped, source: 'restore', healthToday: healthNow));
      return;
    }
    if (inflated) {
      unawaited(_accept(capped, source: 'restore', healthToday: healthNow));
    }
  }

  void loadOffset({required int offset, required String dayKey}) {
    final today = _today;
    if (dayKey == today) {
      _offset = offset;
      _offsetDayKey = today;
    } else {
      _offset = 0;
      _offsetDayKey = '';
    }
  }

  /// KST midnight. Yesterday's total and Health cap do not carry over.
  bool rollTo(String todayKey, {bool notify = true}) {
    if (_dayKey.isEmpty) {
      _dayKey = todayKey;
      return false;
    }
    if (_dayKey == todayKey) return false;
    _dayKey = todayKey;
    _steps = 0;
    _anchorFloor = 0;
    _baselineReady = false;
    _health = null;
    _offset = 0;
    _offsetDayKey = '';
    PedometerHealthCap.forget();
    if (notify) _notify();
    unawaited(_write(0, source: 'sensor'));
    return true;
  }

  bool _rollIfNewDay() => rollTo(_today);

  Future<void> _accept(
    int steps, {
    required String source,
    int? healthToday,
  }) async {
    final clampedFloor = PedometerStepTruth.clampDaily(_steps);
    if (clampedFloor != _steps) _steps = clampedFloor;
    var daily = PedometerStepTruth.clampDaily(steps);
    if (healthToday != null && healthToday > 0) {
      daily = PedometerStepTruth.dailyFromSources(
        liveDaily: daily,
        persistedToday: _steps,
        healthToday: healthToday,
      );
    }
    final healed = PedometerStepTruth.healthReplacesStored(
      stored: _steps,
      healthToday: healthToday,
      merged: daily,
    );
    if (daily < _steps && !healed) return;
    final raised = daily > _steps;
    if (!source.contains('sensor') && (raised || healed)) {
      _baselineReady = false;
    }
    if (!raised && !healed) return;
    _steps = daily;
    _notify();
    await _write(daily, source: source, healthToday: healthToday);
  }

  Future<void> _write(
    int daily, {
    required String source,
    int? healthToday,
  }) async {
    final health =
        (healthToday != null && healthToday > 0) ? healthToday : _health;
    final commit = onCommit?.call(
      daily,
      SoloPedometerEngine.kmFromSteps(daily),
      dayKey: _today,
      source: DailyMetricsAccount.normalizeSource(source, lastHealth: health),
      lastHealth: health,
    );
    try {
      final update = SoloPedometerForeground.update(
        steps: daily,
        targetKm: 3.0,
        healthToday: (health != null && health > 0) ? health : null,
      );
      if (commit != null) {
        await commit;
      }
      await update;
    } catch (e, st) {
      debugPrint('TodaySteps write: $e\n$st');
    }
  }

  Future<void> _persistHealth(int reading) async {
    try {
      final prefs = await PedometerHealthCap.fresh();
      await PedometerHealthCap.persist(
        prefs,
        todayKey: _today,
        health: reading,
      );
    } catch (_) {}
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  void debugAnchorToday() {
    _offset = 0;
    _offsetDayKey = _today;
    if (_dayKey.isEmpty) _dayKey = _today;
  }

  void debugSeed(int floor) {
    _steps = floor;
    _anchorFloor = floor;
  }

  /// Health merge used by the keepalive tests. Null health does not use
  /// [_health] and does not zero a stored day.
  Future<void> debugApplySources({
    required int? healthToday,
    int persisted = 0,
    int isolate = 0,
  }) {
    if (healthToday != null && healthToday > 0) _health = healthToday;
    final daily = PedometerStepTruth.dailyFromSources(
      liveDaily: healthToday ?? 0,
      persistedToday: persisted,
      isolateDaily: isolate,
      healthToday: healthToday,
    );
    return _accept(daily, source: 'health', healthToday: healthToday);
  }

  Future<void> debugOfferDaily(int steps) {
    return _accept(steps, source: 'sensor', healthToday: _health);
  }
}
