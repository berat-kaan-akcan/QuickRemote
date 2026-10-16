package com.quickremote.wear

import com.quickremote.wear.phone.PhoneReport
import com.quickremote.wear.phone.Pointer
import com.quickremote.wear.phone.PhoneState
import com.quickremote.wear.phone.Show
import com.quickremote.wear.phone.TalkClock
import com.quickremote.wear.phone.TimerAlert
import com.quickremote.wear.phone.WearProtocol
import org.junit.Assert.assertEquals
import org.junit.Test

class PhoneStateTest {

    private val show = Show(running = true, current = 5, total = 20)
    @Test
    fun `the pointer is the laser unless the phone names another`() {
        assertEquals(Pointer.ARROW, Pointer.of(WearProtocol.POINTER_ARROW))
        assertEquals(Pointer.CURSOR, Pointer.of(WearProtocol.POINTER_CURSOR))
        assertEquals(Pointer.LASER, Pointer.of(WearProtocol.POINTER_LASER))
        assertEquals(Pointer.LASER, Pointer.of(null))
        assertEquals(Pointer.LASER, Pointer.of("something-new"))
    }

    private fun report(link: String) = PhoneReport(link, "Ofis-PC", show)

    @Test
    fun `nothing is known right after opening`() {
        assertEquals(PhoneState.Checking, PhoneState.of(reachable = null, report = null, silent = false))
        // The last report waits for the phone to be found.
        assertEquals(
            PhoneState.Checking,
            PhoneState.of(reachable = null, report = report(WearProtocol.LINK_CONNECTED), silent = false),
        )
        assertEquals(PhoneState.Checking, PhoneState.of(reachable = true, report = null, silent = false))
    }

    @Test
    fun `no phone in reach, whatever it last reported`() {
        assertEquals(
            PhoneState.NoPhone,
            PhoneState.of(reachable = false, report = report(WearProtocol.LINK_CONNECTED), silent = false),
        )
    }

    @Test
    fun `a phone that does not answer counts as gone`() {
        assertEquals(
            PhoneState.NoPhone,
            PhoneState.of(reachable = true, report = report(WearProtocol.LINK_CONNECTED), silent = true),
        )
    }

    @Test
    fun `the phone's report decides the rest`() {
        fun of(link: String) = PhoneState.of(reachable = true, report = report(link), silent = false)
        assertEquals(PhoneState.Connected("Ofis-PC", show), of(WearProtocol.LINK_CONNECTED))
        assertEquals(PhoneState.NotConnected(connecting = true), of(WearProtocol.LINK_CONNECTING))
        assertEquals(PhoneState.NotConnected(connecting = false), of(WearProtocol.LINK_DISCONNECTED))
        assertEquals(PhoneState.AppClosed, of(WearProtocol.LINK_CLOSED))
        // The phone as the computer's Bluetooth keyboard: a remote without a slide.
        assertEquals(
            PhoneState.Connected("Ofis-PC", null),
            PhoneState.of(
                reachable = true,
                report = PhoneReport(WearProtocol.LINK_CONNECTED, "Ofis-PC", show = null),
                silent = false,
            ),
        )
        // A link a newer phone app might add: there is an app, and no remote.
        assertEquals(PhoneState.NotConnected(connecting = false), of("something-new"))
    }

    @Test
    fun `a timer alert is read from the phone's words`() {
        assertEquals(TimerAlert(false, 300, "double"), TimerAlert.parse("warning:300:double"))
        assertEquals(TimerAlert(true, 0, ""), TimerAlert.parse("timeUp:0:"))
        assertEquals(null, TimerAlert.parse("something:1:double"))
        assertEquals(null, TimerAlert.parse("warning:x:double"))
    }

    @Test
    fun `the talk's clock runs from its start and stands while paused`() {
        val running = TalkClock(target = 600, running = true, startedAt = 1_000_000L, elapsed = 0)
        assertEquals(125, running.elapsedAt(1_125_400L))
        assertEquals(0, running.elapsedAt(999_000L))
        val paused = TalkClock(target = 600, running = false, startedAt = 0L, elapsed = 42)
        assertEquals(42, paused.elapsedAt(5_000_000L))
        assertEquals(false, TalkClock(0, false, 0L, 0).shown)
    }
}
