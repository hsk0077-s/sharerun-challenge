import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/services/ble_heart_rate_service.dart';
import 'package:share_run_challenge/services/health_data_service.dart';

class FakeBleAdapter implements BleHeartRateAdapter {
  final controller = StreamController<Map<String, Object?>>.broadcast();
  var scanCalls = 0;
  var stopScanCalls = 0;
  var connectCalls = 0;
  String? connectedDeviceId;
  var disconnectCalls = 0;

  @override
  Stream<Map<String, Object?>> get events => controller.stream;

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    scanCalls++;
    controller.add({'type': 'state', 'state': 'scanning'});
  }

  @override
  Future<void> stopScan() async {
    stopScanCalls++;
  }

  @override
  Future<void> connect(String deviceId, {String? deviceName}) async {
    connectCalls++;
    connectedDeviceId = deviceId;
    controller.add({
      'type': 'state',
      'state': 'connected',
      'deviceId': deviceId,
      'deviceName': deviceName ?? 'Garmin Epix Pro',
    });
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    connectedDeviceId = null;
    controller.add({'type': 'state', 'state': 'disconnected'});
  }
}

void main() {
  group('BLE 0x2A37 Heart Rate Measurement Parser', () {
    test('parses uint8 BPM when bit 0 == 0', () {
      // Flags = 0x06 (uint8 format, sensor contact supported & detected), BPM = 148
      final m = BleHeartRateMeasurement.tryParse(const [0x06, 148]);
      expect(m, isNotNull);
      expect(m!.bpm, 148);
      expect(m.isUint16Format, isFalse);
      expect(m.sensorContactSupported, isTrue);
      expect(m.sensorContactDetected, isTrue);
      expect(parseBleHeartRateMeasurement(const [0x00, 72]), 72);
    });

    test('parses uint16 little-endian BPM when bit 0 == 1', () {
      // Flags = 0x01 (uint16 format), BPM = 185 (0xB9, 0x00)
      final m = BleHeartRateMeasurement.tryParse(const [0x01, 0xB9, 0x00]);
      expect(m, isNotNull);
      expect(m!.bpm, 185);
      expect(m.isUint16Format, isTrue);
    });

    test('parses optional Energy Expended and RR-Intervals', () {
      // Flags = 0x18 (uint8 + Energy Expended + RR-Interval)
      // BPM = 152, Energy = 250 kJ (0xFA, 0x00), RR = 800/1024s (0x20, 0x03)
      final m = BleHeartRateMeasurement.tryParse(
        const [0x18, 152, 0xFA, 0x00, 0x20, 0x03],
      );
      expect(m, isNotNull);
      expect(m!.bpm, 152);
      expect(m.energyExpendedKj, 250);
      expect(m.rrIntervalsMs, [781]);
    });

    test('rejects <30 or >230 BPM and lost sensor contact', () {
      expect(parseBleHeartRateMeasurement(const [0x00, 29]), isNull);
      expect(parseBleHeartRateMeasurement(const [0x00, 0]), isNull);
      expect(parseBleHeartRateMeasurement(const [0x00, 231]), isNull);
      expect(parseBleHeartRateMeasurement(const [0x01, 0x00, 0x01]), isNull); // 256 BPM
      // Flags = 0x04 (contact supported, NOT detected)
      expect(parseBleHeartRateMeasurement(const [0x04, 140]), isNull);
      expect(
        BleHeartRateMeasurement.isSensorContactExplicitlyLost(const [0x04, 140]),
        isTrue,
      );
      // Malformed length
      expect(parseBleHeartRateMeasurement(const []), isNull);
      expect(parseBleHeartRateMeasurement(const [0x01, 140]), isNull);
    });
  });

  group('BleHeartRateService + HealthDataService integration', () {
    test('discovers devices, connects, streams BPM, and feeds HealthDataService',
        () async {
      var now = DateTime.utc(2026, 10, 25, 12, 0, 0);
      final adapter = FakeBleAdapter();
      final service = BleHeartRateService(
        adapter: adapter,
        clock: () => now,
      );
      addTearDown(service.dispose);

      await service.startScan();
      expect(service.state, BleConnectionState.scanning);

      adapter.controller.add({
        'type': 'deviceFound',
        'id': 'AA:BB:CC:11:22:33',
        'name': 'Garmin Forerunner 265',
        'rssi': -52,
      });
      await Future<void>.delayed(Duration.zero);
      expect(service.discoveredDevices, hasLength(1));
      expect(service.discoveredDevices.first.name, 'Garmin Forerunner 265');

      await service.connect(service.discoveredDevices.first);
      await Future<void>.delayed(Duration.zero);
      expect(service.isConnected, isTrue);
      expect(service.deviceName, 'Garmin Forerunner 265');

      final bpms = <int>[];
      final sub = service.bpmStream.listen(bpms.add);
      addTearDown(sub.cancel);

      // Emit valid uint8 BPM = 155, invalid 245, valid uint16 BPM = 162
      adapter.controller.add({
        'type': 'measurement',
        'bytes': [0x00, 155],
      });
      now = now.add(const Duration(seconds: 2));
      adapter.controller.add({
        'type': 'measurement',
        'bytes': [0x00, 245], // filtered out
      });
      adapter.controller.add({
        'type': 'measurement',
        'bytes': [0x01, 162, 0x00],
      });
      await Future<void>.delayed(Duration.zero);

      expect(bpms, [155, 162]);
      expect(service.lastBpm, 162);

      // Gemini Pro Edge Case 2: skin contact lost (0x04) immediately clears ghost BPM
      adapter.controller.add({
        'type': 'measurement',
        'bytes': [0x04, 162],
      });
      await Future<void>.delayed(Duration.zero);
      expect(service.sensorContactDetected, isFalse);
      expect(service.lastBpm, isNull);
      expect(service.recentValidBpm(), isNull);

      // Contact restored (0x06 = contact supported + detected)
      adapter.controller.add({
        'type': 'measurement',
        'bytes': [0x06, 158],
      });
      await Future<void>.delayed(Duration.zero);
      expect(service.sensorContactDetected, isTrue);
      expect(service.lastBpm, 158);
      expect(service.recentValidBpm(), 158);

      final healthService = HealthDataService(bleHeartRateService: service);
      expect(await healthService.requestRunDataAuthorization(), isTrue);
      expect(await healthService.readLatestHeartRate(), 158);

      final runSamples = await healthService.readRunSamples(
        startedAt: DateTime.utc(2026, 10, 25, 11, 59, 0),
        endedAt: DateTime.utc(2026, 10, 25, 12, 1, 0),
      );
      expect(runSamples.heartRates, [155, 162, 158]);

      await service.disconnect();
      await Future<void>.delayed(Duration.zero);
      expect(service.isConnected, isFalse);
      expect(service.lastBpm, isNull);
    });

    test('auto-reconnects with exponential backoff on unexpected disconnect',
        () async {
      final adapter = FakeBleAdapter();
      final service = BleHeartRateService(
        adapter: adapter,
        initialReconnectDelay: const Duration(milliseconds: 20),
      );
      addTearDown(service.dispose);

      await service.connect(
        const BleHrDevice(id: '11:22:33:44:55:66', name: 'Polar H10'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.isConnected, isTrue);
      expect(adapter.connectCalls, 1);

      // Simulate unexpected drop from native side (not user disconnect())
      adapter.controller.add({
        'type': 'state',
        'state': 'disconnected',
        'deviceId': '11:22:33:44:55:66',
        'deviceName': 'Polar H10',
      });
      await Future<void>.delayed(Duration.zero);
      expect(service.isConnected, isFalse);
      expect(service.reconnectAttempts, 1);

      // Wait for 20ms initial backoff timer to fire and reconnect
      await Future<void>.delayed(const Duration(milliseconds: 45));
      expect(adapter.connectCalls, 2);
      expect(service.isConnected, isTrue);
      expect(service.reconnectAttempts, 0);
    });
  });
}
