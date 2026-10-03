import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';

import '../onboarding/src_onboarding_controller.dart';
import 'daily_metrics_account.dart';
import 'kst_calendar.dart';
import 'pedometer_health_cap.dart';
import 'pedometer_step_truth.dart';
import 'solo_pedometer_foreground.dart';
import 'today_steps.dart';

/// Process-level walking steps: survives Walking Challenge dispose/rebuild
/// and rebinds after `FlutterJNI was detached` on `step_count`.
///
/// This listener only feeds the single [TodaySteps] owner. It does not keep
/// its own baseline or write a daily total.
class WalkingStepKeepAlive with WidgetsBindingObserver {
  WalkingStepKeepAlive({
    required this.onDaily,
    TodaySteps? today,
  }) : today = today ?? TodaySteps() {
    this.today.onCommit = onDaily;
  }

  final Future<void> Function(
    int steps,
    double km, {
    required String dayKey,
    required String source,
    int? lastHealth,
  }) onDaily;
  final TodaySteps today;

  final Health _health = Health();
  StreamSubscription<StepCount>? _sub;
  Timer? _healthTimer;
  var _listening = false;
  DateTime? _lastRebindAt;

  Future<void> attach() async {
    if (_listening) return;
    _listening = true;
    WidgetsBinding.instance.addObserver(this);
    SoloPedometerForeground.onRawSample = today.onRaw;
    SoloPedometerForeground.onHealthRefresh = refreshHealth;
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
    if (SoloPedometerForeground.onRawSample == today.onRaw) {
      SoloPedometerForeground.onRawSample = null;
    }
    if (SoloPedometerForeground.onHealthRefresh == refreshHealth) {
      SoloPedometerForeground.onHealthRefresh = null;
    }
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
    unawaited(SoloPedometerForeground.ensureAlive(steps: today.steps));
  }

  void _onIsolate(int _) {}

  Future<void> syncFromSources({required String reason}) async {
    try {
      await DailyMetricsAccount.pullIntoPrefs(
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      final prefs = await PedometerHealthCap.fresh();
      final todayKey = KstCalendar.dateKey();
      final savedDay = prefs.getString('lastSavedDate') ?? '';
      final persisted = PedometerStepTruth.cachedDailyIfSameDay(
        cachedSteps: prefs.getInt('${todayKey}_steps') ?? 0,
        cachedDayKey: savedDay,
        todayKey: todayKey,
      );
      if (savedDay == todayKey) {
        today.loadOffset(
          offset: prefs.getInt('stepOffset') ??
              prefs.getInt('${todayKey}_step_offset') ??
              0,
          dayKey: todayKey,
        );
      } else {
        today.loadOffset(offset: 0, dayKey: '');
      }
      int? healthToday;
      try {
        healthToday = await PedometerKstClock.queryTodaySteps(
          _health,
          requestIfMissing: false,
        );
      } catch (e, st) {
        debugPrint('WalkingStepKeepAlive health: $e\n$st');
      }
      final persistedHealth = PedometerHealthCap.fromPrefs(
        prefs,
        todayKey: todayKey,
      );
      if (healthToday != null && healthToday > 0) {
        await PedometerHealthCap.persist(
          prefs,
          todayKey: todayKey,
          health: healthToday,
        );
      }
      today.restore(
        persisted,
        health: (healthToday != null && healthToday > 0)
            ? healthToday
            : persistedHealth,
      );
      if (healthToday != null && healthToday > 0) {
        await today.onHealth(healthToday);
      }
      debugPrint(
        '${PedometerStepTruth.sourceLog(
          source: 'keepalive-$reason',
          daily: today.steps,
          raw: healthToday,
          ui: persisted,
        )} owner=${today.steps}',
      );
    } catch (e, st) {
      debugPrint('WalkingStepKeepAlive sync: $e\n$st');
    }
  }

  /// Notification tick. Today's Health Connect total only — no Firestore pull.
  /// Resume still uses [syncFromSources], which reads the same full-day window.
  Future<void> refreshHealth() async {
    try {
      final healthToday = await PedometerKstClock.queryTodaySteps(
        _health,
        requestIfMissing: false,
      );
      if (healthToday != null && healthToday > 0) {
        await today.onHealth(healthToday);
      }
    } catch (e, st) {
      debugPrint('WalkingStepKeepAlive health refresh: $e\n$st');
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
      debugPrint(
        '${PedometerStepTruth.sourceLog(
          source: 'keepalive-rebind',
          daily: today.steps,
          ui: today.steps,
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
    today.onRaw(event.steps);
  }

  @visibleForTesting
  void debugAnchorToday() {
    today.debugAnchorToday();
  }

  @visibleForTesting
  int get debugFloor => today.steps;

  @visibleForTesting
  void debugIngestRaw(int raw) {
    today.onRaw(raw);
  }

  @visibleForTesting
  void debugSeedFloor(int floor) {
    today.debugSeed(floor);
  }

  @visibleForTesting
  Future<void> debugPublishHealth({
    required int? healthToday,
    int persisted = 0,
    int isolate = 0,
  }) {
    return today.debugApplySources(
      healthToday: healthToday,
      persisted: persisted,
      isolate: isolate,
    );
  }

  @visibleForTesting
  Future<void> debugPublishSensor(int steps) {
    return today.debugOfferDaily(steps);
  }
}
