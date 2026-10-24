package com.quickremote.wear

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status
import com.quickremote.wear.phone.PhoneState
import com.quickremote.wear.ui.MainActivity
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * While the phone is connected to a computer, the remote is an Ongoing
 * Activity: from Wear OS 5 the watch shows it again when the screen wakes,
 * instead of the watch face, and its icon on the watch face opens it. Not
 * only while a show runs: over Bluetooth the watch cannot tell. It keeps the
 * link to the phone listening meanwhile, and stops by itself a while after
 * the connection has gone ([STOP_AFTER_MS]).
 */
class PresentingService : Service() {
    private val app get() = application as QuickRemoteWearApp
    private val scope = MainScope()
    private var ending: Job? = null
    private var running = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (running) return START_NOT_STICKY
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
            )
        } catch (e: RuntimeException) {
            // Refused (the app is in the background, or a permission the
            // connectedDevice type needs is missing): no Ongoing Activity
            // this time, and the next start tries again.
            Log.w(TAG, "Ongoing activity not started: ${e.message}")
            stopSelf()
            return START_NOT_STICKY
        }
        running = true
        app.phone.start()
        scope.launch {
            app.phone.state.collect { state ->
                if (active(state)) {
                    ending?.cancel()
                    ending = null
                } else if (ending == null) {
                    ending = launch {
                        delay(STOP_AFTER_MS)
                        stopSelf()
                    }
                }
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        scope.cancel()
        if (running) app.phone.stop()
        super.onDestroy()
    }

    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.presenting_channel), NotificationManager.IMPORTANCE_LOW),
        )
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val text = getString(R.string.presenting)
        val builder = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_presenting)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(text)
            .setContentIntent(open)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setSilent(true)
        OngoingActivity.Builder(this, NOTIFICATION_ID, builder)
            .setStaticIcon(R.drawable.ic_presenting)
            .setTouchIntent(open)
            .setStatus(Status.Builder().addTemplate(text).build())
            .build()
            .apply(this)
        return builder.build()
    }

    companion object {
        private const val TAG = "QuickRemotePresenting"
        private const val CHANNEL = "presenting"
        private const val NOTIFICATION_ID = 1

        /** A dropped connection keeps it this long: it may come back. */
        private const val STOP_AFTER_MS = 60_000L

        /** The phone is connected to a computer: the remote is in use. */
        fun active(state: PhoneState): Boolean = state is PhoneState.Connected

        fun start(context: Context) {
            try {
                ContextCompat.startForegroundService(context, Intent(context, PresentingService::class.java))
            } catch (e: RuntimeException) {
                // ForegroundServiceStartNotAllowedException when the app is no
                // longer in front; the remote still works without it.
                Log.w(TAG, "Presenting service not started: ${e.message}")
            }
        }
    }
}
