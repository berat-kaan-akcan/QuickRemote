package com.quickremote.wear.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Pointer
import com.quickremote.wear.phone.Show
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.LocalWearPalette
import com.quickremote.wear.ui.theme.WearColors
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.min
import kotlin.math.sin

/** The four quarters of the tools page, clockwise from the top. */
private enum class Tool(val angle: Float) { LASER(-90f), WHITE(0f), END(90f), BLACK(180f) }

/**
 * The show's tools, a swipe from the slide buttons: the round screen in four
 * quarters around the slide number. The laser on top (opens the laser
 * screen), the white and the black screen at the sides, and ending the show
 * at the bottom, which takes a hold of a second (a ring fills, the wrist
 * ticks) so that it is never pressed by accident.
 *
 * [pointer] names the laser's quarter. While no slideshow runs the computer
 * ignores the laser and the black and white screens ([showTools] false):
 * their quarters are faded and call [onUnavailable] instead.
 */
@Composable
fun ToolsPage(
    show: Show?,
    onPress: (RemoteAction) -> Unit,
    onLaser: () -> Unit,
    pointer: Pointer,
    showTools: Boolean,
    onUnavailable: () -> Unit,
) {
    val palette = LocalWearPalette.current
    val haptics = rememberHaptics()
    val press by rememberUpdatedState(onPress)
    val laser by rememberUpdatedState(onLaser)
    val usable by rememberUpdatedState(showTools)
    val unavailable by rememberUpdatedState(onUnavailable)
    val scope = rememberCoroutineScope()
    val ending = remember { Animatable(0f) }
    var pressed by remember { mutableStateOf<Tool?>(null) }

    val endLabel = stringResource(R.string.action_end)
    val labels = mapOf(
        Tool.LASER to stringResource(pointer.label),
        Tool.WHITE to stringResource(R.string.action_white_screen),
        Tool.BLACK to stringResource(R.string.action_black_screen),
    )
    // The quarters have room for one word.
    val words = mapOf(
        Tool.LASER to stringResource(pointer.word),
        Tool.WHITE to stringResource(R.string.tool_white),
        Tool.BLACK to stringResource(R.string.tool_black),
    )

    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val screen = min(maxWidth.value, maxHeight.value).dp
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .semantics {
                        contentDescription = labels.values.joinToString() + ", " + endLabel
                        val showOnly = listOf(
                            CustomAccessibilityAction(labels.getValue(Tool.LASER)) { laser(); true },
                            CustomAccessibilityAction(labels.getValue(Tool.WHITE)) {
                                press(RemoteAction.WHITE_SCREEN); true
                            },
                            CustomAccessibilityAction(labels.getValue(Tool.BLACK)) {
                                press(RemoteAction.BLACK_SCREEN); true
                            },
                        )
                        customActions = (if (showTools) showOnly else emptyList()) +
                            CustomAccessibilityAction(endLabel) { press(RemoteAction.END); true }
                    }
                    .pointerInput(Unit) {
                        awaitEachGesture {
                            val first = awaitFirstDown(requireUnconsumed = false)
                            val tool = toolAt(first.position, size.width / 2f, size.height / 2f) ?: return@awaitEachGesture
                            pressed = tool
                            var hold: Job? = null
                            var done = false
                            if (tool == Tool.END) {
                                first.consume()
                                hold = scope.launch {
                                    ending.snapTo(0f)
                                    ending.animateTo(1f, tween(END_HOLD_MS, easing = LinearEasing))
                                    done = true
                                    haptics.sent()
                                    press(RemoteAction.END)
                                }
                            }
                            var released = false
                            while (true) {
                                val change = awaitPointerEvent().changes.firstOrNull { it.id == first.id } ?: break
                                if (!change.pressed) {
                                    released = true
                                    break
                                }
                                if (tool == Tool.END) {
                                    // Held still on its quarter, ending is not
                                    // a swipe: the pages stay where they are.
                                    change.consume()
                                    if (toolAt(change.position, size.width / 2f, size.height / 2f) != Tool.END) break
                                } else if (change.isConsumed ||
                                    (change.position - first.position).getDistance() > viewConfiguration.touchSlop
                                ) {
                                    break
                                }
                            }
                            pressed = null
                            when {
                                tool == Tool.END -> if (!done) {
                                    hold?.cancel()
                                    scope.launch { ending.animateTo(0f, tween(END_HOLD_MS / 4)) }
                                } else {
                                    scope.launch { ending.snapTo(0f) }
                                }
                                !released -> Unit
                                !usable -> {
                                    haptics.failed()
                                    unavailable()
                                }
                                tool == Tool.LASER -> laser()
                                tool == Tool.WHITE -> press(RemoteAction.WHITE_SCREEN)
                                tool == Tool.BLACK -> press(RemoteAction.BLACK_SCREEN)
                            }
                        }
                    },
            ) {
                val c = Offset(size.width / 2, size.height / 2)
                val outer = size.minDimension / 2
                val fills = mapOf(
                    Tool.LASER to palette.raised,
                    Tool.WHITE to WearColors.white,
                    Tool.END to palette.danger.copy(alpha = 0.18f),
                    Tool.BLACK to WearColors.black,
                )
                for (tool in Tool.entries) {
                    drawArc(
                        fills.getValue(tool), tool.angle - 45f, 90f, true,
                        Offset(c.x - outer, c.y - outer), Size(outer * 2, outer * 2),
                        alpha = if (showTools || tool == Tool.END) 1f else DISABLED_ALPHA,
                    )
                    if (pressed == tool) {
                        drawArc(
                            Color.White.copy(alpha = 0.16f), tool.angle - 45f, 90f, true,
                            Offset(c.x - outer, c.y - outer), Size(outer * 2, outer * 2),
                        )
                    }
                }
                // The black quarter on the black screen: its edge in the outline.
                val edge = 2.dp.toPx()
                drawArc(
                    palette.border, Tool.BLACK.angle - 45f, 90f, false,
                    Offset(c.x - outer + edge / 2, c.y - outer + edge / 2),
                    Size(outer * 2 - edge, outer * 2 - edge), style = Stroke(edge),
                )
                // Gaps between the quarters, and the hole for the slide number.
                val gap = GAP.toPx()
                for (angle in listOf(45f, 135f)) {
                    val r = Math.toRadians(angle.toDouble())
                    val d = Offset((cos(r) * outer).toFloat(), (sin(r) * outer).toFloat())
                    drawLine(WearColors.black, c - d, c + d, gap)
                }
                drawCircle(WearColors.black, outer * HOLE + gap / 2, c)
                // Ending: a ring that fills along the edge.
                if (ending.value > 0f) {
                    val width = 6.dp.toPx()
                    val inset = width / 2 + 2.dp.toPx()
                    drawArc(
                        palette.danger, -90f, 360f * ending.value, false,
                        Offset(inset, inset), Size(size.width - inset * 2, size.height - inset * 2),
                        style = Stroke(width, cap = StrokeCap.Round),
                    )
                }
            }

            val mid = screen * LABEL_RADIUS
            val faded = !showTools
            ToolLabel(Tool.LASER, mid, faded) {
                Canvas(Modifier.size(screen * 0.11f)) {
                    drawLaserDot(center, size.minDimension / 2, palette.laser)
                }
                Text(words.getValue(Tool.LASER), style = MaterialTheme.typography.labelSmall, color = palette.laser)
            }
            ToolLabel(Tool.WHITE, mid, faded) {
                Text(words.getValue(Tool.WHITE), style = toolText(), color = WearColors.inkText, textAlign = TextAlign.Center)
            }
            ToolLabel(Tool.BLACK, mid, faded) {
                Text(words.getValue(Tool.BLACK), style = toolText(), color = WearColors.paperText, textAlign = TextAlign.Center)
            }
            ToolLabel(Tool.END, mid) {
                Icon(WearIcons.Stop, contentDescription = null, tint = palette.danger, modifier = Modifier.size(screen * 0.1f))
                Text(stringResource(R.string.hold_to_end), style = MaterialTheme.typography.labelSmall, color = palette.danger)
            }

            Box(Modifier.align(Alignment.Center)) {
                if (ending.value > 0f) {
                    Text(
                        stringResource(R.string.ending),
                        style = MaterialTheme.typography.labelSmall,
                        color = palette.danger,
                        textAlign = TextAlign.Center,
                    )
                } else {
                    // The hole holds the slide number; a longer word is cut.
                    Text(
                        showText(show),
                        style = MaterialTheme.typography.labelSmall,
                        color = palette.textSecondary,
                        textAlign = TextAlign.Center,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.widthIn(max = screen * HOLE * 0.9f),
                    )
                }
            }
        }
    }
}

