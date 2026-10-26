package com.sharerun.share_run_challenge

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * 달리는 동안 프로세스가 죽지 않게 붙들어 두는 포그라운드 서비스.
 * 화면이 꺼져도 [WatchTracker]의 심박·걸음·GPS 수집이 이어진다.
 * 데이터는 여기서 다루지 않는다.
 */
class TrackingService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "러닝 기록", NotificationManager.IMPORTANCE_LOW)
        )
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("쉐어런")
            .setContentText("러닝을 기록하고 있어요")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, foregroundTypes())
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: SecurityException) {
            // 심박·걸음·위치 권한이 하나도 없으면 시스템이 이 유형의 서비스를 거부한다.
            // 여기서 죽지 않고 서비스만 끈다(수집은 앞에 떠 있는 동안 이어진다).
            stopSelf()
        }
        return START_NOT_STICKY
    }

    /**
     * 허용된 권한에 맞는 유형만 단다. Android 14부터는 유형마다 그에 맞는 권한이
     * 있어야 하고, 없으면 [SecurityException]이 난다.
     */
    private fun foregroundTypes(): Int {
        var types = 0
        val health = granted(Manifest.permission.BODY_SENSORS) ||
            granted(Manifest.permission.ACTIVITY_RECOGNITION)
        if (health) types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
        if (granted(Manifest.permission.ACCESS_FINE_LOCATION)) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        }
        return types
    }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    companion object {
        private const val CHANNEL_ID = "sharerun_tracking"
        private const val NOTIFICATION_ID = 7101

        fun start(context: Context) {
            // 권한이 하나도 없으면 서비스를 켜지 않는다. 켜 놓고 startForeground를 못 부르면
            // 시스템이 앱을 강제로 끝낸다.
            val sensors = listOf(
                Manifest.permission.BODY_SENSORS,
                Manifest.permission.ACTIVITY_RECOGNITION,
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
            val any = sensors.any {
                context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
            }
            if (!any) return
            context.startForegroundService(Intent(context, TrackingService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TrackingService::class.java))
        }
    }
}
