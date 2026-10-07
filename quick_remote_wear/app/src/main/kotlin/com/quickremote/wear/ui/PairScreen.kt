package com.quickremote.wear.ui

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Search
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.items
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
import com.quickremote.wear.hid.HidConnection
import com.quickremote.wear.hid.HidState
import com.quickremote.wear.hid.PcScanner

private enum class Visibility { ON, DENIED, UNSUPPORTED }

/**
 * Adds a computer, from either side: the computer pairs with the watch made
 * visible, or the watch finds the computer and pairs with it. Wear OS may not
 * offer the first, so the second is always there.
 */
@Composable
fun PairScreen(hid: HidConnection, state: HidState, onConnected: () -> Unit) {
    val context = LocalContext.current
    val scanner = remember { PcScanner(context.applicationContext) }
    DisposableEffect(scanner) { onDispose { scanner.close() } }
    val found by scanner.found.collectAsStateWithLifecycle()
    val searching by scanner.searching.collectAsStateWithLifecycle()
    val pairing by scanner.pairing.collectAsStateWithLifecycle()
    var searched by remember { mutableStateOf(false) }
    var visibility by remember { mutableStateOf<Visibility?>(null) }

    // A computer connected, whichever way it paired: back to the remote. The
    // one connected when the screen opened does not count.
    val connectedBefore = remember { (state as? HidState.Connected)?.host?.address }
    LaunchedEffect(state) {
        if (state is HidState.Connected && state.host.address != connectedBefore) onConnected()
    }
    LaunchedEffect(pairing) {
        (pairing as? PcScanner.Pairing.Bonded)?.let { hid.connect(it.address, justPaired = true) }
    }

    // The result code is the granted duration, RESULT_CANCELED (0) if refused.
    val makeVisible = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        visibility = if (it.resultCode > 0) Visibility.ON else Visibility.DENIED
    }
    fun search() {
        searched = true
        scanner.search()
    }
    val searchPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        if (Permissions.granted(context, Permissions.search)) search()
    }

    val listState = rememberTransformingLazyColumnState()
    val spec = rememberTransformationSpec()
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(state = listState, contentPadding = contentPadding) {
            item {
                ListHeader(modifier = headerItem(spec)) {
                    Text(stringResource(R.string.add_computer))
                }
            }
            item {
                Button(
                    onClick = {
                        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                            .putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, VISIBLE_SECONDS)
                        try {
                            makeVisible.launch(intent)
                        } catch (_: ActivityNotFoundException) {
                            visibility = Visibility.UNSUPPORTED
                        }
                    },
                    modifier = buttonItem(spec),
                    transformation = SurfaceTransformation(spec),
                    icon = { Icon(WearIcons.Bluetooth, contentDescription = null) },
                    secondaryLabel = { Text(stringResource(R.string.pair_from_computer_hint)) },
                    label = { Text(stringResource(R.string.pair_from_computer)) },
                )
            }
            visibility?.let { visible ->
                item {
                    Note(
                        when (visible) {
                            Visibility.ON -> stringResource(R.string.pair_visible, watchName(context))
                            Visibility.DENIED -> stringResource(R.string.pair_visible_denied)
                            Visibility.UNSUPPORTED -> stringResource(R.string.pair_visible_unsupported)
                        },
                        textItem(spec),
                    )
                }
            }
            item {
                FilledTonalButton(
                    onClick = {
                        if (Permissions.granted(context, Permissions.search)) {
                            search()
                        } else {
                            searchPermission.launch(Permissions.search)
                        }
                    },
                    enabled = !searching,
                    modifier = buttonItem(spec),
                    transformation = SurfaceTransformation(spec),
                    icon = { Icon(Icons.Rounded.Search, contentDescription = null) },
                    secondaryLabel = { Text(stringResource(R.string.pair_from_watch_hint)) },
                    label = { Text(stringResource(R.string.pair_from_watch)) },
                )
            }
            pairingNote(pairing)?.let { note ->
                item { Note(stringResource(note), textItem(spec)) }
            }
            items(found, key = { it.address }) { pc ->
                FilledTonalButton(
                    onClick = { scanner.pair(pc.address) },
                    enabled = pairing !is PcScanner.Pairing.Bonding,
                    modifier = buttonItem(spec),
                    transformation = SurfaceTransformation(spec),
                    label = { Text(pc.name, maxLines = 2) },
                )
            }
            if (searching) {
                item {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                        modifier = textItem(spec),
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp))
                        Text(stringResource(R.string.pair_searching), style = MaterialTheme.typography.bodySmall)
                    }
                }
            } else if (searched && found.isEmpty()) {
                item { Note(stringResource(R.string.pair_none_found), textItem(spec)) }
            }
        }
    }
}

private fun pairingNote(pairing: PcScanner.Pairing): Int? = when (pairing) {
    PcScanner.Pairing.Idle -> null
    is PcScanner.Pairing.Bonding -> R.string.pair_bonding
    is PcScanner.Pairing.Bonded -> R.string.pair_connecting
    is PcScanner.Pairing.Failed -> R.string.pair_failed
}

@Composable
private fun Note(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center,
        modifier = modifier,
    )
}

/** The name a computer lists the watch under. */
@SuppressLint("MissingPermission") // Shown only after the permissions were granted.
private fun watchName(context: android.content.Context): String =
    context.getSystemService(BluetoothManager::class.java)?.adapter?.name.orEmpty()

private const val VISIBLE_SECONDS = 120
