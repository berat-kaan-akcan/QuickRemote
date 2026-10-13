package com.quickremote.wear.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Show

/**
 * The slide number, as "5 / 20", or whether a slideshow is running at all.
 * Without a [show] (the phone is the computer's Bluetooth keyboard) it names
 * the connection, which is why there is no number.
 */
@Composable
fun ShowLabel(show: Show?, modifier: Modifier = Modifier) {
    val numbered = show != null && show.running && show.current > 0 && show.total > 0
    Text(
        showText(show),
        style = if (numbered) MaterialTheme.typography.titleMedium else MaterialTheme.typography.labelMedium,
        color = if (numbered) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant,
        maxLines = 1,
        modifier = modifier,
    )
}

@Composable
fun showText(show: Show?): String = when {
    show == null -> stringResource(R.string.show_bluetooth)
    !show.running -> stringResource(R.string.show_stopped)
    // A program driven with keys only (a WPS the user started) tells no slide.
    show.current > 0 && show.total > 0 -> stringResource(R.string.show_slide, show.current, show.total)
    else -> stringResource(R.string.show_running)
}
