import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/user_model.dart';
import '../../run_tracking/services/ephemeral_sensor_buffer.dart';
import '../../run_tracking/services/health_data_service.dart';

/// Jena AI 검증 파이프라인 전송 준비 완료 이벤트.
@immutable
class JenaPipelineReadyEvent {
  const JenaPipelineReadyEvent({
    required this.at,
    required this.watchType,
    required this.heartRateSampleCount,
    required this.cadenceSampleCount,
  });

  final DateTime at;
  final WatchType watchType;
  final int heartRateSampleCount;
  final int cadenceSampleCount;
}

/// 원본 HR/케이던스를 로컬 메모리에만 적재한 뒤 Jena 준비 이벤트를 방출한다.
class WatchLinkTelemetryService {
  WatchLinkTelemetryService({
    required HealthDataService healthDataService,
    EphemeralSensorBuffer? buffer,
  })  : _healthDataService = healthDataService,
        _buffer = buffer ?? EphemeralSensorBuffer();

  final HealthDataService _healthDataService;
  final EphemeralSensorBuffer _buffer;
  final StreamController<JenaPipelineReadyEvent> _readyController =
      StreamController<JenaPipelineReadyEvent>.broadcast();

  Stream<JenaPipelineReadyEvent> get readyEvents => _readyController.stream;

  Future<void> stageForJenaPipeline({required WatchType watchType}) async {
    final heartRates = <int>[];
    final cadenceSpm = <int>[];

    try {
      final latestHr = await _healthDataService.readLatestHeartRate();
      if (latestHr != null && latestHr > 0) {
        heartRates.add(latestHr);
      }
    } catch (error, stackTrace) {
      debugPrint('WatchLinkTelemetry HR cache skipped: $error\n$stackTrace');
    }

    _buffer.destroy();
    for (final bpm in heartRates) {
      _buffer.addHeartRate(bpm);
    }
    for (final spm in cadenceSpm) {
      _buffer.addCadence(spm);
    }

    if (!_readyController.isClosed) {
      _readyController.add(
        JenaPipelineReadyEvent(
          at: DateTime.now(),
          watchType: watchType,
          heartRateSampleCount: heartRates.length,
          cadenceSampleCount: cadenceSpm.length,
        ),
      );
    }
  }

  void dispose() {
    _buffer.destroy();
    unawaited(_readyController.close());
  }
}
