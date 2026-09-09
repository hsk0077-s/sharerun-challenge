import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/activity_packet.dart';
import '../models/route_point.dart';
import '../models/run_telemetry.dart';
import 'accelerometer_collector_service.dart';
import 'ephemeral_sensor_buffer.dart';
import 'gps_tracking_service.dart';
import 'gyro_stability_service.dart';
import 'health_data_service.dart';

class RunSessionService {
  RunSessionService({
    required GpsTrackingService gpsTrackingService,
    required HealthDataService healthDataService,
    required GyroStabilityService gyroStabilityService,
    required AccelerometerCollectorService accelerometerCollectorService,
  })  : _gpsTrackingService = gpsTrackingService,
        _healthDataService = healthDataService,
        _gyroStabilityService = gyroStabilityService,
        _accelerometerCollector = accelerometerCollectorService;

  final GpsTrackingService _gpsTrackingService;
  final HealthDataService _healthDataService;
  final GyroStabilityService _gyroStabilityService;
  final AccelerometerCollectorService _accelerometerCollector;

  final _telemetryController = StreamController<RunTelemetry>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;
  DateTime? _startedAt;
  Position? _lastPosition;
  double _distanceMeters = 0;
  int? _currentHeartRate;
  int? _currentCadenceSpm;
  int _lastStepCount = 0;
  final List<RoutePoint> _routePoints = [];
  final List<TimedIntSample> _heartRateSeries = [];
  final List<TimedIntSample> _cadenceSeries = [];

  Stream<RunTelemetry> get telemetryStream => _telemetryController.stream;

