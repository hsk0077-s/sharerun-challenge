import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationVisibility;
import 'package:go_router/go_router.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/root_navigator.dart';
import '../../app/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import 'kst_calendar.dart';
import 'pedometer_day_rollover.dart';
import 'pedometer_health_cap.dart';
import 'pedometer_step_truth.dart';

const _channelId = 'src_walking_coin_pickup';
const _channelName = '워킹챌린지 코인 줍기';
const _iconMeta = 'mipmap/ic_launcher';
const _targetKmKey = 'solo_pedo_target_km';
const _healthBaseKey = 'solo_pedo_health_base';
const _stepsKey = 'solo_pedo_steps';
const _stepsAtKey = 'solo_pedo_steps_at';
const _claimedKey = 'solo_pedo_claimed_steps';
const _pendingKey = 'solo_pedo_pending_share';
const _keepAliveKey = 'solo_pedo_keep_alive';
const _openCommand = 'open_solo_pedometer';
const _smartPushDateKey = 'src_smart_push_date';
const _smartPushMorningKey = 'src_smart_push_fired_morning';
const _smartPushLunchKey = 'src_smart_push_fired_lunch';
const _smartPushEveningKey = 'src_smart_push_fired_evening';
const _smartPushEnabledKey = 'walking_challenge_benefit_notif';
const _smartPushChannelId = 'src_walking_smart_time';
const _smartPushChannelName = '워킹챌린지 스마트 타임 푸시';
const _smartMorningId = 801;
const _smartLunchId = 1231;
const _smartEveningId = 1801;

@pragma('vm:entry-point')
void startSoloPedometerForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(SoloPedometerForegroundHandler());
}

class SoloPedometerForegroundHandler extends TaskHandler {
  StreamSubscription<StepCount>? _sub;
  var _lastRaw = 0;
  var _steps = 0;

