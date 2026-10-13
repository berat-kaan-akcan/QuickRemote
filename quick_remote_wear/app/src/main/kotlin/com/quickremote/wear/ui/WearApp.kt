package com.quickremote.wear.ui

import android.Manifest
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
import androidx.wear.compose.material3.timeTextCurvedText
import androidx.wear.compose.material3.timeTextSeparator
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
        timeText = {
            // The computer's name beside the time, while there is one.
            val computer = connected?.pc.orEmpty().shortened(COMPUTER_NAME_LENGTH)
            TimeText(maxSweepAngle = TIME_TEXT_SWEEP) { time ->
                timeTextCurvedText(time)
                if (computer.isNotEmpty()) {
                    timeTextSeparator()
                    timeTextCurvedText(computer)
                }
            }
        },
    ) {
        // Outlives the connected screen: a dropped and restored connection
        // comes back to the page the presenter was on. Null until the first
        // connection, which opens on the slide buttons if a show is running.
        var page by rememberSaveable { mutableStateOf<Int?>(null) }
        val nav = rememberSwipeDismissableNavController()
        SwipeDismissableNavHost(navController = nav, startDestination = ROUTE_HOME) {
            composable(ROUTE_HOME) {
                when (val current = state) {
                    is PhoneState.Connected -> ConnectedScreen(
                        show = current.show,
                        onAction = { phone.send(it.command) },
                        onLaser = { nav.navigate(ROUTE_LASER) },
                        page = page ?: if (current.show?.running == true) PAGE_REMOTE else PAGE_ACTIONS,
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
                // The laser's own Bluetooth socket to the phone needs the
                // "nearby devices" permission: asked for once per start,
                // here where it is used. Refused, the laser works as before.
                val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
                    if (granted) phone.laserScreen(true)
                }
                DisposableEffect(phone) {
                    phone.laserScreen(true)
                    if (!phone.directPermitted && !askedForBluetooth) {
                        askedForBluetooth = true
                        permission.launch(Manifest.permission.BLUETOOTH_CONNECT)
                    }
                    onDispose { phone.laserScreen(false) }
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

private fun String.shortened(length: Int): String = if (this.length <= length) this else take(length - 1).trimEnd() + "…"

/** The Bluetooth permission is asked for once per start of the app. */
private var askedForBluetooth = false

private const val NOTICE_MS = 4_000L

/** The time and a computer's name fit in this arc on the smallest round screen. */
private const val TIME_TEXT_SWEEP = 130f
private const val COMPUTER_NAME_LENGTH = 14
