package com.quickremote.wear

import com.quickremote.wear.phone.AlertService
import com.quickremote.wear.phone.WearProtocol
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The watch and the phone app are built apart; this keeps their words for each other equal. */
class WearProtocolTest {

    private val phone = File("../../quick_remote_app")
    private val relay = phone.resolve("android/app/src/main/kotlin/com/quickremote/quick_remote_app/WearRelay.kt").readText()
    private val bridge = phone.resolve("lib/services/wear/wear_bridge.dart").readText()
    private val manifest = phone.resolve("android/app/src/main/AndroidManifest.xml").readText()
    private val capabilities = phone.resolve("android/app/src/main/res/values/wear.xml").readText()

    private fun relayConst(name: String) = Regex("""const val $name = "([^"]+)"""").find(relay)!!.groupValues[1]

    @Test
    fun `paths and keys match the phone's relay`() {
        mapOf(
            "PATH_STATE" to WearProtocol.PATH_STATE,
            "KEY_LINK" to WearProtocol.KEY_LINK,
            "KEY_MODE" to WearProtocol.KEY_MODE,
            "MODE_WIFI" to WearProtocol.MODE_WIFI,
            "KEY_PC" to WearProtocol.KEY_PC,
            "KEY_RUNNING" to WearProtocol.KEY_RUNNING,
            "KEY_CURRENT" to WearProtocol.KEY_CURRENT,
            "KEY_TOTAL" to WearProtocol.KEY_TOTAL,
            "KEY_POINTER" to WearProtocol.KEY_POINTER,
            "POINTER_LASER" to WearProtocol.POINTER_LASER,
            "KEY_DURATION" to WearProtocol.KEY_DURATION,
            "KEY_TIMER_TARGET" to WearProtocol.KEY_TIMER_TARGET,
            "KEY_TIMER_RUNNING" to WearProtocol.KEY_TIMER_RUNNING,
            "KEY_TIMER_START" to WearProtocol.KEY_TIMER_START,
            "KEY_TIMER_ELAPSED" to WearProtocol.KEY_TIMER_ELAPSED,
            "KEY_STAMP" to WearProtocol.KEY_STAMP,
            "PATH_DURATION" to WearProtocol.PATH_DURATION,
            "PATH_ALERT" to WearProtocol.PATH_ALERT,
            "LINK_CLOSED" to WearProtocol.LINK_CLOSED,
            "PATH_HELLO" to WearProtocol.PATH_HELLO,
            "PATH_COMMAND" to WearProtocol.PATH_COMMAND,
            "PATH_MOVE" to WearProtocol.PATH_MOVE,
            "PATH_PING" to WearProtocol.PATH_PING,
            "PATH_PONG" to WearProtocol.PATH_PONG,
            "PATH_MOVED" to WearProtocol.PATH_MOVED,
            "PATH_ERROR" to WearProtocol.PATH_ERROR,
        ).forEach { (name, value) -> assertEquals(name, relayConst(name), value) }
    }

    @Test
    fun `the laser's own socket is the one the phone listens on`() {
        val direct = phone.resolve("android/app/src/main/kotlin/com/quickremote/quick_remote_app/WearDirect.kt").readText()
        // \r too: a Windows checkout has CRLF line ends.
        fun value(name: String) = Regex("""const val $name = "?([^"\r\n]+)"?""").find(direct)!!.groupValues[1]
        assertEquals(value("DIRECT_UUID"), WearProtocol.DIRECT_UUID)
        mapOf(
            "FRAME_SIZE" to WearProtocol.FRAME_SIZE,
            "FRAME_MOVE" to WearProtocol.FRAME_MOVE,
            "FRAME_MOVED" to WearProtocol.FRAME_MOVED,
            "FRAME_PING" to WearProtocol.FRAME_PING,
            "FRAME_PONG" to WearProtocol.FRAME_PONG,
        ).forEach { (name, number) -> assertEquals(name, value(name), number.toString()) }
    }

    @Test
    fun `the state's keys and link values are the ones the phone writes`() {
        listOf(
            WearProtocol.KEY_LINK,
            WearProtocol.KEY_MODE,
            WearProtocol.KEY_PC,
            WearProtocol.KEY_RUNNING,
            WearProtocol.KEY_CURRENT,
            WearProtocol.KEY_TOTAL,
            WearProtocol.KEY_POINTER,
            WearProtocol.KEY_DURATION,
            WearProtocol.KEY_TIMER_TARGET,
            WearProtocol.KEY_TIMER_RUNNING,
            WearProtocol.KEY_TIMER_START,
            WearProtocol.KEY_TIMER_ELAPSED,
        ).forEach { assertTrue("wear_bridge.dart writes no '$it'", "'$it': " in bridge) }
        listOf(
            WearProtocol.POINTER_LASER,
            WearProtocol.POINTER_ARROW,
            WearProtocol.POINTER_CURSOR,
        ).forEach { assertTrue("wear_bridge.dart has no pointer '$it'", "'$it'" in bridge) }
        listOf(
            WearProtocol.LINK_CONNECTED,
            WearProtocol.LINK_CONNECTING,
            WearProtocol.LINK_DISCONNECTED,
        ).forEach { assertTrue("wear_bridge.dart has no link '$it'", "=> '$it'," in bridge) }
        assertTrue(
            "wear_bridge.dart writes other modes",
            "'${WearProtocol.KEY_MODE}': bluetooth ? '${WearProtocol.MODE_BLUETOOTH}' : '${WearProtocol.MODE_WIFI}'," in bridge,
        )
    }

    @Test
    fun `the phone declares the capability and listens under the paths' prefix`() {
        assertTrue("<item>${WearProtocol.CAPABILITY}</item>" in capabilities)
        // No code refers to the array: without the keep rule a release build
        // of the phone app drops it, and the watch finds no phone.
        val keep = phone.resolve("android/app/src/main/res/raw/keep.xml").readText()
        assertTrue("tools:keep=\"@array/android_wear_capabilities\"" in keep)
        val prefix = Regex("""android:scheme="wear" android:host="\*" android:pathPrefix="([^"]+)"""")
            .find(manifest)!!.groupValues[1]
        listOf(
            WearProtocol.PATH_HELLO,
            WearProtocol.PATH_COMMAND,
            WearProtocol.PATH_MOVE,
            WearProtocol.PATH_PING,
        ).forEach { assertTrue(it, it.startsWith(prefix)) }
    }

    @Test
    fun `the phone app opens for the watch's link`() {
        val (scheme, host) = WearProtocol.OPEN_URI.split("://")
        assertTrue("""<data android:scheme="$scheme" android:host="$host"/>""" in manifest)
    }

    @Test
    fun `the timer's vibrations are the phone's patterns`() {
        val timer = phone.resolve("lib/widgets/presentation_timer.dart").readText()
        val cases = Regex("""case '(\w+)':\s*(?:case '\w+':\s*)?(?:default:\s*)?Vibration\.vibrate\(pattern: \[([\d, ]+)]""")
            .findAll(timer).map { it.groupValues[1] to it.groupValues[2] }.toList()
        assertTrue("no patterns found in presentation_timer.dart", cases.size >= 4)
        for ((name, pattern) in cases) {
            val timings = pattern.split(',').map { it.trim().toLong() }
            assertEquals(name, timings, AlertService.timings(name)!!.toList())
        }
    }

    @Test
    fun `the watch's alerts are the words the phone's relay sends`() {
        assertTrue("\"\$kind:\$seconds:\$pattern\"" in relay)
        assertTrue("'timeUp'" in bridge && "'warning'" in bridge)
    }
}
