import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/jena_validation/models/jena_validation_request.dart';
import 'package:share_run_challenge/features/jena_validation/run_device_info.dart';

void main() {
  test('device info keeps model, OS, app version, and heart-rate use',
      () async {
    final info = await RunDeviceInfo.collect(
      watchUsed: false,
      heartRateUsed: true,
      readDevice: () async => (
        model: 'SM-N970F\nextra',
        osVersion: 'Android 12',
      ),
      readAppVersion: () async => '1.0.0+12',
    );

    expect(info.toJson(), {
      'model': 'SM-N970F extra',
      'os_version': 'Android 12',
      'app_version': '1.0.0+12',
      'watch_used': false,
      'heart_rate_used': true,
    });
    expect(info.toJson().keys, [
      'model',
      'os_version',
      'app_version',
      'watch_used',
      'heart_rate_used',
    ]);
  });

  test('the validate payload sends device info and nothing else', () {
    const info = RunDeviceInfo(
      model: 'SM-N970F',
      osVersion: 'Android 12',
      appVersion: '1.0.0',
      watchUsed: true,
      heartRateUsed: false,
    );
    final json = JenaValidationRequest(
      activityId: 'activity-1',
      userId: 'user-1',
      distanceKm: 2,
      durationSeconds: 700,
      heartRates: const [],
      cadenceSpm: const [160],
      gyroStabilityScore: 0.4,
      deviceInfo: info,
    ).toJson();

    expect(json['device_info'], info.toJson());
    expect(json['device_info'].keys, isNot(contains('email')));
    expect(json.containsKey('device_id'), isFalse);
  });

  test('Android release number becomes a readable OS label', () {
    expect(androidOsLabel('12'), 'Android 12');
    expect(androidOsLabel(' 16\n'), 'Android 16');
    expect(androidOsLabel(''), isNull);
  });
}
