import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/router/route_names.dart';
import '../onboarding/src_onboarding_controller.dart';
import 'pedometer_step_truth.dart';
import 'solo_pedometer_foreground.dart';
import '../../core/notifications/reminder_preferences.dart';
import '../../core/notifications/reminder_schedule.dart';
import '../../core/notifications/reminder_zone.dart';

const _goldenChannelId = 'src_walking_golden_hour';
const _goldenChannelName = '워킹챌린지 코인 줍기';
const _payload = RouteNames.soloPedometerPath;

@pragma('vm:entry-point')
void walkingChallengeNotificationTapBackground(NotificationResponse response) {
  // Payload is consumed on the next UI isolate via launch details / tap callback.
}

/// 워킹챌린지 골든타임 로컬 푸시 스케줄러.
abstract final class WalkingChallengeNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static var _ready = false;

  /// 알림을 눌러 앱이 열렸으면 true. 시작 화면을 건너뛰는 데 쓴다.
  static final ValueNotifier<bool> launchedFromNotification =
      ValueNotifier<bool>(false);

  static Future<void> ensureInitialized() async {
    try {
      await ensureReminderTimeZone();
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
      final android = _plugin.resolvePlatformSpecificImplementation<
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
      for (final id in legacyGoldenReminderIds) {
        await _cancel(id);
      }
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        launchedFromNotification.value = true;
      }
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

  /// 저녁 알림 하나만 사용자 이름을 넣은 문구로 바꿔 예약한다. 일반 알림의 저녁 알림과
  /// 같은 번호라서 하루에 저녁 알림은 한 번만 온다. 아침·낮은 일반 알림이 맡는다.
  static Future<void> syncDailyPushes({
    required bool enabled,
    required String nickname,
  }) async {
    try {
      await ensureInitialized();
      if (!await ReminderPreferences.isEnabled()) {
        await _cancel(walkingEveningReminderId);
        return;
      }
      if (!enabled ||
          !usesPersonalEveningCopy(
            PlatformDispatcher.instance.locale.languageCode,
          )) {
        // 일반(번역된) 저녁 알림이 그대로 남는다.
        return;
      }
      final name = _displayName(nickname);
      await _scheduleDaily(
        id: walkingEveningReminderId,
        hour: 20,
        minute: 30,
        title: '🚨 $name님, 아직 안 주운 SHARE',
        body: WalkingChallengeNotificationCopy.goldenEveningBody(),
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
    await ensureReminderTimeZone();
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
      _nextLocal(hour, minute),
      details,
      androidScheduleMode: reminderScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _payload,
    );
  }

  static tz.TZDateTime _nextLocal(int hour, int minute) {
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
