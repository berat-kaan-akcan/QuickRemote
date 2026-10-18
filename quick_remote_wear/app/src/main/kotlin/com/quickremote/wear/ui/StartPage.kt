package com.quickremote.wear.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
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
 * Under it the talk's length ([duration], seconds, 0: none), which a tap
 * opens to pick by the minute ([onEditDuration], [DurationScreen]); the
 * phone's timer takes it too, and a length picked there shows here. Null from a phone that keeps no length: then Start's
 * word stands there.
 */
@Composable
fun StartPage(show: Show?, onPress: (RemoteAction) -> Unit, duration: Int?, onEditDuration: () -> Unit) {
    val palette = LocalWearPalette.current
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val screen = min(maxWidth.value, maxHeight.value).dp
            val diameter = screen * 0.4f
            ConnectionPill(
                show,
                screen,
                Modifier.align(Alignment.TopCenter).offset(y = screen * 0.215f - screen * 0.045f),
            )
            // The ring around Start, and a green glow under it.
            Canvas(Modifier.fillMaxSize()) {
                val unit = size.minDimension / 100f
                val at = Offset(center.x, 53f * unit)
                drawCircle(
                    Brush.radialGradient(
                        listOf(WearColors.success.copy(alpha = 0.3f), WearColors.success.copy(alpha = 0f)),
                        center = at.copy(y = at.y + 3f * unit),
                        radius = 26f * unit,
                    ),
                    26f * unit,
                    at.copy(y = at.y + 3f * unit),
                )
                drawCircle(palette.border, 23.5f * unit, at, style = Stroke(1.dp.toPx()))
            }
            RoundButton(
                onClick = { onPress(RemoteAction.START) },
                fill = StartFill,
                diameter = diameter,
                label = stringResource(R.string.action_start),
                modifier = Modifier.align(Alignment.TopCenter).offset(y = screen * 0.53f - diameter / 2),
            ) {
                Icon(
                    Icons.Rounded.PlayArrow,
                    contentDescription = null,
                    tint = WearColors.onSuccess,
                    modifier = Modifier.size(diameter * 0.55f),
                )
            }
            Box(
                modifier = Modifier.align(Alignment.TopCenter).offset(y = screen * 0.78f),
                contentAlignment = Alignment.Center,
            ) {
                if (duration == null) {
                    Text(
                        stringResource(R.string.action_start),
                        fontSize = with(LocalDensity.current) { (screen * 0.058f).toSp() },
                        fontWeight = FontWeight.SemiBold,
                        color = palette.text,
                        maxLines = 1,
                    )
                } else {
                    DurationChip(duration, onEditDuration, screen)
                }
            }
        }
    }
}

/**
 * On top, as the phone's chip: "● Connected · Slideshow off" over Wi-Fi;
 * over Bluetooth (no [show]: a keyboard is told nothing) the connection's name.
 */
@Composable
private fun ConnectionPill(show: Show?, screen: Dp, modifier: Modifier) {
    val palette = LocalWearPalette.current
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(screen * 0.02f),
        modifier = modifier
            .clip(CircleShape)
            .background(palette.surface)
            .border(1.dp, palette.border, CircleShape)
            .padding(horizontal = screen * 0.037f, vertical = screen * 0.013f),
    ) {
        if (show == null) {
            Icon(WearIcons.Bluetooth, contentDescription = null, tint = WearColors.info, modifier = Modifier.size(screen * 0.046f))
        } else {
            Canvas(Modifier.size(screen * 0.037f)) {
                drawCircle(WearColors.success.copy(alpha = 0.25f))
                drawCircle(WearColors.success, size.minDimension * 0.26f)
            }
        }
        Text(
            if (show == null) showText(null) else stringResource(R.string.connected_show, showText(show)),
            fontSize = with(LocalDensity.current) { (screen * 0.047f).toSp() },
            fontWeight = FontWeight.SemiBold,
            color = palette.text,
            maxLines = 1,
        )
    }
}

/** "20 min ✎": the talk's length; a tap opens the wheel that picks it. */
@Composable
private fun DurationChip(duration: Int, onEdit: () -> Unit, screen: Dp) {
    val palette = LocalWearPalette.current
    val minutes = duration / 60
    val text = if (minutes == 0) stringResource(R.string.duration_none) else stringResource(R.string.duration_minutes, minutes)
    val label = stringResource(R.string.duration_title) + ": " + text
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(screen * 0.02f),
        modifier = Modifier
            .clip(CircleShape)
            .background(palette.raised)
            .clickable(role = Role.Button, onClickLabel = label, onClick = onEdit)
            .semantics { contentDescription = label }
            .heightIn(min = screen * 0.12f)
            .padding(horizontal = screen * 0.05f),
    ) {
        Text(
            text,
            style = MaterialTheme.typography.labelMedium,
            color = if (minutes == 0) palette.textSecondary else palette.text,
            maxLines = 1,
        )
        Icon(
            Icons.Rounded.Edit,
            contentDescription = null,
            tint = palette.accentText,
            modifier = Modifier.size(screen * 0.06f),
        )
    }
}

private val StartFill = Brush.linearGradient(listOf(WearColors.successDeep, WearColors.success))
