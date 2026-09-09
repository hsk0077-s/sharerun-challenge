package com.sharerun.share_run_challenge

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Health Connect permission UI requires FragmentActivity (health package).
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
