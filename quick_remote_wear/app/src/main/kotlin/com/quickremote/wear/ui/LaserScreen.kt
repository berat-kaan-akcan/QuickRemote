package com.quickremote.wear.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.OutlinedIconButton
import com.quickremote.wear.R
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.WearColors
import kotlin.math.min

/** The small laser disc under the slide buttons: opens the laser screen. */
@Composable
fun LaserButton(diameter: Dp, onClick: () -> Unit) {
    RoundButton(
        onClick = onClick,
        fill = SolidColor(MaterialTheme.colorScheme.surfaceContainerHigh),
        diameter = diameter,
        label = stringResource(R.string.action_laser),
    ) {
        Canvas(Modifier.fillMaxSize()) { drawLaserDot(center, size.minDimension / 2) }
    }
}

/**
 * The laser: the whole screen is a touchpad, as the phone's is. The slide's
 * laser comes on as the finger touches ([onDown], false when there is no
 * computer), follows it ([onMove], in the computer's cursor units) and goes
 * out as it leaves ([onUp]); the bezel still changes slides ([onAction]
 * answers whether the command went out). The back button, a swipe from the
 * left edge and the close button at the bottom return to the slide buttons
 * ([onClose]).
 */
@Composable
fun LaserScreen(
    onDown: () -> Boolean,
    onMove: (Float, Float) -> Unit,
    onUp: () -> Unit,
    onAction: (RemoteAction) -> Boolean,
    onClose: () -> Unit,
) {
    val haptics = rememberHaptics()
    val down by rememberUpdatedState(onDown)
    val move by rememberUpdatedState(onMove)
    val up by rememberUpdatedState(onUp)
    val bezel = rememberSlideBezel { if (onAction(it)) haptics.step() else haptics.failed() }
    var finger by remember { mutableStateOf<Offset?>(null) }
    val background = MaterialTheme.colorScheme.background
    val hint = MaterialTheme.colorScheme.surfaceContainerHigh
    val label = stringResource(R.string.laser_hint)

    BoxWithConstraints(modifier = Modifier.fillMaxSize().then(bezel)) {
        val screen = min(maxWidth.value, maxHeight.value).dp
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .semantics { contentDescription = label }
                .pointerInput(Unit) {
                    awaitEachGesture {
                        val first = awaitFirstDown()
                        // Left unconsumed, a touch on the left edge is the
                        // system's swipe back, as on every other screen.
                        if (first.position.x < EDGE_WIDTH.toPx()) return@awaitEachGesture
                        first.consume()
                        if (!down()) {
                            haptics.failed()
                            return@awaitEachGesture
                        }
                        finger = first.position
                        haptics.sent()
                        try {
                            while (true) {
                                val change = awaitPointerEvent().changes.firstOrNull { it.id == first.id } ?: break
                                // Read before consuming: a consumed change moves by zero.
                                val delta = change.positionChange()
                                change.consume()
                                if (!change.pressed) break
                                finger = change.position
                                move(delta.x / density * LASER_GAIN, delta.y / density * LASER_GAIN)
                            }
                        } finally {
                            up()
                            finger = null
                        }
                    }
                },
        ) {
            drawRect(background)
            val radius = size.minDimension * 0.06f
            val at = finger
            if (at == null) {
                // Idle: a dim dot in the middle says where the laser is.
                drawCircle(hint, radius * 1.6f)
                drawLaserDot(center, radius, alpha = 0.6f)
            } else {
                drawLaserDot(at, radius * 1.4f)
            }
        }
        OutlinedIconButton(
            onClick = onClose,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .offset(y = -screen * 0.06f)
                .size(screen * 0.15f),
        ) {
            Icon(
                Icons.Rounded.Close,
                contentDescription = stringResource(R.string.laser_close),
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

/** The brand's laser dot: a glow and its core. */
private fun DrawScope.drawLaserDot(at: Offset, radius: Float, alpha: Float = 1f) {
    drawCircle(WearColors.laser.copy(alpha = 0.3f * alpha), radius * 0.84f, at)
    drawCircle(WearColors.laser.copy(alpha = alpha), radius * 0.48f, at)
}

/**
 * Cursor units per dp of finger movement. The phone's touchpad sends 8 per
 * logical pixel (touchpad_view.dart); the watch is half as wide, so more.
 */
private const val LASER_GAIN = 12f

/** Where a touch is the swipe back instead of the laser: Wear's SwipeToDismissBox edge. */
private val EDGE_WIDTH = 30.dp
