package com.quickremote.wear

import com.quickremote.wear.phone.PhoneReport
import com.quickremote.wear.phone.PhoneState
import com.quickremote.wear.phone.Show
import com.quickremote.wear.phone.WearProtocol
import org.junit.Assert.assertEquals
import org.junit.Test

class PhoneStateTest {

    private val show = Show(running = true, current = 5, total = 20)
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
}
