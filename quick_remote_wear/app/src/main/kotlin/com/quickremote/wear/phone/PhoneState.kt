package com.quickremote.wear.phone

/** The slideshow on the computer. [current] is 0 while the program does not tell the slide. */
data class Show(val running: Boolean, val current: Int, val total: Int)

/**
 * The phone's state DataItem. [show] is null while the phone is the
 * computer's Bluetooth keyboard: a keyboard is told nothing.
 */
data class PhoneReport(val link: String, val pc: String, val show: Show?)

sealed interface PhoneState {
    /** Just opened: the phone has not been found or has not answered yet. */
    data object Checking : PhoneState

    /** No phone with QuickRemote in reach, or it does not answer. */
    data object NoPhone : PhoneState

    /** QuickRemote is not running on the phone. */
    data object AppClosed : PhoneState

    /** The phone app runs without a computer; [connecting]: it is trying one. */
    data class NotConnected(val connecting: Boolean) : PhoneState

    /** [show] is null when the computer does not tell (the phone is its Bluetooth keyboard). */
    data class Connected(val pc: String, val show: Show?) : PhoneState

    companion object {
        /**
         * [reachable]: a phone with QuickRemote is in reach (null: not known
         * yet). [report]: its last state, which may be from before the phone
         * app was killed, so a phone that stays [silent] counts as gone.
         */
        fun of(reachable: Boolean?, report: PhoneReport?, silent: Boolean): PhoneState = when {
            reachable == null -> Checking
            !reachable || silent -> NoPhone
            report == null -> Checking
            else -> when (report.link) {
                WearProtocol.LINK_CONNECTED -> Connected(report.pc, report.show)
                WearProtocol.LINK_CONNECTING -> NotConnected(connecting = true)
                WearProtocol.LINK_CLOSED -> AppClosed
                else -> NotConnected(connecting = false)
            }
        }
    }
}

/** Something that happened once, for the wrist. */
sealed interface LinkEvent {
    /** The computer refused a command; [text] is the phone's wording. */
    data class PcError(val text: String) : LinkEvent

    /** A command did not reach the phone. */
    data object NotSent : LinkEvent
}
