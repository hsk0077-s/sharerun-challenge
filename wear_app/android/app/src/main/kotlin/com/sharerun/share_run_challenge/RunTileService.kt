package com.sharerun.share_run_challenge

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * 시계 화면(타일)에서 바로 달리기를 시작하는 버튼.
 * 누르면 앱이 열리고 [MainActivity.EXTRA_AUTOSTART]를 보고 곧바로 3·2·1을 센다.
 * 앱이 비밀번호나 기록을 타일에 싣지 않는다(문구와 버튼뿐).
 */
class RunTileService : TileService() {
    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val launch = ActionBuilders.LaunchAction.Builder()
            .setAndroidActivity(
                ActionBuilders.AndroidActivity.Builder()
                    .setPackageName(packageName)
                    .setClassName(MainActivity::class.java.name)
                    .addKeyToExtraMapping(
                        MainActivity.EXTRA_AUTOSTART,
                        ActionBuilders.AndroidBooleanExtra.Builder().setValue(true).build(),
                    )
                    .build(),
            )
            .build()
        val clickable = ModifiersBuilders.Clickable.Builder()
            .setId("start_run")
            .setOnClick(launch)
            .build()
        val button = LayoutElementBuilders.Box.Builder()
            .setWidth(dp(112f))
            .setHeight(dp(112f))
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setBackground(
                        ModifiersBuilders.Background.Builder()
                            .setColor(argb(0xFF1FA855.toInt()))
                            .setCorner(ModifiersBuilders.Corner.Builder().setRadius(dp(56f)).build())
                            .build(),
                    )
                    .setClickable(clickable)
                    .build(),
            )
            .addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText("START")
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setSize(sp(24f))
                            .setColor(argb(0xFFFFFFFF.toInt()))
                            .build(),
                    )
                    .build(),
            )
            .build()
        val layout = LayoutElementBuilders.Column.Builder()
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText("쉐어런")
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setSize(sp(14f))
                            .setColor(argb(0xFFBDBDBD.toInt()))
                            .build(),
                    )
                    .build(),
            )
            .addContent(button)
            .build()
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(layout))
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        Futures.immediateFuture(
            ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build(),
        )

    private companion object {
        const val RESOURCES_VERSION = "1"
    }
}
