import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/src_onboarding_controller.dart';
import 'kst_calendar.dart';
import 'pedometer_step_truth.dart';
import 'solo_pedometer_engine.dart';
import 'solo_pedometer_foreground.dart';

/// Process-level walking steps: survives Walking Challenge dispose/rebuild
/// and rebinds after `FlutterJNI was detached` on `step_count`.
class WalkingStepKeepAlive with WidgetsBindingObserver {
  WalkingStepKeepAlive({required this.onDaily});

  final Future<void> Function(int steps, double km) onDaily;

  final Health _health = Health();
  StreamSubscription<StepCount>? _sub;
  Timer? _healthTimer;
  var _floor = 0;

  /// Daily total captured when the sensor baseline was taken. Session delta
  /// is cumulative since that sample, so it must not be added to a floor
  /// that already includes earlier batches.
  var _anchorFloor = 0;
  var _baseline = 0;
  var _previousRaw = 0;
  var _baselineReady = false;
  var _offset = 0;
  var _offsetDayKey = '';
  var _floorDayKey = '';

  /// Last positive Health Connect today total. Zero is an empty aggregate,
  /// not a measurement, so it is not stored. A later empty or failed read
  /// cannot max the inflated store back on top of a heal.
  int? _healthToday;
  var _listening = false;
  DateTime? _lastRebindAt;

  /// First attach just records today. A later KST date drops yesterday's
  /// floor so a poll cannot max it back onto the provider.
  void _rollFloorIfNewDay() {
    final today = KstCalendar.dateKey();
    if (_floorDayKey.isEmpty) {
      _floorDayKey = today;
      return;
    }
    if (_floorDayKey == today) return;
    _floorDayKey = today;
    _floor = 0;
    _anchorFloor = 0;
    _baselineReady = false;
    _healthToday = null;
    _offset = 0;
    _offsetDayKey = '';
  }

