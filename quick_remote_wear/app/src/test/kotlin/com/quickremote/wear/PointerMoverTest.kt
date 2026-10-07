package com.quickremote.wear

import com.quickremote.wear.hid.HidReports
import com.quickremote.wear.remote.PointerMover
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class PointerMoverTest {

    @Test
    fun `a mouse report is buttons, x, y`() {
        assertArrayEquals(byteArrayOf(0, 5, -127), HidReports.mouseMove(5, -127))
    }

    @Test
    fun `movement is scaled by the gain`() {
        val mover = PointerMover(gain = 6f)
        mover.add(2f, -1f)
        assertEquals(listOf(12 to -6), mover.take())
        assertEquals(emptyList<Pair<Int, Int>>(), mover.take())
    }

    @Test
    fun `a large move goes out in steps a report can carry`() {
        val mover = PointerMover(gain = 1f)
        mover.add(300f, -10f)
        val steps = mover.take()
        assertEquals(listOf(127 to -10, 127 to 0, 46 to 0), steps)
    }

    @Test
    fun `slow movement adds up instead of being lost`() {
        val mover = PointerMover(gain = 1f)
        var total = 0
        repeat(10) {
            mover.add(0.3f, 0f)
            total += mover.take().sumOf { it.first }
        }
        assertEquals(3, total)
    }
}
