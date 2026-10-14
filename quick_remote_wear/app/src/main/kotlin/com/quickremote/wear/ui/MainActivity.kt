package com.quickremote.wear.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.mutableStateOf
import androidx.wear.ambient.AmbientLifecycleObserver
import com.quickremote.wear.QuickRemoteWearApp
import com.quickremote.wear.ui.theme.QuickRemoteTheme
import com.quickremote.wear.ui.theme.WearTheme

class MainActivity : ComponentActivity() {
    private val app get() = application as QuickRemoteWearApp

    /** The screen is dimmed (always-on display): the remote shows its ambient screen. */
    private val ambient = mutableStateOf(false)

    private val theme = mutableStateOf(WearTheme.COBALT)

    // With this the remote stays in front while the screen is dimmed, on
    // watches with the always-on display on, instead of the watch face.
    private val ambientObserver = AmbientLifecycleObserver(
        this,
        object : AmbientLifecycleObserver.AmbientLifecycleCallback {
            override fun onEnterAmbient(ambientDetails: AmbientLifecycleObserver.AmbientDetails) {
                ambient.value = true
            }

            override fun onExitAmbient() {
                ambient.value = false
            }
        },
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(ambientObserver)
        theme.value = WearTheme.stored(this)
        setContent {
            // Where the presenter picks the theme is still to be decided; the
            // stored one (the brand's cobalt until then) is used.
            QuickRemoteTheme(theme.value) {
                WearApp(app.phone, ambient.value)
            }
        }
    }

    // The watch holds no connection of its own: it listens to the phone while
    // the remote is on screen, and asks for its state on every return.
    override fun onStart() {
        super.onStart()
        app.phone.start()
    }

    override fun onStop() {
        app.phone.stop()
        super.onStop()
    }
}
