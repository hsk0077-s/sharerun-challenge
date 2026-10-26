import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/notifications/reminder_schedule.dart';

void main() {
  test('daily reminders never depend on the exact-alarm permission', () {
    expect(reminderScheduleMode, AndroidScheduleMode.inexactAllowWhileIdle);
    expect(
        reminderScheduleMode, isNot(AndroidScheduleMode.exactAllowWhileIdle));
    expect(reminderScheduleMode, isNot(AndroidScheduleMode.exact));
  });

  group('resolveReminderZone', () {
    test('uses the device time zone when it is known', () async {
      final zone = await resolveReminderZone(
        () async => 'America/New_York',
        isKnown: (_) => true,
      );
      expect(zone, 'America/New_York');
    });

    test('falls back to Seoul when the lookup fails or the name is unknown',
        () async {
      expect(
        await resolveReminderZone(
          () async => throw StateError('no plugin'),
          isKnown: (_) => true,
        ),
        reminderFallbackZone,
      );
      expect(
        await resolveReminderZone(
          () async => 'Mars/Olympus',
          isKnown: (_) => false,
        ),
        reminderFallbackZone,
      );
      expect(
        await resolveReminderZone(() async => '  ', isKnown: (_) => true),
        reminderFallbackZone,
      );
    });
  });

  group('reminderCopyFor', () {
    test('every supported app language has its own copy', () {
      for (final code in [
        'ko',
        'en',
        'ja',
        'zh',
        'es',
        'pt',
        'de',
        'fr',
        'vi',
        'th',
        'id'
      ]) {
        expect(reminderCopyByLanguage.containsKey(code), isTrue, reason: code);
      }
    });

    test('unknown languages get English, Korean stays Korean', () {
      expect(
          reminderCopyFor('xx').channelName, reminderCopyFor('en').channelName);
      expect(reminderCopyFor('KO').morningTitle, contains('아침'));
    });
  });
}
