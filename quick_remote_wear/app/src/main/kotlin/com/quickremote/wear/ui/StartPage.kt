package com.quickremote.wear.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Show
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.LocalWearPalette
import kotlin.math.min

/**
 * While no show runs there is one thing to do: one large Start. Starting
 * turns to the slide buttons; they and the tools are a swipe away for what
 * runs without a slideshow (a PDF in full screen).
 */
@Composable
fun StartPage(show: Show?, onPress: (RemoteAction) -> Unit) {
    val palette = LocalWearPalette.current
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val screen = min(maxWidth.value, maxHeight.value).dp
            val diameter = screen * 0.4f
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
                        fill = palette.accentFill,
                        diameter = diameter,
                        label = stringResource(R.string.action_start),
                    ) {
                        Icon(
                            Icons.Rounded.PlayArrow,
                            contentDescription = null,
                            tint = palette.onAccent,
                            modifier = Modifier.size(diameter * 0.55f),
                        )
                    }
                }
                Text(
                    stringResource(R.string.action_start),
                    style = MaterialTheme.typography.labelSmall,
                    color = palette.text,
                    maxLines = 1,
                )
            }
        }
    }
}
