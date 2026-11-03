package com.sharerun.share_run_challenge

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Instagram Stories (`com.instagram.share.ADD_TO_STORY`) and a TikTok image
 * send. The poster file is the only payload.
 */
object RunFinishImageShare {
    private const val channelName = "share_run/finish_image_share"
    private const val instagram = "com.instagram.android"
    private const val tiktok = "com.zhiliaoapp.musically"
    private const val tiktokAlt = "com.ss.android.ugc.trill"

    fun register(activity: MainActivity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "instagramInstalled" -> result.success(activity.isPkgInstalled(instagram))
                    "tiktokInstalled" -> result.success(
                        activity.isPkgInstalled(tiktok) || activity.isPkgInstalled(tiktokAlt),
                    )
                    "shareInstagramStory" -> result.success(
                        activity.shareInstagramStory(call.argument("path")),
                    )
                    "shareTikTok" -> result.success(activity.shareTikTok(call.argument("path")))
                    "installedTargets" -> result.success(activity.installedShareTargets())
                    "shareTarget" -> result.success(
                        activity.shareToTarget(
                            call.argument("id"),
                            call.argument("path"),
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }
}

@Suppress("DEPRECATION")
private fun MainActivity.isPkgInstalled(packageName: String): Boolean {
    return try {
        packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }
}

private fun MainActivity.shareUri(path: String?): Uri? {
    if (path.isNullOrBlank()) return null
    val source = File(path)
    if (!source.exists()) return null
    val cached = File(cacheDir, "share_run_finish.png")
    source.copyTo(cached, overwrite = true)
    return FileProvider.getUriForFile(this, "$packageName.runfinish.fileprovider", cached)
}

private fun MainActivity.shareInstagramStory(path: String?): Boolean {
    if (!isPkgInstalled("com.instagram.android")) return false
    val uri = shareUri(path) ?: return false
    val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
        setDataAndType(uri, "image/png")
        putExtra("source_application", packageName)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        clipData = ClipData.newRawUri("share_run", uri)
        setPackage("com.instagram.android")
    }
    return try {
        grantUriPermission("com.instagram.android", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

private fun MainActivity.installedShareTargets(): List<String> {
    val ids = mutableListOf<String>()
    if (isPkgInstalled("com.instagram.android")) {
        ids += "story"
        ids += "feed"
    }
    if (isPkgInstalled("com.zhiliaoapp.musically") || isPkgInstalled("com.ss.android.ugc.trill")) {
        ids += "tiktok"
    }
    if (isPkgInstalled("com.facebook.katana")) ids += "facebook"
    if (isPkgInstalled("com.kakao.talk")) ids += "kakao"
    if (isPkgInstalled("jp.naver.line.android")) ids += "line"
    if (isPkgInstalled("com.twitter.android")) ids += "x"
    if (isPkgInstalled("com.whatsapp")) ids += "whatsapp"
    if (isPkgInstalled("org.telegram.messenger")) ids += "telegram"
    return ids
}

private fun MainActivity.shareToTarget(id: String?, path: String?): Boolean {
    if (id == "story") return shareInstagramStory(path)
    val pkg = when (id) {
        "feed" -> "com.instagram.android"
        "tiktok" -> when {
            isPkgInstalled("com.zhiliaoapp.musically") -> "com.zhiliaoapp.musically"
            isPkgInstalled("com.ss.android.ugc.trill") -> "com.ss.android.ugc.trill"
            else -> return false
        }
        "facebook" -> "com.facebook.katana"
        "kakao" -> "com.kakao.talk"
        "line" -> "jp.naver.line.android"
        "x" -> "com.twitter.android"
        "whatsapp" -> "com.whatsapp"
        "telegram" -> "org.telegram.messenger"
        else -> return false
    }
    if (!isPkgInstalled(pkg)) return false
    val uri = shareUri(path) ?: return false
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "image/png"
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        clipData = ClipData.newRawUri("share_run", uri)
        setPackage(pkg)
    }
    return try {
        grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

private fun MainActivity.shareTikTok(path: String?): Boolean {
    val pkg = when {
        isPkgInstalled("com.zhiliaoapp.musically") -> "com.zhiliaoapp.musically"
        isPkgInstalled("com.ss.android.ugc.trill") -> "com.ss.android.ugc.trill"
        else -> return false
    }
    val uri = shareUri(path) ?: return false
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "image/png"
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        clipData = ClipData.newRawUri("share_run", uri)
        setPackage(pkg)
    }
    return try {
        grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}
