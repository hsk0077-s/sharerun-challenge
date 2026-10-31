import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/remaining_surface.dart';
import 'health_data_service.dart';

class WatchPermissionRequestResult {
  const WatchPermissionRequestResult({
    required this.granted,
    this.missingPermissionLabel,
    this.openedHealthConnectInstall = false,
    this.healthConnectInstallLaunchFailed = false,
  });

  final bool granted;
  final String? missingPermissionLabel;
  final bool openedHealthConnectInstall;
  final bool healthConnectInstallLaunchFailed;
}

/// Requests Android/iOS runtime permissions needed for watch linking and run validation.
class WatchRuntimePermissionsService {
  WatchRuntimePermissionsService({
    required HealthDataService healthDataService,
  }) : _healthDataService = healthDataService;

  final HealthDataService _healthDataService;

  Future<WatchPermissionRequestResult> requestForWatchLinking() async {
    // Health Connect must be checked first — before location or Firestore I/O.
    final healthResult = await _healthDataService.requestWatchLinkAuthorization();
    if (healthResult.openedInstall) {
      return WatchPermissionRequestResult(
        granted: false,
        missingPermissionLabel: RemainingSurface.trNow(
          'run_tracking.watch_runtime_permissions_service.body',
          'Health Connect 앱 설치',
        ),
        openedHealthConnectInstall: true,
        healthConnectInstallLaunchFailed: healthResult.installLaunchFailed,
      );
    }
    if (!healthResult.granted) {
      return WatchPermissionRequestResult(
        granted: false,
        missingPermissionLabel: RemainingSurface.trNow(
          'run_tracking.watch_runtime_permissions_service.body.2',
          'Health Connect 건강 데이터',
        ),
      );
    }

    if (Platform.isAndroid) {
      try {
        final activityStatus = await Permission.activityRecognition.request();
        if (!activityStatus.isGranted) {
          return WatchPermissionRequestResult(
            granted: false,
            missingPermissionLabel: RemainingSurface.trNow(
              'run_tracking.watch_runtime_permissions_service.body.3',
              '신체 활동 인식',
            ),
          );
        }
      } catch (_) {
        return WatchPermissionRequestResult(
          granted: false,
          missingPermissionLabel: RemainingSurface.trNow(
            'run_tracking.watch_runtime_permissions_service.body.3',
            '신체 활동 인식',
          ),
        );
      }
    }

    try {
      final locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (locationServicesEnabled) {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {
      // Location is helpful for runs but must not block watch linking.
    }

    return const WatchPermissionRequestResult(granted: true);
  }
}
