package com.quickremote.wear

import com.quickremote.wear.hid.HidKeys
import com.quickremote.wear.hid.HidReports
import com.quickremote.wear.remote.RemoteAction
import java.io.File
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class HidReportsTest {

    @Test
    fun `key down holds the key under its modifiers`() {
        assertArrayEquals(
            byteArrayOf(0x01, 0, 0x4E, 0, 0, 0, 0, 0),
            HidReports.keyDown(0x01, HidKeys.PAGE_DOWN),
        )
        assertArrayEquals(ByteArray(8), HidReports.keysUp())
    }

    @Test
    fun `the slideshow keys match the phone's Bluetooth remote`() {
        assertEquals(HidKeys.PAGE_DOWN, RemoteAction.NEXT.key)
        assertEquals(HidKeys.PAGE_UP, RemoteAction.PREV.key)
        assertEquals(HidKeys.F5, RemoteAction.START.key)
        assertEquals(HidKeys.ESCAPE, RemoteAction.END.key)
        assertEquals(HidKeys.B, RemoteAction.BLACK_SCREEN.key)
        assertEquals(HidKeys.W, RemoteAction.WHITE_SCREEN.key)
        assertEquals(setOf(HidKeys.MOD_NONE), RemoteAction.entries.map { it.modifiers }.toSet())

        // Same usage IDs as the phone's bt_key_mapping.dart.
        val dart = phoneFile("lib/services/bluetooth/bt_key_mapping.dart").readText()
        fun dartKey(name: String) = Regex("""int $name\s*=\s*0x([0-9A-Fa-f]+);""")
            .find(dart)!!.groupValues[1].toInt(16)
        assertEquals(dartKey("keyPageDown"), HidKeys.PAGE_DOWN)
        assertEquals(dartKey("keyPageUp"), HidKeys.PAGE_UP)
        assertEquals(dartKey("keyF5"), HidKeys.F5)
        assertEquals(dartKey("keyEscape"), HidKeys.ESCAPE)
        assertEquals(dartKey("keyB"), HidKeys.B)
        assertEquals(dartKey("keyW"), HidKeys.W)
    }

    @Test
    fun `the report descriptor is the phone's, byte for byte`() {
        val kotlin = phoneFile("android/app/src/main/kotlin/com/quickremote/quick_remote_app/BluetoothHidService.kt")
            .readText()
        val block = kotlin.substringAfter("HID_REPORT_DESCRIPTOR: ByteArray = byteArrayOf(")
            .substringBefore("\n        )")
        val ids = mapOf("REPORT_ID_KEYBOARD" to 1, "REPORT_ID_MOUSE" to 2, "REPORT_ID_CONSUMER" to 3)
        val phone = block.lines()
            .map { it.substringBefore("//") }
            .flatMap { line ->
                Regex("""0x([0-9A-Fa-f]{2})\.toByte\(\)|REPORT_ID_[A-Z]+""").findAll(line).map {
                    val hex = it.groupValues[1]
                    if (hex.isNotEmpty()) hex.toInt(16).toByte() else ids.getValue(it.value).toByte()
                }.toList()
            }
        assertEquals(phone.size, HidReports.DESCRIPTOR.size)
        assertArrayEquals(phone.toByteArray(), HidReports.DESCRIPTOR)
    }

    /** The test runs in quick_remote_wear/app. */
    private fun phoneFile(path: String) = File("../../quick_remote_app/$path").also {
        check(it.exists()) { "missing ${it.absolutePath}" }
    }
}
