package com.quickremote.wear.phone

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.CapabilityInfo
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import com.quickremote.wear.remote.WireCommands
import com.quickremote.wear.ui.theme.WearTheme
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * The watch's only way to the computer: the phone app, over the Wearable
 * Data Layer. The phone holds the connection to the computer (over Wi-Fi, or
 * as its Bluetooth keyboard) and passes the watch's commands on as if they
 * were pressed on its own screen; the watch pairs with nothing.
 *
 * The phone's state is a DataItem (the last value, synced by the system, also
 * after the two were apart), commands and laser movement are messages (sent
 * now or not at all). Runs while the remote is on screen ([start], [stop]);
 * everything happens on the main thread.
 */
class PhoneLink(context: Context) :
    DataClient.OnDataChangedListener,
    MessageClient.OnMessageReceivedListener,
    CapabilityClient.OnCapabilityChangedListener {

    private val context = context.applicationContext
    private val data = Wearable.getDataClient(this.context)
    private val messages = Wearable.getMessageClient(this.context)
    private val capabilities = Wearable.getCapabilityClient(this.context)
    private val handler = Handler(Looper.getMainLooper())

    private var started = false
    private var users = 0

    /** The phone's node, while it is in reach. */
    private var node: String? = null
    private var phoneName: String? = null
    private var reachable: Boolean? = null
    private var report: PhoneReport? = null

    /** States the phone has written since the listener started. */
    private var changes = 0

    /** Hellos sent since the phone last wrote its state. */
    private var unanswered = 0

    private val _state = MutableStateFlow<PhoneState>(PhoneState.Checking)
    val state: StateFlow<PhoneState> = _state.asStateFlow()

    private val _theme = MutableStateFlow(WearTheme.stored(this.context))

    /**
     * The color theme: the stored one, replaced and stored when the phone
     * names another, and kept while the phone is away or names none.
     */
    val theme: StateFlow<WearTheme> = _theme.asStateFlow()

    private val _events = MutableSharedFlow<LinkEvent>(extraBufferCapacity = 8)
    val events: SharedFlow<LinkEvent> = _events.asSharedFlow()

    /**
     * Starts listening to the phone. Called by the remote while it is on
     * screen and by [com.quickremote.wear.PresentingService] while a show
     * runs; it listens until both have called [stop].
     */
    fun start() {
        users++
        if (started) return
        started = true
        data.addListener(this, STATE_URI, DataClient.FILTER_LITERAL)
        messages.addListener(this)
        capabilities.addListener(this, WearProtocol.CAPABILITY)
        if (awake) laserScreen(true)
        // The state from before the watch last looked, shown until the phone
        // answers the hello: the remote opens at once. The newest one: there
        // can be several (an old copy from another node), and the first was
        // one with an old talk clock (it showed the time from a show that had
        // ended). Not over one the phone has written meanwhile.
        val asked = changes
        data.getDataItems(STATE_URI, DataClient.FILTER_LITERAL).addOnSuccessListener { items ->
            try {
                if (Log.isLoggable(TAG, Log.DEBUG)) Log.d(TAG, "Stored states: ${items.count}")
                if (changes == asked) {
                    items.maxByOrNull { DataMapItem.fromDataItem(it).dataMap.getLong(WearProtocol.KEY_STAMP, 0L) }
                        ?.let { report = read(it) }
                }
            } finally {
                items.release()
            }
            publish()
        }
        refresh()
    }

    fun stop() {
        if (users > 0) users--
        if (!started || users > 0) return
        laserUp()
        started = false
        direct.close()
        handler.removeCallbacksAndMessages(null)
        data.removeListener(this)
        messages.removeListener(this)
        capabilities.removeListener(this)
    }

    /** Looks for the phone again and asks it for its state. */
    fun refresh() {
        unanswered = 0
        capabilities.getCapability(WearProtocol.CAPABILITY, CapabilityClient.FILTER_REACHABLE)
            .addOnSuccessListener { onNodes(it.nodes, asked = true) }
            // No Play services, or no phone was ever set up.
            .addOnFailureListener { onNodes(emptySet(), asked = true) }
    }

    override fun onCapabilityChanged(info: CapabilityInfo) = onNodes(info.nodes, asked = false)

    private fun onNodes(nodes: Set<Node>, asked: Boolean) {
        val phone = nodes.firstOrNull { it.isNearby } ?: nodes.firstOrNull()
        val changed = phone?.id != node
        node = phone?.id
        phoneName = phone?.displayName
        reachable = phone != null
        Log.d(TAG, "Phone: ${phone?.displayName ?: "none"}")
        // A phone that came into reach may have changed since its last report.
        if (phone != null && (changed || asked)) {
            unanswered = 0
            hello()
        }
        publish()
    }

    private val helloAgain = Runnable { hello() }

    /**
     * Asks the phone to write its state. A phone whose app was killed left
     * "connected" behind; its listener service answers "closed". Repeated
     * until the answer comes.
     */
    private fun hello() {
        handler.removeCallbacks(helloAgain)
        val to = node ?: return
        if (!started) return
        unanswered++
        messages.sendMessage(to, WearProtocol.PATH_HELLO, EMPTY)
        publish()
        handler.postDelayed(helloAgain, HELLO_RETRY_MS)
    }

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.dataItem.uri.path != WearProtocol.PATH_STATE) continue
            changes++
            report = if (event.type == DataEvent.TYPE_CHANGED) read(event.dataItem) else null
            if (Log.isLoggable(TAG, Log.DEBUG)) Log.d(TAG, "State: $report")
            unanswered = 0
            handler.removeCallbacks(helloAgain)
        }
        publish()
    }

    private fun read(item: DataItem): PhoneReport {
        val map = DataMapItem.fromDataItem(item).dataMap
        return PhoneReport(
            link = map.getString(WearProtocol.KEY_LINK, ""),
            pc = map.getString(WearProtocol.KEY_PC, ""),
            show = if (map.getString(WearProtocol.KEY_MODE, "") == WearProtocol.MODE_BLUETOOTH) {
                null
            } else {
                Show(
                    running = map.getBoolean(WearProtocol.KEY_RUNNING, false),
                    current = map.getInt(WearProtocol.KEY_CURRENT, 0),
                    total = map.getInt(WearProtocol.KEY_TOTAL, 0),
                    laserAnywhere = map.getBoolean(WearProtocol.KEY_LASER_ANYWHERE, false),
                )
            },
            pointer = Pointer.of(map.getString(WearProtocol.KEY_POINTER)),
            theme = map.getString(WearProtocol.KEY_THEME),
            duration = if (map.containsKey(WearProtocol.KEY_DURATION)) map.getInt(WearProtocol.KEY_DURATION) else null,
            clock = if (map.containsKey(WearProtocol.KEY_TIMER_TARGET)) {
                TalkClock(
                    target = map.getInt(WearProtocol.KEY_TIMER_TARGET),
                    running = map.getBoolean(WearProtocol.KEY_TIMER_RUNNING),
                    startedAt = map.getLong(WearProtocol.KEY_TIMER_START),
                    elapsed = map.getInt(WearProtocol.KEY_TIMER_ELAPSED),
                )
            } else {
                null
            },
        )
    }

    private fun publish() {
        _state.value = PhoneState.of(reachable, report, silent = unanswered > SILENT_AFTER)
        val theme = WearTheme.ofWire(report?.theme)
        if (theme != null && theme != _theme.value) {
            WearTheme.store(context, theme)
            _theme.value = theme
        }
    }

    override fun onMessageReceived(event: MessageEvent) {
        when (event.path) {
            WearProtocol.PATH_ERROR -> _events.tryEmit(LinkEvent.PcError(String(event.data, Charsets.UTF_8)))
            WearProtocol.PATH_ALERT ->
                TimerAlert.parse(String(event.data, Charsets.UTF_8))?.let { _events.tryEmit(LinkEvent.Timer(it)) }
            WearProtocol.PATH_PONG -> onPong(event.data)
            WearProtocol.PATH_MOVED -> onMoved()
        }
    }

    /** Sends [command] to the computer. False when there is no computer to send it to. */
    fun send(command: String): Boolean {
        val to = node
        if (to == null || _state.value !is PhoneState.Connected) return false
        messages.sendMessage(to, WearProtocol.PATH_COMMAND, command.toByteArray(Charsets.UTF_8))
            .addOnFailureListener {
                Log.w(TAG, "$command not sent: ${it.message}")
                _events.tryEmit(LinkEvent.NotSent)
                refresh()
            }
        return true
    }

    /** The talk's length picked here, in seconds (0: none): the phone keeps it and its timer takes it. */
    fun setDuration(seconds: Int): Boolean {
        val to = node
        if (to == null || _state.value !is PhoneState.Connected) return false
        messages.sendMessage(to, WearProtocol.PATH_DURATION, seconds.toString().toByteArray(Charsets.UTF_8))
            .addOnFailureListener {
                Log.w(TAG, "Duration not sent: ${it.message}")
                _events.tryEmit(LinkEvent.NotSent)
            }
        return true
    }

    /** Brings QuickRemote to the front on the phone. */
    fun openOnPhone() {
        val intent = Intent(Intent.ACTION_VIEW)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .setData(WearProtocol.OPEN_URI.toUri())
        val opening = RemoteActivityHelper(context).startRemoteActivity(intent, node)
        opening.addListener(
            {
                try {
                    opening.get()
                } catch (e: Exception) {
                    Log.w(TAG, "Not opened on the phone: ${e.message}")
                    _events.tryEmit(LinkEvent.NotSent)
                }
            },
            ContextCompat.getMainExecutor(context),
        )
    }

    // ── Laser ──────────────────────────────────────────────────────────────

    private val mover = MoveSender(MOVE_INTERVAL_MS, MOVES_ON_THEIR_WAY, MOVE_LOST_MS)
    private var laser = false
    private var movedAtMs = 0L

    /**
     * The laser screen is open. An idle link to the phone sleeps (measured:
     * the first messages of a touch took 760 ms there and back, and 2 s to
     * come down to 80), so while the screen is open a ping every
     * [AWAKE_INTERVAL_MS] keeps it awake for the touch to come. The watch's
     * own socket to the phone ([DirectLink]) is open for as long, when the
     * watch may use Bluetooth; call again when that permission was given.
     */
    fun laserScreen(open: Boolean) {
        awake = open
        handler.removeCallbacks(keepAwake)
        if (open && started) {
            handler.post(keepAwake)
            direct.open(phoneName)
        } else {
            direct.close()
        }
    }

    /** Whether the watch may open its own socket to the phone. */
    val directPermitted: Boolean get() = direct.permitted()

    private val direct = DirectLink(context, onMoved = { onMoved() }, onPong = { onPong(it) })

    /** Movement goes over the watch's own socket while there is one, else as a message. */
    private fun sendMove(to: String, bytes: ByteArray, answered: Boolean) {
        if (direct.connected) {
            direct.move(bytes)
        } else {
            val sending = messages.sendMessage(to, WearProtocol.PATH_MOVE, bytes)
            if (answered) sending.addOnFailureListener { onMoved() }
        }
    }

    private var awake = false
    private val keepAwake = object : Runnable {
        override fun run() {
            val to = node
            if (to != null) {
                val bytes = ByteBuffer.allocate(8).putLong(SystemClock.elapsedRealtimeNanos()).array()
                if (direct.connected) direct.ping(bytes) else messages.sendMessage(to, WearProtocol.PATH_PING, bytes)
            }
            handler.postDelayed(this, AWAKE_INTERVAL_MS)
        }
    }

    /** The finger touched the laser screen. False when there is no computer. */
    fun laserDown(): Boolean {
        if (laser) return true
        if (!send(WireCommands.MODE_LASER)) return false
        laser = true
        mover.reset()
        movedAtMs = SystemClock.uptimeMillis()
        handler.postDelayed(keepAlive, KEEP_ALIVE_MS)
        probe.start()
        return true
    }

    /** The finger moved, in the computer's cursor units. */
    fun laserMove(dx: Float, dy: Float) {
        if (!laser) return
        mover.add(dx, dy)
        pump()
    }

    fun laserUp() {
        if (!laser) return
        laser = false
        handler.removeCallbacks(pumpLater)
        handler.removeCallbacks(keepAlive)
        probe.stop()
        // The rest of the movement before the laser goes out, as on the phone.
        val to = node
        if (to != null) mover.rest()?.let { (dx, dy) -> sendMove(to, moveBytes(dx, dy), answered = false) }
        send(WireCommands.LASER_OFF)
        send(WireCommands.MODE_ARROW)
    }

    private val pumpLater = Runnable { pump() }

    private fun pump() {
        handler.removeCallbacks(pumpLater)
        val to = node ?: return
        val now = SystemClock.uptimeMillis()
        val step = mover.take(now)
        if (step == null) {
            // Waiting for the interval or for a lost answer; an answer pumps
            // when it lands.
            mover.waitMs(now)?.let { handler.postDelayed(pumpLater, it) }
            return
        }
        movedAtMs = now
        probe.moves++
        // The sender counts the phone's answers, not this Task: it completes
        // when the message is queued, and messages queued faster than the
        // link carries them arrive seconds late.
        sendMove(to, moveBytes(step.first, step.second), answered = true)
    }

    /** The phone has a movement (or it could not be sent): the next may go. */
    private fun onMoved() {
        mover.delivered()
        if (laser) pump()
    }

    /**
     * The phone puts the laser away when the watch falls silent (out of
     * reach with the finger down), so a finger held still says it is there.
     */
    private val keepAlive = object : Runnable {
        override fun run() {
            val to = node
            if (!laser || to == null) return
            if (SystemClock.uptimeMillis() - movedAtMs >= KEEP_ALIVE_MS) {
                sendMove(to, moveBytes(0f, 0f), answered = false)
            }
            handler.postDelayed(this, KEEP_ALIVE_MS)
        }
    }

    private fun moveBytes(dx: Float, dy: Float): ByteArray =
        ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).putFloat(dx).putFloat(dy).array()

    // ── Measuring the link ─────────────────────────────────────────────────

    /**
     * While the laser is on and `adb shell setprop log.tag.QuickRemoteLink DEBUG`
     * is set: logs the round trip of each [keepAwake] ping, then the
     * gesture's message rate. A queue building up on the way shows as a
     * growing round trip.
     */
    private val probe = Probe()

    private inner class Probe {
        var moves = 0
        private var on = false
        private var startedAtMs = 0L
        private val trips = mutableListOf<Long>()

        fun start() {
            on = Log.isLoggable(TAG, Log.DEBUG)
            if (!on) return
            moves = 0
            trips.clear()
            startedAtMs = SystemClock.uptimeMillis()
        }

        fun pong(sentAtNanos: Long) {
            if (!on) return
            val ms = (SystemClock.elapsedRealtimeNanos() - sentAtNanos) / 1_000_000
            trips += ms
            Log.d(TAG, "Round trip to the phone: $ms ms")
        }

        fun stop() {
            if (!on) return
            on = false
            val seconds = (SystemClock.uptimeMillis() - startedAtMs) / 1000f
            val sorted = trips.sorted()
            Log.d(
                TAG,
                "Laser gesture (${if (direct.connected) "direct" else "messages"}): %.1f s, %d moves (%.1f/s), round trip median %d ms, max %d ms (%d pings)".format(
                    seconds,
                    moves,
                    if (seconds > 0) moves / seconds else 0f,
                    sorted.getOrElse(sorted.size / 2) { -1 },
                    sorted.lastOrNull() ?: -1,
                    sorted.size,
                ),
            )
        }
    }

    private fun onPong(data: ByteArray) {
        if (data.size == 8) probe.pong(ByteBuffer.wrap(data).long)
    }

    private companion object {
        const val TAG = "QuickRemoteLink"
        val STATE_URI: Uri = "wear://*${WearProtocol.PATH_STATE}".toUri()
        val EMPTY = ByteArray(0)

        const val HELLO_RETRY_MS = 3_000L

        /** Two hellos went unanswered: the phone counts as out of reach. */
        const val SILENT_AFTER = 2

        /** At most 40 movement messages a second, about the phone's own touchpad. */
        const val MOVE_INTERVAL_MS = 25L

        /**
         * Movements that may wait for the phone's answer at once. One made
         * the rate one per round trip (measured 86 ms: 15 a second, visibly
         * in steps); more than a few is a queue again when the link slows.
         */
        const val MOVES_ON_THEIR_WAY = 4

        /** No answer to a movement for this long: it or its answer is lost. */
        const val MOVE_LOST_MS = 500L
        const val KEEP_ALIVE_MS = 1_000L
        const val AWAKE_INTERVAL_MS = 200L
    }
}
