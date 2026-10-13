package com.quickremote.wear

import com.quickremote.wear.phone.MoveSender
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MoveSenderTest {

    @Test
    fun `the first movement goes at once`() {
        val sender = MoveSender(minIntervalMs = 33)
        assertNull(sender.take(0))
        sender.add(3f, -2f)
        assertEquals(3f to -2f, sender.take(0))
    }

    @Test
    fun `movement is summed while a message is on its way`() {
        val sender = MoveSender(minIntervalMs = 33)
        sender.add(1f, 1f)
        sender.take(0)
        sender.add(2f, 0f)
        sender.add(4f, -1f)
        // A slow link: long past the interval, still nothing new goes out.
        assertNull(sender.take(200))
        assertNull(sender.waitMs(200))
        sender.delivered()
        assertEquals(6f to -1f, sender.take(200))
    }

    @Test
    fun `a fast link is held to the interval`() {
        val sender = MoveSender(minIntervalMs = 33)
        sender.add(1f, 0f)
        sender.take(100)
        sender.delivered()
        sender.add(5f, 5f)
        assertNull(sender.take(110))
        assertEquals(23L, sender.waitMs(110))
        sender.add(1f, 0f)
        assertEquals(6f to 5f, sender.take(133))
    }

    @Test
    fun `nothing waits when nothing moved`() {
        val sender = MoveSender(minIntervalMs = 33)
        sender.add(1f, 0f)
        sender.take(0)
        sender.delivered()
        assertNull(sender.waitMs(5))
        assertNull(sender.take(50))
    }

    @Test
    fun `the rest goes when the finger lifts, whatever is on its way`() {
        val sender = MoveSender(minIntervalMs = 33)
        sender.add(1f, 0f)
        sender.take(0)
        sender.add(7f, 2f)
        assertEquals(7f to 2f, sender.rest())
        assertNull(sender.rest())
    }

    @Test
    fun `a new gesture starts clean`() {
        val sender = MoveSender(minIntervalMs = 33)
        sender.add(9f, 9f)
        sender.take(1000)
        sender.add(1f, 1f)
        sender.reset()
        assertNull(sender.take(1001))
        sender.add(2f, 0f)
        assertEquals(2f to 0f, sender.take(1001))
    }

    @Test
    fun `several movements may be on their way`() {
        val sender = MoveSender(minIntervalMs = 25, window = 2, lostMs = 500)
        sender.add(1f, 0f)
        assertEquals(1f to 0f, sender.take(0))
        sender.add(2f, 0f)
        assertEquals(25L, sender.waitMs(0))
        assertEquals(2f to 0f, sender.take(25))
        // The window is full: only an answer or a lost one lets the next go.
        sender.add(3f, 0f)
        assertNull(sender.take(60))
        sender.delivered()
        assertEquals(3f to 0f, sender.take(60))
    }

    @Test
    fun `an unanswered movement is given up as lost`() {
        val sender = MoveSender(minIntervalMs = 25, window = 1, lostMs = 500)
        sender.add(1f, 0f)
        sender.take(0)
        sender.add(2f, 0f)
        assertEquals(400L, sender.waitMs(100))
        assertNull(sender.take(499))
        assertEquals(2f to 0f, sender.take(500))
    }
}
