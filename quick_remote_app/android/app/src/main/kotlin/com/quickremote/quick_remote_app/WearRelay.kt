package com.quickremote.quick_remote_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * The phone's end of the watch app's link (quick_remote_wear, PhoneLink.kt),
 * over the Wearable Data Layer. The connection to the PC lives in Dart, so
 * this only carries: the watch's messages go to WearBridge
 * (lib/services/wear/wear_bridge.dart) over a MethodChannel, and its state
 * comes back to be written as a DataItem. The laser's movement can also
 * come over a socket of the watch's own (WearDirect).
 *
 * The Flutter engine exists only while the app runs. Without it a message
 * from the watch is answered here, with the state "closed": the watch then
 * asks for the app to be opened on the phone.
 */
object WearRelay {
    private const val TAG = "QuickRemoteWear"
    const val CHANNEL = "com.quickremote.quick_remote_app/wear"

    // Shared with the watch (WearProtocol.kt there; its WearProtocolTest
    // compares the two files).
    const val PATH_STATE = "/quickremote/state"
    const val KEY_LINK = "link"
    const val KEY_MODE = "mode"
    const val KEY_PC = "pc"
    const val KEY_RUNNING = "running"

    /** The PC's overlay draws the laser, so it works without a slideshow too. */
    const val KEY_LASER_ANYWHERE = "laserAnywhere"

    /** A PDF viewer or browser is in front and no show runs: Start puts it in full screen. */
    const val KEY_VIEWER = "viewer"
    const val KEY_CURRENT = "current"
    const val KEY_TOTAL = "total"

    /** What the watch's laser is on the computer: [POINTER_LASER], "arrow" or "cursor". */
    const val KEY_POINTER = "pointer"
    const val POINTER_LASER = "laser"

    /** The talk's length picked on either side, in seconds (0: none). */
    const val KEY_DURATION = "duration"

    /** The watch's color theme (cobalt, oled, contrast, mint, violet); absent: it keeps its own. */
    const val KEY_THEME = "theme"

    /** The talk's clock: its length (0 counts up), whether it runs, its start (ms since the epoch) and, paused, its time. */
    const val KEY_TIMER_TARGET = "timerTarget"
    const val KEY_TIMER_RUNNING = "timerRunning"
    const val KEY_TIMER_START = "timerStart"
    const val KEY_TIMER_ELAPSED = "timerElapsed"
    const val LINK_CLOSED = "closed"
    const val MODE_WIFI = "wifi"
    const val PATH_HELLO = "/quickremote/hello"
    const val PATH_COMMAND = "/quickremote/command"
    const val PATH_MOVE = "/quickremote/move"
    const val PATH_PING = "/quickremote/ping"
    const val PATH_PONG = "/quickremote/pong"
    const val PATH_MOVED = "/quickremote/moved"
    const val PATH_ERROR = "/quickremote/error"

    /** Watch: the talk's length it picked, in seconds, as UTF-8 text. */
    const val PATH_DURATION = "/quickremote/duration"

    /** To the watch: a timer warning, "warning:SECONDS:PATTERN" or "timeUp:0:PATTERN" (an empty pattern does not vibrate). */
    const val PATH_ALERT = "/quickremote/alert"

    /** Written with every state, so that an unchanged one still reaches the watch as a change. */
    private const val KEY_STAMP = "stamp"

    private val main = Handler(Looper.getMainLooper())
    private val EMPTY = ByteArray(0)

    /** The running app's channel to Dart. Main thread only. */
    private var channel: MethodChannel? = null

    /** The watch that last sent a message: errors go to it. */
    @Volatile
    private var watch: String? = null

