package com.quickremote.wear.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.OutlinedIconButton
import androidx.wear.compose.material3.ScreenScaffold
import com.quickremote.wear.R
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.WearColors
import kotlin.math.min

/**
 * The first page: the slideshow's actions as symbols. Start and stop, a black
 * and a white disc for the black and white screen, and the computers below.
 * Ending the show sits here, a swipe away from the slide buttons, so that it
 * is never pressed by accident.
 */
@Composable
fun ActionsPage(onPress: (RemoteAction) -> Unit, onComputers: () -> Unit) {
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            // In proportions of the round screen, above the page indicator.
            val screen = min(maxWidth.value, maxHeight.value).dp
            val diameter = screen * 0.24f
            Column(
                modifier = Modifier.align(Alignment.Center).offset(y = -screen * 0.06f),
                verticalArrangement = Arrangement.spacedBy(screen * 0.04f),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(screen * 0.06f)) {
                    RoundButton(
                        onClick = { onPress(RemoteAction.START) },
                        fill = CobaltFill,
                        diameter = diameter,
                        label = stringResource(R.string.action_start),
                    ) {
                        Icon(
                            Icons.Rounded.PlayArrow,
                            contentDescription = null,
                            tint = WearColors.white,
                            modifier = Modifier.size(diameter * 0.55f),
                        )
                    }
                    RoundButton(
                        onClick = { onPress(RemoteAction.END) },
                        fill = SolidColor(MaterialTheme.colorScheme.surfaceContainerHigh),
                        diameter = diameter,
                        label = stringResource(R.string.action_end),
                    ) {
                        Icon(
                            WearIcons.Stop,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(diameter * 0.5f),
                        )
                    }
                }
                // The screen colors themselves are the symbols.
                Row(horizontalArrangement = Arrangement.spacedBy(screen * 0.06f)) {
                    RoundButton(
                        onClick = { onPress(RemoteAction.BLACK_SCREEN) },
                        fill = SolidColor(WearColors.black),
                        diameter = diameter,
                        label = stringResource(R.string.action_black_screen),
                        border = BorderStroke(2.dp, MaterialTheme.colorScheme.outline),
                    )
                    RoundButton(
                        onClick = { onPress(RemoteAction.WHITE_SCREEN) },
                        fill = SolidColor(WearColors.white),
                        diameter = diameter,
                        label = stringResource(R.string.action_white_screen),
                    )
                }
            }
            OutlinedIconButton(
                onClick = onComputers,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .offset(y = -screen * 0.11f)
                    .size(screen * 0.15f),
            ) {
                Icon(
                    WearIcons.Bluetooth,
                    contentDescription = stringResource(R.string.computers_title),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}
