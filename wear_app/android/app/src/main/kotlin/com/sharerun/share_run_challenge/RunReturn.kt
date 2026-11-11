package com.sharerun.share_run_challenge

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 달리는 중에 시계 화면 등으로 나갔다가 쉐어런 달리기 화면으로 돌아오게 하는 도우미.
 *
 * - 이벤트 기반이다. 화면에서 사라질 때(onStop) 한 번만 [DELAY_MS] 뒤 확인을 예약하고, 다시 보이면(onStart) 취소한다.
 *   주기적으로 깨어나지 않는다. 화면이 꺼져 있으면 켜지는 순간(ACTION_SCREEN_ON) 한 번만 확인한다.
 * - 백그라운드에서는 액티비티를 직접 띄울 수 없다(Android 10+ 백그라운드 액티비티 시작 제한).
 *   허용된 방법인 전체 화면 인텐트 알림([USE_FULL_SCREEN_INTENT])으로 요청한다.
 * - 통화 수신·통화 중, 일시정지·종료 상태에서는 돌아오지 않는다.
 * - 돌아온 직후 사용자가 곧바로 또 나가면(다른 일을 하려는 것) 한동안 돌아오지 않는다.
 */
object RunReturn {
    private const val TAG = "RunReturn"
    private const val CHANNEL_ID = "sharerun_return_quiet"
    private const val NOTIFICATION_ID = 7102

    /** 화면에서 사라진 뒤 확인하기까지 기다리는 시간. */
    const val DELAY_MS = 8_000L

    /** 돌아온 뒤 이 시간 안에 또 나가면 사용자가 나가려는 것으로 본다. */
    private const val QUICK_LEAVE_MS = 40_000L

    /** 위 경우에 자동 복귀를 쉬는 시간. */
    private const val SUPPRESS_MS = 5 * 60_000L

    /** 달리는 중(일시정지·종료 아님)일 때만 true. Dart가 단계가 바뀔 때마다 알려 준다. */
    @Volatile
    var enabled = false

    private val handler = Handler(Looper.getMainLooper())
    private var pending: Runnable? = null
    private var screenReceiver: BroadcastReceiver? = null
    private var lastReturnAt = 0L
    private var suppressUntil = 0L

    /** 쉐어런이 다시 화면에 보인다. 예약과 알림을 거둔다. */
    fun onForeground(context: Context) {
        cancel(context)
    }

    /** 화면에서 사라졌다. 달리는 중이고 화면이 켜져 있으면 잠시 뒤 확인을 예약한다. */
    fun onBackground(context: Context) {
        val app = context.applicationContext
        cancel(app)
        if (!enabled) return
        val now = SystemClock.elapsedRealtime()
        if (lastReturnAt != 0L && now - lastReturnAt < QUICK_LEAVE_MS) {
            // 돌아오자마자 또 나갔다. 사용자가 일부러 나간 것이므로 한동안 두지 않는다.
            suppressUntil = now + SUPPRESS_MS
            lastReturnAt = 0L
        }
        if (now < suppressUntil) {
            Log.i(TAG, "skip: suppressed after a quick leave")
            return
        }
        // 화면이 꺼져서 사라진 것이면(손목을 내림) 아무것도 하지 않는다. 켜지면 그대로 쉐어런이 보인다.
        val power = app.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!power.isInteractive) return
        val task = Runnable {
            pending = null
            returnIfStillAway(app)
        }
        pending = task
        handler.postDelayed(task, DELAY_MS)
    }

    /** 예약·화면 켜짐 대기·알림을 모두 거둔다. */
    fun cancel(context: Context) {
        pending?.let { handler.removeCallbacks(it) }
        pending = null
        val app = context.applicationContext
        screenReceiver?.let {
            try {
                app.unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        screenReceiver = null
        try {
            (app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
    }

    /** 달리기가 끝나거나 멈추면 모든 상태를 처음으로 돌린다. */
    fun reset(context: Context) {
        enabled = false
        lastReturnAt = 0L
        suppressUntil = 0L
        cancel(context)
    }

    private fun returnIfStillAway(app: Context) {
        if (!enabled) return
        if (inCall(app)) {
            Log.i(TAG, "skip: in call")
            return
        }
        val power = app.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!power.isInteractive) {
            waitForScreenOn(app)
            return
        }
        requestRunScreen(app)
    }

    /** 화면이 꺼져 있으면 켜지는 순간 한 번만 다시 확인한다. */
    private fun waitForScreenOn(app: Context) {
        if (screenReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                try {
                    app.unregisterReceiver(this)
                } catch (_: Exception) {
                }
                screenReceiver = null
                returnIfStillAway(app)
            }
        }
        try {
            app.registerReceiver(receiver, IntentFilter(Intent.ACTION_SCREEN_ON))
            screenReceiver = receiver
        } catch (e: Exception) {
            Log.w(TAG, "screen-on wait failed: $e")
        }
    }

    /** 통화 수신·통화 중이면 true. 권한 없이 오디오 모드로 본다. */
    fun inCall(context: Context): Boolean {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        return when (audio.mode) {
            AudioManager.MODE_RINGTONE,
            AudioManager.MODE_IN_CALL,
            AudioManager.MODE_IN_COMMUNICATION -> true
            else -> false
        }
    }

    /**
     * 전체 화면 인텐트 알림으로 달리기 화면을 요청한다. 소리·진동은 없다.
     * 이 권한을 못 받는 기기에서는 알림만 잠깐 보이고, 눌러서 돌아올 수 있다.
     */
    private fun requestRunScreen(app: Context) {
        val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 34 && !manager.canUseFullScreenIntent()) {
            Log.i(TAG, "full-screen intent not allowed on this device")
        }
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "쉐어런", NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            },
        )
        val open = PendingIntent.getActivity(
            app,
            1,
            Intent(app, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(app, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_run)
            .setContentTitle("쉐어런")
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setSilent(true)
            .setAutoCancel(true)
            .setTimeoutAfter(15_000L)
            .setContentIntent(open)
            .setFullScreenIntent(open, true)
            .build()
        try {
            lastReturnAt = SystemClock.elapsedRealtime()
            manager.notify(NOTIFICATION_ID, notification)
            Log.i(TAG, "run screen requested")
        } catch (e: Exception) {
            Log.w(TAG, "notify failed: $e")
        }
    }
}
