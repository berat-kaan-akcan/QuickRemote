package com.quickremote.wear.remote

/**
 * The commands the watch sends, by their names in RemoteCommands
 * (packages/quick_remote_shared/lib/src/remote_commands.dart). The phone
 * passes them on to the computer as they are.
 */
object WireCommands {
    const val NEXT = "NEXT"
    const val PREV = "PREV"
    const val START = "START"
    const val END = "END"
    const val BLACK_SCREEN = "BLACK_SCREEN"
    const val WHITE_SCREEN = "WHITE_SCREEN"
    const val MODE_LASER = "MODE_LASER"
    const val LASER_OFF = "LASER_OFF"
    const val MODE_ARROW = "MODE_ARROW"
}
