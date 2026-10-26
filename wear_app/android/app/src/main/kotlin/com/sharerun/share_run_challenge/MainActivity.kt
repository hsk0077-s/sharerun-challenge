package com.sharerun.share_run_challenge

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 워치 센서 채널 `sharerun/watch_sensors`.
 *
 * - requestPermissions: 심박·걸음·위치(·알림) 권한을 묻고 허용된 센서 이름 목록을 돌려준다.
 * - startTracking / stopTracking: 포그라운드 서비스와 센서 수집을 켜고 끈다.
 * - readSnapshot: 지금까지 모인 심박(bpm)·걸음 수·거리(km).
 * - getString / putString / remove: 로그인 토큰과 기록 대기열을 앱 전용 저장소에 둔다.
 */
class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermissions" -> requestSensorPermissions(result)
            "startTracking" -> {
                WatchTracker.start(
                    this,
                    bodySensors = granted(Manifest.permission.BODY_SENSORS),
                    activityRecognition = granted(Manifest.permission.ACTIVITY_RECOGNITION),
                    fineLocation = granted(Manifest.permission.ACCESS_FINE_LOCATION),
                )
                try {
                    TrackingService.start(this)
                } catch (_: Exception) {
                    // 서비스를 못 켜도 앞에 떠 있는 동안은 수집이 이어진다.
                }
                result.success(WatchTracker.snapshot())
            }
            "stopTracking" -> {
                WatchTracker.stop()
                TrackingService.stop(this)
                result.success(null)
            }
            "readSnapshot" -> result.success(WatchTracker.snapshot())
            "getString" -> {
                val key = call.argument<String>("key")
                val stored = prefs().getString(key, null)
                val plain = SecretBox.open(stored)
                if (plain != null && SecretBox.needsMigration(stored)) {
                    // 예전에 평문으로 저장된 값은 읽을 때 암호화해서 다시 저장한다.
                    SecretBox.seal(plain)?.let { prefs().edit().putString(key, it).apply() }
                }
                result.success(plain)
            }
            "putString" -> {
                val value = call.argument<String>("value")
                val sealed = value?.let { SecretBox.seal(it) }
                if (value != null && sealed == null) {
                    result.error("seal_failed", "could not encrypt value", null)
                } else {
                    prefs().edit().putString(call.argument<String>("key"), sealed).apply()
                    result.success(null)
                }
            }
            "remove" -> {
                prefs().edit().remove(call.argument<String>("key")).apply()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun prefs() = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun grantedSensors(): List<String> = buildList {
        if (granted(Manifest.permission.BODY_SENSORS)) add("heartRate")
        if (granted(Manifest.permission.ACTIVITY_RECOGNITION)) add("steps")
        if (granted(Manifest.permission.ACCESS_FINE_LOCATION)) add("gps")
    }

    private fun requestSensorPermissions(result: MethodChannel.Result) {
        val wanted = mutableListOf(
            Manifest.permission.BODY_SENSORS,
            Manifest.permission.ACTIVITY_RECOGNITION,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
        if (Build.VERSION.SDK_INT >= 33) wanted.add(Manifest.permission.POST_NOTIFICATIONS)
        val missing = wanted.filter { !granted(it) }
        if (missing.isEmpty()) {
            result.success(grantedSensors())
            return
        }
        if (pendingPermissionResult != null) {
            result.error("busy", "permission request already open", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        pendingPermissionResult?.success(grantedSensors())
        pendingPermissionResult = null
    }

    companion object {
        private const val CHANNEL = "sharerun/watch_sensors"
        private const val PREFS = "sharerun_watch"
        private const val PERMISSION_REQUEST = 7100
    }
}
