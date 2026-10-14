package com.quickremote.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.ui.theme.WearColors
import kotlin.math.min

/**
 * The room's screen is black (or white): the watch looks the same, so a
 * glance tells it. A tap anywhere brings the slide back ([onRestore]); the
 * bezel still changes slides underneath.
 */
@Composable
fun BlankScreen(white: Boolean, onRestore: () -> Unit) {
    val fill = if (white) WearColors.paper else WearColors.black
    val text = if (white) WearColors.inkText else WearColors.paperText
    val hint = if (white) WearColors.inkTextMuted else WearColors.paperTextMuted
    val back = stringResource(R.string.blank_restore)
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(fill)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                role = Role.Button,
                onClickLabel = back,
                onClick = onRestore,
            ),
    ) {
        val screen = min(maxWidth.value, maxHeight.value).dp
        Column(
            modifier = Modifier.align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(screen * 0.03f),
        ) {
            Box(
                Modifier
                    .size(screen * 0.2f)
                    .background(if (white) WearColors.white else WearColors.black, CircleShape)
                    .border(2.dp, if (white) WearColors.paperBorder else WearColors.paperTextMuted, CircleShape),
            )
            Text(
                stringResource(if (white) R.string.blank_white else R.string.blank_black),
                style = MaterialTheme.typography.titleMedium,
                color = text,
                textAlign = TextAlign.Center,
            )
            Text(
                back,
                style = MaterialTheme.typography.bodySmall,
                color = hint,
                textAlign = TextAlign.Center,
            )
        }
    }
}
