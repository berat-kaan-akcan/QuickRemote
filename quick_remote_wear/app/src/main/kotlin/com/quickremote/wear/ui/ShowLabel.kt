package com.quickremote.wear.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.Show
import com.quickremote.wear.phone.TalkClock
import com.quickremote.wear.ui.theme.LocalWearPalette
import com.quickremote.wear.ui.theme.WearFonts
import java.util.Locale
import kotlinx.coroutines.delay

/**
 * The slide number, as "5 / 20", or whether a slideshow is running at all.
 * Without a [show] (the phone is the computer's Bluetooth keyboard) it names
 * the connection, which is why there is no number.
 */
@Composable
fun showText(show: Show?): String = when {
    show == null -> stringResource(R.string.show_bluetooth)
    show.viewer -> stringResource(R.string.show_viewer)
    !show.running ->stringResource(R.string.show_stopped)
    // A program driven with keys only (a WPS the user started) tells no slide.
    show.current > 0 && show.total > 0 -> stringResource(R.string.show_slide, show.current, show.total)
    else -> stringResource(R.string.show_running)
}

/**
 * The talk's clock: with a length, the time left ("12:48"), and past the end
 * how far past it ("+1:12", in the danger color); without one, how long the
 * talk has run. Past an hour "1:08:42". Nothing while it does not run.
 */
@Composable
fun ShowClock(clock: TalkClock?, modifier: Modifier = Modifier) {
    if (clock == null || !clock.shown) return
    val palette = LocalWearPalette.current
    val now by produceState(System.currentTimeMillis(), clock) {
        while (true) {
            value = System.currentTimeMillis()
            // On the clock's own second, not the watch's.
            delay(1_000L - ((value - clock.startedAt) % 1_000L).coerceAtLeast(0L))
        }
    }
    val elapsed = clock.elapsedAt(now)
    val over = clock.target > 0 && elapsed > clock.target
    val seconds = when {
        clock.target <= 0 -> elapsed
        over -> elapsed - clock.target
        else -> clock.target - elapsed
    }
    val color = if (over) palette.danger else palette.laser
    // With the phone's timer symbol, the figures in Space Grotesk.
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        modifier = modifier,
    ) {
        Icon(WearIcons.Timer, contentDescription = null, tint = color, modifier = Modifier.size(13.dp))
        Text(
            (if (over) "+" else "") + elapsedText(seconds * 1_000L),
            style = MaterialTheme.typography.labelMedium,
            fontFamily = WearFonts.grotesk,
            fontWeight = FontWeight.SemiBold,
            color = color,
            maxLines = 1,
        )
    }
}

/**
 * [clock] as the dimmed screen says it, to the minute: "12 min left", "Time's
 * up", or how long the talk has run. Null while it does not run.
 */
@Composable
fun ambientClockText(clock: TalkClock?): String? {
    if (clock == null || !clock.shown) return null
    val now by produceState(System.currentTimeMillis(), clock) {
        while (true) {
            value = System.currentTimeMillis()
            delay(AMBIENT_TICK_MS)
        }
    }
    val elapsed = clock.elapsedAt(now)
    return when {
        clock.target <= 0 -> stringResource(R.string.clock_minutes, elapsed / 60)
        elapsed >= clock.target -> stringResource(R.string.time_up)
        // Rounded up: "1 min left" until the very end.
        else -> stringResource(R.string.clock_minutes_left, (clock.target - elapsed + 59) / 60)
    }
}

/** The dimmed screen is drawn anew about once a minute anyway. */
private const val AMBIENT_TICK_MS = 20_000L

fun elapsedText(ms: Long): String {
    val seconds = ms / 1_000L
    val h = seconds / 3_600L
    val m = seconds / 60L % 60L
    val s = seconds % 60L
    return if (h > 0) String.format(Locale.ROOT, "%d:%02d:%02d", h, m, s) else String.format(Locale.ROOT, "%d:%02d", m, s)
}
