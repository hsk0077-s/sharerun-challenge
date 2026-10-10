import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/privacy/login_devices.dart';
import 'package:share_run_challenge/screens/login_devices_screen.dart';

Widget _host(List<LoginDevice> rows) {
  return ProviderScope(
    overrides: [loginDevicesProvider.overrideWith((ref) async => rows)],
    child: const MaterialApp(home: LoginDevicesScreen()),
  );
}

void main() {
  test('a device row keeps only model, OS, app version and last seen', () {
    final row = LoginDevice.fromJson({
      'device_id': 'abc',
      'model': 'SM-N970N',
      'os_version': 'Android 12',
      'app_version': '1.0+3',
      'last_seen_at': '2026-10-10T09:00:00+00:00',
      'current': true,
    });
    expect(row.model, 'SM-N970N');
    expect(row.current, isTrue);
    expect(row.lastSeenAt, isNotNull);
  });

  testWidgets('lists devices, marks this one, and promises no location',
      (tester) async {
    await tester.pumpWidget(
      _host([
        LoginDevice.fromJson({
          'device_id': 'a',
          'model': 'Galaxy Note10',
          'os_version': 'Android 12',
          'app_version': '1.0+3',
          'last_seen_at': '2026-10-10T09:00:00+00:00',
          'current': true,
        }),
        LoginDevice.fromJson({
          'device_id': 'b',
          'model': 'Pixel 8',
          'os_version': 'Android 15',
          'app_version': '1.0+2',
          'last_seen_at': '2026-10-09T09:00:00+00:00',
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Galaxy Note10 (이 기기)'), findsOneWidget);
    expect(find.text('Pixel 8'), findsOneWidget);
    expect(find.textContaining('IP 주소는 저장하지 않아요'), findsOneWidget);
    expect(find.byKey(LoginDevicesScreen.signOutKey), findsOneWidget);
  });

  testWidgets('sign out everywhere asks first and cancel does nothing',
      (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(LoginDevicesScreen.signOutKey));
    await tester.tap(find.byKey(LoginDevicesScreen.signOutKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('이 폰을 포함해'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.textContaining('이 폰을 포함해'), findsNothing);
  });
}
