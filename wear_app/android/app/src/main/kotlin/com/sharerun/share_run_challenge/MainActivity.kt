package com.sharerun.share_run_challenge

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import android.net.Uri
import androidx.core.content.ContextCompat
import androidx.wear.remote.interactions.RemoteActivityHelper
import androidx.wear.widget.ConfirmationOverlay
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
 * - vibrate: `pattern`(밀리초 목록: 기다림, 진동, 쉼, 진동 …)대로 한 번 울린다. 1km 통과·일시정지·종료 알림.
 * - consumeAutostart: 시계 타일로 열렸으면 한 번만 true. 앱이 이미 떠 있을 때 타일을 누르면 `autostartRequested`를 보낸다.
 * - `networkAvailable`(앱 쪽으로 보내는 알림): 인터넷이 (다시) 연결됐다.
 * - getString / putString / remove: 로그인 토큰과 기록 대기열을 앱 전용 저장소에 둔다.
 * - signingCertSha1: 이 앱 서명 인증서의 SHA-1. Firebase 키의 안드로이드 앱 제한을 통과하려고 로그인 요청에 붙인다.
 */
class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var channel: MethodChannel? = null
    private var autostart = false
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methods = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methods.setMethodCallHandler(::onMethodCall)
        channel = methods
        autostart = intent?.getBooleanExtra(EXTRA_AUTOSTART, false) == true
        watchNetwork()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(EXTRA_AUTOSTART, false)) {
            // 앱이 이미 떠 있는 채로 타일을 눌렀다.
            channel?.invokeMethod("autostartRequested", null)
        }
    }

    override fun onDestroy() {
        networkCallback?.let {
            try {
                getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(it)
            } catch (_: Exception) {
            }
        }
        networkCallback = null
        super.onDestroy()
    }

    /** 인터넷이 연결될 때마다 앱에 알려 올리지 못한 기록을 다시 올리게 한다. */
    private fun watchNetwork() {
        if (networkCallback != null) return
        try {
            val manager = getSystemService(ConnectivityManager::class.java) ?: return
            val callback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    runOnUiThread { channel?.invokeMethod("networkAvailable", null) }
                }
            }
            manager.registerDefaultNetworkCallback(callback)
            networkCallback = callback
        } catch (_: Exception) {
            // 연결 상태를 못 받아도 주기적 재시도와 앱을 다시 켤 때의 올리기가 있다.
        }
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
                // 달리는 동안 화면이 꺼지며 시계 화면으로 돌아가지 않게 켜 둔다. 끝나면 푼다.
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                result.success(WatchTracker.snapshot())
            }
            "stopTracking" -> {
                WatchTracker.stop()
                TrackingService.stop(this)
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                result.success(null)
            }
            "readSnapshot" -> result.success(WatchTracker.snapshot())
            "consumeAutostart" -> {
                val requested = autostart
                autostart = false
                result.success(requested)
            }
            "vibrate" -> {
                vibrate(call.argument<List<Int>>("pattern").orEmpty())
                result.success(null)
            }
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
            "signingCertSha1" -> result.success(signingCertSha1())
            "openOnPhone" -> openOnPhone(call.argument("uri"), result)
            else -> result.notImplemented()
        }
    }

    private fun prefs() = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** 페어링된 폰에서 [uriString]을 연다. 실패해도 앱은 멈추지 않는다. */
    private fun openOnPhone(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrBlank()) {
            result.success(false)
            return
        }
        val uri = try {
            Uri.parse(uriString)
        } catch (_: Exception) {
            result.success(false)
            return
        }
        if (uri.scheme != "sharerun") {
            result.success(false)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW)
                .addCategory(Intent.CATEGORY_BROWSABLE)
                .setData(uri)
            val future = RemoteActivityHelper(this).startRemoteActivity(intent)
            future.addListener({
                try {
                    future.get()
                    runOnUiThread {
                        try {
                            ConfirmationOverlay()
                                .setType(ConfirmationOverlay.OPEN_ON_PHONE_ANIMATION)
                                .showOn(this)
                        } catch (_: Exception) {
                        }
                        result.success(true)
                    }
                } catch (_: Exception) {
                    runOnUiThread { result.success(false) }
                }
            }, ContextCompat.getMainExecutor(this))
        } catch (_: Exception) {
            result.success(false)
        }
    }

    /** 지금 설치된 앱의 서명 인증서 SHA-1(대문자 16진수). 못 읽으면 null. */
    private fun signingCertSha1(): String? {
        return try {
            val signing = packageManager
                .getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo ?: return null
            val certs = if (signing.hasMultipleSigners()) {
                signing.apkContentsSigners
            } else {
                signing.signingCertificateHistory
            }
            val cert = certs?.lastOrNull() ?: return null
            java.security.MessageDigest.getInstance("SHA-1")
                .digest(cert.toByteArray())
                .joinToString("") { "%02X".format(it) }
        } catch (e: Exception) {
            null
        }
    }

    /** 진동을 못 내는 기기에서도 앱이 멈추지 않도록 실패는 삼킨다. */
    private fun vibrate(pattern: List<Int>) {
        if (pattern.size < 2) return
        try {
            val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            if (vibrator == null || !vibrator.hasVibrator()) return
            val timings = LongArray(pattern.size) { pattern[it].toLong().coerceIn(0L, 2000L) }
            vibrator.vibrate(VibrationEffect.createWaveform(timings, -1))
        } catch (_: Exception) {
        }
    }

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

        /** 시계 타일이 앱을 열 때 붙이는 값. 있으면 시작 화면에서 바로 카운트다운을 한다. */
        const val EXTRA_AUTOSTART = "sharerun.autostart"
        private const val PREFS = "sharerun_watch"
        private const val PERMISSION_REQUEST = 7100
    }
}
