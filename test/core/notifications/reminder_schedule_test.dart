import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/notifications/reminder_schedule.dart';

void main() {
  test('daily reminders never depend on the exact-alarm permission', () {
    expect(reminderScheduleMode, AndroidScheduleMode.inexactAllowWhileIdle);
    expect(reminderScheduleMode, isNot(AndroidScheduleMode.exactAllowWhileIdle));
    expect(reminderScheduleMode, isNot(AndroidScheduleMode.exact));
  });
}
