package com.sharerun.share_run_challenge

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
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
