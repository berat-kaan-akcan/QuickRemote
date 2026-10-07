package com.quickremote.wear.ui

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Warning
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.RadioButton
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import com.quickremote.wear.R
import com.quickremote.wear.hid.HidState
import com.quickremote.wear.hid.Host
import com.quickremote.wear.remote.Presenter

/**
 * What the keyboard is doing while no computer is connected, and the paired
 * computers to pick from, and the program the laser is for. Also the
 * "Computers" screen of the remote.
 */
@Composable
fun StatusScreen(
    state: HidState,
    hosts: List<Host>,
    onConnect: (Host) -> Unit,
    onAddComputer: () -> Unit,
    onRetry: () -> Unit,
    presenter: Presenter,
    onPresenter: (Presenter) -> Unit,
) {
    val listState = rememberTransformingLazyColumnState()
    val spec = rememberTransformationSpec()
    // Computers make sense to pick only once the keyboard is registered.
    val canConnect = state is HidState.Waiting || state is HidState.Refused || state is HidState.Connected
    val noComputers = hosts.isEmpty()
    // Items that appear with a new state push the list down; a new state
    // starts at the top, where its title is.
    LaunchedEffect(state::class, hosts.size) { listState.scrollToItem(0) }
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(state = listState, contentPadding = contentPadding) {
            item {
                ListHeader(modifier = headerItem(spec)) {
                    when {
                        state.isBusy -> CircularProgressIndicator(modifier = Modifier.size(16.dp))
                        state.isProblem -> Icon(
                            Icons.Rounded.Warning,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(18.dp),
                        )
                    }
                    if (state.isBusy || state.isProblem) Spacer(Modifier.width(6.dp))
                    Text(stateTitle(state), textAlign = TextAlign.Center)
                }
            }
            if (state.hasText(noComputers)) {
                item {
                    Text(
                        stateText(state),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = textItem(spec),
                    )
                }
            }
            if (state is HidState.Unavailable) {
                item {
                    FilledTonalButton(
                        onClick = onRetry,
                        modifier = buttonItem(spec),
                        transformation = SurfaceTransformation(spec),
                        icon = { Icon(Icons.Rounded.Refresh, contentDescription = null) },
                        label = { Text(stringResource(R.string.retry)) },
                    )
                }
            }
            if (canConnect && !noComputers) {
                item {
                    ListHeader(modifier = headerItem(spec)) {
                        Text(stringResource(R.string.computers_title))
                    }
                }
                items(hosts, key = { it.address }) { host ->
                    val connected = (state as? HidState.Connected)?.host?.address == host.address
                    FilledTonalButton(
                        onClick = { onConnect(host) },
                        modifier = buttonItem(spec),
                        transformation = SurfaceTransformation(spec),
                        icon = { Icon(WearIcons.Bluetooth, contentDescription = null) },
                        secondaryLabel = if (connected) {
                            { Text(stringResource(R.string.computer_connected), maxLines = 1) }
                        } else {
                            null
                        },
                        label = { Text(host.name, maxLines = 2) },
                    )
                }
            }
            if (canConnect) {
                item {
                    Button(
                        onClick = onAddComputer,
                        modifier = buttonItem(spec),
                        transformation = SurfaceTransformation(spec),
                        icon = { Icon(Icons.Rounded.Add, contentDescription = null) },
                        label = { Text(stringResource(R.string.add_computer)) },
                    )
                }
                item {
                    ListHeader(modifier = headerItem(spec)) {
                        Text(stringResource(R.string.presenter_title))
                    }
                }
                items(Presenter.entries, key = { it.name }) { program ->
                    RadioButton(
                        selected = program == presenter,
                        onSelect = { onPresenter(program) },
                        modifier = buttonItem(spec),
                        transformation = SurfaceTransformation(spec),
                        label = { Text(presenterName(program)) },
                    )
                }
            }
        }
    }
}

private val HidState.isBusy: Boolean
    get() = this is HidState.Off || this is HidState.Starting ||
        (this is HidState.Waiting && target != null)

private val HidState.isProblem: Boolean
    get() = this is HidState.Unsupported || this is HidState.BluetoothOff ||
        this is HidState.Unavailable || this is HidState.Refused

private fun HidState.hasText(noComputers: Boolean): Boolean = when (this) {
    HidState.Off, HidState.Starting -> false
    is HidState.Waiting -> target != null || noComputers
    else -> true
}

@Composable
private fun stateTitle(state: HidState): String = stringResource(
    when (state) {
        HidState.Off, HidState.Starting -> R.string.state_starting
        HidState.Unsupported -> R.string.state_unsupported_title
        HidState.BluetoothOff -> R.string.state_bluetooth_off_title
        HidState.Unavailable -> R.string.state_unavailable_title
        is HidState.Waiting -> if (state.target != null) R.string.state_connecting else R.string.state_waiting
        is HidState.Refused -> R.string.state_refused_title
        is HidState.Connected -> R.string.state_connected
    },
)

@Composable
private fun stateText(state: HidState): String = when (state) {
    HidState.Off, HidState.Starting -> ""
    HidState.Unsupported -> stringResource(R.string.state_unsupported)
    HidState.BluetoothOff -> stringResource(R.string.state_bluetooth_off)
    HidState.Unavailable -> stringResource(R.string.state_unavailable)
    is HidState.Waiting -> state.target?.name ?: stringResource(R.string.state_waiting_none)
    is HidState.Refused -> stringResource(R.string.state_refused, state.host.name)
    is HidState.Connected -> state.host.name
}

@Composable
fun presenterName(presenter: Presenter): String = stringResource(
    when (presenter) {
        Presenter.POWERPOINT -> R.string.presenter_powerpoint
        Presenter.IMPRESS -> R.string.presenter_impress
        Presenter.WPS -> R.string.presenter_wps
    },
)
