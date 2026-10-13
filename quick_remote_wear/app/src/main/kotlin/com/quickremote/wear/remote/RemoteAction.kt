package com.quickremote.wear.remote

/** What the watch's buttons and bezel do to a presentation, as the command sent for it. */
enum class RemoteAction(val command: String) {
    NEXT(WireCommands.NEXT),
    PREV(WireCommands.PREV),
    START(WireCommands.START),
    END(WireCommands.END),

    // Toggles: pressed again, the slide comes back.
    BLACK_SCREEN(WireCommands.BLACK_SCREEN),
    WHITE_SCREEN(WireCommands.WHITE_SCREEN),
}