  /// Last positive Health Connect today total. Sensor commits and plain ints
  /// keep using it so a later 29,999 cannot climb back over that reading.
  int? _healthToday;
  var lastFiredDateKey = '';
  var lastSavedDate = '';
  var stepOffset = 0;
  var firedMorning = false;
  var firedLunch = false;
  var firedEvening = false;
  var isPushEnabled = true;
  var _smartFlagsHydrated = false;
  var _sensorRebindInFlight = false;
  DateTime? _lastSensorRebindAt;
  static final _smartPlugin = FlutterLocalNotificationsPlugin();
  static var _smartPluginReady = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      try {
        final prefs = await PedometerHealthCap.fresh();
        lastSavedDate = prefs.getString('lastSavedDate') ?? '';
        stepOffset = prefs.getInt('stepOffset') ?? 0;
      } catch (e, st) {
        debugPrint('SoloPedometerForegroundHandler load date: $e\n$st');
      }
      _listenSensor(reason: 'onStart');
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler onStart: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler onStart: $e\n$st');
    }
  }

  void _listenSensor({required String reason}) {
    if (_sensorRebindInFlight) return;
    final now = DateTime.now();
    if (!PedometerStepTruth.shouldRebindSensor(
      now: now,
      lastRebindAt: _lastSensorRebindAt,
      force: reason == 'onStart',
    )) {
      return;
    }
    _sensorRebindInFlight = true;
    _lastSensorRebindAt = now;
    try {
      unawaited(_sub?.cancel());
      debugPrint(
        '${PedometerStepTruth.sourceLog(
          source: 'isolate-rebind',
          daily: _steps,
          offset: stepOffset,
          ui: _steps,
        )} reason=$reason',
      );
      _sub = Pedometer.stepCountStream.listen(
        (event) {
          try {
            _lastRaw = event.steps;
            FlutterForegroundTask.sendDataToMain(<Object>['raw', event.steps]);
          } catch (e, st) {
            debugPrint('SoloPedometerForegroundHandler step: $e\n$st');
          }
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('SoloPedometerForegroundHandler stream: $error\n$stack');
          _listenSensor(reason: 'stream-error');
        },
        onDone: () {
          debugPrint('SoloPedometerForegroundHandler stream done');
          _listenSensor(reason: 'stream-done');
        },
        cancelOnError: false,
      );
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler listen: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler listen: $e\n$st');
    } finally {
      _sensorRebindInFlight = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_sub == null) _listenSensor(reason: 'onStart');
    unawaited(_commit());
    unawaited(_smartFromOwnerPrefs());
  }

  @override
  void onReceiveData(Object data) {}

  Future<void> _smartFromOwnerPrefs() async {
    var steps = 0;
    try {
      final prefs = await PedometerHealthCap.fresh();
      final todayKey = KstCalendar.dateKey();
      final stored = prefs.getInt('${todayKey}_steps') ?? 0;
      final health = PedometerHealthCap.fromPrefs(prefs, todayKey: todayKey);
      steps = PedometerHealthCap.cap(stored, health);
    } catch (_) {}
    await _maybeFireSmartPushes(steps);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    try {
      await _sub?.cancel();
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler onDestroy: $e\n$st');
    }
    if (!isTimeout) return;
    try {
      final keep =
          await FlutterForegroundTask.getData<bool>(key: _keepAliveKey) ??
              false;
      if (!keep) return;
      await SoloPedometerForeground.ensureAlive();
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler timeout restart: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler timeout restart: $e\n$st');
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.sendDataToMain(_openCommand);
  }

  Future<void> _maybeFireSmartPushes(int currentSteps) async {
    try {
      final now = DateTime.now();
      await _hydrateSmartPushFlags(now);
      final todayKey = KstCalendar.dateKey(now);
      if (lastFiredDateKey != todayKey) {
        firedMorning = false;
        firedLunch = false;
        firedEvening = false;
        lastFiredDateKey = todayKey;
        await _persistSmartPushFlags(now);
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        isPushEnabled = prefs.getBool(_smartPushEnabledKey) ?? true;
      } catch (_) {}
      if (!isPushEnabled) return;

      final minutes = now.hour * 60 + now.minute;
      var dirty = false;

      if (!firedMorning && now.hour >= 8) {
        await _showSmartPush(
          id: _smartMorningId,
          title: '☀️ 굿모닝! 오늘 걸음을 주워 보세요.',
          body: WalkingChallengeNotificationCopy.harvestHint(currentSteps),
        );
        firedMorning = true;
        dirty = true;
      }

      if (!firedLunch && minutes >= 12 * 60 + 30) {
        if (currentSteps < 1500) {
          await _showSmartPush(
            id: _smartLunchId,
            title: '🍱 점심 식사 후 가벼운 산책 어떠세요?',
            body: WalkingChallengeNotificationCopy.harvestHint(currentSteps),
          );
        }
        firedLunch = true;
        dirty = true;
      }

      if (!firedEvening && now.hour >= 18) {
        if (currentSteps < 4500) {
          await _showSmartPush(
            id: _smartEveningId,
            title: '오늘 걸음은 이렇게 주울 수 있어요',
            body: WalkingChallengeNotificationCopy.harvestHint(currentSteps),
          );
        }
        firedEvening = true;
        dirty = true;
      }

      if (dirty) await _persistSmartPushFlags(now);
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler smart push: $e\n$st');
    }
  }

  Future<void> _hydrateSmartPushFlags(DateTime now) async {
    if (_smartFlagsHydrated) return;
    _smartFlagsHydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = KstCalendar.dateKey(now);
      final savedDate = prefs.getString(_smartPushDateKey) ?? '';
      if (savedDate != todayKey) {
        lastFiredDateKey = savedDate;
        return;
      }
      lastFiredDateKey = todayKey;
      firedMorning = prefs.getBool(_smartPushMorningKey) ?? false;
      firedLunch = prefs.getBool(_smartPushLunchKey) ?? false;
      firedEvening = prefs.getBool(_smartPushEveningKey) ?? false;
      isPushEnabled = prefs.getBool(_smartPushEnabledKey) ?? true;
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler smart hydrate: $e\n$st');
    }
  }

  Future<void> _persistSmartPushFlags(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = KstCalendar.dateKey(now);
      await prefs.setString(_smartPushDateKey, todayKey);
      await prefs.setBool(_smartPushMorningKey, firedMorning);
      await prefs.setBool(_smartPushLunchKey, firedLunch);
      await prefs.setBool(_smartPushEveningKey, firedEvening);
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler smart persist: $e\n$st');
    }
  }

  Future<void> _ensureSmartPlugin() async {
    if (_smartPluginReady) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _smartPlugin.initialize(initSettings);
    final android = _smartPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _smartPushChannelId,
        _smartPushChannelName,
        description: '워킹챌린지 아침·점심·저녁 조건부 리마인더',
        importance: Importance.high,
      ),
    );
    _smartPluginReady = true;
  }

  Future<void> _showSmartPush({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureSmartPlugin();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _smartPushChannelId,
        _smartPushChannelName,
        channelDescription: '워킹챌린지 아침·점심·저녁 조건부 리마인더',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _smartPlugin.show(
      id,
      title,
      body,
      details,
      payload: RouteNames.soloPedometerPath,
    );
  }

  /// Remembers a positive Health reading. Zero and null leave the last one.
  int? _healthForMerge(int? incoming) {
    if (incoming != null && incoming > 0) _healthToday = incoming;
    return _healthToday;
  }

  ({int next, int? health}) _capCommit({
    required int computed,
    required int saved,
    int? healthToday,
    int? persistedHealth,
  }) {
    final remembered = _healthForMerge(healthToday);
    final health = PedometerHealthCap.effective(
      live: remembered,
      persisted: persistedHealth,
    );
    if (health != null && health > 0) _healthToday = health;
    final next = PedometerStepTruth.dailyFromSources(
      liveDaily: computed,
      persistedToday: saved,
      isolateDaily: _steps,
      healthToday: health,
    );
    return (next: next, health: health);
  }

  /// Merge used by [_commit], without the foreground-task plugin.
  ///
  /// [persistedHealth] is the last positive Health stored for today. A new
  /// isolate has no memory of the heal, so a stale 29,999 commit still uses it.
  @visibleForTesting
  int debugMergeCommit({
    required int computed,
    required int saved,
    int? healthToday,
    int? persistedHealth,
  }) {
    final next = _capCommit(
      computed: computed,
      saved: saved,
      healthToday: healthToday,
      persistedHealth: persistedHealth,
    ).next;
    _steps = next;
    return next;
  }

  Future<void> _commit() async {
    try {
      final todayIso = KstCalendar.dateKey();
      if (lastSavedDate.isEmpty) {
        lastSavedDate = todayIso;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastSavedDate', lastSavedDate);
          await prefs.setInt('stepOffset', stepOffset);
        } catch (_) {}
      } else if (lastSavedDate != todayIso) {
        // `_lastRaw == 0` must not store today's `next` as the hardware offset.
        final sensorTotal = PedometerDayRollover.hardwareSnapshot(_lastRaw);
        final plan = PedometerDayRollover.plan(
          todayKey: todayIso,
          sensorTotal: sensorTotal,
        );
        stepOffset = plan.stepOffset;
        lastSavedDate = plan.dateKey;
        lastFiredDateKey = plan.dateKey;
        firedMorning = false;
        firedLunch = false;
        firedEvening = false;
        _steps = 0;
        _healthToday = null;
        PedometerHealthCap.forget();
        await _persistSmartPushFlags(DateTime.now());
        try {
          final prefs = await PedometerHealthCap.fresh();
          await PedometerHealthCap.clear(prefs);
          for (final entry in PedometerDayRollover.prefsToWrite(plan).entries) {
            final value = entry.value;
            if (value is int) {
              await prefs.setInt(entry.key, value);
            } else if (value is double) {
              await prefs.setDouble(entry.key, value);
            } else if (value is String) {
              await prefs.setString(entry.key, value);
            }
          }
        } catch (_) {}
        await FlutterForegroundTask.saveData(key: _stepsKey, value: 0);
        await FlutterForegroundTask.saveData(
          key: _claimedKey,
          value: 0,
        );
        await _publish(0);
        FlutterForegroundTask.sendDataToMain(0);
        return;
      }
      // Same-day totals are decided in the main isolate. Do not write the
      // task key or the notification from this isolate's own anchor.
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler commit: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler commit: $e\n$st');
    }
  }

  Future<void> _publish(int steps, {int? healthToday}) async {
    try {
      await FlutterForegroundTask.saveData(key: _stepsKey, value: steps);
      await FlutterForegroundTask.saveData(
        key: _stepsAtKey,
        value: DateTime.now().millisecondsSinceEpoch,
      );
      final resolved = await SoloPedometerForeground.resolveNotification(
        rawSteps: steps,
        healthToday: healthToday,
      );
      debugPrint(
        PedometerStepTruth.sourceLog(
          source: 'notif-publish',
          daily: resolved.effectiveSteps,
          ui: steps,
        ),
      );
      await FlutterForegroundTask.saveData(
        key: _claimedKey,
        value: resolved.claimedSteps,
      );
      await FlutterForegroundTask.saveData(
        key: _pendingKey,
        value: resolved.pendingShare,
      );
      await FlutterForegroundTask.updateService(
        notificationTitle: resolved.title,
        notificationText: resolved.body,
        notificationIcon: SoloPedometerForeground.launcherIcon,
        notificationInitialRoute: RouteNames.soloPedometerPath,
      );
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler publish: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler publish: $e\n$st');
    }
  }
}

