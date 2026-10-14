package com.quickremote.wear.ui

import android.Manifest
import android.os.SystemClock
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.TimeText
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.quickremote.wear.phone.LinkEvent
import com.quickremote.wear.phone.PhoneLink
import com.quickremote.wear.phone.PhoneState
import kotlinx.coroutines.delay

private const val ROUTE_HOME = "home"
private const val ROUTE_LASER = "laser"

@Composable
fun WearApp(phone: PhoneLink, ambient: Boolean) {
    val state by phone.state.collectAsStateWithLifecycle()
    val connected = state as? PhoneState.Connected
    val haptics = rememberHaptics()

    // The laser's own Bluetooth socket to the phone needs the "nearby
    // devices" permission: asked for as soon as the app opens (once per
    // start), so that it is there by the time the laser is. Refused, the
    // laser works as before.
    var bluetoothAllowed by remember { mutableStateOf(phone.directPermitted) }
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        bluetoothAllowed = granted
    }
    LaunchedEffect(Unit) {
        if (!bluetoothAllowed && !askedForBluetooth) {
            askedForBluetooth = true
            permission.launch(Manifest.permission.BLUETOOTH_CONNECT)
        }
    }

    // Outlives the connected screen: a dropped and restored connection comes
    // back to the page the presenter was on. Null until the first
    // connection, which opens on the slide buttons if a show is running.
    var page by rememberSaveable { mutableStateOf<Page?>(null) }

    // The link to the phone is kept awake while the laser screen is open, and
    // while the slide buttons are on screen, whose Next turns into the laser
    // when held: the same laser, as quick. Not while the screen is dimmed,
    // where a touch only wakes the watch. Opened again when the permission
    // comes, for the socket.
    var laserOpen by remember { mutableStateOf(false) }
    val awake = laserOpen || (connected != null && page == Page.REMOTE && !ambient)
    DisposableEffect(phone, awake, bluetoothAllowed) {
        if (awake) phone.laserScreen(true)
        onDispose { if (awake) phone.laserScreen(false) }
    }
    val heldLaser = remember(phone) {
        HeldLaser(
            onDown = phone::laserDown,
            onMove = phone::laserMove,
            onUp = phone::laserUp,
        )
    }

    // How long the show has run, counted from when the watch saw it start.
    // Kept through a dropped connection; the Bluetooth keyboard tells no show.
    var startedAt by rememberSaveable { mutableStateOf<Long?>(null) }
    val running = connected?.let { it.show?.running == true }
    LaunchedEffect(running) {
        when (running) {
            true -> if (startedAt == null) startedAt = SystemClock.elapsedRealtime()
            false -> startedAt = null
            null -> Unit
        }
    }

    // What the computer answered to a command, shown for a moment.
    var notice by remember { mutableStateOf<Notice?>(null) }
    LaunchedEffect(phone) {
        phone.events.collect { event ->
            haptics.failed()
            if (event is LinkEvent.PcError) notice = Notice(event.text)
        }
    }
    LaunchedEffect(notice) {
        if (notice != null) {
            delay(NOTICE_MS)
            notice = null
        }
    }

    AppScaffold(
        // Only the time: the computer's name would crowd the top of the remote.
        timeText = { TimeText() },
    ) {
        val nav = rememberSwipeDismissableNavController()
        SwipeDismissableNavHost(navController = nav, startDestination = ROUTE_HOME) {
            composable(ROUTE_HOME) {
                when (val current = state) {
                    is PhoneState.Connected -> ConnectedScreen(
                        show = current.show,
                        startedAt = startedAt,
                        onAction = { phone.send(it.command) },
                        onLaser = { nav.navigate(ROUTE_LASER) },
                        laser = heldLaser,
                        page = page,
                        onPageChange = { page = it },
                    )
                    else -> PhoneStatusScreen(
                        state = current,
                        onOpenPhone = phone::openOnPhone,
                        onRetry = phone::refresh,
                    )
                }
            }
            composable(ROUTE_LASER) {
                // Without a computer there is nothing to point at.
                if (connected == null) {
                    LaunchedEffect(Unit) { nav.popBackStack(ROUTE_HOME, inclusive = false) }
                }
                DisposableEffect(Unit) {
                    laserOpen = true
                    onDispose { laserOpen = false }
                }
                LaserScreen(
                    onDown = phone::laserDown,
                    onMove = phone::laserMove,
                    onUp = phone::laserUp,
                    onAction = { phone.send(it.command) },
                    onClose = { nav.popBackStack() },
                )
            }
        }
        notice?.let { NoticeBanner(it.text) }
        // Over the remote, which stays as it is underneath.
        if (ambient) AmbientScreen(state)
    }
}

/** A new object for every error, so that the same text again starts its time anew. */
private class Notice(val text: String)

/** The Bluetooth permission is asked for once per start of the app. */
private var askedForBluetooth = false

private const val NOTICE_MS = 4_000L


