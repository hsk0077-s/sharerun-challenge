package com.sharerun.share_run_challenge

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * 저장하는 값(로그인 갱신 토큰 등)을 Android Keystore의 AES-GCM 키로 암호화한다.
 * 키는 기기 밖으로 나오지 않는다. 풀 수 없으면(키 삭제·복원 등) null을 돌려주고,
 * 호출한 쪽은 "연결 안 됨"으로 보고 다시 연결하게 한다.
 */
object SecretBox {
    private const val ALIAS = "sharerun_watch_store"
    private const val PREFIX = "enc1:"

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        gen.init(
            KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return gen.generateKey()
    }

    /** 암호화에 실패하면 null — 호출한 쪽은 평문으로 저장하지 않고 저장을 포기한다. */
    fun seal(plain: String): String? = try {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val body = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        PREFIX + Base64.encodeToString(cipher.iv + body, Base64.NO_WRAP)
    } catch (_: Exception) {
        null
    }

    /**
     * 암호화된 값은 풀어서 돌려주고, 풀 수 없으면 null.
     * 이 버전 이전에 평문으로 저장된 값은 그대로 돌려준다([needsMigration]으로 알 수 있음).
     */
    fun open(stored: String?): String? {
        if (stored == null) return null
        if (!stored.startsWith(PREFIX)) return stored
        return try {
            val raw = Base64.decode(stored.removePrefix(PREFIX), Base64.NO_WRAP)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, raw, 0, 12))
            String(cipher.doFinal(raw, 12, raw.size - 12), Charsets.UTF_8)
        } catch (_: Exception) {
            null
        }
    }

    fun needsMigration(stored: String?) = stored != null && !stored.startsWith(PREFIX)
}
