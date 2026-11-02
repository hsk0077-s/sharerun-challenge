import 'dart:io';

import 'package:health/health.dart';

import 'ble_heart_rate_service.dart';
import 'ephemeral_sensor_buffer.dart';
import 'health_connect_store_launcher.dart';

class HealthAuthorizationResult {
  const HealthAuthorizationResult({
    required this.granted,
    this.openedInstall = false,
    this.installLaunchFailed = false,
  });

  final bool granted;
  final bool openedInstall;
  final bool installLaunchFailed;
}

class HealthDataService {
  HealthDataService({
    Health? health,
    BleHeartRateService? bleHeartRateService,
  })  : _health = health ?? Health(),
        _bleHeartRateService = bleHeartRateService;

  final Health _health;
  final BleHeartRateService? _bleHeartRateService;

  /// Health Connect에서는 걸음 수만 읽는다(1.0). 심박수는 Health Connect로 읽지 않고,
  /// BLE 심박 센서(0x180D) 직접 연결로만 받는다.
  static const List<HealthDataType> watchLinkTypes = [
    HealthDataType.STEPS,
  ];

  Future<bool> requestRunDataAuthorization() async {
    if (_bleHeartRateService?.isConnected == true) {
      return true;
    }
    final result = await requestWatchLinkAuthorization();
    return result.granted;
  }

  Future<HealthAuthorizationResult> requestWatchLinkAuthorization() async {
    await _health.configure();

    if (Platform.isAndroid) {
      final ready = await _ensureHealthConnectAvailable();
      if (ready != null) {
        return ready;
      }
    }

    try {
      final types = watchLinkTypes;
      final permissions = List<HealthDataAccess>.filled(
        types.length,
        HealthDataAccess.READ,
      );

      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (!authorized) {
        return const HealthAuthorizationResult(granted: false);
      }

      return const HealthAuthorizationResult(granted: true);
    } on UnsupportedError {
      final installResult = await _openHealthConnectInstallFlow();
      return HealthAuthorizationResult(
        granted: false,
        openedInstall: installResult.opened,
        installLaunchFailed: installResult.failed,
      );
    } catch (_) {
      return const HealthAuthorizationResult(granted: false);
    }
  }

  /// Returns a result when install is required; null when Health Connect is ready.
  Future<HealthAuthorizationResult?> _ensureHealthConnectAvailable() async {
    final status = await _health.getHealthConnectSdkStatus();
    if (status == HealthConnectSdkStatus.sdkAvailable) {
      return null;
    }

    final installResult = await _openHealthConnectInstallFlow();
    return HealthAuthorizationResult(
      granted: false,
      openedInstall: installResult.opened,
      installLaunchFailed: installResult.failed,
    );
  }

  Future<({bool opened, bool failed})> _openHealthConnectInstallFlow() async {
    try {
      await _health.installHealthConnect();
      return (opened: true, failed: false);
    } catch (_) {
      // Fall through to Play Store URL launcher.
    }

    final opened = await HealthConnectStoreLauncher.open();
    return (opened: opened, failed: !opened);
  }

  /// Counts step samples from the last [window] so the UI can tell
  /// "permission granted" apart from "the watch is not writing to Health Connect".
  /// Returns null when the read itself fails.
  Future<HealthRecentSamples?> readRecentSampleCounts({
    Duration window = const Duration(hours: 24),
  }) async {
    final now = DateTime.now();
    try {
      final points = await _health.getHealthDataFromTypes(
        types: watchLinkTypes,
        startTime: now.subtract(window),
        endTime: now,
      );
      var steps = 0;
      for (final point in points) {
        if (point.type == HealthDataType.STEPS) steps++;
      }
      return HealthRecentSamples(stepsCount: steps);
    } catch (_) {
      return null;
    }
  }

  /// Latest BPM from the direct BLE HR sensor (`0x180D`). Null when no sensor is
  /// connected: heart rate is not read from Health Connect.
  Future<int?> readLatestHeartRate() async {
    return _bleHeartRateService?.recentValidBpm();
  }

  Future<HealthRunSamples> readRunSamples({
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final heartRates = <int>[];
    var steps = 0;

    final bleSamples = _bleHeartRateService?.samplesInWindow(
          startedAt: startedAt,
          endedAt: endedAt,
        ) ??
        const <int>[];
    heartRates.addAll(bleSamples);

    try {
      final points = await _health.getHealthDataFromTypes(
        types: watchLinkTypes,
        startTime: startedAt,
        endTime: endedAt,
      );

      for (final point in points) {
        if (point.type == HealthDataType.STEPS) {
          final value = _numValue(point.value)?.round();
          if (value != null && value > 0) {
            steps += value;
          }
        }
      }
    } catch (_) {
      // Allow BLE-only run samples even if Health Connect is not installed.
    }

    final minutes = endedAt.difference(startedAt).inSeconds / 60;
    final cadence = minutes <= 0 ? 0 : (steps / minutes).round();

    return HealthRunSamples(
      heartRates: heartRates,
      cadenceSpm: cadence > 0 ? [cadence] : const [],
      totalSteps: steps,
    );
  }

  num? _numValue(Object value) {
    if (value is NumericHealthValue) {
      return value.numericValue;
    }
    if (value is num) {
      return value;
    }
    return null;
  }
}

class HealthRecentSamples {
  const HealthRecentSamples({required this.stepsCount});

  final int stepsCount;

  bool get isEmpty => stepsCount == 0;
}

class HealthRunSamples {
  const HealthRunSamples({
    required this.heartRates,
    required this.cadenceSpm,
    required this.totalSteps,
  });

  final List<int> heartRates;
  final List<int> cadenceSpm;
  final int totalSteps;

  void writeTo(EphemeralSensorBuffer buffer) {
    for (final bpm in heartRates) {
      buffer.addHeartRate(bpm);
    }
    for (final spm in cadenceSpm) {
      buffer.addCadence(spm);
    }
  }
}
