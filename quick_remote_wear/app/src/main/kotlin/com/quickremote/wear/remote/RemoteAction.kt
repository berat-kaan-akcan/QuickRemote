package com.quickremote.wear.remote

import com.quickremote.wear.hid.HidKeys

/**
 * What the watch can do to a presentation, as the keyboard shortcut it sends.
 * These are the same in PowerPoint, Impress and WPS (the phone's
 * bt_key_mapping.dart sends the same keys for all three), so the watch needs
 * no program choice for them.
 */
enum class RemoteAction(val modifiers: Int, val key: Int) {
    NEXT(HidKeys.MOD_NONE, HidKeys.PAGE_DOWN),
    PREV(HidKeys.MOD_NONE, HidKeys.PAGE_UP),
    START(HidKeys.MOD_NONE, HidKeys.F5),
    END(HidKeys.MOD_NONE, HidKeys.ESCAPE),

    // Toggles: pressed again, the slide comes back.
    BLACK_SCREEN(HidKeys.MOD_NONE, HidKeys.B),
    WHITE_SCREEN(HidKeys.MOD_NONE, HidKeys.W),
}
