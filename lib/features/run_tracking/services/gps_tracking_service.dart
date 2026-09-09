import 'dart:io';

import 'package:geolocator/geolocator.dart';

/// GPS 권한 및 1초 주기 실시간 위치 스트림.
class GpsTrackingService {
  Future<GpsPermissionResult> resolvePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return GpsPermissionResult.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return GpsPermissionResult.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return GpsPermissionResult.denied;
    }
    return GpsPermissionResult.granted;
  }

  Future<bool> ensurePermission() async {
    final result = await resolvePermission();
    return result == GpsPermissionResult.granted;
  }

  Stream<Position> watchOutdoorPosition() {
    return Geolocator.getPositionStream(locationSettings: _liveSettings());
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(locationSettings: _liveSettings());
  }

  LocationSettings _liveSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Share Run Challenge',
          notificationText: '실시간 러닝 GPS 추적 중',
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }
}

enum GpsPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}
