package com.quickremote.wear.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Show
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.LocalWearPalette
import com.quickremote.wear.ui.theme.WearColors
import kotlin.math.min

/**
 * While no show runs there is one thing to do: one large Start. Starting
 * turns to the slide buttons; they and the tools are a swipe away for what
 * runs without a slideshow (a PDF in full screen). Start is green in
 * every theme, as on the phone.
 *
 * Under it the talk's length ([duration], seconds, 0: none), picked with −
 * and + ([onDuration]); the phone's timer takes it too, and a length picked
 * there shows here. Null from a phone that keeps no length: then Start's
 * word stands there.
 */
@Composable
fun StartPage(show: Show?, onPress: (RemoteAction) -> Unit, duration: Int?, onDuration: (Int) -> Boolean) {
    val palette = LocalWearPalette.current
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val screen = min(maxWidth.value, maxHeight.value).dp
            val diameter = screen * 0.36f
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(screen * 0.025f),
            ) {
                Text(
                    showText(show),
                    style = MaterialTheme.typography.labelMedium,
                    color = palette.textSecondary,
                    maxLines = 1,
                )
                Box(
                    modifier = Modifier
                        .size(diameter + screen * 0.07f)
                        .border(2.dp, palette.border, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    RoundButton(
                        onClick = { onPress(RemoteAction.START) },
                        fill = StartFill,
                        diameter = diameter,
                        label = stringResource(R.string.action_start),
                    ) {
                        Icon(
                            Icons.Rounded.PlayArrow,
                            contentDescription = null,
                            tint = WearColors.onSuccess,
                            modifier = Modifier.size(diameter * 0.55f),
                        )
                    }
                }
                if (duration == null) {
                    Text(
                        stringResource(R.string.action_start),
                        style = MaterialTheme.typography.labelSmall,
                        color = palette.text,
                        maxLines = 1,
                    )
                } else {
                    DurationPicker(duration, onDuration, screen)
                }
            }
        }
    }
}

/** "−  20 min  +": the talk's length in [STEPS]. */
@Composable
private fun DurationPicker(duration: Int, onDuration: (Int) -> Boolean, screen: Dp) {
    val palette = LocalWearPalette.current
    val haptics = rememberHaptics()
    // Shown at once; the phone's answer follows.
    var picked by remember(duration) { mutableIntStateOf(duration) }
    val minutes = picked / 60
    val lower = STEPS.lastOrNull { it < minutes }
    val higher = STEPS.firstOrNull { it > minutes }
    fun pick(to: Int?) {
        if (to == null) return
        if (onDuration(to * 60)) {
            picked = to * 60
            haptics.step()
        } else {
            haptics.failed()
        }
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(screen * 0.02f),
    ) {
        StepButton("−", stringResource(R.string.duration_shorter), lower != null, screen) { pick(lower) }
        Text(
            if (minutes == 0) stringResource(R.string.duration_none) else stringResource(R.string.duration_minutes, minutes),
            style = MaterialTheme.typography.labelMedium,
            color = if (minutes == 0) palette.textSecondary else palette.text,
            textAlign = TextAlign.Center,
            maxLines = 1,
            modifier = Modifier.widthIn(min = screen * 0.22f),
        )
        StepButton("+", stringResource(R.string.duration_longer), higher != null, screen) { pick(higher) }
    }
}

@Composable
private fun StepButton(symbol: String, label: String, enabled: Boolean, screen: Dp, onClick: () -> Unit) {
    val palette = LocalWearPalette.current
    RoundButton(
        onClick = onClick,
        fill = SolidColor(palette.raised),
        diameter = screen * 0.13f,
        label = label,
        modifier = Modifier.alpha(if (enabled) 1f else DISABLED_ALPHA),
    ) {
        Text(symbol, style = MaterialTheme.typography.titleMedium, color = palette.text)
    }
}

/** The lengths offered, in minutes; 0 is none (the clock counts up). */
private val STEPS = listOf(0, 5, 10, 15, 20, 25, 30, 40, 45, 50, 60, 75, 90, 120)

private val StartFill = Brush.linearGradient(listOf(WearColors.successDeep, WearColors.success))
