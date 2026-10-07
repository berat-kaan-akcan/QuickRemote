package com.quickremote.wear.remote

import kotlin.math.abs
import kotlin.math.sign

/**
 * Turns bezel or crown rotation into slide steps: +1 next, -1 previous, 0 none.
 *
 * A Galaxy Watch bezel, physical on the Classic models and touch on the
 * others, is a low resolution encoder (the `android.hardware.rotaryencoder.lowres`
 * feature, which Wear Compose checks too): every detent is one event, so one
 * event is one step. A crown (Pixel Watch) sends many small deltas, summed
 * until they reach [stepPx]; a pause or a change of direction starts the sum anew.
 */
class BezelStepper(
    private val lowRes: Boolean,
    private val stepPx: Float,
    private val idleResetMs: Long = 400,
) {
    private var sum = 0f
    private var lastAtMs = -1L

    fun onRotate(deltaPx: Float, atMs: Long): Int {
        if (deltaPx == 0f) return 0
        if (lowRes) return deltaPx.sign.toInt()
        val idle = lastAtMs < 0 || atMs - lastAtMs > idleResetMs
        if (idle || sum.sign != deltaPx.sign) sum = 0f
        lastAtMs = atMs
        sum += deltaPx
        if (abs(sum) < stepPx) return 0
        // At most one step per event, and the excess is dropped: one large
        // delta (a fast flick of the crown) moves one slide, not several.
        val step = sum.sign.toInt()
        sum = 0f
        return step
    }
}
