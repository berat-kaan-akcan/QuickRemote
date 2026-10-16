package com.quickremote.wear.ui

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import com.quickremote.wear.R
import com.quickremote.wear.phone.PhoneState

/**
 * Why there is no remote yet, and what to do about it on the phone. Nothing
 * is set up here: the remote opens by itself once the phone is connected to
 * a computer.
 */
@Composable
fun PhoneStatusScreen(state: PhoneState, onOpenPhone: () -> Unit, onRetry: () -> Unit) {
    val listState = rememberTransformingLazyColumnState()
    val spec = rememberTransformationSpec()
    val busy = state is PhoneState.Checking || (state is PhoneState.NotConnected && state.connecting)
    val text = stateText(state)
    // A new state starts at the top, where its title is.
    LaunchedEffect(state) { listState.scrollToItem(0) }
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(state = listState, contentPadding = contentPadding) {
            item {
                ListHeader(modifier = Modifier.headerItem(this, spec)) {
                    when {
                        busy -> CircularProgressIndicator(modifier = Modifier.size(16.dp))
                        state is PhoneState.NoPhone -> Icon(
                            Icons.Rounded.Warning,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(18.dp),
                        )
                    }
                    if (busy || state is PhoneState.NoPhone) Spacer(Modifier.width(6.dp))
                    Text(stateTitle(state), textAlign = TextAlign.Center)
                }
            }
            if (text != null) {
                item {
                    Text(
                        text,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.textItem(this, spec),
                    )
                }
            }
            if (state is PhoneState.AppClosed || state is PhoneState.NotConnected) {
                item {
                    Button(
                        onClick = onOpenPhone,
                        modifier = Modifier.buttonItem(this, spec),
                        transformation = SurfaceTransformation(spec),
                        icon = { Icon(WearIcons.Phone, contentDescription = null) },
                        label = { Text(stringResource(R.string.open_on_phone)) },
                    )
                }
            }
            if (state is PhoneState.NoPhone) {
                item {
                    FilledTonalButton(
                        onClick = onRetry,
                        modifier = Modifier.buttonItem(this, spec),
                        transformation = SurfaceTransformation(spec),
                        icon = { Icon(Icons.Rounded.Refresh, contentDescription = null) },
                        label = { Text(stringResource(R.string.retry)) },
                    )
                }
            }
        }
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
