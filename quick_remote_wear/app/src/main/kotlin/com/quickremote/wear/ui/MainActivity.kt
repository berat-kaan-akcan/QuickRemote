package com.quickremote.wear.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.quickremote.wear.QuickRemoteWearApp
import com.quickremote.wear.hid.HidSessionService
import com.quickremote.wear.ui.theme.QuickRemoteTheme

class MainActivity : ComponentActivity() {
    private val app get() = application as QuickRemoteWearApp

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            QuickRemoteTheme {
                WearApp(app.hid, app.presenter)
            }
        }
    }

    override fun onStart() {
        super.onStart()
        app.remoteVisible.value = true
    }

    override fun onStop() {
        app.remoteVisible.value = false
        super.onStop()
    }

    override fun onDestroy() {
        // Swiped away or closed with Back: the keyboard goes with the remote.
        // The screen turning off only stops the activity.
        if (isFinishing) HidSessionService.stop(this)
        super.onDestroy()
    }
}
