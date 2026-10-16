package com.quickremote.wear.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Picker
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.rememberPickerState
import com.quickremote.wear.R
import com.quickremote.wear.ui.theme.LocalWearPalette
import kotlin.math.min

/**
 * The talk's length, picked by the minute: a wheel from "no time limit" to
 * [MAX_MINUTES], scrolled with a finger, the bezel or the crown. The tick
 * keeps it ([onPick], in seconds); back leaves it as it was.
 */
@Composable
fun DurationScreen(seconds: Int, onPick: (Int) -> Unit) {
    val palette = LocalWearPalette.current
    val state = rememberPickerState(
        initialNumberOfOptions = MAX_MINUTES + 1,
        initiallySelectedIndex = (seconds / 60).coerceIn(0, MAX_MINUTES),
        shouldRepeatOptions = false,
    )
    val none = stringResource(R.string.duration_none)
    val title = stringResource(R.string.duration_title)
    // Read once per option passed, not per frame of the scroll.
    val chosen by remember { derivedStateOf { state.selectedOptionIndex } }
    val chosenText = if (chosen == 0) none else stringResource(R.string.duration_minutes, chosen)
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val screen = min(maxWidth.value, maxHeight.value).dp
            Text(
                title,
                style = MaterialTheme.typography.labelMedium,
                color = palette.textSecondary,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .offset(y = screen * 0.17f),
            )
            Picker(
                state = state,
                contentDescription = { "$title: $chosenText" },
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(screen * 0.7f, screen * 0.5f),
            ) { minutes ->
                val selected = minutes == chosen
                Box(Modifier.height(screen * 0.13f), contentAlignment = Alignment.Center) {
                    Text(
                        if (minutes == 0) none else stringResource(R.string.duration_minutes, minutes),
                        style = if (minutes == 0) MaterialTheme.typography.titleMedium else MaterialTheme.typography.displaySmall,
                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                        color = if (selected) palette.text else palette.muted,
                        maxLines = 1,
                    )
                }
            }
            RoundButton(
                onClick = { onPick(chosen * 60) },
                fill = palette.accentFill,
                diameter = screen * 0.17f,
                label = stringResource(R.string.duration_done),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .offset(y = -screen * 0.05f),
            ) {
                Icon(Icons.Rounded.Check, contentDescription = null, tint = palette.onAccent)
            }
        }
    }
}

/** The longest talk offered, in minutes. */
private const val MAX_MINUTES = 180
