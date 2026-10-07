package com.quickremote.wear.hid

/** USB HID usage IDs (HID Usage Tables §10, keyboard page) the watch sends. */
object HidKeys {
    const val MOD_NONE = 0x00
    const val MOD_LCTRL = 0x01

    const val A = 0x04
    const val B = 0x05
    const val L = 0x0F
    const val W = 0x1A
    const val ESCAPE = 0x29
    const val F5 = 0x3E
    const val PAGE_UP = 0x4B
    const val PAGE_DOWN = 0x4E
}

/**
 * The watch as a Bluetooth keyboard + mouse + consumer control. The descriptor
 * is byte for byte the phone's (quick_remote_app/android/.../BluetoothHidService.kt),
 * so computers treat both the same.
 */
object HidReports {
    const val ID_KEYBOARD = 1
    const val ID_MOUSE = 2
    const val ID_CONSUMER = 3

    /** Keyboard report size without the report ID: modifiers, reserved, 6 keys. */
    const val KEYBOARD_SIZE = 8

    val DESCRIPTOR: ByteArray = bytes(
        // ── Keyboard ──────────────────────────────────────────────────────────
        0x05, 0x01,        // Usage Page (Generic Desktop)
        0x09, 0x06,        // Usage (Keyboard)
        0xA1, 0x01,        // Collection (Application)
        0x85, ID_KEYBOARD, //   Report ID (1)
        0x05, 0x07,        //   Usage Page (Key Codes)
        0x19, 0xE0,        //   Usage Minimum (224 = Left Control)
        0x29, 0xE7,        //   Usage Maximum (231 = Right GUI)
        0x15, 0x00,        //   Logical Minimum (0)
        0x25, 0x01,        //   Logical Maximum (1)
        0x75, 0x01,        //   Report Size (1)
        0x95, 0x08,        //   Report Count (8): modifier bits
        0x81, 0x02,        //   Input (Data, Variable, Absolute)
        0x95, 0x01,        //   Report Count (1)
        0x75, 0x08,        //   Report Size (8): reserved byte
        0x81, 0x01,        //   Input (Constant)
        0x95, 0x06,        //   Report Count (6): key array
        0x75, 0x08,        //   Report Size (8)
        0x15, 0x00,        //   Logical Minimum (0)
        0x25, 0x65,        //   Logical Maximum (101)
        0x05, 0x07,        //   Usage Page (Key Codes)
        0x19, 0x00,        //   Usage Minimum (0)
        0x29, 0x65,        //   Usage Maximum (101)
        0x81, 0x00,        //   Input (Data, Array)
        0xC0,              // End Collection

        // ── Mouse ─────────────────────────────────────────────────────────────
        0x05, 0x01,        // Usage Page (Generic Desktop)
        0x09, 0x02,        // Usage (Mouse)
        0xA1, 0x01,        // Collection (Application)
        0x09, 0x01,        //   Usage (Pointer)
        0xA1, 0x00,        //   Collection (Physical)
        0x85, ID_MOUSE,    //     Report ID (2)
        0x05, 0x09,        //     Usage Page (Buttons)
        0x19, 0x01,        //     Usage Minimum (1)
        0x29, 0x03,        //     Usage Maximum (3)
        0x15, 0x00,        //     Logical Minimum (0)
        0x25, 0x01,        //     Logical Maximum (1)
        0x95, 0x03,        //     Report Count (3)
        0x75, 0x01,        //     Report Size (1)
        0x81, 0x02,        //     Input (Data, Variable, Absolute)
        0x95, 0x01,        //     Report Count (1)
        0x75, 0x05,        //     Report Size (5): padding
        0x81, 0x01,        //     Input (Constant)
        0x05, 0x01,        //     Usage Page (Generic Desktop)
        0x09, 0x30,        //     Usage (X)
        0x09, 0x31,        //     Usage (Y)
        0x15, 0x81,        //     Logical Minimum (-127)
        0x25, 0x7F,        //     Logical Maximum (127)
        0x75, 0x08,        //     Report Size (8)
        0x95, 0x02,        //     Report Count (2)
        0x81, 0x06,        //     Input (Data, Variable, Relative)
        0xC0,              //   End Collection
        0xC0,              // End Collection

        // ── Consumer Control ──────────────────────────────────────────────────
        0x05, 0x0C,        // Usage Page (Consumer)
        0x09, 0x01,        // Usage (Consumer Control)
        0xA1, 0x01,        // Collection (Application)
        0x85, ID_CONSUMER, //   Report ID (3)
        0x15, 0x00,        //   Logical Minimum (0)
        0x26, 0xFF, 0x03,  //   Logical Maximum (1023)
        0x19, 0x00,        //   Usage Minimum (0)
        0x2A, 0xFF, 0x03,  //   Usage Maximum (1023)
        0x75, 0x10,        //   Report Size (16)
        0x95, 0x01,        //   Report Count (1)
        0x81, 0x00,        //   Input (Data, Array)
        0xC0,              // End Collection
    )

    /** A keyboard report with [key] held under [modifiers]. */
    fun keyDown(modifiers: Int, key: Int): ByteArray =
        ByteArray(KEYBOARD_SIZE).also {
            it[0] = modifiers.toByte()
            it[2] = key.toByte()
        }

    /** The keyboard report that releases every key. */
    fun keysUp(): ByteArray = ByteArray(KEYBOARD_SIZE)

    /** A mouse report moving by [dx], [dy] (each within ±127) with no button held. */
    fun mouseMove(dx: Int, dy: Int): ByteArray {
        require(dx in -MOUSE_STEP..MOUSE_STEP && dy in -MOUSE_STEP..MOUSE_STEP)
        return byteArrayOf(0, dx.toByte(), dy.toByte())
    }

    /** The largest move one mouse report carries per axis. */
    const val MOUSE_STEP = 127

    private fun bytes(vararg values: Int) = ByteArray(values.size) { values[it].toByte() }
}
