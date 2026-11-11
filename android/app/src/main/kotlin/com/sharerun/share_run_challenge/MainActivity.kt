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
    private var linkChannel: MethodChannel? = null
    private var pendingLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Health Connect permission UI requires FragmentActivity (health package).
        pendingLink = shareRunLinkOf(intent)
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
        val links = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "share_run/links",
        )
        links.setMethodCallHandler { call, result ->
            if (call.method != "getInitialLink") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val link = pendingLink ?: shareRunLinkOf(intent)
            pendingLink = null
            if (link != null) {
                // 같은 주소를 다시 열지 않도록 인텐트에서 지운다.
                setIntent(Intent(intent).setData(null))
            }
            result.success(link)
        }
        linkChannel = links
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
        val link = shareRunLinkOf(intent)
        if (link != null) {
            // Dart가 아직 듣고 있지 않으면(로그인 전 등) 남겨 두었다가 나중에 getInitialLink로 넘긴다.
            pendingLink = link
            setIntent(Intent(intent).setData(null))
            linkChannel?.invokeMethod("onLink", link, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (pendingLink == link) pendingLink = null
                }

                override fun error(code: String, message: String?, details: Any?) {}

                override fun notImplemented() {}
            })
        }
    }

    private fun shareRunLinkOf(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (data.scheme != "sharerun") return null
        return data.toString()
    }
}
