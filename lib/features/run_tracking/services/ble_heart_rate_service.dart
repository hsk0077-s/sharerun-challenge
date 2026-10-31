import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../l10n/remaining_surface.dart';

/// Bluetooth SIG Heart Rate Service (0x180D) & Heart Rate Measurement (0x2A37).
const kBleHeartRateServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
const kBleHeartRateMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';
const kBleClientCharacteristicConfigUuid =
    '00002902-0000-1000-8000-00805f9b34fb';

/// Valid physiological running/walking heart rate range accepted by ShareRun.
const kBleMinValidBpm = 30;
const kBleMaxValidBpm = 230;

/// Connection lifecycle for a direct BLE Heart Rate sensor (0x180D).
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// Discovered BLE Heart Rate peripheral.
@immutable
class BleHrDevice {
  const BleHrDevice({
    required this.id,
    required this.name,
    this.rssi = -60,
  });

  final String id;
  final String name;
  final int rssi;

  factory BleHrDevice.fromMap(Map<Object?, Object?> map) {
    final rawName = (map['name'] as String?)?.trim();
    return BleHrDevice(
      id: (map['id'] as String?)?.trim() ?? '',
      name: (rawName != null && rawName.isNotEmpty)
          ? rawName
          : 'BLE 심박 센서 (${map['id'] ?? ''})',
      rssi: (map['rssi'] as num?)?.toInt() ?? -60,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'rssi': rssi,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BleHrDevice &&
          other.id == id &&
          other.name == name &&
          other.rssi == rssi);

  @override
  int get hashCode => Object.hash(id, name, rssi);
}

/// Parsed Bluetooth SIG Heart Rate Measurement (0x2A37) packet.
@immutable
class BleHeartRateMeasurement {
  const BleHeartRateMeasurement({
    required this.bpm,
    required this.isUint16Format,
    required this.sensorContactSupported,
    required this.sensorContactDetected,
    this.energyExpendedKj,
    this.rrIntervalsMs = const [],
  });

  final int bpm;
  final bool isUint16Format;
  final bool sensorContactSupported;
  final bool sensorContactDetected;
  final int? energyExpendedKj;
  final List<int> rrIntervalsMs;

  /// Returns true when the 0x2A37 Flags byte explicitly indicates that
  /// skin contact detection is supported (bit 2 = 1) and contact is lost (bit 1 = 0).
  static bool isSensorContactExplicitlyLost(List<int> bytes) {
    if (bytes.isEmpty) return false;
    final flags = bytes[0] & 0xFF;
    final contactSupported = (flags & 0x04) != 0;
    final contactDetected = (flags & 0x02) != 0;
    return contactSupported && !contactDetected;
  }

