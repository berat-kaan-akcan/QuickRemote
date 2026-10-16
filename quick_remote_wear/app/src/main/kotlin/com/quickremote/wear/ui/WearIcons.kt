package com.quickremote.wear.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.addPathNodes
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

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
