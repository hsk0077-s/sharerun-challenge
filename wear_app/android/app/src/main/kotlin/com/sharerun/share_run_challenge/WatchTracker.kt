package com.sharerun.share_run_challenge

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.PowerManager

/**
 * 달리는 동안 심박·걸음·위치를 모아 두는 곳. 프로세스에 하나만 있고,
 * Flutter 쪽은 [snapshot]을 주기적으로 읽어 간다.
 *
 * 값을 만들어 내지 않는다. 센서가 없거나 권한이 없으면 그 값은 0으로 남는다.
 */
object WatchTracker : SensorEventListener, LocationListener {
    // GPS 한 점의 오차가 이보다 크면 거리에 넣지 않는다.
    private const val MAX_ACCURACY_METERS = 30f

    // 점과 점 사이 속도가 이보다 빠르면(시속 약 43km) 튄 점으로 보고 버린다.
    private const val MAX_SPEED_METERS_PER_SECOND = 12f

    // 이보다 짧은 이동은 제자리 흔들림으로 본다.
    private const val MIN_STEP_METERS = 2f

    private var active = false
    private var sensorManager: SensorManager? = null
    private var locationManager: LocationManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private var heartRate = 0
    private var stepBaseline = -1f
    private var steps = 0
    private var distanceMeters = 0.0
    private var lastLocation: Location? = null
    private var hasGps = false
    private val route = mutableListOf<Map<String, Any>>()

    val isActive: Boolean
        @Synchronized get() = active

    @SuppressLint("MissingPermission", "WakelockTimeout")
    @Synchronized
    fun start(context: Context, bodySensors: Boolean, activityRecognition: Boolean, fineLocation: Boolean) {
        if (active) return
        val app = context.applicationContext
        heartRate = 0
        stepBaseline = -1f
        steps = 0
        distanceMeters = 0.0
        lastLocation = null
        hasGps = false
        route.clear()

        val power = app.getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "sharerun:tracking").apply {
            setReferenceCounted(false)
            acquire()
        }

        val sensors = app.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorManager = sensors
        if (bodySensors) {
            sensors.getDefaultSensor(Sensor.TYPE_HEART_RATE)?.let {
                sensors.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }
        if (activityRecognition) {
            sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)?.let {
                sensors.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }

        val location = app.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        locationManager = location
        if (fineLocation && location.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            location.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 0f, this)
        }
        active = true
    }

    @Synchronized
    fun stop() {
        if (!active) return
        sensorManager?.unregisterListener(this)
        try {
            locationManager?.removeUpdates(this)
        } catch (_: SecurityException) {
        }
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        sensorManager = null
        locationManager = null
        active = false
    }

    @Synchronized
    fun snapshot(): Map<String, Any> = mapOf(
        "active" to active,
        "heartRate" to heartRate,
        "steps" to steps,
        "distanceKm" to distanceMeters / 1000.0,
        "hasGps" to hasGps,
        "route" to route.toList(),
    )

    @Synchronized
    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_HEART_RATE -> {
                // 0은 "아직 못 쟀다"는 뜻이다. 이전 값을 그대로 둔다.
                val bpm = event.values.firstOrNull()?.toInt() ?: 0
                if (bpm > 0) heartRate = bpm
            }
            Sensor.TYPE_STEP_COUNTER -> {
                val total = event.values.firstOrNull() ?: return
                // 걸음 센서는 부팅 뒤 누적값이라, 첫 값을 0으로 삼는다.
                if (stepBaseline < 0f) stepBaseline = total
                steps = (total - stepBaseline).toInt().coerceAtLeast(0)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    @Synchronized
    override fun onLocationChanged(location: Location) {
        if (!location.hasAccuracy() || location.accuracy > MAX_ACCURACY_METERS) return
        hasGps = true
        val previous = lastLocation
        if (previous == null) {
            lastLocation = location
            remember(location)
            return
        }
        val meters = previous.distanceTo(location)
        val seconds = (location.elapsedRealtimeNanos - previous.elapsedRealtimeNanos) / 1e9
        if (meters < MIN_STEP_METERS || seconds <= 0.0) {
            // 제자리: 기준점은 옮기지 않아 천천히 걷는 거리가 쌓이게 한다.
            return
        }
        if (meters / seconds > MAX_SPEED_METERS_PER_SECOND) return
        lastLocation = location
        remember(location)
        distanceMeters += meters
    }

    private fun remember(location: Location) {
        if (route.size >= 400) return
        val stamp = java.time.Instant.ofEpochMilli(location.time).toString()
        route.add(
            mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "recordedAt" to stamp,
            ),
        )
    }

    @Deprecated("Required on API < 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    override fun onProviderEnabled(provider: String) {}

    override fun onProviderDisabled(provider: String) {}
}