  /// Parses raw 0x2A37 characteristic bytes according to Bluetooth SIG HRS spec:
  /// - Byte 0 (Flags):
  ///   - Bit 0: Heart Rate Value Format (0 = UINT8 at byte[1], 1 = UINT16 LE at bytes[1..2])
  ///   - Bits 1..2: Sensor Contact Status (bit 2 = supported, bit 1 = detected)
  ///   - Bit 3: Energy Expended Status (1 = UINT16 LE present)
  ///   - Bit 4: RR-Interval bit (1 = one or more UINT16 LE in 1/1024s units present)
  /// Returns null when the packet is malformed, sensor contact is explicitly lost,
  /// or BPM is outside [kBleMinValidBpm, kBleMaxValidBpm] (30..230).
  static BleHeartRateMeasurement? tryParse(List<int> bytes) {
    if (bytes.length < 2) return null;

    final flags = bytes[0] & 0xFF;
    final isUint16 = (flags & 0x01) != 0;
    final contactSupported = (flags & 0x04) != 0;
    final contactDetected = contactSupported ? ((flags & 0x02) != 0) : true;

    if (contactSupported && !contactDetected) {
      return null;
    }

    var offset = 1;
    final int bpm;
    if (isUint16) {
      if (bytes.length < offset + 2) return null;
      bpm = (bytes[offset] & 0xFF) | ((bytes[offset + 1] & 0xFF) << 8);
      offset += 2;
    } else {
      bpm = bytes[offset] & 0xFF;
      offset += 1;
    }

    if (bpm < kBleMinValidBpm || bpm > kBleMaxValidBpm) {
      return null;
    }

    int? energyExpended;
    final hasEnergyExpended = (flags & 0x08) != 0;
    if (hasEnergyExpended) {
      if (bytes.length < offset + 2) return null;
      energyExpended =
          (bytes[offset] & 0xFF) | ((bytes[offset + 1] & 0xFF) << 8);
      offset += 2;
    }

    final rrIntervals = <int>[];
    final hasRrInterval = (flags & 0x10) != 0;
    if (hasRrInterval) {
      while (offset + 1 < bytes.length) {
        final rawRr =
            (bytes[offset] & 0xFF) | ((bytes[offset + 1] & 0xFF) << 8);
        final rrMs = (rawRr * 1000) ~/ 1024;
        rrIntervals.add(rrMs);
        offset += 2;
      }
    }

    return BleHeartRateMeasurement(
      bpm: bpm,
      isUint16Format: isUint16,
      sensorContactSupported: contactSupported,
      sensorContactDetected: contactDetected,
      energyExpendedKj: energyExpended,
      rrIntervalsMs: List.unmodifiable(rrIntervals),
    );
  }
}

/// Convenience helper returning valid BPM (`30..230`) or null from 0x2A37 bytes.
int? parseBleHeartRateMeasurement(List<int> bytes) {
  return BleHeartRateMeasurement.tryParse(bytes)?.bpm;
}

/// Immutable snapshot of the BLE Heart Rate service state for UI & providers.
@immutable
class BleHeartRateSnapshot {
  const BleHeartRateSnapshot({
    this.state = BleConnectionState.disconnected,
    this.deviceId,
    this.deviceName,
    this.lastBpm,
    this.lastUpdatedAt,
    this.discoveredDevices = const [],
    this.errorMessage,
    this.sensorContactDetected = true,
    this.reconnectAttempts = 0,
  });

  final BleConnectionState state;
  final String? deviceId;
  final String? deviceName;
  final int? lastBpm;
  final DateTime? lastUpdatedAt;
  final List<BleHrDevice> discoveredDevices;
  final String? errorMessage;
  final bool sensorContactDetected;
  final int reconnectAttempts;

  bool get isConnected => state == BleConnectionState.connected;
  bool get isScanning => state == BleConnectionState.scanning;

  BleHeartRateSnapshot copyWith({
    BleConnectionState? state,
    String? deviceId,
    bool clearDevice = false,
    String? deviceName,
    int? lastBpm,
    bool clearBpm = false,
    DateTime? lastUpdatedAt,
    List<BleHrDevice>? discoveredDevices,
    String? errorMessage,
    bool clearError = false,
    bool? sensorContactDetected,
    int? reconnectAttempts,
  }) {
    return BleHeartRateSnapshot(
      state: state ?? this.state,
      deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
      deviceName: clearDevice ? null : (deviceName ?? this.deviceName),
      lastBpm: clearBpm ? null : (lastBpm ?? this.lastBpm),
      lastUpdatedAt:
          clearBpm ? null : (lastUpdatedAt ?? this.lastUpdatedAt),
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sensorContactDetected:
          sensorContactDetected ?? this.sensorContactDetected,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

/// Timestamped BPM sample recorded during a run.
@immutable
class BleHeartRateSample {
  const BleHeartRateSample({
    required this.bpm,
    required this.recordedAt,
  });

  final int bpm;
  final DateTime recordedAt;
}

/// Low-level transport interface so unit & widget tests run without hardware.
abstract class BleHeartRateAdapter {
  Stream<Map<String, Object?>> get events;
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)});
  Future<void> stopScan();
  Future<void> connect(String deviceId, {String? deviceName});
  Future<void> disconnect();
}

/// Production adapter bridging to Kotlin (`BleHeartRatePlugin.kt`) and Swift (`BleHeartRatePlugin.swift`).
class MethodChannelBleHeartRateAdapter implements BleHeartRateAdapter {
  MethodChannelBleHeartRateAdapter({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _method =
            methodChannel ?? const MethodChannel('share_run/ble_heart_rate'),
        _events = eventChannel ??
            const EventChannel('share_run/ble_heart_rate_events');

  final MethodChannel _method;
  final EventChannel _events;

  @override
  Stream<Map<String, Object?>> get events {
    return _events.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return event.map((k, v) => MapEntry('$k', v));
      }
      return const <String, Object?>{};
    });
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await _method.invokeMethod<void>('startScan', {
      'timeoutMs': timeout.inMilliseconds,
      'serviceUuid': kBleHeartRateServiceUuid,
    });
  }