  Future<void> attach() async {
    if (_listening) return;
    _listening = true;
    WidgetsBinding.instance.addObserver(this);
    SoloPedometerForeground.addLiveStepsListener(_onIsolate);
    await syncFromSources(reason: 'attach');
    await _listenSensor(reason: 'attach');
    _healthTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(syncFromSources(reason: 'poll'));
    });
  }

  Future<void> detach() async {
    _listening = false;
    WidgetsBinding.instance.removeObserver(this);
    SoloPedometerForeground.removeLiveStepsListener(_onIsolate);
    _healthTimer?.cancel();
    _healthTimer = null;
    await _sub?.cancel();
    _sub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_listenSensor(reason: 'resume'));
    unawaited(syncFromSources(reason: 'resume'));
    unawaited(SoloPedometerForeground.ensureAlive(steps: _floor));
  }

  void _onIsolate(int _) {
    unawaited(_onIsolateTrusted());
  }

  Future<void> _onIsolateTrusted() async {
    _rollFloorIfNewDay();
    final trusted = await SoloPedometerForeground.liveSteps();
    final daily = PedometerStepTruth.dailyFromSources(
      liveDaily: trusted,
      healthToday: _healthToday,
    );
    await _publish(daily, source: 'isolate', healthToday: _healthToday);
  }

  Future<void> syncFromSources({required String reason}) async {
    try {
      _rollFloorIfNewDay();
      final prefs = await SharedPreferences.getInstance();
      final todayKey = KstCalendar.dateKey();
      final savedDay = prefs.getString('lastSavedDate') ?? '';
      final persisted = PedometerStepTruth.cachedDailyIfSameDay(
        cachedSteps: prefs.getInt('${todayKey}_steps') ?? 0,
        cachedDayKey: savedDay,
        todayKey: todayKey,
      );
      if (savedDay == todayKey) {
        _offset = prefs.getInt('stepOffset') ??
            prefs.getInt('${todayKey}_step_offset') ??
            _offset;
        _offsetDayKey = todayKey;
      } else {
        _offset = 0;
        _offsetDayKey = '';
      }
      final isolate = await SoloPedometerForeground.liveSteps();
      int? healthToday;
      try {
        healthToday = await PedometerKstClock.queryTodaySteps(
          _health,
          requestIfMissing: false,
        );
      } catch (e, st) {
        debugPrint('WalkingStepKeepAlive health: $e\n$st');
      }
      if (healthToday != null && healthToday > 0) _healthToday = healthToday;
      final healthForMerge =
          (healthToday != null && healthToday > 0) ? healthToday : _healthToday;
      final daily = PedometerStepTruth.dailyFromSources(
        liveDaily: healthToday ?? 0,
        persistedToday: persisted,
        isolateDaily: isolate,
        healthToday: healthForMerge,
      );
      debugPrint(
        '${PedometerStepTruth.sourceLog(
          source: 'keepalive-$reason',
          daily: daily,
          raw: healthToday,
          offset: _offset,
          healthBase: _floor,
          ui: persisted,
        )} isolate=$isolate',
      );
      await _publish(
        daily,
        source: 'keepalive-$reason',
        healthToday: healthForMerge,
      );
    } catch (e, st) {
      debugPrint('WalkingStepKeepAlive sync: $e\n$st');
    }
  }

  Future<void> _listenSensor({required String reason}) async {
    if (!PedometerStepTruth.shouldRebindSensor(
      now: DateTime.now(),
      lastRebindAt: _lastRebindAt,
      force: reason == 'attach' || reason == 'resume',
    )) {
      return;
    }
    _lastRebindAt = DateTime.now();
    try {
      await _sub?.cancel();
      _baselineReady = false;
      debugPrint(
        '${PedometerStepTruth.sourceLog(
          source: 'keepalive-rebind',
          daily: _floor,
          offset: _offset,
          healthBase: _floor,
        )} reason=$reason',
      );
      _sub = Pedometer.stepCountStream.listen(
        _onSensor,
        onError: (Object error, StackTrace stack) {
          debugPrint('WalkingStepKeepAlive sensor: $error\n$stack');
          unawaited(_listenSensor(reason: 'stream-error'));
        },
        onDone: () {
          debugPrint('${PedometerStepTruth.logPrefix} source=keepalive-done');
          unawaited(_listenSensor(reason: 'stream-done'));
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      debugPrint('WalkingStepKeepAlive listen: $e\n$st');
    }
  }

  void _onSensor(StepCount event) {
    _onSensorRaw(event.steps);
  }

  void _onSensorRaw(int raw) {
    _rollFloorIfNewDay();
    var sessionDelta = 0;
    if (!_baselineReady) {
      _baseline = raw;
      _baselineReady = true;
      _previousRaw = raw;
      _anchorFloor = PedometerStepTruth.clampDaily(_floor);
    } else {
      final sample = PedometerStepTruth.acceptSensorDelta(
        raw: raw,
        baseline: _baseline,
        previousRaw: _previousRaw,
      );
      _previousRaw = raw;
      if (sample.rebase) {
        _baseline = raw;
        _anchorFloor = PedometerStepTruth.clampDaily(_floor);
        unawaited(
          _publish(
            PedometerStepTruth.clampDaily(_floor),
            source: 'keepalive-sensor',
            healthToday: _healthToday,
          ),
        );
        return;
      }
      sessionDelta = sample.delta;
    }
    final todayKey = KstCalendar.dateKey();
    final next = PedometerStepTruth.fromSensorEvent(
      raw: raw,
      healthBase: _anchorFloor,
      sessionDelta: sessionDelta,
      stepOffset: _offset,
      // Empty offset day means the snapshot is not today's yet. Passing it
      // makes fromSensorEvent drop raw-oldOffset (yesterday's 5377).
      floorDayKey: _offsetDayKey,
      todayKey: todayKey,
    );
    debugPrint(
      PedometerStepTruth.sourceLog(
        source: 'keepalive-sensor',
        daily: next,
        raw: raw,
        offset: _offset,
        healthBase: _anchorFloor,
        sessionDelta: sessionDelta,
        ui: _floor,
      ),
    );
    unawaited(
      _publish(next, source: 'keepalive-sensor', healthToday: _healthToday),
    );
  }

  Future<void> _publish(
    int steps, {
    required String source,
    int? healthToday,
  }) async {
    final clampedFloor = PedometerStepTruth.clampDaily(_floor);
    final floorWasPoison = clampedFloor != _floor;
    if (floorWasPoison) _floor = clampedFloor;
    var daily = PedometerStepTruth.clampDaily(steps);
    if (healthToday != null && healthToday > 0) {
      daily = PedometerStepTruth.dailyFromSources(
        liveDaily: daily,
        persistedToday: _floor,
        healthToday: healthToday,
      );
    }
    final healed = PedometerStepTruth.healthReplacesStored(
      stored: _floor,
      healthToday: healthToday,
      merged: daily,
    );
    if (daily < _floor && !healed) return;
    final raised = daily > _floor;
    // Health, prefs, and the isolate may move the floor. The next sample
    // must baseline again so its cumulative delta is not added on top.
    if (!source.contains('sensor') && (raised || healed)) {
      _baselineReady = false;
    }
    _floor = daily;
    if (raised || healed) {
      final write = onDaily(daily, SoloPedometerEngine.kmFromSteps(daily));
      if (healed) await write;
    }
    if (raised ||
        healed ||
        floorWasPoison ||
        source.contains('resume') ||
        source.contains('attach')) {
      final update = SoloPedometerForeground.update(
        steps: daily,
        targetKm: 3.0,
        healthToday:
            (healthToday != null && healthToday > 0) ? healthToday : null,
      );
      if (healed) {
        await update;
      } else {
        unawaited(update);
      }
    }
  }

  /// Marks the offset as today's so sensor samples are not dropped as stale.
  @visibleForTesting
  void debugAnchorToday() {
    _offset = 0;
    _offsetDayKey = KstCalendar.dateKey();
  }

  @visibleForTesting
  int get debugFloor => _floor;

  /// First raw is the baseline. Later raws are cumulative counter samples.
  @visibleForTesting
  void debugIngestRaw(int raw) {
    _onSensorRaw(raw);
  }

  @visibleForTesting
  void debugSeedFloor(int floor) {
    _floor = floor;
  }

  @visibleForTesting
  Future<void> debugPublishHealth({
    required int? healthToday,
    int persisted = 0,
    int isolate = 0,
  }) {
    if (healthToday != null && healthToday > 0) _healthToday = healthToday;
    final daily = PedometerStepTruth.dailyFromSources(
      liveDaily: healthToday ?? 0,
      persistedToday: persisted,
      isolateDaily: isolate,
      healthToday: healthToday,
    );
    return _publish(daily, source: 'keepalive-poll', healthToday: healthToday);
  }

  /// Sensor path: uses the last positive Health, not the argument of this call.
  @visibleForTesting
  Future<void> debugPublishSensor(int steps) {
    return _publish(
      steps,
      source: 'keepalive-sensor',
      healthToday: _healthToday,
    );
  }
}
