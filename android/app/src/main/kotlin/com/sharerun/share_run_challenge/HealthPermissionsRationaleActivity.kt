package com.sharerun.share_run_challenge

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Health Connect 권한 고지 전용 Activity.
 * Flutter 엔진을 띄우지 않아 런처/최근앱에 클론 인스턴스가 생기지 않는다.
 */
class HealthPermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val pad = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            24f,
            resources.displayMetrics,
        ).toInt()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(pad, pad, pad, pad)
            gravity = Gravity.CENTER_HORIZONTAL
        }

        root.addView(
            TextView(this).apply {
                text = "쉐어런"
                setTextColor(Color.parseColor("#171717"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                gravity = Gravity.CENTER
            },
        )
        root.addView(
            TextView(this).apply {
                text =
                    "이 앱은 걸음 보상과 러닝 기록 검증을 위해 Health Connect / HealthKit에서 " +
                        "걸음 수와 심박수 데이터를 읽습니다. " +
                        "심박수 원본은 서버에 저장하지 않고 검증 계산에만 씁니다. " +
                        "데이터는 이 목적에만 사용하며 광고나 판매에 쓰지 않습니다. 동의 철회는 " +
                        "기기 설정 > Health Connect에서 언제든 가능합니다."
                setTextColor(Color.parseColor("#6B7280"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setPadding(0, pad, 0, 0)
            },
        )

        root.addView(
            TextView(this).apply {
                text = "개인정보 처리방침 보기"
                setTextColor(Color.parseColor("#2563EB"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setPadding(0, pad, 0, 0)
                setOnClickListener {
                    startActivity(
                        Intent(
                            Intent.ACTION_VIEW,
                            Uri.parse("https://share-run-challenge.web.app/privacy.html"),
                        ),
                    )
                }
            },
        )

        setContentView(root)
    }
}