  @override
  Future<void> stopScan() async {
    await _method.invokeMethod<void>('stopScan');
  }

  @override
  Future<void> connect(String deviceId, {String? deviceName}) async {
    await _method.invokeMethod<void>('connect', {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'serviceUuid': kBleHeartRateServiceUuid,
      'characteristicUuid': kBleHeartRateMeasurementUuid,
    });
  }

  @override
  Future<void> disconnect() async {
    await _method.invokeMethod<void>('disconnect');
  }
}

/// High-level service managing BLE 0x180D / 0x2A37 scanning, connection,
/// exponential backoff auto-reconnection, skin-contact ghost-BPM protection,
/// packet parsing, and real-time heart rate streaming into ShareRun.
class BleHeartRateService {
  BleHeartRateService({
    BleHeartRateAdapter? adapter,
    DateTime Function()? clock,
    this.maxHistorySamples = 7200,
    this.autoReconnect = true,
    this.maxReconnectAttempts = 6,
    this.initialReconnectDelay = const Duration(seconds: 1),
  })  : _adapter = adapter ?? MethodChannelBleHeartRateAdapter(),
        _clock = clock ?? DateTime.now {
    if (adapter != null) {
      _ensureEventSubscription();
    }
  }

  void _ensureEventSubscription() {
    if (_eventSub != null) return;
    _eventSub = _adapter.events.listen(
      _handleAdapterEvent,
      onError: (Object error) {
        if (error is MissingPluginException) return;
        _updateSnapshot(
          _snapshot.copyWith(
            state: BleConnectionState.error,
            errorMessage: '$error',
          ),
        );
      },
    );
  }

  final BleHeartRateAdapter _adapter;
  final DateTime Function() _clock;
  final int maxHistorySamples;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration initialReconnectDelay;

  StreamSubscription<Map<String, Object?>>? _eventSub;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _userInitiatedDisconnect = false;

  final _snapshotController =
      StreamController<BleHeartRateSnapshot>.broadcast();
  final _bpmController = StreamController<int>.broadcast();
  final List<BleHeartRateSample> _history = [];

  BleHeartRateSnapshot _snapshot = const BleHeartRateSnapshot();

  BleHeartRateSnapshot get snapshot => _snapshot;
  BleConnectionState get state => _snapshot.state;
  int? get lastBpm => _snapshot.lastBpm;
  String? get deviceName => _snapshot.deviceName;
  String? get deviceId => _snapshot.deviceId;
  bool get isConnected => _snapshot.isConnected;
  bool get sensorContactDetected => _snapshot.sensorContactDetected;
  int get reconnectAttempts => _reconnectAttempts;
  List<BleHrDevice> get discoveredDevices => _snapshot.discoveredDevices;

  Stream<BleHeartRateSnapshot> get snapshotStream => _snapshotController.stream;
  Stream<int> get bpmStream => _bpmController.stream;

  /// Returns the most recent valid BPM if connected, skin contact is intact,
  /// and received within [maxAge].
  int? recentValidBpm({Duration maxAge = const Duration(seconds: 15)}) {
    final bpm = _snapshot.lastBpm;
    final updatedAt = _snapshot.lastUpdatedAt;
    if (!_snapshot.isConnected ||
        !_snapshot.sensorContactDetected ||
        bpm == null ||
        updatedAt == null) {
      return null;
    }
    if (_clock().difference(updatedAt) > maxAge) {
      return null;
    }
    return bpm;
  }

