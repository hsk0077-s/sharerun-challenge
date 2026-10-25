package com.sharerun.share_run_challenge

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Health Connect permission UI requires FragmentActivity (health package).
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "share_run/voice_coach_mute",
        ).setMethodCallHandler { call, result ->
            if (call.method != "mediaVolume") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            result.success(audio.getStreamVolume(AudioManager.STREAM_MUSIC))
        }
        // 달리기 중 음악: 다른 음악 앱을 조절(미디어 키)하거나 기본 음악 앱을 연다.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "share_run/music",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "key" -> {
                    val code = when (call.argument<String>("action")) {
                        "playPause" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                        "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
                        "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
                        else -> null
                    }
                    if (code == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, code))
                        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, code))
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
                "openApp" -> {
                    try {
                        val intent = Intent.makeMainSelectorActivity(
                            Intent.ACTION_MAIN,
                            Intent.CATEGORY_APP_MUSIC,
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "share_run/integrity",
        ).setMethodCallHandler { call, result ->
            if (call.method != "requestToken") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val nonce = call.argument<String>("nonce")
            val projectNumber = call.argument<String>("projectNumber")?.toLongOrNull()
            if (nonce.isNullOrBlank() || projectNumber == null) {
                result.error("bad_args", "nonce and projectNumber are required", null)
                return@setMethodCallHandler
            }
            try {
                IntegrityManagerFactory.create(applicationContext)
                    .requestIntegrityToken(
                        IntegrityTokenRequest.builder()
                            .setNonce(nonce)
                            .setCloudProjectNumber(projectNumber)
                            .build(),
                    )
                    .addOnSuccessListener { response -> result.success(response.token()) }
                    .addOnFailureListener { error ->
                        result.error("integrity_failed", error.message, null)
                    }
            } catch (error: Exception) {
                result.error("integrity_failed", error.message, null)
            }
        }
        RunFinishImageShare.register(this, flutterEngine)
        BleHeartRatePlugin.register(this, flutterEngine)
    }

    override fun getInitialRoute(): String? {
        val fromIntent = intent?.getStringExtra("route")
        if (!fromIntent.isNullOrBlank()) {
            return fromIntent
        }
        return super.getInitialRoute()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
