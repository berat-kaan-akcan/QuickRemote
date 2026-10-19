package com.quickremote.wear.ui

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.wear.compose.foundation.pager.PagerDefaults
import androidx.wear.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.wear.compose.foundation.pager.HorizontalPager
import androidx.wear.compose.material3.HorizontalPageIndicator
import androidx.wear.compose.material3.HorizontalPagerScaffold
import com.quickremote.wear.R
import com.quickremote.wear.phone.Pointer
import com.quickremote.wear.phone.Show
import com.quickremote.wear.phone.TalkClock
import com.quickremote.wear.remote.RemoteAction
import kotlinx.coroutines.delay

/** The pages of a connected watch, in their order. */
enum class Page { START, TOOLS, REMOTE }

/**
 * A connected watch: pages swiped between. While a show runs, the tools and
 * the slide buttons; while none runs, Start comes first, and starting turns
 * to the slide buttons. A show that ends returns to Start. The bezel (or
 * crown) changes slides on every page. [page] is kept by the caller, so that
 * a dropped and restored connection comes back to the same page (null: the
 * first connection). [onAction] answers whether the command went out;
 * [onLaser] opens the laser screen.
 *
 * The black and white screens are toggles the computer does not report, so
 * the watch remembers what it sent and shows it ([BlankScreen]) until it is
 * sent again, or the slide or the show changes.
 *
 * Over Wi-Fi with no slideshow running (nothing open, or a PDF), the
 * computer ignores the laser and the black and white screens: they are
 * faded, and a tap says when they work. Over Bluetooth the watch is told
 * nothing about the show, so they stay as they are. [pointer] names the laser.
 */
@Composable
fun ConnectedScreen(
    show: Show?,
    clock: TalkClock?,
    duration: Int?,
    onEditDuration: () -> Unit,
    onAction: (RemoteAction) -> Boolean,
    onLaser: () -> Unit,
    laser: HeldLaser,
    pointer: Pointer,
    page: Page?,
    onPageChange: (Page) -> Unit,
) {
    val haptics = rememberHaptics()
    // Over Bluetooth the computer tells nothing: the talk's clock, which runs
    // from the watch's Start to its End, stands in for the show.
    val running = show?.running ?: (clock?.running == true)
    var blank by rememberSaveable { mutableStateOf<RemoteAction?>(null) }
    val showTools = show == null || running
    var tip by remember { mutableStateOf<Notice?>(null) }
    val needsShow = stringResource(R.string.needs_show)
    val unavailable = { tip = Notice(needsShow) }
    LaunchedEffect(tip) {
        if (tip != null) {
            delay(TIP_MS)
            tip = null
        }
    }

    fun press(action: RemoteAction, fromBezel: Boolean = false) {
        val sent = onAction(action)
        when {
            !sent -> haptics.failed()
            fromBezel -> haptics.step()
            else -> haptics.sent()
        }
        if (!sent) return
        when (action) {
            RemoteAction.BLACK_SCREEN, RemoteAction.WHITE_SCREEN ->
                blank = if (blank == action || !showTools) null else action
            else -> blank = null
        }
    }

    LaunchedEffect(show?.current, running) { blank = null }

    // After Start, a show that does not come is said: the page stays on Start.
    var startedAt by remember { mutableStateOf<Long?>(null) }
    val notStarted = stringResource(R.string.show_not_started)
    LaunchedEffect(startedAt, running) {
        if (running) startedAt = null
        if (startedAt == null) return@LaunchedEffect
        delay(START_WAIT_MS)
        if (!running) tip = Notice(notStarted)
        startedAt = null
    }

    // Start is a page only while no show runs; the pages are made anew when
    // that changes. A show that starts keeps the page (Start becomes the
    // slide buttons), one that ends goes back to Start.
    val pages = if (running) listOf(Page.TOOLS, Page.REMOTE) else listOf(Page.START, Page.TOOLS, Page.REMOTE)
    var wasRunning by remember { mutableStateOf(running) }
    val target = when {
        // The first connection opens on Start unless a show is known to run:
        // over Bluetooth nothing is known, and a talk begins with Start.
        running == wasRunning -> page ?: if (running) Page.REMOTE else Page.START
        running -> Page.REMOTE.takeIf { page == null || page == Page.START } ?: page!!
        else -> Page.START
    }
    wasRunning = running

    Box(
        modifier = Modifier
            .fillMaxSize()
            .slideBezel { press(it, fromBezel = true) },
    ) {
        key(running) {
            val pagerState = rememberPagerState(
                initialPage = pages.indexOf(target).takeIf { it >= 0 } ?: pages.indexOf(Page.REMOTE),
            ) { pages.size }
            LaunchedEffect(pagerState) {
                snapshotFlow { pagerState.currentPage }.collect { onPageChange(pages[it]) }
            }
            HorizontalPagerScaffold(
                pagerState = pagerState,
                pageIndicator = { HorizontalPageIndicator(pagerState) },
            ) {
                // No rotary behavior: the bezel changes slides, not pages. The
                // pages slide plainly (no AnimatedPage zoom) and settle fast,
                // after a short swipe: the default felt slow on the watch.
                HorizontalPager(
                    state = pagerState,
                    flingBehavior = PagerDefaults.snapFlingBehavior(
                        state = pagerState,
                        snapAnimationSpec = PAGE_SNAP,
                        snapPositionalThreshold = 0.3f,
                    ),
                    rotaryScrollableBehavior = null,
                ) { index ->
                    when (pages[index]) {
                        // Start stays on this page: the slide buttons come
                        // when the show is known to run (the pages are made
                        // anew then, see target). Moving at once left the
                        // user on Next with no show when START did nothing.
                        Page.START -> StartPage(
                            show = show,
                            onPress = { action ->
                                press(action)
                                if (action == RemoteAction.START) startedAt = System.currentTimeMillis()
                            },
                            duration = duration,
                            onEditDuration = onEditDuration,
                        )
                        Page.TOOLS -> ToolsPage(
                            show = show,
                            onPress = { press(it) },
                            onLaser = onLaser,
                            pointer = pointer,
                            showTools = showTools,
                            onUnavailable = unavailable,
                        )
                        Page.REMOTE -> RemotePage(
                            show = show,
                            clock = clock,
                            onPress = { press(it) },
                            onLaser = onLaser,
                            laser = laser,
                            pointer = pointer,
                            canPoint = showTools,
                            onUnavailable = unavailable,
                        )
                    }
                }
            }
        }
        blank?.let { action ->
            BlankScreen(white = action == RemoteAction.WHITE_SCREEN, onRestore = { press(action) })
        }
        tip?.let { NoticeBanner(it.text) }
    }
}

/** How long "only while a slideshow runs" stays. */
private const val TIP_MS = 2_500L

/** How long Start waits for the show before saying it did not start (PowerPoint can take seconds). */
private const val START_WAIT_MS = 8_000L

private val PAGE_SNAP = spring<Float>(stiffness = Spring.StiffnessMedium)
