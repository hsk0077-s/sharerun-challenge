import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../models/activity_packet.dart';

/// 차량·킥보드 탑승 필터링용 가속도 1Hz 스냅샷.
class AccelerometerCollectorService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  AccelerometerEvent? _latest;
  final List<AccelerometerSample> _samples = [];

  void start() {
    _samples.clear();
    _latest = null;
    _subscription?.cancel();
    _subscription = accelerometerEventStream().listen((event) {
      _latest = event;
    });
  }

  void captureSnapshot({required int elapsedSeconds}) {
    final latest = _latest;
    if (latest == null) return;
    _samples.add(
      AccelerometerSample(
        x: latest.x,
        y: latest.y,
        z: latest.z,
        recordedAt: DateTime.now(),
        elapsedSeconds: elapsedSeconds,
      ),
    );
    if (_samples.length > 7200) {
      _samples.removeAt(0);
    }
  }

  List<AccelerometerSample> snapshot() =>
      List<AccelerometerSample>.unmodifiable(_samples);

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _latest = null;
  }

  void clear() => _samples.clear();
}
