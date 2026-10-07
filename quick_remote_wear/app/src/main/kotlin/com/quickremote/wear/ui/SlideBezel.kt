package com.quickremote.wear.ui

import android.util.Log
import androidx.compose.foundation.focusable
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.quickremote.wear.remote.BezelStepper
import com.quickremote.wear.remote.RemoteAction

/**
 * The bezel (or crown) as the slide keys: a modifier for a screen's root that
 * turns each step into [onSlide] with NEXT or PREV.
 */
@Composable
fun rememberSlideBezel(onSlide: (RemoteAction) -> Unit): Modifier {
    val context = LocalContext.current
    val slide by rememberUpdatedState(onSlide)
    val stepPx = with(LocalDensity.current) { CROWN_STEP.toPx() }
    val stepper = remember(stepPx) {
        BezelStepper(
            lowRes = context.packageManager.hasSystemFeature(LOW_RES_ROTARY),
            stepPx = stepPx,
        )
    }
    val focus = remember { FocusRequester() }

    // The bezel needs the focus, also after the screen was off. A coroutine
    // runs after the first frame, when the focus target is attached.
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(lifecycle) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) { focus.requestFocus() }
    }

    return Modifier
        .onRotaryScrollEvent { event ->
            val step = stepper.onRotate(event.verticalScrollPixels, event.uptimeMillis)
            Log.d(TAG, "rotary ${event.verticalScrollPixels} -> $step")
            if (step > 0) slide(RemoteAction.NEXT)
            if (step < 0) slide(RemoteAction.PREV)
            true
        }
        .focusRequester(focus)
        .focusable()
}

private const val TAG = "QuickRemoteBezel"

/** The bezel feature Wear Compose checks too (RotaryScrollableDefaults). */
private const val LOW_RES_ROTARY = "android.hardware.rotaryencoder.lowres"

/** Crown rotation per slide on watches without a bezel. */
private val CROWN_STEP = 48.dp
