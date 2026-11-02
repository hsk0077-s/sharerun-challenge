import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:share_run_challenge/features/run_tracking/services/health_data_service.dart';

void main() {
  test('Health Connect asks only for steps (no heart rate)', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final perms =
        File('android/app/src/main/res/values/health_permissions.xml')
            .readAsStringSync();
    expect(manifest, isNot(contains('READ_HEART_RATE')));
    expect(perms, isNot(contains('READ_HEART_RATE')));
    expect(perms, contains('READ_STEPS'));
    expect(HealthDataService.watchLinkTypes, [HealthDataType.STEPS]);
  });
}
