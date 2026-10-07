package com.quickremote.wear.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.quickremote.wear.hid.HidConnection
import com.quickremote.wear.hid.HidSessionService
import com.quickremote.wear.hid.HidState
import com.quickremote.wear.remote.PresenterStore

private const val ROUTE_HOME = "home"
private const val ROUTE_COMPUTERS = "computers"
private const val ROUTE_PAIR = "pair"
private const val ROUTE_LASER = "laser"

@Composable
fun WearApp(hid: HidConnection, presenters: PresenterStore) {
    val context = LocalContext.current
    var granted by remember { mutableStateOf(Permissions.granted(context, Permissions.keyboard)) }

    // Every return to the app checks the permissions again (they may have
    // been changed in the settings) and retries a dropped connection at once.
    LifecycleResumeEffect(Unit) {
        granted = Permissions.granted(context, Permissions.keyboard)
        if (granted) HidSessionService.start(context)
        onPauseOrDispose {}
    }

    AppScaffold {
        if (!granted) {
            PermissionScreen(onGranted = {
                granted = true
                HidSessionService.start(context)
            })
            return@AppScaffold
        }
        val state by hid.state.collectAsStateWithLifecycle()
        val hosts by hid.hosts.collectAsStateWithLifecycle()
        val presenter by presenters.presenter.collectAsStateWithLifecycle()
        // Outlives the connected screen: a dropped and restored connection
        // comes back to the page the presenter was on.
        var page by rememberSaveable { mutableIntStateOf(PAGE_ACTIONS) }
        val nav = rememberSwipeDismissableNavController()
        SwipeDismissableNavHost(navController = nav, startDestination = ROUTE_HOME) {
            composable(ROUTE_HOME) {
                when (val current = state) {
                    is HidState.Connected -> ConnectedScreen(
                        onAction = { hid.send(it.modifiers, it.key) },
                        onLaser = { nav.navigate(ROUTE_LASER) },
                        onComputers = { nav.navigate(ROUTE_COMPUTERS) },
                        page = page,
                        onPageChange = { page = it },
                    )
                    else -> StatusScreen(
                        state = current,
                        hosts = hosts,
                        onConnect = { hid.connect(it.address) },
                        onAddComputer = { nav.navigate(ROUTE_PAIR) },
                        onRetry = { HidSessionService.start(context) },
                        presenter = presenter,
                        onPresenter = presenters::set,
                    )
                }
            }
            composable(ROUTE_LASER) {
                // Without a computer there is nothing to point at.
                if (state !is HidState.Connected) {
                    LaunchedEffect(Unit) { nav.popBackStack(ROUTE_HOME, inclusive = false) }
                }
                LaserScreen(
                    presenter = presenter,
                    onShortcut = { hid.send(it.modifiers, it.key) },
                    onPointer = { dx, dy -> hid.move(dx, dy) },
                    onAction = { hid.send(it.modifiers, it.key) },
                    onClose = { nav.popBackStack() },
                )
            }
            composable(ROUTE_COMPUTERS) {
                StatusScreen(
                    state = state,
                    hosts = hosts,
                    onConnect = {
                        hid.connect(it.address)
                        nav.popBackStack(ROUTE_HOME, inclusive = false)
                    },
                    onAddComputer = { nav.navigate(ROUTE_PAIR) },
                    onRetry = { HidSessionService.start(context) },
                    presenter = presenter,
                    onPresenter = presenters::set,
                )
            }
            composable(ROUTE_PAIR) {
                PairScreen(
                    hid = hid,
                    state = state,
                    onConnected = { nav.popBackStack(ROUTE_HOME, inclusive = false) },
                )
            }
        }
    }
}
