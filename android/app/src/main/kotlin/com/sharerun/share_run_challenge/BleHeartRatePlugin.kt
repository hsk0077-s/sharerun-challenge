package com.sharerun.share_run_challenge

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Standard Bluetooth Low Energy Heart Rate Profile (Service 0x180D, Characteristic 0x2A37)
 * direct scanner & GATT client for Garmin / Xiaomi / Amazfit / Polar / Coospo / Magene sensors.
 */
class BleHeartRatePlugin(private val activity: Activity) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "share_run/ble_heart_rate"
        private const val EVENT_CHANNEL = "share_run/ble_heart_rate_events"
        private const val PERMISSION_REQUEST_CODE = 1809

        val HR_SERVICE_UUID: UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        val HR_MEASUREMENT_CHAR_UUID: UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        fun register(activity: Activity, flutterEngine: FlutterEngine) {
            val plugin = BleHeartRatePlugin(activity)
            val messenger = flutterEngine.dartExecutor.binaryMessenger
            MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(plugin)
            EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(plugin)
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var bluetoothGatt: BluetoothGatt? = null
    private var isScanning = false
    private var stopScanRunnable: Runnable? = null

    private val bluetoothAdapter: BluetoothAdapter?
        get() {
            val manager =
                activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            return manager?.adapter
        }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startScan" -> {
                val timeoutMs = (call.argument<Number>("timeoutMs")?.toLong() ?: 10000L)
                    .coerceIn(1000L, 60000L)
                startScan(timeoutMs, result)
            }
            "stopScan" -> {
                stopScanInternal()
                result.success(null)
            }
            "connect" -> {
                val deviceId = call.argument<String>("deviceId")
                val deviceName = call.argument<String>("deviceName")
                if (deviceId.isNullOrBlank()) {
                    result.error("bad_args", "deviceId is required", null)
                    return
                }
                connectToDevice(deviceId, deviceName, result)
            }
            "disconnect" -> {
                disconnectInternal()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun ensureBlePermissions(): Boolean {
        val needed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        val missing = needed.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) return true
        ActivityCompat.requestPermissions(
            activity,
            missing.toTypedArray(),
            PERMISSION_REQUEST_CODE,
        )
        return false
    }

    @SuppressLint("MissingPermission")
    private fun startScan(timeoutMs: Long, result: MethodChannel.Result) {
        if (!ensureBlePermissions()) {
            result.error(
                "permission_required",
                "근처 블루투스 기기 찾기 권한을 허용한 뒤 다시 스캔해 주세요.",
                null,
            )
            return
        }
        val adapter = bluetoothAdapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("bluetooth_disabled", "블루투스가 꺼져 있습니다. 블루투스를 켜 주세요.", null)
            return
        }
        val scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            result.error("scanner_unavailable", "BLE 스캐너를 사용할 수 없습니다.", null)
            return
        }

        stopScanInternal()
        isScanning = true
        emitEvent(mapOf("type" to "state", "state" to "scanning"))

        val filters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(HR_SERVICE_UUID))
                .build(),
        )
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        try {
            scanner.startScan(filters, settings, scanCallback)
            val stopTask = Runnable {
                if (isScanning) {
                    stopScanInternal()
                    if (bluetoothGatt == null) {
                        emitEvent(mapOf("type" to "state", "state" to "disconnected"))
                    }
                }
            }
            stopScanRunnable = stopTask
            mainHandler.postDelayed(stopTask, timeoutMs)
            result.success(null)
        } catch (e: Exception) {
            isScanning = false
            result.error("scan_failed", e.message ?: "BLE 스캔 실패", null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopScanInternal() {
        stopScanRunnable?.let { mainHandler.removeCallbacks(it) }
        stopScanRunnable = null
        if (!isScanning) return
        isScanning = false
        try {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(scanCallback)
        } catch (_: Exception) {
        }
    }

    @SuppressLint("MissingPermission")
    private fun connectToDevice(
        deviceId: String,
        deviceName: String?,
        result: MethodChannel.Result,
    ) {
        if (!ensureBlePermissions()) {
            result.error("permission_required", "블루투스 연결 권한이 필요합니다.", null)
            return
        }
        stopScanInternal()
        disconnectInternal(notifyDisconnected = false)

        val adapter = bluetoothAdapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("bluetooth_disabled", "블루투스가 꺼져 있습니다.", null)
            return
        }

        try {
            val device: BluetoothDevice = adapter.getRemoteDevice(deviceId)
            emitEvent(
                mapOf(
                    "type" to "state",
                    "state" to "connecting",
                    "deviceId" to deviceId,
                    "deviceName" to (deviceName ?: device.name ?: "BLE 심박 센서"),
                ),
            )
            bluetoothGatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(activity, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(activity, false, gattCallback)
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("connect_failed", e.message ?: "기기 연결 실패", null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun disconnectInternal(notifyDisconnected: Boolean = true) {
        try {
            bluetoothGatt?.disconnect()
            bluetoothGatt?.close()
        } catch (_: Exception) {
        } finally {
            bluetoothGatt = null
        }
        if (notifyDisconnected) {
            emitEvent(mapOf("type" to "state", "state" to "disconnected"))
        }
    }

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            val name = result.scanRecord?.deviceName ?: device.name ?: "BLE 심박 센서 (${device.address})"
            emitEvent(
                mapOf(
                    "type" to "deviceFound",
                    "id" to device.address,
                    "name" to name,
                    "rssi" to result.rssi,
                ),
            )
        }

        override fun onScanFailed(errorCode: Int) {
            isScanning = false
            emitEvent(
                mapOf(
                    "type" to "state",
                    "state" to "error",
                    "error" to "BLE 스캔 오류 (코드 $errorCode)",
                ),
            )
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    emitEvent(
                        mapOf(
                            "type" to "state",
                            "state" to "connected",
                            "deviceId" to gatt.device.address,
                            "deviceName" to (gatt.device.name ?: "BLE 심박 센서"),
                        ),
                    )
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    try {
                        gatt.close()
                    } catch (_: Exception) {
                    }
                    if (bluetoothGatt === gatt) {
                        bluetoothGatt = null
                    }
                    emitEvent(
                        mapOf(
                            "type" to "state",
                            "state" to "disconnected",
                            "deviceId" to gatt.device.address,
                        ),
                    )
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) return
            val hrService = gatt.getService(HR_SERVICE_UUID) ?: return
            val hrChar = hrService.getCharacteristic(HR_MEASUREMENT_CHAR_UUID) ?: return
            gatt.setCharacteristicNotification(hrChar, true)
            val descriptor = hrChar.getDescriptor(CCCD_UUID) ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                gatt.writeDescriptor(
                    descriptor,
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE,
                )
            } else {
                @Suppress("DEPRECATION")
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                @Suppress("DEPRECATION")
                gatt.writeDescriptor(descriptor)
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            if (characteristic.uuid == HR_MEASUREMENT_CHAR_UUID) {
                forwardMeasurement(value)
            }
        }

        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU &&
                characteristic.uuid == HR_MEASUREMENT_CHAR_UUID
            ) {
                @Suppress("DEPRECATION")
                val bytes = characteristic.value ?: return
                forwardMeasurement(bytes)
            }
        }
    }

    private fun forwardMeasurement(value: ByteArray) {
        val unsignedBytes = value.map { it.toInt() and 0xFF }
        emitEvent(
            mapOf(
                "type" to "measurement",
                "bytes" to unsignedBytes,
            ),
        )
    }

    private fun emitEvent(payload: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(payload)
        }
    }
}