    /** Called when the Flutter engine is ready. */
    fun attach(context: Context, channel: MethodChannel) {
        val app = context.applicationContext
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "state" -> {
                    putState(
                        app,
                        link = call.argument<String>(KEY_LINK) ?: LINK_CLOSED,
                        mode = call.argument<String>(KEY_MODE) ?: MODE_WIFI,
                        pc = call.argument<String>(KEY_PC) ?: "",
                        running = call.argument<Boolean>(KEY_RUNNING) ?: false,
                        laserAnywhere = call.argument<Boolean>(KEY_LASER_ANYWHERE) ?: false,
                        viewer = call.argument<Boolean>(KEY_VIEWER) ?: false,
                        current = call.argument<Int>(KEY_CURRENT) ?: 0,
                        total = call.argument<Int>(KEY_TOTAL) ?: 0,
                        pointer = call.argument<String>(KEY_POINTER) ?: POINTER_LASER,
                        theme = call.argument<String>(KEY_THEME),
                        clock = Clock(
                            duration = call.argument<Number>(KEY_DURATION)?.toInt() ?: 0,
                            target = call.argument<Number>(KEY_TIMER_TARGET)?.toInt() ?: 0,
                            running = call.argument<Boolean>(KEY_TIMER_RUNNING) ?: false,
                            start = call.argument<Number>(KEY_TIMER_START)?.toLong() ?: 0L,
                            elapsed = call.argument<Number>(KEY_TIMER_ELAPSED)?.toInt() ?: 0,
                        ),
                    )
                    result.success(null)
                }
                "alert" -> {
                    val to = watch
                    val kind = call.argument<String>("kind")
                    val seconds = call.argument<Number>("seconds")?.toInt() ?: 0
                    val pattern = call.argument<String>("pattern") ?: ""
                    if (to != null && kind != null) {
                        val text = "$kind:$seconds:$pattern"
                        Wearable.getMessageClient(app).sendMessage(to, PATH_ALERT, text.toByteArray(Charsets.UTF_8))
                    }
                    result.success(null)
                }
                "startDirect" -> {
                    // The permission was just given: start what attach could not.
                    WearDirect.start(app)
                    result.success(null)
                }
                "error" -> {
                    val to = watch
                    val text = call.argument<String>("text")
                    if (to != null && text != null) {
                        Wearable.getMessageClient(app).sendMessage(to, PATH_ERROR, text.toByteArray(Charsets.UTF_8))
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        WearDirect.start(app)
        // Dart writes no state until a watch asks (most phones have none).
        // A watch that already shows "closed" does not ask again, so one in
        // reach now counts as having asked.
        Wearable.getNodeClient(app).connectedNodes
            .addOnSuccessListener { nodes -> if (nodes.isNotEmpty()) this.channel?.invokeMethod("hello", null) }
            .addOnFailureListener { /* No Play services or no Wear OS app: no watch. */ }
    }

    /** Called when the app's Activity, and with it the engine and the connection to the PC, goes away. */
    fun detach(context: Context) {
        WearDirect.stop()
        if (channel == null) return
        channel?.setMethodCallHandler(null)
        channel = null
        if (watch != null) putClosed(context.applicationContext)
    }

    /** A message from the watch, on the listener service's thread. */
    fun onMessage(context: Context, event: MessageEvent) {
        val app = context.applicationContext
        watch = event.sourceNodeId
        if (event.path == PATH_PING) {
            Wearable.getMessageClient(app).sendMessage(event.sourceNodeId, PATH_PONG, event.data)
            return
        }
        val path = event.path
        val data = event.data
        // Answered at once: the watch sends its next movement only after
        // this, so that movement never queues up on the way.
        if (path == PATH_MOVE) Wearable.getMessageClient(app).sendMessage(event.sourceNodeId, PATH_MOVED, EMPTY)
        main.post {
            val dart = channel
            if (dart == null) {
                // The app is not running: commands are dropped, and the watch
                // learns why from the state.
                putClosed(app)
                return@post
            }
            when (path) {
                PATH_HELLO -> dart.invokeMethod("hello", null)
                PATH_COMMAND -> dart.invokeMethod("command", String(data, Charsets.UTF_8))
                PATH_DURATION -> String(data, Charsets.UTF_8).toIntOrNull()?.let { dart.invokeMethod("duration", it) }
                PATH_MOVE -> if (data.size == 8) {
                    val bytes = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
                    dart.invokeMethod("move", listOf(bytes.float.toDouble(), bytes.float.toDouble()))
                }
            }
        }
    }

    /** Laser movement that came over the watch's own socket (WearDirect), on its thread. */
    fun onMove(dx: Double, dy: Double) {
        main.post { channel?.invokeMethod("move", listOf(dx, dy)) }
    }

    private fun putClosed(context: Context) = putState(context, LINK_CLOSED, MODE_WIFI, "", false, false, false, 0, 0, POINTER_LASER, null, Clock())

    private fun putState(
        context: Context,
        link: String,
        mode: String,
        pc: String,
        running: Boolean,
        laserAnywhere: Boolean,
        viewer: Boolean,
        current: Int,
        total: Int,
        pointer: String,
        theme: String?,
        clock: Clock,
    ) {
        val request = PutDataMapRequest.create(PATH_STATE).apply {
            dataMap.putString(KEY_LINK, link)
            dataMap.putString(KEY_MODE, mode)
            dataMap.putString(KEY_PC, pc)
            dataMap.putBoolean(KEY_RUNNING, running)
            dataMap.putBoolean(KEY_LASER_ANYWHERE, laserAnywhere)
            dataMap.putBoolean(KEY_VIEWER, viewer)
            dataMap.putInt(KEY_CURRENT, current)
            dataMap.putInt(KEY_TOTAL, total)
            dataMap.putString(KEY_POINTER, pointer)
            theme?.let { dataMap.putString(KEY_THEME, it) }
            dataMap.putInt(KEY_DURATION, clock.duration)
            dataMap.putInt(KEY_TIMER_TARGET, clock.target)
            dataMap.putBoolean(KEY_TIMER_RUNNING, clock.running)
            dataMap.putLong(KEY_TIMER_START, clock.start)
            dataMap.putInt(KEY_TIMER_ELAPSED, clock.elapsed)
            dataMap.putLong(KEY_STAMP, System.currentTimeMillis())
        }
        // Urgent: the slide number on the watch follows at once, not with
        // the next batch.
        Wearable.getDataClient(context).putDataItem(request.asPutDataRequest().setUrgent())
            .addOnFailureListener { Log.w(TAG, "State not written: ${it.message}") }
    }
}

/** The talk's length and clock, as the state carries them (WearBridge._clockState). */
private data class Clock(
    val duration: Int = 0,
    val target: Int = 0,
    val running: Boolean = false,
    val start: Long = 0L,
    val elapsed: Int = 0,
)

/**
 * Receives the watch's messages. Declared in the manifest, so the system
 * starts it for a message also while the app is closed.
 */
class WearListenerService : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) = WearRelay.onMessage(this, event)
}
