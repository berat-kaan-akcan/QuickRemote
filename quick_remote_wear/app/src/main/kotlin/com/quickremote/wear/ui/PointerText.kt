package com.quickremote.wear.ui

import android.content.Context
import androidx.annotation.StringRes
import androidx.core.content.edit
import com.quickremote.wear.R
import com.quickremote.wear.phone.Pointer

/** The pointer's name for screen readers: "Laser pointer", "Arrow pointer", "Mouse cursor". */
@get:StringRes
val Pointer.label: Int
    get() = when (this) {
        Pointer.LASER -> R.string.action_laser
        Pointer.ARROW -> R.string.action_arrow
        Pointer.CURSOR -> R.string.action_cursor
    }

/** One word, for the tools page. */
@get:StringRes
val Pointer.word: Int
    get() = when (this) {
        Pointer.LASER -> R.string.tool_laser
        Pointer.ARROW -> R.string.tool_arrow
        Pointer.CURSOR -> R.string.tool_cursor
    }

/** Along the top of the laser screen. */
@get:StringRes
val Pointer.hint: Int
    get() = when (this) {
        Pointer.LASER -> R.string.laser_hint
        Pointer.ARROW -> R.string.arrow_hint
        Pointer.CURSOR -> R.string.cursor_hint
    }

/** Under Next, until it has been held once. */
@get:StringRes
val Pointer.holdHint: Int
    get() = when (this) {
        Pointer.LASER -> R.string.hold_for_laser
        Pointer.ARROW -> R.string.hold_for_arrow
        Pointer.CURSOR -> R.string.hold_for_cursor
    }

/** Hints shown until the presenter has done what they tell, kept across starts. */
object Tips {
    private const val PREFS = "quickremote"

    /** Next held for the laser. */
    const val HELD_LASER = "tip_held_laser"

    fun seen(context: Context, tip: String): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(tip, false)

    fun markSeen(context: Context, tip: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit { putBoolean(tip, true) }
    }
}
