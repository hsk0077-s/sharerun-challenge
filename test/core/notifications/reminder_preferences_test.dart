import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_run_challenge/core/notifications/reminder_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reminders are on until the user turns them off', () async {
    expect(await ReminderPreferences.isEnabled(), isTrue);
    await ReminderPreferences.setEnabled(false);
    expect(await ReminderPreferences.isEnabled(), isFalse);
    await ReminderPreferences.setEnabled(true);
    expect(await ReminderPreferences.isEnabled(), isTrue);
  });
}
