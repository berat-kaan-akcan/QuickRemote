package com.quickremote.wear.phone

/** The slideshow on the computer. [current] is 0 while the program does not tell the slide. */
data class Show(val running: Boolean, val current: Int, val total: Int)

/** What the watch's laser is on the computer ([WearProtocol.KEY_POINTER]). */
enum class Pointer {
    LASER,
    ARROW,
    CURSOR,
    ;

    companion object {
        /** A phone from before the key, or a word not known yet, means the laser. */
        fun of(word: String?): Pointer = when (word) {
            WearProtocol.POINTER_ARROW -> ARROW
            WearProtocol.POINTER_CURSOR -> CURSOR
            else -> LASER
        }
    }
}

/**
 * The talk's clock as the phone keeps it: its length in seconds ([target],
 * 0 counts up), whether it runs, since when ([startedAt], the wall clock in
 * ms, which the watch and the phone share) and, paused, how far it got.
 */
data class TalkClock(val target: Int, val running: Boolean, val startedAt: Long, val elapsed: Int) {
    /** Seconds on the clock at [now] (ms since the epoch). */
    fun elapsedAt(now: Long): Int =
        if (running && startedAt > 0) ((now - startedAt) / 1_000L).toInt().coerceAtLeast(0) else elapsed

    /** It shows: running, or paused part of the way. */
    val shown: Boolean get() = running || elapsed > 0
}

/** A warning of the talk's clock: [secondsLeft] before the end, or the end ([timeUp]). */
data class TimerAlert(val timeUp: Boolean, val secondsLeft: Int, val pattern: String) {
    companion object {
        /** "warning:300:double", "timeUp:0:triple"; null when it is not one. */
        fun parse(text: String): TimerAlert? {
            val parts = text.split(':')
            if (parts.size != 3) return null
            val seconds = parts[1].toIntOrNull() ?: return null
            return when (parts[0]) {
                "warning" -> TimerAlert(false, seconds, parts[2])
                "timeUp" -> TimerAlert(true, 0, parts[2])
                else -> null
            }
        }
    }
}

/**
 * The phone's state DataItem. [show] is null while the phone is the
 * computer's Bluetooth keyboard: a keyboard is told nothing.
 */
data class PhoneReport(
    val link: String,
    val pc: String,
    val show: Show?,
    val pointer: Pointer = Pointer.LASER,
    /** The talk's length; null from a phone that does not keep one. */
    val duration: Int? = null,
    val clock: TalkClock? = null,
)

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
    data class Connected(
        val pc: String,
        val show: Show?,
        val pointer: Pointer = Pointer.LASER,
        val duration: Int? = null,
        val clock: TalkClock? = null,
    ) : PhoneState

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
                WearProtocol.LINK_CONNECTED -> Connected(report.pc, report.show, report.pointer, report.duration, report.clock)
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

    /** The talk's clock warned; [AlertService] vibrates it. */
    data class Timer(val alert: TimerAlert) : LinkEvent
}
