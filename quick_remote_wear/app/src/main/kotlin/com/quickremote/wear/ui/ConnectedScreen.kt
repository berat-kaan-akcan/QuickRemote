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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.wear.compose.foundation.pager.HorizontalPager
import androidx.wear.compose.material3.HorizontalPageIndicator
import androidx.wear.compose.material3.HorizontalPagerScaffold
import com.quickremote.wear.phone.Show
import com.quickremote.wear.remote.RemoteAction
import kotlinx.coroutines.launch

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
 */
@Composable
fun ConnectedScreen(
    show: Show?,
    startedAt: Long?,
    onAction: (RemoteAction) -> Boolean,
    onLaser: () -> Unit,
    laser: HeldLaser,
    page: Page?,
    onPageChange: (Page) -> Unit,
) {
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()
    val running = show?.running == true
    var blank by rememberSaveable { mutableStateOf<RemoteAction?>(null) }

    fun press(action: RemoteAction, fromBezel: Boolean = false) {
        val sent = onAction(action)
        when {
            !sent -> haptics.failed()
            fromBezel -> haptics.step()
            else -> haptics.sent()
        }
        if (!sent) return
        when (action) {
            RemoteAction.BLACK_SCREEN, RemoteAction.WHITE_SCREEN -> blank = if (blank == action) null else action
            else -> blank = null
        }
    }
    val bezel = rememberSlideBezel { press(it, fromBezel = true) }

    LaunchedEffect(show?.current, running) { blank = null }

    // Start is a page only while no show runs; the pages are made anew when
    // that changes. A show that starts keeps the page (Start becomes the
    // slide buttons), one that ends goes back to Start.
    val pages = if (running) listOf(Page.TOOLS, Page.REMOTE) else listOf(Page.START, Page.TOOLS, Page.REMOTE)
    var wasRunning by remember { mutableStateOf(running) }
    val target = when {
        running == wasRunning -> page ?: if (show == null || running) Page.REMOTE else Page.START
        running -> Page.REMOTE.takeIf { page == null || page == Page.START } ?: page!!
        else -> Page.START
    }
    wasRunning = running

    Box(
        modifier = Modifier
            .fillMaxSize()
            .then(bezel),
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
                        Page.START -> StartPage(
                            show = show,
                            onPress = { action ->
                                press(action)
                                onPageChange(Page.REMOTE)
                                scope.launch {
                                    pagerState.animateScrollToPage(pages.indexOf(Page.REMOTE), animationSpec = PAGE_SNAP)
                                }
                            },
                        )
                        Page.TOOLS -> ToolsPage(show = show, onPress = { press(it) }, onLaser = onLaser)
                        Page.REMOTE -> RemotePage(
                            show = show,
                            startedAt = startedAt,
                            onPress = { press(it) },
                            onLaser = onLaser,
                            laser = laser,
                        )
                    }
                }
            }
        }
        blank?.let { action ->
            BlankScreen(white = action == RemoteAction.WHITE_SCREEN, onRestore = { press(action) })
        }
    }
}

private val PAGE_SNAP = spring<Float>(stiffness = Spring.StiffnessMedium)
