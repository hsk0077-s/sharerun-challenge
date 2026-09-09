import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

@immutable
class RunTrackerState {
  const RunTrackerState({
    required this.isRunning,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.currentPace,
    this.lastError,
  });

  final bool isRunning;
  final double distanceKm;
  final int elapsedSeconds;
  final String currentPace;
  final String? lastError;

  factory RunTrackerState.initial() {
    return const RunTrackerState(
      isRunning: false,
      distanceKm: 0,
      elapsedSeconds: 0,
      currentPace: '--:-- /KM',
    );
  }

  RunTrackerState copyWith({
    bool? isRunning,
    double? distanceKm,
    int? elapsedSeconds,
    String? currentPace,
    String? lastError,
    bool clearError = false,
  }) {
    return RunTrackerState(
      isRunning: isRunning ?? this.isRunning,
      distanceKm: distanceKm ?? this.distanceKm,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentPace: currentPace ?? this.currentPace,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final runTrackerProvider =
    NotifierProvider<RunTrackerNotifier, RunTrackerState>(RunTrackerNotifier.new);

class RunTrackerNotifier extends Notifier<RunTrackerState> {
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;

  @override
  RunTrackerState build() {
    ref.onDispose(_cleanup);
    return RunTrackerState.initial();
  }

  Future<void> startRun() async {
    if (state.isRunning) return;

    try {
      final granted = await _ensureLocationPermission();
      if (!granted) {
        state = state.copyWith(
          lastError: '위치 권한이 필요합니다. 설정에서 허용해 주세요.',
        );
        return;
      }

      _cleanup();
      _lastPosition = null;
      state = RunTrackerState.initial().copyWith(isRunning: true, clearError: true);

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final nextSeconds = state.elapsedSeconds + 1;
        state = state.copyWith(
          elapsedSeconds: nextSeconds,
          currentPace: formatPace(
            elapsedSeconds: nextSeconds,
            distanceKm: state.distanceKm,
          ),
        );
      });

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      ).listen(
        _onPosition,
        onError: (Object e) {
          debugPrint('RunTracker GPS error: $e');
          state = state.copyWith(lastError: 'GPS 수신 중 오류가 발생했습니다.');
        },
      );
    } catch (e) {
      debugPrint('RunTracker startRun error: $e');
      _cleanup();
      state = RunTrackerState.initial().copyWith(
        lastError: '달리기를 시작할 수 없습니다. 위치 서비스를 확인해 주세요.',
      );
    }
  }

  Future<void> stopRun() async {
    _cleanup();
    state = state.copyWith(
      isRunning: false,
      currentPace: formatPace(
        elapsedSeconds: state.elapsedSeconds,
        distanceKm: state.distanceKm,
      ),
      clearError: true,
    );
  }

  void reset() {
    _cleanup();
    state = RunTrackerState.initial();
  }

  void _onPosition(Position position) {
    if (!state.isRunning) return;

    var distanceKm = state.distanceKm;
    final previous = _lastPosition;
    if (previous != null) {
      final deltaMeters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      if (deltaMeters.isFinite && deltaMeters > 0) {
        distanceKm += deltaMeters / 1000.0;
      }
    }
    _lastPosition = position;

    state = state.copyWith(
      distanceKm: distanceKm,
      currentPace: formatPace(
        elapsedSeconds: state.elapsedSeconds,
        distanceKm: distanceKm,
      ),
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    _positionSub?.cancel();
    _positionSub = null;
    _lastPosition = null;
  }

  /// Pace as `m:ss /KM` from elapsed time and distance.
  static String formatPace({
    required int elapsedSeconds,
    required double distanceKm,
  }) {
    if (distanceKm < 0.01 || elapsedSeconds <= 0) {
      return '--:-- /KM';
    }
    final secPerKm = elapsedSeconds / distanceKm;
    if (!secPerKm.isFinite || secPerKm <= 0) {
      return '--:-- /KM';
    }
    final total = secPerKm.round().clamp(0, 59 * 60);
    final minutes = total ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString();
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss /KM';
  }
}
