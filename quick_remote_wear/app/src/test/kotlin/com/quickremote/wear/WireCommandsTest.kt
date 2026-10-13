package com.quickremote.wear

import com.quickremote.wear.remote.RemoteAction
import com.quickremote.wear.remote.WireCommands
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WireCommandsTest {

    private val shared = File("../../packages/quick_remote_shared/lib/src/remote_commands.dart").readText()
    private val bridge = File("../../quick_remote_app/lib/services/wear/wear_bridge.dart").readText()

    /** `static const next = 'NEXT';` in RemoteCommands. */
    private fun dartCommand(name: String) = Regex("""static const $name\s*=\s*'([A-Z_]+)';""")
        .find(shared)!!.groupValues[1]

    private val commands = mapOf(
        "next" to WireCommands.NEXT,
        "prev" to WireCommands.PREV,
        "start" to WireCommands.START,
        "end" to WireCommands.END,
        "blackScreen" to WireCommands.BLACK_SCREEN,
        "whiteScreen" to WireCommands.WHITE_SCREEN,
        "modeLaser" to WireCommands.MODE_LASER,
        "laserOff" to WireCommands.LASER_OFF,
        "modeArrow" to WireCommands.MODE_ARROW,
    )

    @Test
    fun `the commands are RemoteCommands' names`() {
        commands.forEach { (dart, kotlin) -> assertEquals(dart, dartCommand(dart), kotlin) }
    }

    @Test
    fun `the phone passes on every command the watch sends, and no other`() {
        val allowed = Regex("""static const watchCommands = <String>\{(.*?)\};""", RegexOption.DOT_MATCHES_ALL)
            .find(bridge)!!.groupValues[1]
        val names = Regex("""RemoteCommands\.(\w+)""").findAll(allowed).map { it.groupValues[1] }.toSet()
        assertEquals(commands.keys, names)
    }

    @Test
    fun `every button sends one of the commands`() {
        assertTrue(RemoteAction.entries.all { it.command in commands.values })
    }
}