  Future<void> start() async {
    final permission = await _gpsTrackingService.resolvePermission();
    if (permission != GpsPermissionResult.granted) {
      throw GpsPermissionException(permission);
    }

    final healthReady = await _healthDataService.requestRunDataAuthorization();
    if (!healthReady) {
      throw StateError('Health data permission is required for Jena validation.');
    }

    _startedAt = DateTime.now();
    _lastPosition = null;
    _distanceMeters = 0;
    _currentHeartRate = null;
    _currentCadenceSpm = null;
    _lastStepCount = 0;
    _routePoints.clear();
    _heartRateSeries.clear();
    _cadenceSeries.clear();
    _gyroStabilityService.start();
    _accelerometerCollector.start();

    _positionSubscription = _gpsTrackingService.watchOutdoorPosition().listen(
      _handlePosition,
      onError: _telemetryController.addError,
    );
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_onSecondTick()),
    );
    _emitTelemetry();
  }

  Future<CompletedRunSession> finish({
    String? activityId,
    String? userId,
  }) async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      throw StateError('Run session has not started.');
    }

    final endedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _gyroStabilityService.stop();
    await _accelerometerCollector.stop();

    final buffer = EphemeralSensorBuffer();
    final samples = await _healthDataService.readRunSamples(
      startedAt: startedAt,
      endedAt: endedAt,
    );
    samples.writeTo(buffer);

    final durationSeconds = endedAt.difference(startedAt).inSeconds;
    final gyroScore = _gyroStabilityService.calculateStabilityScore();
    final routePoints = List<RoutePoint>.unmodifiable(_routePoints);
    final distanceKm = _distanceMeters / 1000;

    if (_heartRateSeries.isEmpty && samples.heartRates.isNotEmpty) {
      for (var i = 0; i < samples.heartRates.length; i++) {
        final elapsed = samples.heartRates.length == 1
            ? durationSeconds
            : (durationSeconds * i ~/ (samples.heartRates.length - 1));
        _heartRateSeries.add(
          TimedIntSample(elapsedSeconds: elapsed, value: samples.heartRates[i]),
        );
      }
    }
    if (_cadenceSeries.isEmpty && samples.cadenceSpm.isNotEmpty) {
      for (final spm in samples.cadenceSpm) {
        _cadenceSeries.add(
          TimedIntSample(elapsedSeconds: durationSeconds, value: spm),
        );
      }
    }

    final telemetry = RunTelemetry(
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      currentHeartRate:
          _heartRateSeries.isEmpty ? null : _heartRateSeries.last.value,
      currentCadenceSpm:
          _cadenceSeries.isEmpty ? null : _cadenceSeries.last.value,
      gyroStabilityScore: gyroScore,
      routePoints: routePoints,
    );

    final packet = ActivityPacket(
      activityId: activityId ??
          'activity-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? '',
      startedAt: startedAt,
      endedAt: endedAt,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      gpsTrajectory: ActivityPacket.trajectoryFromRoute(
        routePoints: routePoints,
        startedAt: startedAt,
      ),
      heartRateSeries: List<TimedIntSample>.of(_heartRateSeries),
      cadenceSeries: List<TimedIntSample>.of(_cadenceSeries),
      accelerometerData: _accelerometerCollector.snapshot(),
      gyroStabilityScore: gyroScore,
    );

    _startedAt = null;
    _lastPosition = null;
    _distanceMeters = 0;
    _currentHeartRate = null;
    _currentCadenceSpm = null;
    _routePoints.clear();
    _heartRateSeries.clear();
    _cadenceSeries.clear();
    _accelerometerCollector.clear();
    _telemetryController.add(RunTelemetry.empty);

    return CompletedRunSession(
      telemetry: telemetry,
      sensorBuffer: buffer,
      routePoints: routePoints,
      startedAt: startedAt,
      endedAt: endedAt,
      totalSteps: samples.totalSteps,
      activityPacket: packet,
    );
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    await _positionSubscription?.cancel();
    await _gyroStabilityService.stop();
    await _accelerometerCollector.stop();
    await _telemetryController.close();
  }

  Future<void> _onSecondTick() async {
    if (_startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
    _accelerometerCollector.captureSnapshot(elapsedSeconds: elapsed);

    final bpm = await _healthDataService.readLatestHeartRate();
    if (bpm != null) {
      _currentHeartRate = bpm;
      _heartRateSeries.add(TimedIntSample(elapsedSeconds: elapsed, value: bpm));
    }
    if (elapsed > 0 && elapsed % 5 == 0) {
      await _pollCadence(elapsed);
    }
    _emitTelemetry();
  }

  Future<void> _pollCadence(int elapsedSeconds) async {
    if (_startedAt == null) return;
    try {
      final samples = await _healthDataService.readRunSamples(
        startedAt: _startedAt!,
        endedAt: DateTime.now(),
      );
      final delta = samples.totalSteps - _lastStepCount;
      _lastStepCount = samples.totalSteps;
      if (delta > 0) {
        final spm = (delta * 60 / 5).round().clamp(0, 250);
        if (spm > 0) {
          _currentCadenceSpm = spm;
          _cadenceSeries.add(
            TimedIntSample(elapsedSeconds: elapsedSeconds, value: spm),
          );
        }
      }
    } catch (_) {}
  }

  void _handlePosition(Position position) {
    final last = _lastPosition;
    if (last != null) {
      _distanceMeters += Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );
    }
    _lastPosition = position;
    _routePoints.add(
      RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        recordedAt: DateTime.now(),
      ),
    );
    _emitTelemetry();
  }

  void _emitTelemetry() {
    final startedAt = _startedAt;
    if (startedAt == null) {
      _telemetryController.add(RunTelemetry.empty);
      return;
    }
    _telemetryController.add(
      RunTelemetry(
        distanceKm: _distanceMeters / 1000,
        durationSeconds: DateTime.now().difference(startedAt).inSeconds,
        currentHeartRate: _currentHeartRate,
        currentCadenceSpm: _currentCadenceSpm,
        gyroStabilityScore: _gyroStabilityService.calculateStabilityScore(),
        routePoints: List<RoutePoint>.unmodifiable(_routePoints),
      ),
    );
  }
}

class GpsPermissionException implements Exception {
  GpsPermissionException(this.result);
  final GpsPermissionResult result;

  @override
  String toString() => switch (result) {
        GpsPermissionResult.serviceDisabled => '위치 서비스가 꺼져 있습니다.',
        GpsPermissionResult.deniedForever =>
          '위치 권한이 영구 거부되었습니다. 설정에서 허용해 주세요.',
        GpsPermissionResult.denied => '위치 권한이 필요합니다.',
        GpsPermissionResult.granted => '위치 권한이 허용되었습니다.',
      };
}

class CompletedRunSession {
  CompletedRunSession({
    required this.telemetry,
    required this.sensorBuffer,
    required this.routePoints,
    required this.startedAt,
    required this.endedAt,
    required this.totalSteps,
    required this.activityPacket,
  });

  final RunTelemetry telemetry;
  final EphemeralSensorBuffer sensorBuffer;
  List<RoutePoint> routePoints;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalSteps;
  final ActivityPacket activityPacket;

  /// 거리·페이스 연산 후 원본 GPS를 해싱하고 메모리에서 파기.
  void anonymizeAndDiscardRawLocation() {
    activityPacket.anonymizeAndDiscardRawGps();
    routePoints = const [];
  }

  void discardAllSensitive() {
    anonymizeAndDiscardRawLocation();
    activityPacket.discard();
    sensorBuffer.destroy();
  }
}