abstract final class SoloPedometerForeground {
  static const launcherIcon = NotificationIcon(
    metaDataName: _iconMeta,
    backgroundColor: AppColors.primaryMint,
  );
  static var _ensuring = false;
  static int? _knownHealthToday;
  static String _knownHealthDay = '';
  static var _uiBound = false;
  static var _launchConsumed = false;
  static DateTime? _lastOpenAt;
  static GoRouter? _uiRouter;
  static void Function(int steps)? onLiveSteps;

  /// Raw TYPE_STEP_COUNTER sample from the foreground isolate. The main
  /// isolate's [TodaySteps] owner decides the daily total.
  static void Function(int raw)? onRawSample;
  static final List<void Function(int steps)> _liveListeners = [];

  static void addLiveStepsListener(void Function(int steps) listener) {
    if (!_liveListeners.contains(listener)) {
      _liveListeners.add(listener);
    }
  }

  static void removeLiveStepsListener(void Function(int steps) listener) {
    _liveListeners.remove(listener);
  }

  static void _emitLiveSteps(int steps) {
    onLiveSteps?.call(steps);
    for (final listener in List<void Function(int)>.of(_liveListeners)) {
      listener(steps);
    }
  }

  static ForegroundTaskOptions get _taskOptions => ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowAutoRestart: true,
        stopWithTask: false,
      );

  static String titleFor({required double pendingShare}) {
    final pendingCoinsInt = pendingShare.floor();
    if (pendingCoinsInt > 0) {
      return '$pendingCoinsInt SHARE 대기 중! 🪙';
    }
    return '오늘 0보 달성! 🪙';
  }

  static String bodyFor({
    required int steps,
    int claimedSteps = 0,
    double? pendingShare,
  }) {
    return '오늘 ${_comma(steps)}보를 걸었습니다. 터치해서 즉시 코인을 주우세요!';
  }

  static Future<
      ({
        String title,
        String body,
        double pendingShare,
        int effectiveSteps,
        int claimedSteps,
      })> resolveNotification({
    required int rawSteps,
    int? healthToday,
  }) async {
    final prefs = await PedometerHealthCap.fresh();
    final todayKey = KstCalendar.dateKey();
    final claimedSteps = prefs.getInt('${todayKey}_claimed_steps') ?? 0;
    // UI / isolate store *daily* steps. Midnight sensor offset must not be
    // subtracted again — that zeroed the shade while the walking screen
    // still showed the persisted daily count (e.g. 1,835 vs 0 / 4,500).
    final persistedToday = prefs.getInt('${todayKey}_steps') ?? 0;
    final health = PedometerHealthCap.effective(
      live: healthToday,
      persisted: PedometerHealthCap.fromPrefs(prefs, todayKey: todayKey),
    );
    final effectiveSteps = PedometerStepTruth.dailyFromSources(
      liveDaily: rawSteps,
      persistedToday: persistedToday,
      healthToday: health,
    );
    final copy = WalkingChallengeNotificationCopy.fromDailySteps(
      effectiveSteps,
      claimedSteps: claimedSteps,
    );
    debugPrint(
      PedometerStepTruth.sourceLog(
        source: 'notif-resolve',
        daily: effectiveSteps,
        raw: rawSteps,
        ui: persistedToday,
      ),
    );

    return (
      title: copy.title,
      body: copy.body,
      pendingShare: 0.0,
      effectiveSteps: effectiveSteps,
      claimedSteps: claimedSteps,
    );
  }

  static double pendingShare({
    required int steps,
    required int claimedSteps,
    int stepOffset = 0,
  }) {
    // [2단 락] 걸음 수 비례 무한 pending SHARE 잠금.
    return 0.0 * (steps + claimedSteps + stepOffset);
  }

  static String _comma(int n) {
    final raw = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    return n < 0 ? '-$buf' : '$buf';
  }

  static void attachRouter(GoRouter? router) {
    _uiRouter = router;
  }

  static void bindUi() {
    if (_uiBound) return;
    _uiBound = true;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openIfLaunchedFromNotification();
    });
  }

  static void _onTaskData(Object data) {
    if (data == _openCommand) {
      openWalkingChallenge();
      return;
    }
    if (data is List &&
        data.length >= 2 &&
        data.first == 'raw' &&
        data[1] is int) {
      onRawSample?.call(data[1] as int);
      return;
    }
    if (data is int) {
      _emitLiveSteps(data);
    }
  }

  static void openIfLaunchedFromNotification() {
    if (_launchConsumed) return;
    final launch = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (launch != RouteNames.soloPedometerPath) return;
    _launchConsumed = true;
    openWalkingChallenge();
  }

  static void openWalkingChallenge() {
    final now = DateTime.now();
    if (_lastOpenAt != null &&
        now.difference(_lastOpenAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastOpenAt = now;
    try {
      final router = _uiRouter;
      if (router != null) {
        final loc = router.routeInformationProvider.value.uri.path;
        if (loc != RouteNames.soloPedometerPath) {
          router.go(RouteNames.soloPedometerPath);
        }
        return;
      }
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;
      final name = ModalRoute.of(nav.context)?.settings.name;
      if (name == RouteNames.soloPedometerPath ||
          name == RouteNames.soloPedometer) {
        return;
      }
      nav.pushNamed(RouteNames.soloPedometerPath);
    } catch (e, st) {
      debugPrint('SoloPedometerForeground openWalkingChallenge: $e\n$st');
    }
  }

  static Future<int> liveSteps() async {
    try {
      final steps =
          await FlutterForegroundTask.getData<int>(key: _stepsKey) ?? 0;
      final at = await FlutterForegroundTask.getData<int>(key: _stepsAtKey);
      if (at == null || at <= 0) {
        return PedometerStepTruth.clampDaily(steps);
      }
      return PedometerStepTruth.cachedDailyIfSameDay(
        cachedSteps: steps,
        cachedDayKey: KstCalendar.dateKey(
          DateTime.fromMillisecondsSinceEpoch(at),
        ),
        todayKey: KstCalendar.dateKey(),
      );
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForeground liveSteps: $e\n$st');
      return 0;
    } catch (e, st) {
      debugPrint('SoloPedometerForeground liveSteps: $e\n$st');
      return 0;
    }
  }

  /// Last positive Health for this KST day. A later null or zero keeps it.
  @visibleForTesting
  static int? knownHealthForSend(int? healthToday) {
    final today = KstCalendar.dateKey();
    if (_knownHealthDay != today) {
      _knownHealthDay = today;
      _knownHealthToday = null;
    }
    if (healthToday != null && healthToday > 0) {
      _knownHealthToday = healthToday;
    }
    return _knownHealthToday;
  }

  @visibleForTesting
  static void debugResetKnownHealth() {
    _knownHealthToday = null;
    _knownHealthDay = '';
  }

  /// Persists a positive reading, then keeps it for this KST day even when
  /// the next call has no live Health (background read failed or returned 0).
  static Future<int?> _healthForTask(int? healthToday) async {
    if (healthToday != null && healthToday > 0) {
      try {
        final prefs = await PedometerHealthCap.fresh();
        await PedometerHealthCap.persist(
          prefs,
          todayKey: KstCalendar.dateKey(),
          health: healthToday,
        );
      } catch (_) {}
    }
    final remembered = knownHealthForSend(healthToday);
    if (remembered != null && remembered > 0) return remembered;
    try {
      final prefs = await PedometerHealthCap.fresh();
      final stored = PedometerHealthCap.fromPrefs(
        prefs,
        todayKey: KstCalendar.dateKey(),
      );
      return knownHealthForSend(stored);
    } catch (_) {
      return remembered;
    }
  }

  /// Payload [update] and [start] send. After a positive Health reading, a
  /// plain step update still carries that Health.
  @visibleForTesting
  static Object debugTaskPayload(int merged, int? healthToday) {
    final health = knownHealthForSend(healthToday);
    if (health != null && health > 0) return <Object>[merged, health];
    return merged;
  }

  static void _sendTaskSteps(int merged, int? health) {
    if (health != null && health > 0) {
      FlutterForegroundTask.sendDataToTask(<Object>[merged, health]);
    } else {
      FlutterForegroundTask.sendDataToTask(merged);
    }
  }

  static Future<int> _mergedSteps(int steps, {int? healthToday}) async {
    final saved = await liveSteps();
    return PedometerStepTruth.dailyFromSources(
      liveDaily: steps,
      persistedToday: saved,
      healthToday: healthToday,
    );
  }

  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: '워킹챌린지 걸음 수와 채굴 진행도를 잠금화면과 상단바에 표시합니다.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: _taskOptions,
    );
  }

  static Future<void> start({
    required int steps,
    required double targetKm,
    required int healthBase,
    int claimedSteps = 0,
    double? pendingShare,
    int? healthToday,
  }) async {
    try {
      initForegroundTask();
      try {
        final perm = await FlutterForegroundTask.checkNotificationPermission();
        if (perm != NotificationPermission.granted) {
          await FlutterForegroundTask.requestNotificationPermission();
        }
      } catch (e, st) {
        debugPrint('SoloPedometerForeground notification perm: $e\n$st');
      }
      final health = await _healthForTask(healthToday);
      final merged = await _mergedSteps(steps, healthToday: health);
      final resolved = await resolveNotification(
        rawSteps: merged,
        healthToday: health,
      );
      await FlutterForegroundTask.saveData(key: _keepAliveKey, value: true);
      await FlutterForegroundTask.saveData(key: _targetKmKey, value: targetKm);
      await FlutterForegroundTask.saveData(
        key: _healthBaseKey,
        value: math.max(healthBase, merged),
      );
      await FlutterForegroundTask.saveData(key: _stepsKey, value: merged);
      await FlutterForegroundTask.saveData(
        key: _claimedKey,
        value: resolved.claimedSteps,
      );
      await FlutterForegroundTask.saveData(
        key: _pendingKey,
        value: resolved.pendingShare,
      );
      await FlutterForegroundTask.saveData(
        key: _stepsAtKey,
        value: DateTime.now().millisecondsSinceEpoch,
      );
      final title = resolved.title;
      final text = resolved.body;
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          foregroundTaskOptions: _taskOptions,
          notificationTitle: title,
          notificationText: text,
          notificationIcon: launcherIcon,
          notificationInitialRoute: RouteNames.soloPedometerPath,
        );
        _sendTaskSteps(merged, health);
        return;
      }
      await FlutterForegroundTask.startService(
        serviceTypes: const [ForegroundServiceTypes.health],
        notificationTitle: title,
        notificationText: text,
        notificationIcon: launcherIcon,
        notificationInitialRoute: RouteNames.soloPedometerPath,
        callback: startSoloPedometerForegroundCallback,
      );
      _sendTaskSteps(merged, health);
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForeground start: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForeground start: $e\n$st');
    }
  }

  static Future<void> update({
    required int steps,
    required double targetKm,
    int? healthBase,
    int? claimedSteps,
    double? pendingShare,
    int? healthToday,
  }) async {
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await ensureAlive(
          steps: steps,
          targetKm: targetKm,
          claimedSteps: claimedSteps,
          pendingShare: pendingShare,
          healthToday: healthToday,
        );
        return;
      }
      final health = await _healthForTask(healthToday);
      final merged = await _mergedSteps(steps, healthToday: health);
      await FlutterForegroundTask.saveData(key: _keepAliveKey, value: true);
      await FlutterForegroundTask.saveData(key: _targetKmKey, value: targetKm);
      await FlutterForegroundTask.saveData(key: _stepsKey, value: merged);
      await FlutterForegroundTask.saveData(
        key: _stepsAtKey,
        value: DateTime.now().millisecondsSinceEpoch,
      );
      if (healthBase != null) {
        await FlutterForegroundTask.saveData(
          key: _healthBaseKey,
          value: math.max(healthBase, merged),
        );
      }
      if (claimedSteps != null) {
        await FlutterForegroundTask.saveData(
          key: _claimedKey,
          value: claimedSteps,
        );
      }
      final resolved = await resolveNotification(
        rawSteps: merged,
        healthToday: health,
      );
      await FlutterForegroundTask.saveData(
        key: _pendingKey,
        value: resolved.pendingShare,
      );
      await FlutterForegroundTask.updateService(
        foregroundTaskOptions: _taskOptions,
        notificationTitle: resolved.title,
        notificationText: resolved.body,
        notificationIcon: launcherIcon,
        notificationInitialRoute: RouteNames.soloPedometerPath,
      );
      _sendTaskSteps(merged, health);
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForeground update: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForeground update: $e\n$st');
    }
  }

  static Future<void> ensureAlive({
    int? steps,
    double? targetKm,
    int? claimedSteps,
    double? pendingShare,
    int? healthToday,
  }) async {
    if (_ensuring) return;
    _ensuring = true;
    try {
      final keep =
          await FlutterForegroundTask.getData<bool>(key: _keepAliveKey) ??
              false;
      if (!keep) return;
      if (await FlutterForegroundTask.isRunningService) return;
      final savedSteps = steps ??
          await FlutterForegroundTask.getData<int>(key: _stepsKey) ??
          0;
      final savedKm = targetKm ??
          await FlutterForegroundTask.getData<double>(key: _targetKmKey) ??
          3.0;
      final healthBase =
          await FlutterForegroundTask.getData<int>(key: _healthBaseKey) ??
              savedSteps;
      final savedClaimed = claimedSteps ??
          await FlutterForegroundTask.getData<int>(key: _claimedKey) ??
          0;
      await start(
        steps: savedSteps,
        targetKm: savedKm,
        healthBase: healthBase,
        claimedSteps: savedClaimed,
        pendingShare: pendingShare,
        healthToday: healthToday,
      );
    } on PlatformException catch (e, st) {
      debugPrint(
        'SoloPedometerForeground ensureAlive PlatformException: $e\n$st',
      );
    } catch (e, st) {
      debugPrint('SoloPedometerForeground ensureAlive: $e\n$st');
    } finally {
      _ensuring = false;
    }
  }

  static Future<void> stop() async {
    try {
      await FlutterForegroundTask.saveData(key: _keepAliveKey, value: false);
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.stopService();
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForeground stop: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForeground stop: $e\n$st');
    }
  }
}
