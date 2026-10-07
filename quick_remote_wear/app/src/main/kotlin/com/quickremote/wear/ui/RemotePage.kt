package com.quickremote.wear.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.ScreenScaffold
import com.quickremote.wear.R
import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.ui.theme.WearColors
import kotlin.math.min

/**
 * The slide buttons: two large circles side by side, previous and next, and
 * the small laser below them, which opens the laser screen ([onLaser]).
 */
@Composable
fun RemotePage(onPress: (RemoteAction) -> Unit, onLaser: () -> Unit) {
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            // In proportions of the round screen: the largest two circles
            // that fit side by side on every size (192 dp and up), lifted a
            // little so the laser stays clear of the page indicator.
            val screen = min(maxWidth.value, maxHeight.value).dp
            Column(
                modifier = Modifier.align(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(screen * 0.04f),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(screen * 0.04f)) {
                    SlideButton(next = false, diameter = screen * 0.44f) { onPress(RemoteAction.PREV) }
                    SlideButton(next = true, diameter = screen * 0.44f) { onPress(RemoteAction.NEXT) }
                }
                LaserButton(diameter = screen * 0.16f, onClick = onLaser)
            }
        }
    }
}

/** A slide button in the brand's cobalt, next a shade brighter than previous. */
@Composable
private fun SlideButton(next: Boolean, diameter: Dp, onClick: () -> Unit) {
    RoundButton(
        onClick = onClick,
        fill = if (next) CobaltFill else CobaltDeepFill,
        diameter = diameter,
        label = stringResource(if (next) R.string.action_next else R.string.action_prev),
    ) {
        Icon(
            if (next) WearIcons.ChevronRight else WearIcons.ChevronLeft,
            contentDescription = null,
            tint = WearColors.white,
            modifier = Modifier.size(diameter * 0.46f),
        )
    }
}
