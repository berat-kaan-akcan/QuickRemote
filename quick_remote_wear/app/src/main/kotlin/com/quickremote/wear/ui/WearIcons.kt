package com.quickremote.wear.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.graphics.vector.group
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp
import com.quickremote.wear.ui.theme.WearColors

/** Icons the core Material set lacks. */
object WearIcons {
    /** Material's "smartphone". */
    val Phone: ImageVector = icon(
        "Phone",
        "M17,1.01L7,1c-1.1,0 -2,0.9 -2,2v18c0,1.1 0.9,2 2,2h10c1.1,0 2,-0.9 2,-2V3c0,-1.1 -0.9,-1.99 -2,-1.99z" +
            "M17,19H7V5h10v14z",
    )

    /** A rounded square: "stop", the end of the slideshow. */
    val Stop: ImageVector = icon(
        "Stop",
        "M8,6h8a2,2 0 0 1 2,2v8a2,2 0 0 1 -2,2H8a2,2 0 0 1 -2,-2V8a2,2 0 0 1 2,-2z",
    )

    /** A bold, rounded chevron: the slide buttons' arrows. */
    val ChevronLeft: ImageVector = chevron("ChevronLeft", 15f, 8f)
    val ChevronRight: ImageVector = chevron("ChevronRight", 9f, 16f)

    /** Material's "more_horiz". */
    val MoreHoriz: ImageVector = icon(
        "MoreHoriz",
        "M6,10c-1.1,0 -2,0.9 -2,2s0.9,2 2,2 2,-0.9 2,-2 -0.9,-2 -2,-2z" +
            "M18,10c-1.1,0 -2,0.9 -2,2s0.9,2 2,2 2,-0.9 2,-2 -0.9,-2 -2,-2z" +
            "M12,10c-1.1,0 -2,0.9 -2,2s0.9,2 2,2 2,-0.9 2,-2 -0.9,-2 -2,-2z",
    )

    /**
     * The QuickRemote mark (brand/logo/mark-white.svg without the glow): a
     * white "Q" ring whose tail ends in the laser dot. Draw it with Image, not
     * Icon, which would tint the dot.
     */
    val Mark: ImageVector = ImageVector.Builder("Mark", 48.dp, 48.dp, 368f, 368f).apply {
        group(translationX = 181f, translationY = 181f) {
            path(stroke = SolidColor(WearColors.white), strokeLineWidth = 38f) {
                // rect x=-118 y=-118 w=200 h=200 rx=70
                moveTo(-48f, -118f)
                horizontalLineToRelative(60f)
                arcToRelative(70f, 70f, 0f, false, true, 70f, 70f)
                verticalLineToRelative(60f)
                arcToRelative(70f, 70f, 0f, false, true, -70f, 70f)
                horizontalLineToRelative(-60f)
                arcToRelative(70f, 70f, 0f, false, true, -70f, -70f)
                verticalLineToRelative(-60f)
                arcToRelative(70f, 70f, 0f, false, true, 70f, -70f)
                close()
            }
            path(
                stroke = SolidColor(WearColors.white),
                strokeLineWidth = 38f,
                strokeLineCap = StrokeCap.Round,
            ) {
                moveTo(16f, 16f)
                lineTo(74f, 74f)
            }
            path(fill = SolidColor(WearColors.laser)) {
                moveTo(97f, 120f)
                arcToRelative(23f, 23f, 0f, true, false, 46f, 0f)
                arcToRelative(23f, 23f, 0f, true, false, -46f, 0f)
                close()
            }
        }
    }.build()

    private fun chevron(name: String, armX: Float, tipX: Float): ImageVector =
        ImageVector.Builder(name, 24.dp, 24.dp, 24f, 24f).apply {
            path(
                stroke = SolidColor(Color.Black),
                strokeLineWidth = 2.6f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                moveTo(armX, 5f)
                lineTo(tipX, 12f)
                lineTo(armX, 19f)
            }
        }.build()

    private fun icon(name: String, pathData: String): ImageVector =
        ImageVector.Builder(name, 24.dp, 24.dp, 24f, 24f)
            .addPath(addPathNodes(pathData), fill = SolidColor(Color.Black))
            .build()
}
