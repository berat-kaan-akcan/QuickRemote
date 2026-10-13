package com.quickremote.wear.phone

/**
 * What the watch and the phone app say to each other over the Wearable Data
 * Layer. The phone's side is WearRelay.kt (quick_remote_app/android) and
 * lib/services/wear/wear_bridge.dart; WearProtocolTest keeps the three equal.
 */
object WearProtocol {
    /** Declared by the phone app (res/values/wear.xml): the node to talk to. */
    const val CAPABILITY = "quickremote_phone"

    /** The DataItem the phone keeps current: its connection and the slideshow. */
    const val PATH_STATE = "/quickremote/state"
    const val KEY_LINK = "link"
    const val KEY_MODE = "mode"
    const val KEY_PC = "pc"
    const val KEY_RUNNING = "running"
    const val KEY_CURRENT = "current"
    const val KEY_TOTAL = "total"

    /** [KEY_LINK]: the phone app is not running. */
    const val LINK_CLOSED = "closed"
    const val LINK_DISCONNECTED = "disconnected"
    const val LINK_CONNECTING = "connecting"
    const val LINK_CONNECTED = "connected"

    /** [KEY_MODE]: how the phone reaches the computer. */
    const val MODE_WIFI = "wifi"

    /** As a Bluetooth keyboard, which gets no answer: no slide, no errors. */
    const val MODE_BLUETOOTH = "bluetooth"

    // Messages from the watch.
    /** "Write the state again": the answer tells a stale DataItem from a live phone. */
    const val PATH_HELLO = "/quickremote/hello"

    /** A command name, UTF-8. */
    const val PATH_COMMAND = "/quickremote/command"

    /** Laser movement: float32 dx, float32 dy, little-endian. */
    const val PATH_MOVE = "/quickremote/move"

    /** Answered with [PATH_PONG] and the same bytes: measures the link. */
    const val PATH_PING = "/quickremote/ping"

    // Messages from the phone.
    const val PATH_PONG = "/quickremote/pong"

    /** A [PATH_MOVE] arrived: the watch may send the next one. */
    const val PATH_MOVED = "/quickremote/moved"

    /** A command the computer refused, as text in the phone's language, UTF-8. */
    const val PATH_ERROR = "/quickremote/error"

    // The watch's own Bluetooth socket to the phone, for the laser (DirectLink).
    /** The RFCOMM service the phone app listens on (WearDirect.kt there). */
    const val DIRECT_UUID = "87ee80c8-0bb4-41b3-b323-c934438d4992"

    /** A frame: one of the types below and eight bytes. */
    const val FRAME_SIZE = 9

    /** Watch: movement as in [PATH_MOVE]. Answered with [FRAME_MOVED]. */
    const val FRAME_MOVE = 1
    const val FRAME_MOVED = 2

    /** Watch: answered with [FRAME_PONG] and the same bytes. */
    const val FRAME_PING = 3
    const val FRAME_PONG = 4

    /** Opened on the phone with RemoteActivityHelper: brings the phone app to the front. */
    const val OPEN_URI = "quickremote://watch"
}
