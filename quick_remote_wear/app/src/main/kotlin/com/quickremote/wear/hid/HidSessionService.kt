package com.quickremote.wear.hid

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import com.quickremote.wear.QuickRemoteWearApp
import com.quickremote.wear.R
import com.quickremote.wear.ui.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

/**
 * Holds the keyboard session. Android drops the HID registration of an app
 * that leaves the foreground without a foreground service, which on a watch
 * happens every time the screen turns off.
 *
 * Started with startService from the app in front (allowed there), so a
 * refused startForeground leaves a plain service instead of a crash: the
 * keyboard then works while the app is on screen.
 */
class HidSessionService : Service() {

    private val app get() = application as QuickRemoteWearApp
    private val hid get() = app.hid
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onCreate() {
        super.onCreate()
        // With no computer connected and nobody looking, the session would
        // only page computers every 32 s for as long as it ran. A connected
        // one stays: the screen turns off during every presentation.
        scope.launch {
            combine(hid.state, app.remoteVisible) { state, visible -> visible || state is HidState.Connected }
                .distinctUntilChanged()
                .collectLatest { needed ->
                    if (!needed) {
                        delay(IDLE_STOP_MS)
                        Log.d(TAG, "No computer and the remote closed for ${IDLE_STOP_MS / 1000} s: stopping")
                        stopSelf()
                    }
                }
        }
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
            )
        } catch (e: RuntimeException) {
            // ForegroundServiceStartNotAllowedException, or a SecurityException
            // without BLUETOOTH_CONNECT (connectedDevice's prerequisite).
            Log.w(TAG, "No foreground service: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        hid.start()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        scope.cancel()
        hid.stop()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun notification(): Notification {
        NotificationManagerCompat.from(this).createNotificationChannel(
            NotificationChannelCompat.Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_LOW)
                .setName(getString(R.string.notification_channel))
                .build(),
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(R.string.notification_text))
            .setContentIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    companion object {
        private const val TAG = "QuickRemoteHid"
        private const val CHANNEL_ID = "keyboard"
        private const val NOTIFICATION_ID = 1
        private const val IDLE_STOP_MS = 5 * 60_000L

        /** Starts the session, or retries a dropped connection when it runs. Call from the app in front. */
        fun start(context: Context) {
            context.startService(Intent(context, HidSessionService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, HidSessionService::class.java))
        }
    }
}
