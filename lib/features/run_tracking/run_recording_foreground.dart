import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pedometer/solo_pedometer_foreground.dart';
import 'run_recording_policy.dart';

const _elapsedKey = 'src_run_elapsed';
const _kmKey = 'src_run_km';
const _serviceId = 412;

@pragma('vm:entry-point')
void startRunRecordingForeground() {
  FlutterForegroundTask.setTaskHandler(RunRecordingTaskHandler());
}

class RunRecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_refreshNotification());
  }

  @override
  void onReceiveData(Object data) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() {}

  Future<void> _refreshNotification() async {
    try {
      final elapsed =
          await FlutterForegroundTask.getData<int>(key: _elapsedKey) ?? 0;
      final km = await FlutterForegroundTask.getData<double>(key: _kmKey) ?? 0;
      await FlutterForegroundTask.updateService(
        notificationTitle: runRecordingNotificationTitle,
        notificationText: runRecordingNotificationBody(
          elapsedSeconds: elapsed,
          distanceKm: km,
        ),
      );
    } catch (error, stack) {
      debugPrint('run recording refresh: $error\n$stack');
    }
  }
}

/// Health + location foreground task for an active run.
///
/// The walking service uses the same plugin, so a run borrows it and gives
/// it back when the run ends. A killed process leaves [runRecordingActiveKey]
/// set; the next launch only shows a notice and does not resume.
abstract final class RunRecordingForeground {
  static var _active = false;
  static var _token = 0;

  static Future<void> start() async {
    if (_active) return;
    final token = ++_token;
    _active = true;
    SoloPedometerForeground.runRecording = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(runRecordingActiveKey, true);
      await FlutterForegroundTask.saveData(
        key: SoloPedometerForeground.runRecordingKey,
        value: true,
      );
      await FlutterForegroundTask.saveData(key: _elapsedKey, value: 0);
      await FlutterForegroundTask.saveData(key: _kmKey, value: 0.0);
      if (token != _token) return;
      _init();
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      if (token != _token) return;
      final types = await _serviceTypes();
      if (token != _token) return;
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: types,
        notificationTitle: runRecordingNotificationTitle,
        notificationText: runRecordingNotificationBody(
          elapsedSeconds: 0,
          distanceKm: 0,
        ),
        notificationIcon: SoloPedometerForeground.launcherIcon,
        callback: startRunRecordingForeground,
      );
      if (token != _token || !_active) {
        if (SoloPedometerForeground.runRecording) {
          await _stopServiceIfOurs();
        }
      }
    } catch (error, stack) {
      debugPrint('run recording start: $error\n$stack');
    }
  }

  static Future<void> note({
    required int elapsedSeconds,
    required double distanceKm,
  }) async {
    if (!_active) return;
    final body = runRecordingNotificationBody(
      elapsedSeconds: elapsedSeconds,
      distanceKm: distanceKm,
    );
    try {
      await FlutterForegroundTask.saveData(
        key: _elapsedKey,
        value: elapsedSeconds < 0 ? 0 : elapsedSeconds,
      );
      await FlutterForegroundTask.saveData(
        key: _kmKey,
        value: !distanceKm.isFinite || distanceKm < 0 ? 0.0 : distanceKm,
      );
      if (!_active) return;
      await FlutterForegroundTask.updateService(
        notificationTitle: runRecordingNotificationTitle,
        notificationText: body,
      );
    } catch (error, stack) {
      debugPrint('run recording note: $error\n$stack');
    }
  }

  static Future<void> stop() async {
    if (!_active) {
      _token++;
      return;
    }
    _token++;
    _active = false;
    try {
      await _stopServiceIfOurs();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(runRecordingActiveKey, false);
      SoloPedometerForeground.runRecording = false;
      await FlutterForegroundTask.saveData(
        key: SoloPedometerForeground.runRecordingKey,
        value: false,
      );
    } catch (error, stack) {
      SoloPedometerForeground.runRecording = false;
      debugPrint('run recording stop: $error\n$stack');
    }
    try {
      await SoloPedometerForeground.ensureAlive();
    } catch (error, stack) {
      debugPrint('run recording restore walk: $error\n$stack');
    }
  }

  /// Cold start after a kill. Clears the flag and does not write a ledger.
  static Future<bool> consumeInterruptedRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(runRecordingActiveKey) != true) return false;
      await prefs.setBool(runRecordingActiveKey, false);
      _active = false;
      _token++;
      SoloPedometerForeground.runRecording = false;
      try {
        final owned = await FlutterForegroundTask.getData<bool>(
              key: SoloPedometerForeground.runRecordingKey,
            ) ??
            false;
        await FlutterForegroundTask.saveData(
          key: SoloPedometerForeground.runRecordingKey,
          value: false,
        );
        if (owned && await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
      } catch (error, stack) {
        debugPrint('run recording leftover: $error\n$stack');
      }
      return true;
    } catch (error, stack) {
      debugPrint('run recording interrupt read: $error\n$stack');
      return false;
    }
  }

  static void _init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'src_run_recording',
        channelName: '달리기 기록',
        channelDescription: '화면이 꺼져도 달리기 경로와 음성 코칭을 이어갑니다.',
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
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowAutoRestart: false,
        stopWithTask: false,
      ),
    );
  }

  /// Location type requires a while-in-use grant on Android 14+.
  /// Never asks for always-on background location.
  static Future<List<ForegroundServiceTypes>> _serviceTypes() async {
    if (!Platform.isAndroid) {
      return const [ForegroundServiceTypes.health];
    }
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!granted) return const [ForegroundServiceTypes.health];
    } catch (error, stack) {
      debugPrint('run recording location type: $error\n$stack');
      return const [ForegroundServiceTypes.health];
    }
    return const [
      ForegroundServiceTypes.health,
      ForegroundServiceTypes.location,
    ];
  }

  static Future<void> _stopServiceIfOurs() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}
