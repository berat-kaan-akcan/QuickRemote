package com.quickremote.wear

import com.quickremote.wear.hid.HidKeys
import com.quickremote.wear.remote.Presenter
import com.quickremote.wear.remote.Shortcut
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PresenterTest {

    private val dart = File("../../quick_remote_app/lib/services/bluetooth/bt_key_mapping.dart").readText()

    private fun dartConst(name: String) = Regex("""int $name\s*=\s*0x([0-9A-Fa-f]+);""")
        .find(dart)!!.groupValues[1].toInt(16)

    @Test
    fun `the laser keys are the phone's usage IDs`() {
        assertEquals(dartConst("modLCtrl"), HidKeys.MOD_LCTRL)
        assertEquals(dartConst("keyA"), HidKeys.A)
        assertEquals(dartConst("keyL"), HidKeys.L)
    }

    @Test
    fun `the laser keys match the phone's Bluetooth remote`() {
        val ctrlL = Shortcut(HidKeys.MOD_LCTRL, HidKeys.L)
        val ctrlA = Shortcut(HidKeys.MOD_LCTRL, HidKeys.A)
        // bt_key_mapping.dart: PowerPoint's MODE_LASER is Ctrl+L, LASER_OFF Ctrl+A.
        assertEquals(ctrlL, Presenter.POWERPOINT.laserDown)
        assertEquals(ctrlA, Presenter.POWERPOINT.laserUp)
        // Impress: MODE_LASER is a no-op.
        assertNull(Presenter.IMPRESS.laserDown)
        assertNull(Presenter.IMPRESS.laserUp)
        // WPS: MODE_LASER is Ctrl+A (the arrow); putting it away is the same key.
        assertEquals(ctrlA, Presenter.WPS.laserDown)
        assertNull(Presenter.WPS.laserUp)
        listOf(
            "RemoteCommands.modeLaser:       _KeyAction(modLCtrl, [keyL])",
            "RemoteCommands.laserOff:        _KeyAction(modLCtrl, [keyA])",
            "RemoteCommands.modeLaser:   _KeyAction(modLCtrl, [keyA])",
            "RemoteCommands.modeLaser:       _NoopAction()",
        ).forEach { check(it in dart) { "bt_key_mapping.dart changed: $it" } }
    }
}
