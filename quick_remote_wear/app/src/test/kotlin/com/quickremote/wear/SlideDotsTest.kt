package com.quickremote.wear

import com.quickremote.wear.ui.DotKind
import com.quickremote.wear.ui.MAX_DOTS
import com.quickremote.wear.ui.TIME_GAP
import com.quickremote.wear.ui.slideDots
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class SlideDotsTest {
    @Test
    fun oneDotPerSlideAcrossTheUpperEdge() {
        val dots = slideDots(current = 7, total = 24)
        assertEquals(24, dots.size)
        assertEquals(188f, dots.first().degrees, 0.001f)
        assertEquals(352f, dots.last().degrees, 0.001f)
        assertTrue(dots.zipWithNext().all { (a, b) -> b.degrees > a.degrees })
    }

    @Test
    fun passedSlidesTheCurrentOneAndThoseAhead() {
        val kinds = slideDots(current = 3, total = 5).map { it.kind }
        assertEquals(
            listOf(DotKind.PASSED, DotKind.PASSED, DotKind.CURRENT, DotKind.AHEAD, DotKind.AHEAD),
            kinds,
        )
    }

    @Test
    fun noDotUnderTheTime() {
        for (total in 1..MAX_DOTS) {
            val dots = slideDots(current = 1, total = total)
            assertTrue(dots.none { abs(it.degrees - 270f) < TIME_GAP })
        }
        // An odd count put the middle slide's dot right under it.
        val middle = slideDots(current = 4, total = 7)[3]
        assertTrue(abs(middle.degrees - 270f) >= TIME_GAP)
    }

    @Test
    fun aSingleSlideSitsAtTheStart() {
        val dots = slideDots(current = 1, total = 1)
        assertEquals(1, dots.size)
        assertEquals(188f, dots.single().degrees, 0.001f)
    }

    @Test
    fun tooManySlidesMakeNoDots() {
        assertEquals(MAX_DOTS, slideDots(1, MAX_DOTS).size)
        assertTrue(slideDots(1, MAX_DOTS + 1).isEmpty())
        assertTrue(slideDots(0, 0).isEmpty())
    }
}
