package com.quickremote.wear.remote

import android.content.Context
import androidx.core.content.edit
import com.quickremote.wear.hid.HidKeys
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** A key under its modifiers, as one keyboard report. */
data class Shortcut(val modifiers: Int, val key: Int)

/**
 * The program showing the slides. The computer does not tell a keyboard which
 * one runs, so the presenter picks it, as on the phone's Bluetooth remote
 * (BtTarget in bt_key_mapping.dart). Only the laser differs: the slide keys
 * are the same in all three.
 */
enum class Presenter(
    /** Pressed when the finger touches the laser screen. */
    val laserDown: Shortcut?,
    /** Pressed when the finger leaves it. */
    val laserUp: Shortcut?,
) {
    /** Ctrl+L is the laser, Ctrl+A puts it away again (the arrow). */
    POWERPOINT(Shortcut(HidKeys.MOD_LCTRL, HidKeys.L), Shortcut(HidKeys.MOD_LCTRL, HidKeys.A)),

    /** No laser shortcut: the cursor itself is the laser. */
    IMPRESS(null, null),

    /** No laser either, and the show hides the cursor until Ctrl+A (the arrow). */
    WPS(Shortcut(HidKeys.MOD_LCTRL, HidKeys.A), null),
}

/** The presenter's choice of program, kept across restarts. PowerPoint until chosen, as on the phone. */
class PresenterStore(context: Context) {
    private val prefs = context.getSharedPreferences("remote", Context.MODE_PRIVATE)
    private val _presenter = MutableStateFlow(
        Presenter.entries.firstOrNull { it.name == prefs.getString(KEY, null) } ?: Presenter.POWERPOINT,
    )
    val presenter: StateFlow<Presenter> = _presenter.asStateFlow()

    fun set(presenter: Presenter) {
        _presenter.value = presenter
        prefs.edit { putString(KEY, presenter.name) }
    }

    private companion object {
        const val KEY = "presenter"
    }
}
