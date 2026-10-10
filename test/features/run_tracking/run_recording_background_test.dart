import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/run_tracking/run_recording_policy.dart';

void main() {
  test('notification shows elapsed time and distance', () {
    expect(
      runRecordingNotificationBody(elapsedSeconds: 0, distanceKm: 0),
      '00:00 · 0.00 km',
    );
    expect(
      runRecordingNotificationBody(elapsedSeconds: 75, distanceKm: 1.2),
      '01:15 · 1.20 km',
    );
    expect(
      runRecordingNotificationBody(elapsedSeconds: 3661, distanceKm: 10),
      '1:01:01 · 10.00 km',
    );
  });

  test('warns only when a run is starting with a gap', () {
    expect(
      shouldWarnRunMayStop(
        beforeRun: true,
        locationReady: true,
        notificationReady: true,
        batteryReady: true,
      ),
      isFalse,
    );
    expect(
      shouldWarnRunMayStop(
        beforeRun: true,
        locationReady: false,
        notificationReady: true,
        batteryReady: true,
      ),
      isTrue,
    );
    expect(
      shouldWarnRunMayStop(
        beforeRun: false,
        locationReady: false,
        notificationReady: false,
        batteryReady: false,
      ),
      isFalse,
    );
  });

  test('korean copy does not offer resume or a reward', () {
    expect(runRecordingNotificationTitle, '쉐어런 · 달리기 기록 중');
    expect(runRecordingChecklistMenuLabel, '달리기 기록 설정 점검');
    expect(runRecordingBatteryGuidance, contains('제한 없음'));
    expect(interruptedRunTitle, '이전 달리기가 중단되었습니다');
    expect(interruptedRunBody, contains('보상은 지급되지 않고'));
    expect(interruptedRunBody, contains('기록도 남지 않습니다'));
    expect(recordingMayStopWarning, contains('화면이 꺼지면'));
  });

  test('manifest allows health and location without battery exemption', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
      manifest,
      contains('android:foregroundServiceType="health|location"'),
    );
    expect(manifest.contains('REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'), isFalse);
  });

  test('checklist does not request always location or the battery dialog', () {
    final source = File(
      'lib/features/run_tracking/run_recording_checklist.dart',
    ).readAsStringSync();
    expect(source.contains('locationAlways'), isFalse);
    expect(source.contains('Permission.location'), isFalse);
    expect(source.contains('requestIgnoreBatteryOptimization('), isFalse);
    expect(source.contains('openIgnoreBatteryOptimizationSettings'), isTrue);
    expect(source.contains('Geolocator.requestPermission'), isTrue);
  });
}
