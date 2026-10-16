package com.quickremote.wear.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalResources
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.TimeText
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.quickremote.wear.PresentingService
import com.quickremote.wear.R
import com.quickremote.wear.phone.LinkEvent
import com.quickremote.wear.phone.PhoneLink
import com.quickremote.wear.phone.PhoneState
import com.quickremote.wear.phone.TalkClock
import com.quickremote.wear.phone.Pointer
import kotlinx.coroutines.delay

private const val ROUTE_HOME = "home"
private const val ROUTE_LASER = "laser"
private const val ROUTE_DURATION = "duration"

@Composable
fun WearApp(phone: PhoneLink, ambient: Boolean) {
    val state by phone.state.collectAsStateWithLifecycle()
    val connected = state as? PhoneState.Connected
    val haptics = rememberHaptics()

    // Asked for as soon as the app opens (once per start), so that they are
    // there when needed. The laser's own Bluetooth socket to the phone needs
    // the "nearby devices" permission (Android 11 grants it with the app);
    // refused, the laser works as before. The Ongoing Activity of a running
    // show (PresentingService) is a notification (asked from Android 13).
    val context = LocalContext.current
    var bluetoothAllowed by remember { mutableStateOf(phone.directPermitted) }
    val permissions = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            it[Manifest.permission.BLUETOOTH_CONNECT]?.let { granted -> bluetoothAllowed = granted }
        }
    }
    LaunchedEffect(Unit) {
        if (askedForPermissions) return@LaunchedEffect
        askedForPermissions = true
        val wanted = buildList {
            if (!bluetoothAllowed && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        if (wanted.isNotEmpty()) permissions.launch(wanted.toTypedArray())
    }

    // While the phone is connected to a computer the remote is an Ongoing
    // Activity, which the watch shows again when the screen wakes; the
    // service ends itself after the connection.
    val active = PresentingService.active(state)
    LaunchedEffect(active) {
        if (active) PresentingService.start(context)
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

    // The talk's clock, which the phone keeps. A phone from before that
    // tells none: then how long the show has run, from when the watch saw
    // it start. Kept through a dropped connection.
    var startedAt by rememberSaveable { mutableStateOf<Long?>(null) }
    val running = connected?.let { it.show?.running == true }
    LaunchedEffect(running) {
        when (running) {
            true -> if (startedAt == null) startedAt = System.currentTimeMillis()
            false -> startedAt = null
            null -> Unit
        }
    }
    // The length just picked here, shown until the phone's answer.
    var picked by remember { mutableStateOf<Int?>(null) }
    LaunchedEffect(connected?.duration) { picked = null }

    var lastClock by remember { mutableStateOf<TalkClock?>(null) }
    LaunchedEffect(connected?.clock) { connected?.clock?.let { lastClock = it } }
    val clock = lastClock ?: startedAt?.let { TalkClock(target = 0, running = true, startedAt = it, elapsed = 0) }

    // What the computer answered to a command, or the talk's clock's
    // warning (AlertService vibrates it), shown for a moment.
    var notice by remember { mutableStateOf<Notice?>(null) }
    val res = LocalResources.current
    LaunchedEffect(phone) {
        phone.events.collect { event ->
            when (event) {
                is LinkEvent.PcError -> {
                    haptics.failed()
                    notice = Notice(event.text)
                }
                LinkEvent.NotSent -> haptics.failed()
                is LinkEvent.Timer -> notice = Notice(
                    if (event.alert.timeUp) {
                        res.getString(R.string.time_up)
                    } else {
                        res.getString(R.string.time_left, elapsedText(event.alert.secondsLeft * 1_000L))
                    },
                )
            }
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
                        clock = clock,
                        duration = picked ?: current.duration,
                        onEditDuration = { nav.navigate(ROUTE_DURATION) },
                        onAction = { phone.send(it.command) },
                        onLaser = { nav.navigate(ROUTE_LASER) },
                        laser = heldLaser,
                        pointer = current.pointer,
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
            composable(ROUTE_DURATION) {
                DurationScreen(seconds = picked ?: connected?.duration ?: 0) { seconds ->
                    if (phone.setDuration(seconds)) {
                        picked = seconds
                        haptics.sent()
                    } else {
                        haptics.failed()
                    }
                    nav.popBackStack()
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
                    pointer = connected?.pointer ?: Pointer.LASER,
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
        if (ambient) AmbientScreen(state, clock.takeIf { connected != null })
    }
}

/** A new object for every message, so that the same text again starts its time anew. */
class Notice(val text: String)

/** The permissions are asked for once per start of the app. */
private var askedForPermissions = false

private const val NOTICE_MS = 4_000L


