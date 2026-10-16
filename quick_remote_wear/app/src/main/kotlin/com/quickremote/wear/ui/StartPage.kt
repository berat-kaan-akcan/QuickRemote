package com.quickremote.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
                    DurationChip(duration, onEditDuration, screen)
                }
            }
        }
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
