import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/app_env.dart';
import '../../core/constants/economy_constants.dart';
import '../onboarding/src_onboarding_controller.dart';

class SoloPedometerSample {
  const SoloPedometerSample({
    required this.steps,
    required this.km,
  });

  final int steps;
  final double km;
}

class FloatingCoin {
  const FloatingCoin({
    required this.id,
    required this.tenthIndex,
    required this.dx,
    required this.dy,
  });

  final String id;
  final int tenthIndex;
  final double dx;
  final double dy;

  factory FloatingCoin.forTenth(int tenthIndex) {
    final dx = -0.82 + ((tenthIndex * 0.41) % 1.64);
    var dy = -0.62 + ((tenthIndex * 0.29) % 1.18);
    if (dx.abs() < 0.18 && dy.abs() < 0.22) {
      dy = dy < 0 ? -0.48 : 0.52;
    }
    return FloatingCoin(
      id: 'coin-$tenthIndex',
      tenthIndex: tenthIndex,
      dx: dx.clamp(-0.88, 0.88),
      dy: dy.clamp(-0.72, 0.78),
    );
  }
}

/// GPS/Jena 없이 걸음 수 → 추정 km. Health + pedometer (+ mock).
class SoloPedometerEngine {
  SoloPedometerEngine();

  final Health _health = Health();
  final _controller = StreamController<SoloPedometerSample>.broadcast();
  StreamSubscription<StepCount>? _pedoSub;
  Timer? _healthTimer;
  Timer? _mockTimer;
  var _disposed = false;
  var _baselineSteps = 0;
  var _baselineReady = false;
  var _sessionDelta = 0;
  var _todayHealthSteps = 0;
  var _healthAtStart = 0;

  Stream<SoloPedometerSample> get samples => _controller.stream;

  static double kmFromSteps(int steps) {
    if (steps <= 0) return 0;
    return (steps * EconomyConstants.pedometerStrideMeters) / 1000.0;
  }

  static const _stepTypes = [HealthDataType.STEPS];
  static const _stepAccess = [HealthDataAccess.READ];

  Future<void> start() async {
    await requestHealthPermissions();
    final today = await _queryTodaySteps();
    if (today != null) {
      _todayHealthSteps = today;
      _healthAtStart = today;
      _emit();
    }
    _listenPedometer();
    _healthTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(syncBackgroundSteps(requestIfMissing: false));
    });
    if (AppEnv.useLocalMockData) {
      _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _sessionDelta += 28;
        _emit();
      });
    }
  }

  /// STEPS + Activity Recognition. 미허용 시 OS 팝업.
  Future<bool> requestHealthPermissions() async {
    try {
      await Permission.activityRecognition.request();
    } on PlatformException {
      // 권한 채널 실패는 무시하고 HealthKit/Health Connect로 이어간다.
    } catch (_) {}
    try {
      await Permission.sensors.request();
    } on PlatformException {
      // iOS 등 sensors 미지원.
    } catch (_) {}
    try {
      await _health.configure();
      var granted = await _health.hasPermissions(
        _stepTypes,
        permissions: _stepAccess,
      );
      if (granted != true) {
        granted = await _health.requestAuthorization(
          _stepTypes,
          permissions: _stepAccess,
        );
      }
      try {
        await _health.requestHealthDataInBackgroundAuthorization();
      } on PlatformException {
        // 백그라운드 Health 미지원 기기.
      } catch (_) {}
      return granted == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 당일 00:00(KST)~현재 Health 누적 걸음으로 게이지를 덮어쓴다.
  Future<void> syncBackgroundSteps({bool requestIfMissing = true}) async {
    if (AppEnv.useLocalMockData && !requestIfMissing) {
      _emit();
      return;
    }
    if (requestIfMissing) {
      await requestHealthPermissions();
    }
    final today = await _queryTodaySteps();
    if (today == null) return;
    _todayHealthSteps = today;
    _healthAtStart = today;
    _sessionDelta = 0;
    _baselineReady = false;
    _emit();
  }

  Future<void> syncFromHealth() =>
      syncBackgroundSteps(requestIfMissing: false);

  Future<int> readTodaySteps() async {
    return await _queryTodaySteps() ?? _todayHealthSteps;
  }

  Future<int?> _queryTodaySteps() async {
    return PedometerKstClock.queryTodaySteps(_health);
  }

  void _listenPedometer() {
    try {
      _pedoSub = Pedometer.stepCountStream.listen(
        (event) {
          final raw = event.steps;
          if (!_baselineReady) {
            _baselineSteps = raw;
            _baselineReady = true;
            return;
          }
          _sessionDelta = math.max(0, raw - _baselineSteps);
          _emit();
        },
        onError: (Object _) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  void _emit() {
    if (_disposed || _controller.isClosed) return;
    final steps = math.max(_todayHealthSteps, _healthAtStart + _sessionDelta);
    final km = kmFromSteps(steps).clamp(0.0, 10.0);
    _controller.add(SoloPedometerSample(steps: steps, km: km.toDouble()));
  }

  Future<void> dispose() async {
    _disposed = true;
    await _pedoSub?.cancel();
    _healthTimer?.cancel();
    _mockTimer?.cancel();
    await _controller.close();
  }
}
