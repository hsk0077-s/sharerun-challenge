package com.sharerun.share_run_challenge

import android.app.Activity
import android.graphics.Color
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
                text = "Share Run Challenge"
                setTextColor(Color.parseColor("#171717"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                gravity = Gravity.CENTER
            },
        )
        root.addView(
            TextView(this).apply {
                text =
                    "이 앱은 러닝 기록 검증을 위해 Health Connect / HealthKit에서 " +
                        "심박수·걸음·운동·거리·칼로리 데이터를 읽습니다. " +
                        "데이터는 기록 검증 목적에만 사용되며, 동의 철회는 " +
                        "기기 설정 > Health Connect에서 언제든 가능합니다."
                setTextColor(Color.parseColor("#6B7280"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setPadding(0, pad, 0, 0)
            },
        )

        setContentView(root)
    }
}
