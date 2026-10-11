package com.sharerun.share_run_challenge

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
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
