package com.sharerun.share_run_challenge

import android.content.Context
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the Play Install Referrer string once, so a friend who installs from a
 * brag card link (`...&referrer=invite%3DCODE`) lands on the invite code field
 * already filled. Returns null when Play has no referrer, the service is not
 * available (sideloaded, emulator) or anything throws. Never a reward by itself.
 */
object InstallReferrerChannel {
    private const val channelName = "share_run/install_referrer"

    fun register(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "getInstallReferrer") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                read(context.applicationContext) { value -> result.success(value) }
            }
    }

    private fun read(context: Context, done: (String?) -> Unit) {
        var finished = false
        fun finish(value: String?) {
            if (finished) return
            finished = true
            done(value)
        }
        try {
            val client = InstallReferrerClient.newBuilder(context).build()
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    try {
                        if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
                            finish(client.installReferrer.installReferrer)
                        } else {
                            finish(null)
                        }
                    } catch (_: Exception) {
                        finish(null)
                    } finally {
                        try {
                            client.endConnection()
                        } catch (_: Exception) {
                        }
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    finish(null)
                }
            })
        } catch (_: Exception) {
            finish(null)
        }
    }
}
