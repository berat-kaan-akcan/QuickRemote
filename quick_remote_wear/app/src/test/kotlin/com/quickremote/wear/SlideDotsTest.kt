package com.quickremote.wear

import com.quickremote.wear.ui.DotKind
import com.quickremote.wear.ui.MAX_DOTS
import com.quickremote.wear.ui.slideDots
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

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
    fun aSingleSlideSitsAtTheTop() {
        val dots = slideDots(current = 1, total = 1)
        assertEquals(1, dots.size)
        assertEquals(270f, dots.single().degrees, 0.001f)
    }

    @Test
    fun tooManySlidesMakeNoDots() {
        assertEquals(MAX_DOTS, slideDots(1, MAX_DOTS).size)
        assertTrue(slideDots(1, MAX_DOTS + 1).isEmpty())
        assertTrue(slideDots(0, 0).isEmpty())
    }
}
