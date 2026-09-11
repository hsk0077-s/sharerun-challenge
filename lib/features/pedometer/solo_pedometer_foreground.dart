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
const _smartPushSnipe1Key = 'src_smart_push_sniped_m1';
const _smartPushSnipe2Key = 'src_smart_push_sniped_m2';
const _smartPushSnipe3Key = 'src_smart_push_sniped_m3';
const _smartPushEnabledKey = 'walking_challenge_benefit_notif';
const _smartPushChannelId = 'src_walking_smart_time';
const _smartPushChannelName = '워킹챌린지 스마트 타임 푸시';
const _smartMorningId = 801;
const _smartLunchId = 1231;
const _smartEveningId = 1801;
const _snipeMilestone1Id = 1201;
const _snipeMilestone2Id = 2701;
const _snipeMilestone3Id = 4201;

@pragma('vm:entry-point')
void startSoloPedometerForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(SoloPedometerForegroundHandler());
}

class SoloPedometerForegroundHandler extends TaskHandler {
  StreamSubscription<StepCount>? _sub;
  var _anchor = 0;
  var _baseline = 0;
  var _lastRaw = 0;
  var _baselineReady = false;
  var _steps = 0;
  var lastFiredDateKey = '';
  var lastSavedDate = '';
  var stepOffset = 0;
  var firedMorning = false;
  var firedLunch = false;
  var firedEvening = false;
  var snipedMilestone1 = false;
  var snipedMilestone2 = false;
  var snipedMilestone3 = false;
  var isPushEnabled = true;
  var _smartFlagsHydrated = false;
  static final _smartPlugin = FlutterLocalNotificationsPlugin();
  static var _smartPluginReady = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      _steps =
          await FlutterForegroundTask.getData<int>(key: _stepsKey) ?? 0;
      _anchor = _steps;
      try {
        final prefs = await SharedPreferences.getInstance();
        lastSavedDate = prefs.getString('lastSavedDate') ?? '';
        stepOffset = prefs.getInt('stepOffset') ?? 0;
      } catch (e, st) {
        debugPrint('SoloPedometerForegroundHandler load date: $e\n$st');
      }
      await _publish(_steps);
      _sub = Pedometer.stepCountStream.listen(
        (event) {
          try {
            _lastRaw = event.steps;
            if (!_baselineReady) {
              _baseline = _lastRaw;
              _baselineReady = true;
              return;
            }
            final fromSensor = _anchor + math.max(0, _lastRaw - _baseline);
            unawaited(_commit(fromSensor.toInt()));
          } catch (e, st) {
            debugPrint('SoloPedometerForegroundHandler step: $e\n$st');
          }
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('SoloPedometerForegroundHandler stream: $error\n$stack');
        },
        cancelOnError: false,
      );
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler onStart: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler onStart: $e\n$st');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_commit(_steps.toInt()));
    unawaited(_maybeFireSmartPushes(_steps));
  }

  @override
  void onReceiveData(Object data) {
    if (data is num) unawaited(_commit(data.toInt()));
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
        snipedMilestone1 = false;
        snipedMilestone2 = false;
        snipedMilestone3 = false;
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
          title: '☀️ 굿모닝! 다음 대회 참가가 코앞이에요.',
          body:
              '오늘 하루 4,500보 완주하고 60 SHARE 모으면 대회 참가비가 훌쩍 가까워집니다. 힘차게 출발할까요?',
        );
        firedMorning = true;
        dirty = true;
      }

      if (!firedLunch && minutes >= 12 * 60 + 30) {
        if (currentSteps < 1500) {
          await _showSmartPush(
            id: _smartLunchId,
            title: '🍱 점심 식사 후 가벼운 산책 어떠세요?',
            body:
                '아직 첫 번째 보상에 도달하지 못했어요. 커피 한잔 들고 가볍게 걸으며 쉐어를 모아볼까요?',
          );
        }
        firedLunch = true;
        dirty = true;
      }

      if (!firedEvening && now.hour >= 18) {
        if (currentSteps < 4500) {
          final remain = 4500 - currentSteps;
          await _showSmartPush(
            id: _smartEveningId,
            title: '🚨 비상! 연속 완주 불꽃이 꺼지기 직전!',
            body:
                '남은 $remain보 걷고 오늘의 60 SHARE 꽉 채워가세요. 놓치면 대회 참가가 늦춰져요!',
          );
        }
        firedEvening = true;
        dirty = true;
      }

      if (currentSteps >= 1200 &&
          currentSteps < 1500 &&
          !snipedMilestone1) {
        await _showSmartPush(
          id: _snipeMilestone1Id,
          title: '👀 앗! 첫 번째 보상까지 딱 300보!',
          body: '조금만 더 걸으면 20 SHARE가 지갑에 쏙! 멈추지 마세요 🏃‍♂️',
        );
        snipedMilestone1 = true;
        dirty = true;
      }
      if (currentSteps >= 2700 &&
          currentSteps < 3000 &&
          !snipedMilestone2) {
        await _showSmartPush(
          id: _snipeMilestone2Id,
          title: '🔥 페이스가 아주 좋아요!',
          body: '두 번째 보상 20 SHARE까지 300보 남았습니다. 화이팅!',
        );
        snipedMilestone2 = true;
        dirty = true;
      }
      if (currentSteps >= 4200 &&
          currentSteps < 4500 &&
          !snipedMilestone3) {
        await _showSmartPush(
          id: _snipeMilestone3Id,
          title: '🏆 완주가 눈앞에 보입니다!',
          body: '마지막 300보! 오늘의 메인 챌린지 60 SHARE를 전부 싹쓸이하세요!',
        );
        snipedMilestone3 = true;
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
      snipedMilestone1 = prefs.getBool(_smartPushSnipe1Key) ?? false;
      snipedMilestone2 = prefs.getBool(_smartPushSnipe2Key) ?? false;
      snipedMilestone3 = prefs.getBool(_smartPushSnipe3Key) ?? false;
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
      await prefs.setBool(_smartPushSnipe1Key, snipedMilestone1);
      await prefs.setBool(_smartPushSnipe2Key, snipedMilestone2);
      await prefs.setBool(_smartPushSnipe3Key, snipedMilestone3);
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

  Future<void> _commit(int computed) async {
    try {
      final saved =
          await FlutterForegroundTask.getData<int>(key: _stepsKey) ?? 0;
      final next =
          math.max(computed, math.max(saved, _steps)).toInt();
      final todayIso = KstCalendar.dateKey();
      if (lastSavedDate.isEmpty) {
        lastSavedDate = todayIso;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastSavedDate', lastSavedDate);
          await prefs.setInt('stepOffset', stepOffset);
        } catch (_) {}
      } else if (lastSavedDate != todayIso) {
        final sensorTotal = _lastRaw > 0 ? _lastRaw : next;
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
        snipedMilestone1 = false;
        snipedMilestone2 = false;
        snipedMilestone3 = false;
        _steps = 0;
        _anchor = 0;
        if (_baselineReady) _baseline = _lastRaw;
        await _persistSmartPushFlags(DateTime.now());
        try {
          final prefs = await SharedPreferences.getInstance();
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
      if (next > _steps && _baselineReady && next > computed) {
        _anchor = next;
        _baseline = _lastRaw;
      }
      final changed = next != _steps;
      _steps = next;
      if (!changed) return;
      await _publish(_steps);
      FlutterForegroundTask.sendDataToMain(_steps);
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler commit: $e\n$st');
    } catch (e, st) {
      debugPrint('SoloPedometerForegroundHandler commit: $e\n$st');
    }
  }

  Future<void> _publish(int steps) async {
    try {
      await FlutterForegroundTask.saveData(key: _stepsKey, value: steps);
      await FlutterForegroundTask.saveData(
        key: _stepsAtKey,
        value: DateTime.now().millisecondsSinceEpoch,
      );
      final resolved =
          await SoloPedometerForeground.resolveNotification(rawSteps: steps);
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
  static var _uiBound = false;
  static var _launchConsumed = false;
  static DateTime? _lastOpenAt;
  static GoRouter? _uiRouter;
  static void Function(int steps)? onLiveSteps;

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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = KstCalendar.dateKey();

    final stepOffset = prefs.getInt('${todayKey}_step_offset') ?? 0;
    final claimedSteps = prefs.getInt('${todayKey}_claimed_steps') ?? 0;

    final effectiveSteps = (rawSteps - stepOffset).clamp(0, 999999);
    final pendingShareAmount = 0.0;
    final currentSteps = effectiveSteps;
    late final String title;
    late final String body;

    if (currentSteps >= 4500) {
      title = '챌린지 완주 성공! 🎉';
      body =
          '60 SHARE 획득 완료! 만보 보너스(+20 SHARE)를 향해 전진 중 (${_comma(currentSteps)}/10,000보)';
    } else if (currentSteps >= 1500) {
      title = '숲길 걷는 중 👟';
      body =
          '현재 ${_comma(currentSteps)}보 · 마일스톤 진행 중 (다음 목표: 4,500보)';
    } else {
      title = '셰어런 챌린지 대기 중 🎯';
      body =
          '오늘의 숲길 산책을 시작해 보세요! (${_comma(currentSteps)} / 4,500보)';
    }

    return (
      title: title,
      body: body,
      pendingShare: pendingShareAmount.toDouble(),
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
    if (data is int) {
      onLiveSteps?.call(data);
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
      return await FlutterForegroundTask.getData<int>(key: _stepsKey) ?? 0;
    } on PlatformException catch (e, st) {
      debugPrint('SoloPedometerForeground liveSteps: $e\n$st');
      return 0;
    } catch (e, st) {
      debugPrint('SoloPedometerForeground liveSteps: $e\n$st');
      return 0;
    }
  }

  static Future<int> _mergedSteps(int steps) async {
    final saved = await liveSteps();
    return math.max(steps, saved);
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
      final merged = await _mergedSteps(steps);
      final resolved =
          await resolveNotification(rawSteps: merged);
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
        FlutterForegroundTask.sendDataToTask(merged);
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
  }) async {
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await ensureAlive(
          steps: steps,
          targetKm: targetKm,
          claimedSteps: claimedSteps,
          pendingShare: pendingShare,
        );
        return;
      }
      final merged = await _mergedSteps(steps);
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
      final resolved = await resolveNotification(rawSteps: merged);
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
      FlutterForegroundTask.sendDataToTask(merged);
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
  }) async {
    if (_ensuring) return;
    _ensuring = true;
    try {
      final keep =
          await FlutterForegroundTask.getData<bool>(key: _keepAliveKey) ??
              false;
      if (!keep) return;
      if (await FlutterForegroundTask.isRunningService) return;
      final savedSteps =
          steps ?? await FlutterForegroundTask.getData<int>(key: _stepsKey) ?? 0;
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
