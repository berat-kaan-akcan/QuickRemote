package com.quickremote.wear

import com.quickremote.wear.remote.BezelStepper
import org.junit.Assert.assertEquals
import org.junit.Test

class BezelStepperTest {

    @Test
    fun `a bezel detent is one step whatever its size`() {
        val bezel = BezelStepper(lowRes = true, stepPx = 100f)
        assertEquals(1, bezel.onRotate(3f, 0))
        assertEquals(1, bezel.onRotate(250f, 10))
        assertEquals(-1, bezel.onRotate(-0.5f, 20))
        assertEquals(0, bezel.onRotate(0f, 30))
    }

    @Test
    fun `clockwise is next, counter-clockwise previous`() {
        val bezel = BezelStepper(lowRes = true, stepPx = 100f)
        assertEquals(listOf(1, 1, -1), listOf(40f, 40f, -40f).mapIndexed { i, d -> bezel.onRotate(d, i * 50L) })
    }

    @Test
    fun `crown deltas add up to a step`() {
        val crown = BezelStepper(lowRes = false, stepPx = 100f)
        assertEquals(0, crown.onRotate(40f, 0))
        assertEquals(0, crown.onRotate(40f, 16))
        assertEquals(1, crown.onRotate(40f, 32))
        // The sum starts again after a step.
        assertEquals(0, crown.onRotate(40f, 48))
        assertEquals(0, crown.onRotate(40f, 64))
        assertEquals(1, crown.onRotate(40f, 80))
    }

    @Test
    fun `one large crown delta is one step, not several`() {
        val crown = BezelStepper(lowRes = false, stepPx = 100f)
        assertEquals(1, crown.onRotate(450f, 0))
        assertEquals(0, crown.onRotate(10f, 16))
    }

    @Test
    fun `a change of direction drops what was summed`() {
        val crown = BezelStepper(lowRes = false, stepPx = 100f)
        assertEquals(0, crown.onRotate(90f, 0))
        assertEquals(0, crown.onRotate(-90f, 16))
        assertEquals(-1, crown.onRotate(-20f, 32))
    }

    @Test
    fun `a pause drops what was summed`() {
        val crown = BezelStepper(lowRes = false, stepPx = 100f, idleResetMs = 400)
        assertEquals(0, crown.onRotate(90f, 0))
        assertEquals(0, crown.onRotate(20f, 1_000))
        assertEquals(1, crown.onRotate(90f, 1_100))
    }
}
