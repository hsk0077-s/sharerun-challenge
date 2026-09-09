import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../app/router/route_names.dart';
import '../onboarding/src_onboarding_controller.dart';
import 'solo_pedometer_foreground.dart';

const _goldenChannelId = 'src_walking_golden_hour';
const _goldenChannelName = '워킹챌린지 코인 줍기';
const _payload = RouteNames.soloPedometerPath;
const _morningId = 830;
const _lunchId = 1330;
const _eveningId = 2130;

@pragma('vm:entry-point')
void walkingChallengeNotificationTapBackground(NotificationResponse response) {
  // Payload is consumed on the next UI isolate via launch details / tap callback.
}

/// 워킹챌린지 골든타임 로컬 푸시 스케줄러.
abstract final class WalkingChallengeNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static var _ready = false;
  static var _tzReady = false;

  static void _ensureTimeZones() {
    if (_tzReady) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    _tzReady = true;
  }

  static Future<void> ensureInitialized() async {
    try {
      _ensureTimeZones();
      if (_ready) return;
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onTap,
        onDidReceiveBackgroundNotificationResponse:
            walkingChallengeNotificationTapBackground,
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.requestNotificationsPermission();
      } catch (e, st) {
        debugPrint('WalkingChallengeNotificationService perm: $e\n$st');
      }
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _goldenChannelId,
          _goldenChannelName,
          description: '워킹챌린지 아침·점심·저녁 코인 수집 리마인더',
          importance: Importance.high,
        ),
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && payload == _payload) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SoloPedometerForeground.openWalkingChallenge();
        });
      }
    } catch (e, st) {
      debugPrint('WalkingChallengeNotificationService init: $e\n$st');
    }
  }

  static void _onTap(NotificationResponse response) {
    if (response.payload != _payload) return;
    SoloPedometerForeground.openWalkingChallenge();
  }

  static Future<void> syncDailyPushes({
    required bool enabled,
    required String nickname,
    required double pendingShare,
  }) async {
    try {
      await ensureInitialized();
      if (!enabled) {
        await _cancel(_morningId);
        await _cancel(_lunchId);
        await _cancel(_eveningId);
        return;
      }
      final name = _displayName(nickname);
      final coins = pendingShare.ceil();
      await _scheduleDaily(
        id: _morningId,
        hour: 8,
        minute: 30,
        title: '🏃‍♂️ $name님, 오늘 아침 걸음 정산!',
        body: '아침 걸음이 벌써 $coins SHARE로 피어났어요. 사라지기 전에 지금 수집해 보세요.',
      );
      await _scheduleDaily(
        id: _lunchId,
        hour: 13,
        minute: 30,
        title: '🏃‍♂️ $name님, 가뿐한 오후의 혜택',
        body: '가볍게 걸은 걸음이 벌써 $coins SHARE로 피어났어요. 사라지기 전에 지금 수집해 보세요.',
      );
      await _scheduleDaily(
        id: _eveningId,
        hour: 21,
        minute: 30,
        title: '🚨 $name님, 미수집 코인 소멸 경보!',
        body: '오늘 모은 $coins SHARE가 잠시 후 자정에 완전히 소멸해요! 지금 즉시 터치하여 보관하세요.',
      );
    } catch (e, st) {
      debugPrint('WalkingChallengeNotificationService sync: $e\n$st');
    }
  }

  static Future<void> _cancel(int id) => _plugin.cancel(id);

  static String _displayName(String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty || SrcOnboardingController.isUnsetNickname(trimmed)) {
      return '러너';
    }
    return trimmed;
  }

  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    _ensureTimeZones();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _goldenChannelId,
        _goldenChannelName,
        channelDescription: '워킹챌린지 아침·점심·저녁 코인 수집 리마인더',
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
      payload: _payload,
    );
  }

  static tz.TZDateTime _nextKst(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }
}