  /// Returns recorded BLE heart rate samples within [startedAt, endedAt].
  List<int> samplesInWindow({
    required DateTime startedAt,
    required DateTime endedAt,
  }) {
    return [
      for (final sample in _history)
        if (!sample.recordedAt.isBefore(startedAt) &&
            !sample.recordedAt.isAfter(endedAt))
          sample.bpm,
    ];
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _ensureEventSubscription();
    _updateSnapshot(
      _snapshot.copyWith(
        state: BleConnectionState.scanning,
        discoveredDevices: const [],
        clearError: true,
      ),
    );
    try {
      await _adapter.startScan(timeout: timeout);
    } on MissingPluginException {
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.error,
          errorMessage: RemainingSurface.trNow(
            'run_tracking.ble_heart_rate_service.body.2',
            '이 기기에서는 블루투스 심박 스캔을 지원하지 않습니다.',
          ),
        ),
      );
    } on PlatformException catch (e) {
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.error,
          errorMessage: e.message ??
              RemainingSurface.trNow(
                'run_tracking.ble_heart_rate_service.body.3',
                '블루투스 권한 또는 상태를 확인해 주세요.',
              ),
        ),
      );
    } catch (e) {
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.error,
          errorMessage: '$e',
        ),
      );
    }
  }

  Future<void> stopScan() async {
    try {
      await _adapter.stopScan();
    } catch (_) {}
    if (_snapshot.state == BleConnectionState.scanning) {
      _updateSnapshot(
        _snapshot.copyWith(state: BleConnectionState.disconnected),
      );
    }
  }

  Future<void> connect(BleHrDevice device) async {
    _userInitiatedDisconnect = false;
    _reconnectTimer?.cancel();
    _updateSnapshot(
      _snapshot.copyWith(
        state: BleConnectionState.connecting,
        deviceId: device.id,
        deviceName: device.name,
        clearError: true,
        reconnectAttempts: _reconnectAttempts,
      ),
    );
    try {
      await _adapter.connect(device.id, deviceName: device.name);
    } on MissingPluginException {
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.error,
          errorMessage: RemainingSurface.trNow(
            'run_tracking.ble_heart_rate_service.body.4',
            '이 기기에서는 블루투스 심박 연결을 지원하지 않습니다.',
          ),
        ),
      );
    } on PlatformException catch (e) {
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.error,
          errorMessage: e.message ??
              RemainingSurface.trNow(
                'run_tracking.ble_heart_rate_service.body.5',
                '센서 연결에 실패했습니다.',
              ),
        ),
      );
    } catch (e) {
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.error,
          errorMessage: '$e',
        ),
      );
    }
  }

  Future<void> disconnect() async {
    _userInitiatedDisconnect = true;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    try {
      await _adapter.disconnect();
    } catch (_) {}
    _updateSnapshot(
      _snapshot.copyWith(
        state: BleConnectionState.disconnected,
        clearDevice: true,
        clearBpm: true,
        clearError: true,
        sensorContactDetected: true,
        reconnectAttempts: 0,
      ),
    );
  }

  /// Processes a raw 0x2A37 byte payload (used by native events and tests).
  /// Immediately clears `lastBpm` if skin contact is explicitly lost so stale
  /// ghost BPM values cannot linger within the 15s window.
  int? ingestMeasurementBytes(List<int> bytes) {
    if (BleHeartRateMeasurement.isSensorContactExplicitlyLost(bytes)) {
      _updateSnapshot(
        _snapshot.copyWith(
          clearBpm: true,
          sensorContactDetected: false,
        ),
      );
      return null;
    }
    final bpm = parseBleHeartRateMeasurement(bytes);
    if (bpm == null) return null;
    _recordBpm(bpm);
    return bpm;
  }

  void _recordBpm(int bpm) {
    if (bpm < kBleMinValidBpm || bpm > kBleMaxValidBpm) return;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    final now = _clock();
    _history.add(BleHeartRateSample(bpm: bpm, recordedAt: now));
    while (_history.length > maxHistorySamples) {
      _history.removeAt(0);
    }
    _updateSnapshot(
      _snapshot.copyWith(
        state: BleConnectionState.connected,
        lastBpm: bpm,
        lastUpdatedAt: now,
        clearError: true,
        sensorContactDetected: true,
        reconnectAttempts: 0,
      ),
    );
    if (!_bpmController.isClosed) {
      _bpmController.add(bpm);
    }
  }

  void _scheduleReconnectIfNeeded(String? devId, String? devName) {
    if (!autoReconnect ||
        _userInitiatedDisconnect ||
        devId == null ||
        devId.isEmpty ||
        _reconnectAttempts >= maxReconnectAttempts) {
      return;
    }
    _reconnectAttempts += 1;
    final backoffFactor = 1 << (_reconnectAttempts - 1);
    final rawMs = initialReconnectDelay.inMilliseconds * backoffFactor;
    final cappedMs = rawMs > 60000 ? 60000 : rawMs;
    _reconnectTimer?.cancel();
    _updateSnapshot(
      _snapshot.copyWith(reconnectAttempts: _reconnectAttempts),
    );
    _reconnectTimer = Timer(Duration(milliseconds: cappedMs), () async {
      if (_userInitiatedDisconnect || _snapshotController.isClosed) return;
      _updateSnapshot(
        _snapshot.copyWith(
          state: BleConnectionState.connecting,
          deviceId: devId,
          deviceName: devName,
          reconnectAttempts: _reconnectAttempts,
        ),
      );
      try {
        await _adapter.connect(devId, deviceName: devName);
      } catch (_) {}
    });
  }

  void _handleAdapterEvent(Map<String, Object?> event) {
    final type = event['type'] as String?;
    switch (type) {
      case 'deviceFound':
        final device = BleHrDevice.fromMap(event);
        if (device.id.isEmpty) return;
        final existing = List<BleHrDevice>.of(_snapshot.discoveredDevices);
        final idx = existing.indexWhere((d) => d.id == device.id);
        if (idx >= 0) {
          existing[idx] = device;
        } else {
          existing.add(device);
        }
        _updateSnapshot(
          _snapshot.copyWith(discoveredDevices: List.unmodifiable(existing)),
        );
      case 'state':
        final rawState = event['state'] as String?;
        final nextState = switch (rawState) {
          'scanning' => BleConnectionState.scanning,
          'connecting' => BleConnectionState.connecting,
          'connected' => BleConnectionState.connected,
          'error' => BleConnectionState.error,
          _ => BleConnectionState.disconnected,
        };
        final devId = (event['deviceId'] as String?) ?? _snapshot.deviceId;
        final devName =
            (event['deviceName'] as String?) ?? _snapshot.deviceName;
        final err = event['error'] as String?;
        if (nextState == BleConnectionState.connected) {
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
        }
        _updateSnapshot(
          _snapshot.copyWith(
            state: nextState,
            deviceId: devId,
            deviceName: devName,
            clearBpm: nextState == BleConnectionState.disconnected,
            errorMessage: err,
            clearError: err == null,
            reconnectAttempts: _reconnectAttempts,
          ),
        );
        if (nextState == BleConnectionState.disconnected) {
          _scheduleReconnectIfNeeded(devId, devName);
        }
      case 'measurement':
        final rawBytes = event['bytes'];
        if (rawBytes is List) {
          final bytes = [
            for (final b in rawBytes)
              if (b is num) b.toInt(),
          ];
          ingestMeasurementBytes(bytes);
          return;
        }
        final directBpm = (event['bpm'] as num?)?.toInt();
        if (directBpm != null) {
          _recordBpm(directBpm);
        }
    }
  }

  void _updateSnapshot(BleHeartRateSnapshot next) {
    _snapshot = next;
    if (!_snapshotController.isClosed) {
      _snapshotController.add(next);
    }
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _eventSub?.cancel();
    await _snapshotController.close();
    await _bpmController.close();
  }
}
