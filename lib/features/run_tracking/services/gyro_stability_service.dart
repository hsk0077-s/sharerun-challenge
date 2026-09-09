import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class GyroStabilityService {
  StreamSubscription<GyroscopeEvent>? _subscription;
  final List<double> _magnitudes = [];

  void start() {
    _magnitudes.clear();
    _subscription?.cancel();
    _subscription = gyroscopeEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      _magnitudes.add(magnitude);

      if (_magnitudes.length > 600) {
        _magnitudes.removeAt(0);
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  double calculateStabilityScore() {
    if (_magnitudes.length < 2) {
      return 1;
    }

    var totalDelta = 0.0;
    for (var index = 1; index < _magnitudes.length; index++) {
      totalDelta += (_magnitudes[index] - _magnitudes[index - 1]).abs();
    }

    final averageDelta = totalDelta / (_magnitudes.length - 1);
    final normalizedMotion = (averageDelta / 2).clamp(0.0, 1.0);
    return 1 - normalizedMotion;
  }
}
