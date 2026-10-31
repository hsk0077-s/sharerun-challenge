import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'reminder_preferences.dart';
import 'reminder_schedule.dart';
import 'reminder_zone.dart';

/// 워킹챌린지 매일 반복 로컬 푸시 (기기 현지 시간 08:30 / 12:30 / 20:30).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'src_walking_daily_encourage';
  static const _morningId = 20830;
  static const _lunchId = 21230;
  static const _eveningId = walkingEveningReminderId;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _ready = false;

  ReminderCopy get _copy =>
      reminderCopyFor(PlatformDispatcher.instance.locale.languageCode);

  Future<void> initialize() async {
    try {
      await ensureReminderTimeZone();
      if (_ready) {
        await applyPreference(await ReminderPreferences.isEnabled());
        return;
      }

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_sharerun'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _plugin.initialize(initSettings);

      await _requestPermissions();
      await _ensureAndroidChannel();
      _ready = true;
      await applyPreference(await ReminderPreferences.isEnabled());
    } catch (e, st) {
      debugPrint('NotificationService initialize: $e\n$st');
    }
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      await android?.requestNotificationsPermission();
    } catch (e, st) {
      debugPrint('NotificationService POST_NOTIFICATIONS: $e\n$st');
    }
    // 리마인더는 정확한 알람이 필요 없는 방식(inexactAllowWhileIdle)이고 매니페스트에도
    // SCHEDULE_EXACT_ALARM이 없다. 여기서 정확한 알람 권한을 요청하면 안드로이드 설정의
    // "알람 및 리마인더" 화면이 앱 시작 때 열린다.

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    try {
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e, st) {
      debugPrint('NotificationService iOS perm: $e\n$st');
    }
  }

  Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final copy = _copy;
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        copy.channelName,
        description: copy.channelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// 설정에서 켜고 끌 때와 앱을 켤 때 호출한다. 끄면 예약된 알림을 모두 지운다.
  Future<void> applyPreference(bool enabled) async {
    try {
      if (enabled) {
        await scheduleDailyWalkingReminders();
      } else {
        await _plugin.cancel(_morningId);
        await _plugin.cancel(_lunchId);
        await _plugin.cancel(_eveningId);
      }
    } catch (e, st) {
      debugPrint('NotificationService applyPreference: $e\n$st');
    }
  }

  Future<void> scheduleDailyWalkingReminders() async {
    await ensureReminderTimeZone();
    final copy = _copy;
    await _scheduleDaily(
      id: _morningId,
      hour: 8,
      minute: 30,
      title: copy.morningTitle,
      body: copy.morningBody,
    );
    await _scheduleDaily(
      id: _lunchId,
      hour: 12,
      minute: 30,
      title: copy.lunchTitle,
      body: copy.lunchBody,
    );
    await _scheduleDaily(
      id: _eveningId,
      hour: 20,
      minute: 30,
      title: copy.eveningTitle,
      body: copy.eveningBody,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final copy = _copy;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        copy.channelName,
        channelDescription: copy.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextLocal(hour, minute),
      details,
      androidScheduleMode: reminderScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextLocal(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }
}