@Composable
private fun toolText() = MaterialTheme.typography.labelMedium

/** A quarter's symbol and word, centred halfway out along the quarter. */
@Composable
private fun androidx.compose.foundation.layout.BoxScope.ToolLabel(
    tool: Tool,
    radius: Dp,
    faded: Boolean = false,
    content: @Composable () -> Unit,
) {
    val r = Math.toRadians(tool.angle.toDouble())
    val at = DpOffset(radius * cos(r).toFloat(), radius * sin(r).toFloat())
    Column(
        modifier = Modifier
            .align(Alignment.Center)
            .offset(at.x, at.y)
            .alpha(if (faded) DISABLED_ALPHA else 1f),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) { content() }
}

/** The quarter under [at], or null in the hole in the middle. */
private fun toolAt(at: Offset, cx: Float, cy: Float): Tool? {
    val dx = at.x - cx
    val dy = at.y - cy
    if (hypot(dx, dy) < min(cx, cy) * HOLE) return null
    val angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()
    return when {
        angle >= -135f && angle < -45f -> Tool.LASER
        angle >= -45f && angle < 45f -> Tool.WHITE
        angle >= 45f && angle < 135f -> Tool.END
        else -> Tool.BLACK
    }
}

/** The hole in the middle, in parts of the screen's radius. */
private const val HOLE = 0.36f

/** Where the quarters' words sit, from the middle, in parts of the screen: clear of the time on top. */
private const val LABEL_RADIUS = 0.29f
private val GAP = 4.dp

/** How long ending the show is held. */
private const val END_HOLD_MS = 1_000
