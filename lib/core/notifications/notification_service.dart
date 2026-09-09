import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 워킹챌린지 매일 반복 로컬 푸시 (08:30 / 12:30 / 20:30 KST).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'src_walking_daily_encourage';
  static const _channelName = '워킹챌린지 참여 독려';
  static const _morningId = 20830;
  static const _lunchId = 21230;
  static const _eveningId = 22030;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _ready = false;
  var _tzReady = false;

  void _ensureTimeZones() {
    if (_tzReady) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    _tzReady = true;
  }

  Future<void> initialize() async {
    try {
      _ensureTimeZones();
      if (_ready) {
        await scheduleDailyWalkingReminders();
        return;
      }

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
      await scheduleDailyWalkingReminders();
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
    try {
      await android?.requestExactAlarmsPermission();
    } catch (e, st) {
      debugPrint('NotificationService exact alarm: $e\n$st');
    }

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
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: '워킹챌린지 아침·점심·저녁 참여 독려',
        importance: Importance.high,
      ),
    );
  }

  Future<void> scheduleDailyWalkingReminders() async {
    _ensureTimeZones();
    await _scheduleDaily(
      id: _morningId,
      hour: 8,
      minute: 30,
      title: '🏃 활기찬 아침, 오늘의 첫걸음을 시작해 보세요!',
      body: '오늘 하루 걷는 모든 발걸음이 소중한 쉐어토큰이 됩니다.',
    );
    await _scheduleDaily(
      id: _lunchId,
      hour: 12,
      minute: 30,
      title: '☕ 가벼운 산책으로 활력을 충전해 볼까요?',
      body: '잠깐의 가벼운 걸음이 오늘의 챌린지 목표를 완성합니다.',
    );
    await _scheduleDaily(
      id: _eveningId,
      hour: 20,
      minute: 30,
      title: '🎁 오늘 획득할 수 있는 쉐어토큰이 남아있어요!',
      body: '오늘의 걸음을 인증하고 준비된 토큰 보상을 놓치지 마세요.',
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: '워킹챌린지 아침·점심·저녁 참여 독려',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextKst(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextKst(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }
}
