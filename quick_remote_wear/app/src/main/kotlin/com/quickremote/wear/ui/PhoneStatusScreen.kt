package com.quickremote.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.ProgressIndicatorDefaults
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.quickremote.wear.R
import com.quickremote.wear.phone.PhoneState
import com.quickremote.wear.ui.theme.LocalWearPalette
import com.quickremote.wear.ui.theme.WearFonts
import kotlin.math.min

/**
 * Why there is no remote yet, and what to do about it on the phone, in the
 * phone's style: a badge, a title, a line, and a pill-shaped key at the
 * bottom. Nothing is set up here: the remote opens by itself once the phone
 * is connected to a computer.
 */
@Composable
fun PhoneStatusScreen(state: PhoneState, onOpenPhone: () -> Unit, onRetry: () -> Unit) {
    val palette = LocalWearPalette.current
    val busy = state is PhoneState.Checking || (state is PhoneState.NotConnected && state.connecting)
    val text = stateText(state)
    // As before, also while the phone connects.
    val open = state is PhoneState.AppClosed || state is PhoneState.NotConnected
    val retry = state is PhoneState.NoPhone
    ScreenScaffold {
        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val screen = min(maxWidth.value, maxHeight.value).dp
            val sp = LocalDensity.current
            val hasKey = open || retry
            // With a key below, the words sit a little higher.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = if (hasKey) screen * 0.08f else 0.dp),
                contentAlignment = Alignment.Center,
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(screen * 0.024f),
                    modifier = Modifier
                        .width(screen * 0.74f)
                        .heightIn(max = if (hasKey) screen * 0.6f else screen * 0.8f)
                        .verticalScroll(rememberScrollState()),
                ) {
                    when {
                        busy -> CircularProgressIndicator(
                            modifier = Modifier.size(screen * 0.11f),
                            colors = ProgressIndicatorDefaults.colors(
                                indicatorColor = palette.accentText,
                                trackColor = palette.border,
                            ),
                            strokeWidth = 2.dp,
                        )
                        state is PhoneState.NoPhone -> StateBadge(Icons.Rounded.Warning, palette.danger, screen)
                        state is PhoneState.AppClosed -> StateBadge(WearIcons.Phone, palette.accentText, screen)
                        state is PhoneState.NotConnected -> StateBadge(WearIcons.Link, palette.accentText, screen)
                    }
                    Text(
                        stateTitle(state),
                        fontFamily = WearFonts.grotesk,
                        fontWeight = FontWeight.Bold,
                        fontSize = with(sp) { (screen * 0.07f).toSp() },
                        lineHeight = 1.2.em,
                        color = palette.text,
                        textAlign = TextAlign.Center,
                    )
                    if (text != null) {
                        Text(
                            text,
                            fontSize = with(sp) { (screen * 0.05f).toSp() },
                            lineHeight = 1.35.em,
                            color = palette.textSecondary,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
            }
            if (hasKey) {
                StateKey(
                    icon = if (open) WearIcons.Phone else Icons.Rounded.Refresh,
                    label = stringResource(if (open) R.string.open_on_phone else R.string.retry),
                    filled = open,
                    onClick = if (open) onOpenPhone else onRetry,
                    screen = screen,
                    modifier = Modifier.align(Alignment.TopCenter).offset(y = screen * 0.84f - screen * 0.0735f),
                )
            }
        }
    }
}

/** The phone's badge: a symbol on a rounded square of its color. */
@Composable
private fun StateBadge(icon: ImageVector, color: Color, screen: Dp) {
    Box(
        modifier = Modifier
            .size(screen * 0.12f)
            .background(color.copy(alpha = 0.16f), RoundedCornerShape(screen * 0.04f)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(screen * 0.07f))
    }
}

/** A pill at the bottom: filled to open the phone, tonal to try again. */
@Composable
private fun StateKey(
    icon: ImageVector,
    label: String,
    filled: Boolean,
    onClick: () -> Unit,
    screen: Dp,
    modifier: Modifier,
) {
    val palette = LocalWearPalette.current
    val content = if (filled) palette.onAccent else palette.accentText
    val fill = if (filled) {
        Brush.linearGradient(listOf(palette.accentEnd, palette.accent))
    } else {
        Brush.linearGradient(List(2) { palette.accent.copy(alpha = 0.18f).compositeOver(palette.surface) })
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(screen * 0.023f, Alignment.CenterHorizontally),
        modifier = modifier
            .width(screen * 0.66f)
            .heightIn(min = screen * 0.147f)
            .clip(CircleShape)
            .background(fill)
            .clickable(role = Role.Button, onClick = onClick),
    ) {
        Icon(icon, contentDescription = null, tint = content, modifier = Modifier.size(screen * 0.054f))
        Text(
            label,
            fontSize = with(LocalDensity.current) { (screen * 0.05f).toSp() },
            fontWeight = FontWeight.SemiBold,
            color = content,
            maxLines = 1,
        )
    }
}

@Composable
fun stateTitle(state: PhoneState): String = stringResource(
    when (state) {
        PhoneState.Checking -> R.string.state_checking
        PhoneState.NoPhone -> R.string.state_no_phone_title
        PhoneState.AppClosed -> R.string.state_app_closed_title
        is PhoneState.NotConnected ->
            if (state.connecting) R.string.state_connecting_title else R.string.state_not_connected_title
        is PhoneState.Connected -> R.string.state_connected
    },
)

@Composable
private fun stateText(state: PhoneState): String? = when (state) {
    PhoneState.Checking -> null
    PhoneState.NoPhone -> stringResource(R.string.state_no_phone)
    PhoneState.AppClosed -> stringResource(R.string.state_app_closed)
    is PhoneState.NotConnected ->
        stringResource(if (state.connecting) R.string.state_connecting else R.string.state_not_connected)
    is PhoneState.Connected -> state.pc
}
