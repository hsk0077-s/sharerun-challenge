import CoreBluetooth
import Flutter
import Foundation

/// Standard BLE Heart Rate Service (0x180D) & Measurement (0x2A37) CoreBluetooth bridge.
final class BleHeartRatePlugin: NSObject, FlutterStreamHandler, CBCentralManagerDelegate, CBPeripheralDelegate {
  static let hrServiceUUID = CBUUID(string: "180D")
  static let hrMeasurementUUID = CBUUID(string: "2A37")

  private var centralManager: CBCentralManager?
  private var eventSink: FlutterEventSink?
  private var discoveredPeripherals: [String: CBPeripheral] = [:]
  private var connectedPeripheral: CBPeripheral?
  private var pendingScanTimeoutWorkItem: DispatchWorkItem?
  private var wantScan = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = BleHeartRatePlugin()
    let methodChannel = FlutterMethodChannel(
      name: "share_run/ble_heart_rate",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "share_run/ble_heart_rate_events",
      binaryMessenger: registrar.messenger()
    )
    methodChannel.setMethodCallHandler(instance.handle)
    eventChannel.setStreamHandler(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if centralManager == nil {
      centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    switch call.method {
    case "startScan":
      let args = call.arguments as? [String: Any]
      let timeoutMs = (args?["timeoutMs"] as? Int) ?? 10000
      startScan(timeoutMs: timeoutMs, result: result)
    case "stopScan":
      stopScanInternal()
      result(nil)
    case "connect":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String,
            !deviceId.isEmpty else {
        result(FlutterError(code: "bad_args", message: "deviceId is required", details: nil))
        return
      }
      connect(deviceId: deviceId, deviceName: args["deviceName"] as? String, result: result)
    case "disconnect":
      disconnectInternal()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startScan(timeoutMs: Int, result: @escaping FlutterResult) {
    guard let manager = centralManager else {
      result(FlutterError(code: "ble_unavailable", message: "CoreBluetooth 초기화 실패", details: nil))
      return
    }
    wantScan = true
    emit(["type": "state", "state": "scanning"])
    if manager.state == .poweredOn {
      beginCoreBluetoothScan(timeoutMs: timeoutMs)
    }
    result(nil)
  }

  private func beginCoreBluetoothScan(timeoutMs: Int) {
    guard let manager = centralManager, manager.state == .poweredOn else { return }
    pendingScanTimeoutWorkItem?.cancel()
    manager.scanForPeripherals(
      withServices: [Self.hrServiceUUID],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
    )
    let work = DispatchWorkItem { [weak self] in
      guard let self = self else { return }
      self.stopScanInternal()
      if self.connectedPeripheral == nil {
        self.emit(["type": "state", "state": "disconnected"])
      }
    }
    pendingScanTimeoutWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs), execute: work)
  }

  private func stopScanInternal() {
    wantScan = false
    pendingScanTimeoutWorkItem?.cancel()
    pendingScanTimeoutWorkItem = nil
    centralManager?.stopScan()
  }

  private func connect(deviceId: String, deviceName: String?, result: @escaping FlutterResult) {
    stopScanInternal()
    guard let manager = centralManager else {
      result(FlutterError(code: "ble_unavailable", message: "Bluetooth 사용 불가", details: nil))
      return
    }
    var target = discoveredPeripherals[deviceId]
    if target == nil, let uuid = UUID(uuidString: deviceId) {
      target = manager.retrievePeripherals(withIdentifiers: [uuid]).first
    }
    guard let peripheral = target else {
      result(FlutterError(code: "not_found", message: "심박 센서를 찾을 수 없습니다. 다시 스캔해 주세요.", details: nil))
      return
    }
    discoveredPeripherals[deviceId] = peripheral
    connectedPeripheral = peripheral
    peripheral.delegate = self
    emit([
      "type": "state",
      "state": "connecting",
      "deviceId": deviceId,
      "deviceName": deviceName ?? peripheral.name ?? "BLE 심박 센서"
    ])
    manager.connect(peripheral, options: nil)
    result(nil)
  }

  private func disconnectInternal() {
    stopScanInternal()
    if let p = connectedPeripheral {
      centralManager?.cancelPeripheralConnection(p)
      connectedPeripheral = nil
    }
    emit(["type": "state", "state": "disconnected"])
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn && wantScan {
      beginCoreBluetoothScan(timeoutMs: 10000)
    } else if central.state == .poweredOff || central.state == .unauthorized {
      emit([
        "type": "state",
        "state": "error",
        "error": "블루투스가 꺼져 있거나 권한이 없습니다."
      ])
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let id = peripheral.identifier.uuidString
    discoveredPeripherals[id] = peripheral
    let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
    let name = advName ?? peripheral.name ?? "BLE 심박 센서"
    emit([
      "type": "deviceFound",
      "id": id,
      "name": name,
      "rssi": RSSI.intValue
    ])
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    emit([
      "type": "state",
      "state": "connected",
      "deviceId": peripheral.identifier.uuidString,
      "deviceName": peripheral.name ?? "BLE 심박 센서"
    ])
    peripheral.discoverServices([Self.hrServiceUUID])
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    if connectedPeripheral?.identifier == peripheral.identifier {
      connectedPeripheral = nil
    }
    emit([
      "type": "state",
      "state": "disconnected",
      "deviceId": peripheral.identifier.uuidString
    ])
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }
    for service in services where service.uuid == Self.hrServiceUUID {
      peripheral.discoverCharacteristics([Self.hrMeasurementUUID], for: service)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    guard let characteristics = service.characteristics else { return }
    for char in characteristics where char.uuid == Self.hrMeasurementUUID {
      peripheral.setNotifyValue(true, for: char)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard characteristic.uuid == Self.hrMeasurementUUID,
          let data = characteristic.value else { return }
    let bytes = data.map { Int($0) }
    emit([
      "type": "measurement",
      "bytes": bytes
    ])
  }

  private func emit(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(payload)
    }
  }
}
