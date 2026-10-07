package com.quickremote.wear.ui

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.wear.compose.foundation.pager.HorizontalPager
import androidx.wear.compose.foundation.pager.PagerDefaults
import androidx.wear.compose.foundation.pager.rememberPagerState
import androidx.wear.compose.material3.HorizontalPageIndicator
import androidx.wear.compose.material3.HorizontalPagerScaffold
import com.quickremote.wear.remote.RemoteAction
import kotlinx.coroutines.launch

const val PAGE_ACTIONS = 0
const val PAGE_REMOTE = 1
private const val PAGE_COUNT = 2

/**
 * A connected watch: two pages, swiped between. The actions first, then the
 * slide buttons; starting the show turns to the slide buttons. The bezel (or
 * crown) changes slides on both pages. [page] is kept by the caller, so that
 * a dropped and restored connection comes back to the same page.
 * [onAction] answers whether the key went out; [onLaser] opens the laser.
 */
@Composable
fun ConnectedScreen(
    onAction: (RemoteAction) -> Boolean,
    onLaser: () -> Unit,
    onComputers: () -> Unit,
    page: Int,
    onPageChange: (Int) -> Unit,
) {
    val haptics = rememberHaptics()
    val pagerState = rememberPagerState(initialPage = page) { PAGE_COUNT }
    val scope = rememberCoroutineScope()

    fun press(action: RemoteAction, fromBezel: Boolean = false) {
        when {
            !onAction(action) -> haptics.failed()
            fromBezel -> haptics.step()
            else -> haptics.sent()
        }
    }
    val bezel = rememberSlideBezel { press(it, fromBezel = true) }

    LaunchedEffect(pagerState) {
        snapshotFlow { pagerState.currentPage }.collect { onPageChange(it) }
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .then(bezel),
    ) {
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
                if (index == PAGE_ACTIONS) {
                    ActionsPage(
                        onPress = { action ->
                            press(action)
                            if (action == RemoteAction.START) {
                                scope.launch { pagerState.animateScrollToPage(PAGE_REMOTE, animationSpec = PAGE_SNAP) }
                            }
                        },
                        onComputers = onComputers,
                    )
                } else {
                    RemotePage(onPress = { press(it) }, onLaser = onLaser)
                }
            }
        }
    }
}

private val PAGE_SNAP = spring<Float>(stiffness = Spring.StiffnessMedium)
