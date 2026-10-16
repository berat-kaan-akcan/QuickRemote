package com.quickremote.wear.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Pointer
import com.quickremote.wear.phone.Show
import com.quickremote.wear.phone.TalkClock
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.LocalWearPalette
import kotlin.math.min

/** What the laser held on the Next button does: the same calls as the laser screen. */
class HeldLaser(
    val onDown: () -> Boolean,
    val onMove: (Float, Float) -> Unit,
    val onUp: () -> Unit,
)

/**
 * The slide buttons. The lower half of the round screen is one large Next
 * button, found without looking; previous and the laser screen are small
 * discs above it, beside the slide number and the talk's clock ([clock]:
 * the time left, or run). A ring along the upper edge shows how far
 * the show is. Held instead of tapped, Next turns into the laser: it follows
 * the finger, anywhere on the screen, until it lifts ([laser]). Until that
 * has been done once, Next says so.
 *
 * [pointer] names what the laser is on the computer. While it would ignore
 * the laser ([canPoint] false: no slideshow runs), the laser disc is faded,
 * and it and the held Next call [onUnavailable] instead.
 */
@Composable
fun RemotePage(
    show: Show?,
    clock: TalkClock?,
    onPress: (RemoteAction) -> Unit,
    onLaser: () -> Unit,
    laser: HeldLaser,
    pointer: Pointer,
    canPoint: Boolean,
    onUnavailable: () -> Unit,
) {
    val palette = LocalWearPalette.current
    val haptics = rememberHaptics()
    val context = LocalContext.current
    val press by rememberUpdatedState(onPress)
    val held by rememberUpdatedState(laser)
    val pointing by rememberUpdatedState(canPoint)
    val unavailable by rememberUpdatedState(onUnavailable)
    var pressed by remember { mutableStateOf(false) }
    var finger by remember { mutableStateOf<Offset?>(null) }
    var holdTip by remember { mutableStateOf(!Tips.seen(context, Tips.HELD_LASER)) }
    val nextLabel = stringResource(R.string.action_next)

    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            // In proportions of the round screen (192 dp and up).
            val screen = min(maxWidth.value, maxHeight.value).dp
            val nextTop = screen * NEXT_TOP
            val nextTopPx = with(LocalDensity.current) { nextTop.toPx() }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        awaitEachGesture {
                            val first = awaitFirstDown(requireUnconsumed = false)
                            if (first.position.y < nextTopPx) return@awaitEachGesture
                            pressed = true
                            // A tap is Next. A swipe belongs to the pages, so
                            // nothing is consumed until the finger has been
                            // held still long enough to be the laser.
                            var outcome = Touch.HOLD
                            withTimeoutOrNull(HOLD_MS) {
                                while (true) {
                                    val change = awaitPointerEvent().changes.firstOrNull { it.id == first.id }
                                    when {
                                        change == null -> outcome = Touch.CANCEL
                                        !change.pressed -> {
                                            change.consume()
                                            outcome = Touch.TAP
                                        }
                                        change.isConsumed ||
                                            (change.position - first.position).getDistance() > viewConfiguration.touchSlop ->
                                            outcome = Touch.CANCEL
                                        else -> continue
                                    }
                                    return@withTimeoutOrNull
                                }
                            }
                            pressed = false
                            when (outcome) {
                                Touch.TAP -> press(RemoteAction.NEXT)
                                Touch.CANCEL -> Unit
                                Touch.HOLD -> if (!pointing) {
                                    haptics.failed()
                                    unavailable()
                                } else {
                                    val on = held.onDown()
                                    if (on) haptics.sent() else haptics.failed()
                                    if (on) finger = first.position
                                    if (on && holdTip) {
                                        holdTip = false
                                        Tips.markSeen(context, Tips.HELD_LASER)
                                    }
                                    try {
                                        while (true) {
                                            val change = awaitPointerEvent().changes
                                                .firstOrNull { it.id == first.id } ?: break
                                            // Read before consuming: a consumed change moves by zero.
                                            val delta = change.positionChange()
                                            change.consume()
                                            if (!change.pressed) break
                                            if (on) {
                                                finger = change.position
                                                held.onMove(delta.x / density * LASER_GAIN, delta.y / density * LASER_GAIN)
                                            }
                                        }
                                    } finally {
                                        if (on) held.onUp()
                                        finger = null
                                    }
                                }
                            }
                        }
                    },
            ) {
                NextButton(
                    pressed = pressed,
                    hint = if (holdTip && canPoint) stringResource(pointer.holdHint) else null,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .height(screen - nextTop)
                        .semantics {
                            role = Role.Button
                            contentDescription = nextLabel
                            onClick { press(RemoteAction.NEXT); true }
                        },
                    screen = screen,
                )

                SmallButton(
                    onClick = { press(RemoteAction.PREV) },
                    label = stringResource(R.string.action_prev),
                    diameter = screen * SMALL,
                    modifier = Modifier.offset(x = screen * 0.07f, y = screen * SMALL_TOP),
                ) {
                    Icon(
                        WearIcons.ChevronLeft,
                        contentDescription = null,
                        tint = palette.text,
                        modifier = Modifier.size(screen * SMALL * 0.55f),
                    )
                }
                LaserButton(
                    diameter = screen * SMALL,
                    pointer = pointer,
                    enabled = canPoint,
                    onClick = if (canPoint) onLaser else onUnavailable,
                    modifier = Modifier.offset(x = screen * (0.93f - SMALL), y = screen * SMALL_TOP),
                )
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .offset(y = screen * 0.19f),
                ) {
                    SlideNumber(show, screen)
                    ShowClock(clock)
                }
                ProgressRing(show, Modifier.fillMaxSize())
                finger?.let { LaserPointer(it) }
            }
        }
    }
}

