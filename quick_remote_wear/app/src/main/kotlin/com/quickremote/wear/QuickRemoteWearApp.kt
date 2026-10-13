package com.quickremote.wear

import android.app.Application
import com.quickremote.wear.phone.PhoneLink

class QuickRemoteWearApp : Application() {
    /** The way to the computer, through the phone app. Runs while the remote is on screen. */
    val phone by lazy { PhoneLink(this) }
}
