package com.quickremote.wear.remote

import com.quickremote.wear.hid.HidReports
import kotlin.math.roundToInt

/**
 * Turns finger movement on the watch into mouse reports, as the phone's
 * Bluetooth touchpad (bt_touchpad_view.dart) does: the movement is scaled by
 * [gain], whole counts go out in steps of at most ±127 (one report's limit)
 * and the fraction waits for the next movement, so slow strokes still move.
 */
class PointerMover(private val gain: Float) {
    private var restX = 0f
    private var restY = 0f

    /** Adds a finger movement, in dp. */
    fun add(dx: Float, dy: Float) {
        restX += dx * gain
        restY += dy * gain
    }

    /** The reports to send for the movement added so far. */
    fun take(): List<Pair<Int, Int>> {
        var x = restX.roundToInt()
        var y = restY.roundToInt()
        restX -= x
        restY -= y
        val steps = mutableListOf<Pair<Int, Int>>()
        while (x != 0 || y != 0) {
            val dx = x.coerceIn(-HidReports.MOUSE_STEP, HidReports.MOUSE_STEP)
            val dy = y.coerceIn(-HidReports.MOUSE_STEP, HidReports.MOUSE_STEP)
            steps += dx to dy
            x -= dx
            y -= dy
        }
        return steps
    }
}