private enum class Touch { TAP, CANCEL, HOLD }

/** The lower part of the round screen, its top edge a flat dome; [hint] under its word. */
@Composable
private fun NextButton(pressed: Boolean, hint: String?, screen: Dp, modifier: Modifier) {
    val palette = LocalWearPalette.current
    Box(
        modifier = modifier
            .graphicsLayer { alpha = if (pressed) 0.82f else 1f }
            .clip(DomeShape)
            .background(palette.accentFill),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.offset(y = -screen * 0.03f),
        ) {
            Icon(
                WearIcons.ChevronRight,
                contentDescription = null,
                tint = palette.onAccent,
                modifier = Modifier.size(screen * 0.24f),
            )
            Text(
                stringResource(R.string.next_short),
                style = MaterialTheme.typography.labelSmall,
                color = palette.onAccent.copy(alpha = 0.85f),
                maxLines = 1,
            )
            if (hint != null) {
                Text(
                    hint,
                    style = MaterialTheme.typography.labelSmall,
                    color = palette.onAccent.copy(alpha = 0.7f),
                    maxLines = 1,
                    modifier = Modifier.padding(top = screen * 0.015f),
                )
            }
        }
    }
}

/** The top edge rises to the middle by [DOME_RISE] of the height. */
private val DomeShape = GenericShape { size, _ ->
    val rise = size.height * DOME_RISE
    moveTo(0f, rise)
    quadraticTo(size.width / 2, -rise, size.width, rise)
    lineTo(size.width, size.height)
    lineTo(0f, size.height)
    close()
}

@Composable
private fun SmallButton(
    onClick: () -> Unit,
    label: String,
    diameter: Dp,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    RoundButton(
        onClick = onClick,
        fill = SolidColor(LocalWearPalette.current.raised),
        diameter = diameter,
        label = label,
        modifier = modifier,
    ) { content() }
}

/** "12/24", the total smaller; without a number, what is known about the show. */
@Composable
private fun SlideNumber(show: Show?, screen: Dp) {
    val palette = LocalWearPalette.current
    if (show == null || !show.running || show.current <= 0 || show.total <= 0) {
        Text(
            showText(show),
            style = MaterialTheme.typography.labelMedium,
            color = palette.textSecondary,
            maxLines = 1,
        )
        return
    }
    val big = with(LocalDensity.current) { (screen * 0.15f).toSp() }
    val small = with(LocalDensity.current) { (screen * 0.075f).toSp() }
    Text(
        buildAnnotatedString {
            append(show.current.toString())
            pushStyle(SpanStyle(fontSize = small, color = palette.muted))
            append("/${show.total}")
            pop()
        },
        fontSize = big,
        fontWeight = FontWeight.Bold,
        color = palette.text,
        maxLines = 1,
    )
}

/** Slide progress along the upper half of the edge, while the slide number is known. */
@Composable
private fun ProgressRing(show: Show?, modifier: Modifier) {
    if (show == null || !show.running || show.current <= 0 || show.total <= 0) return
    val palette = LocalWearPalette.current
    val fraction = (show.current.toFloat() / show.total).coerceIn(0f, 1f)
    Canvas(modifier) {
        val width = RING_WIDTH.toPx()
        val inset = width / 2 + RING_INSET.toPx()
        val arcSize = Size(size.width - inset * 2, size.height - inset * 2)
        val topLeft = Offset(inset, inset)
        drawArc(palette.border, 180f, 180f, false, topLeft, arcSize, style = Stroke(width, cap = StrokeCap.Round))
        drawArc(
            palette.ring, 180f, 180f * fraction, false, topLeft, arcSize,
            style = Stroke(width, cap = StrokeCap.Round),
        )
    }
}

/** The laser dot under the held finger. */
@Composable
private fun LaserPointer(at: Offset) {
    val color = LocalWearPalette.current.laser
    Canvas(Modifier.fillMaxSize()) { drawLaserDot(at, size.minDimension * 0.085f, color) }
}

/** Where the Next button starts, from the top of the screen. */
private const val NEXT_TOP = 0.47f
private const val DOME_RISE = 0.12f

/** The previous and laser discs, and their top: clear of the time along the edge. */
private const val SMALL = 0.2f
private const val SMALL_TOP = 0.245f

/** Held this long without moving, Next becomes the laser. */
private const val HOLD_MS = 350L

private val RING_WIDTH = 3.dp
private val RING_INSET = 2.dp
