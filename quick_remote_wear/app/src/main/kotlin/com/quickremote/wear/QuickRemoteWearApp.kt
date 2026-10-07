package com.quickremote.wear

import android.app.Application
import com.quickremote.wear.hid.HidConnection
import com.quickremote.wear.remote.PresenterStore
import kotlinx.coroutines.flow.MutableStateFlow

class QuickRemoteWearApp : Application() {
    /** One keyboard session per process, run by HidSessionService and shown by the UI. */
    val hid by lazy { HidConnection(this) }

    /** The program the laser is for. */
    val presenter by lazy { PresenterStore(this) }

    /** The remote is on screen (MainActivity between onStart and onStop). */
    val remoteVisible = MutableStateFlow(false)
}
