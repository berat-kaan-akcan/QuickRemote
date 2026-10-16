package com.quickremote.wear.phone

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Vibrates the talk's clock warnings ([WearProtocol.PATH_ALERT]) on the
 * wrist. Declared in the manifest, so Google Play services starts it for a
 * warning also while the remote is not on screen (the wrist down, the watch
 * face back). The remote, when open, shows the warning as well (PhoneLink).
 */
class AlertService : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.path != WearProtocol.PATH_ALERT) return
        val alert = TimerAlert.parse(String(event.data, Charsets.UTF_8)) ?: return
        vibrate(this, alert.pattern)
    }

    companion object {
        /** The phone's timer patterns (vibrateTimerPattern in presentation_timer.dart), in ms: pause, on, pause, on… */
        fun timings(pattern: String): LongArray? = when (pattern) {
            "" -> null
            "short" -> longArrayOf(0, 300)
            "long" -> longArrayOf(0, 800)
            "triple" -> longArrayOf(0, 500, 150, 500, 150, 800)
            else -> longArrayOf(0, 300, 100, 300)
        }

        fun vibrate(context: Context, pattern: String) {
            val timings = timings(pattern) ?: return
            val vibrator = context.getSystemService(Vibrator::class.java) ?: return
            val effect = VibrationEffect.createWaveform(timings, -1)
            // An alarm's vibration: felt also with the screen off or the watch face on.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                vibrator.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(effect, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build())
            }
        }
    }
}
