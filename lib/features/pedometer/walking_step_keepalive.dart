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

  final void Function(int steps, double km) onDaily;

  final Health _health = Health();
  StreamSubscription<StepCount>? _sub;
  Timer? _healthTimer;
  var _floor = 0;
  var _baseline = 0;
  var _baselineReady = false;
  var _offset = 0;
  var _listening = false;
  DateTime? _lastRebindAt;

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

  void _onIsolate(int steps) {
    _publish(steps, source: 'isolate');
  }

  Future<void> syncFromSources({required String reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = KstCalendar.dateKey();
      final persisted = prefs.getInt('${todayKey}_steps') ?? 0;
      _offset = prefs.getInt('stepOffset') ??
          prefs.getInt('${todayKey}_step_offset') ??
          _offset;
      final isolate = await SoloPedometerForeground.liveSteps();
      var healthToday = 0;
      try {
        healthToday = await PedometerKstClock.queryTodaySteps(
              _health,
              requestIfMissing: false,
            ) ??
            0;
      } catch (e, st) {
        debugPrint('WalkingStepKeepAlive health: $e\n$st');
      }
      final daily = PedometerStepTruth.dailyFromSources(
        liveDaily: healthToday,
        persistedToday: persisted,
        isolateDaily: isolate,
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
      _publish(daily, source: 'keepalive-$reason');
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
    final raw = event.steps;
    if (!_baselineReady) {
      _baseline = raw;
      _baselineReady = true;
    }
    final next = PedometerStepTruth.fromSensorEvent(
      raw: raw,
      healthBase: _floor,
      sessionDelta: _baselineReady ? (raw - _baseline).clamp(0, 999999) : 0,
      stepOffset: _offset,
    );
    debugPrint(
      PedometerStepTruth.sourceLog(
        source: 'keepalive-sensor',
        daily: next,
        raw: raw,
        offset: _offset,
        healthBase: _floor,
        sessionDelta: raw - _baseline,
        ui: _floor,
      ),
    );
    _publish(next, source: 'keepalive-sensor');
  }

  void _publish(int steps, {required String source}) {
    final daily = PedometerStepTruth.clampDaily(steps);
    if (daily < _floor) return;
    final raised = daily > _floor;
    _floor = daily;
    if (raised) {
      onDaily(daily, SoloPedometerEngine.kmFromSteps(daily));
    }
    if (raised || source.contains('resume') || source.contains('attach')) {
      unawaited(
        SoloPedometerForeground.update(steps: daily, targetKm: 3.0),
      );
    }
  }
}
