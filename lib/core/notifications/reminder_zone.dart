import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_schedule.dart';

Future<void>? _zoneSetup;

/// 알림 예약에 쓰는 시간대를 기기의 현재 시간대로 한 번 맞춘다.
/// 알림을 예약하는 모든 서비스가 같은 시간대를 쓰도록 여기서만 정한다.
/// 시간대를 알 수 없으면 한국 시간([reminderFallbackZone]).
Future<void> ensureReminderTimeZone() => _zoneSetup ??= _setUp();

Future<void> _setUp() async {
  tz.initializeTimeZones();
  final zone = await resolveReminderZone(
    () async => (await FlutterTimezone.getLocalTimezone()).identifier,
    isKnown: (name) {
      try {
        tz.getLocation(name);
        return true;
      } catch (_) {
        return false;
      }
    },
  );
  tz.setLocalLocation(tz.getLocation(zone));
}
