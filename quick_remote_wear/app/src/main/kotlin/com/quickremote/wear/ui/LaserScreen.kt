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
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.remote.PointerMover
import com.quickremote.wear.remote.Presenter
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.remote.Shortcut
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
 * The laser: the whole screen is a touchpad, as the phone's is. The finger
 * moves the computer's mouse and the dot follows it; the bezel still changes
 * slides. [presenter]'s laser keys go out as the finger touches and leaves
 * ([onShortcut]). [onPointer] answers whether the cursor moved, [onAction]
 * whether the key went out. The back button, a swipe from the left edge and the
 * close button at the bottom return to the slide buttons ([onClose]).
 */
@Composable
fun LaserScreen(
    presenter: Presenter,
    onShortcut: (Shortcut) -> Boolean,
    onPointer: (Int, Int) -> Boolean,
    onAction: (RemoteAction) -> Boolean,
    onClose: () -> Unit,
) {
    val haptics = rememberHaptics()
    val move by rememberUpdatedState(onPointer)
    val program by rememberUpdatedState(presenter)
    val press by rememberUpdatedState(onShortcut)
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
                        val down = awaitFirstDown()
                        // Left unconsumed, a touch on the left edge is the
                        // system's swipe back, as on every other screen.
                        if (down.position.x < EDGE_WIDTH.toPx()) return@awaitEachGesture
                        down.consume()
                        finger = down.position
                        haptics.sent()
                        program.laserDown?.let { press(it) }
                        val mover = PointerMover(LASER_GAIN)
                        var sentAt = down.uptimeMillis
                        fun flush() = mover.take().forEach { (dx, dy) -> move(dx, dy) }
                        try {
                            while (true) {
                                val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id } ?: break
                                // Read before consuming: a consumed change moves by zero.
                                val delta = change.positionChange()
                                change.consume()
                                if (!change.pressed) break
                                finger = change.position
                                mover.add(delta.x / density, delta.y / density)
                                if (change.uptimeMillis - sentAt >= SEND_INTERVAL_MS) {
                                    sentAt = change.uptimeMillis
                                    flush()
                                }
                            }
                        } finally {
                            flush()
                            program.laserUp?.let { press(it) }
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
        // Which program's laser this is: chosen on the computers screen.
        Text(
            presenterName(presenter),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.align(Alignment.TopCenter).offset(y = screen * 0.17f),
        )
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

/** Cursor counts per dp of finger movement: the watch is small, so more than the phone's 4. */
private const val LASER_GAIN = 6f

/** Where a touch is the swipe back instead of the laser: Wear's SwipeToDismissBox edge. */
private val EDGE_WIDTH = 30.dp

/** At most one batch of reports per frame, as on the phone. */
private const val SEND_INTERVAL_MS = 16L
