package com.quickremote.wear.ui

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView

/**
 * A keyboard gets no answer from the computer, so the wrist is where the
 * presenter learns that a key went out, without looking.
 */
class Haptics(context: Context, private val view: View) {
    private val vibrator = context.getSystemService(Vibrator::class.java)

    /**
     * A bezel or crown step, with the detent haptic Wear Compose uses for
     * rotary input (HapticConstants in wear.compose.foundation.rotary). The
     * Galaxy Watch has its own constant.
     */
    fun step() {
        view.performHapticFeedback(if (isGalaxyWatch) GALAXY_ROTARY_FOCUS else ROTARY_ITEM_FOCUS)
    }

    /** A key was sent. */
    fun sent() {
        vibrator?.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
    }

    /** Nothing was sent: no computer is connected. */
    fun failed() {
        vibrator?.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_DOUBLE_CLICK))
    }

    private companion object {
        /** HapticFeedbackConstants.ROTARY_SCROLL_ITEM_FOCUS (public from API 34, honoured by Wear OS 4). */
        const val ROTARY_ITEM_FOCUS = 19
        const val GALAXY_ROTARY_FOCUS = 102
        val isGalaxyWatch = Build.MANUFACTURER.contains("Samsung", ignoreCase = true)
    }
}

@Composable
fun rememberHaptics(): Haptics {
    val context = LocalContext.current
    val view = LocalView.current
    return remember(context, view) { Haptics(context, view) }
}
