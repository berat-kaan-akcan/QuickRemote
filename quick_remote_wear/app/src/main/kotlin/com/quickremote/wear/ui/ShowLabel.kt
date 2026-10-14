package com.quickremote.wear.ui

import android.os.SystemClock
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Show
import com.quickremote.wear.ui.theme.LocalWearPalette
import java.util.Locale
import kotlinx.coroutines.delay

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

/**
 * How long the show has run, from [startedAt] (an elapsedRealtime, null while
 * no show runs): "8:42", past an hour "1:08:42". Counted on the watch, from
 * when it saw the show start.
 */
@Composable
fun ShowClock(startedAt: Long?, modifier: Modifier = Modifier) {
    if (startedAt == null) return
    val now by produceState(SystemClock.elapsedRealtime(), startedAt) {
        while (true) {
            value = SystemClock.elapsedRealtime()
            delay(1_000L - (value - startedAt) % 1_000L)
        }
    }
    Text(
        elapsedText((now - startedAt).coerceAtLeast(0L)),
        style = MaterialTheme.typography.labelMedium,
        color = LocalWearPalette.current.laser,
        maxLines = 1,
        modifier = modifier,
    )
}

fun elapsedText(ms: Long): String {
    val seconds = ms / 1_000L
    val h = seconds / 3_600L
    val m = seconds / 60L % 60L
    val s = seconds % 60L
    return if (h > 0) String.format(Locale.ROOT, "%d:%02d:%02d", h, m, s) else String.format(Locale.ROOT, "%d:%02d", m, s)
}
