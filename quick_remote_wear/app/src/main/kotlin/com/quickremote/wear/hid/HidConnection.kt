package com.quickremote.wear.hid

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Registers the watch as a Bluetooth Classic HID device (keyboard, mouse,
 * consumer control) and keeps it connected to a computer. Adapted from the
 * phone's BluetoothHidService.kt; the computer needs no QuickRemote app.
 *
 * Everything runs on the main thread: the profile and HID callbacks are
 * posted there. Android keeps the registration only while the app is in the
 * foreground or runs a foreground service ([HidSessionService]).
 */
// The session starts only once the Bluetooth permissions are granted (ui/Permissions.kt).
@SuppressLint("MissingPermission")
class HidConnection(private val context: Context) {

    private val _state = MutableStateFlow<HidState>(HidState.Off)
    val state: StateFlow<HidState> = _state.asStateFlow()

    private val _hosts = MutableStateFlow<List<Host>>(emptyList())

    /** Bonded computers, the last one used first. */
    val hosts: StateFlow<List<Host>> = _hosts.asStateFlow()

    private val main = Handler(Looper.getMainLooper())
    private val prefs = context.getSharedPreferences("hid", Context.MODE_PRIVATE)
    private val adapter: BluetoothAdapter?
        get() = context.getSystemService(BluetoothManager::class.java)?.adapter

    private var running = false
    private var proxyRequested = false
    private var hid: BluetoothHidDevice? = null
    private var registered = false
    private var registering = false
    private var host: BluetoothDevice? = null

    /** Address of the computer a connect() is waiting for. */
    private var attempt: String? = null
    private var attemptAtMs = 0L

    /** The computer of the attempt answered: a Bluetooth link to it came up. */
    private var attemptReached = false
    private var connectedAtMs = 0L
    private var retries = 0

    /** Which bonded computer the next automatic attempt tries. */
    private var rotation = 0

    /**
     * The computer the watch paired with from its side. Such a computer reads
     * the watch's records (and learns it is a keyboard) only after a while:
     * BlueZ 2 s after a pairing it did not start. Until then it refuses the
     * keyboard, which is not the lasting refusal [HidState.Refused] reports.
     */
    private var pairedAddress: String? = null
    private var pairedAtMs = 0L

    /** Starts the session, or on a repeat call (the app came back) retries at once. */
    fun start() {
        if (running) {
            when {
                hid == null -> if (!proxyRequested) open()
                !registered -> register()
                host == null -> {
                    retries = 0
                    main.removeCallbacks(reconnectRunnable)
                    reconnect()
                }
            }
            return
        }
        running = true
        retries = 0
        rotation = 0
        ContextCompat.registerReceiver(
            context,
            receiver,
            IntentFilter().apply {
                addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
                addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
                addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            },
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        refreshHosts()
        open()
    }

    /** Disconnects, unregisters and ends the session. */
    fun stop() {
        if (!running) return
        running = false
        main.removeCallbacksAndMessages(null)
        context.unregisterReceiver(receiver)
        hid?.let { device ->
            host?.let { device.disconnect(it) }
            if (registered || registering) device.unregisterApp()
            adapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, device)
        }
        // A proxy still on its way is closed when it arrives (profileListener).
        hid = null
        proxyRequested = false
        registered = false
        registering = false
        host = null
        clearAttempt()
        set(HidState.Off)
    }

    /**
     * Connects to the bonded computer at [address], the user's choice.
     * [justPaired]: the watch paired with it a moment ago (PcScanner).
     */
    fun connect(address: String, justPaired: Boolean = false) {
        rememberHost(address)
        refreshHosts()
        retries = 0
        rotation = 0
        main.removeCallbacks(reconnectRunnable)
        if (justPaired) {
            pairedAddress = address
            pairedAtMs = SystemClock.elapsedRealtime()
        }
        val current = host
        if (current?.address == address) return
        // The disconnect reports back and schedules a reconnect, which now
        // tries [address] first.
        if (current != null) hid?.disconnect(current)
        main.postDelayed({
            val device = bonded(address) ?: return@postDelayed
            attempt?.takeIf { it != address }?.let { other -> bonded(other)?.let { hid?.disconnect(it) } }
            clearAttempt()
            tryConnect(device)
        }, if (justPaired) PAIRED_SETTLE_MS else 0L)
    }

    /** Presses and releases [key] under [modifiers]. False when no computer is connected. */
    fun send(modifiers: Int, key: Int): Boolean {
        val device = hid ?: return false
        val target = host ?: return false
        val sent = device.sendReport(target, HidReports.ID_KEYBOARD, HidReports.keyDown(modifiers, key))
        device.sendReport(target, HidReports.ID_KEYBOARD, HidReports.keysUp())
        return sent
    }

    /** Moves the computer's mouse cursor. False when no computer is connected. */
    fun move(dx: Int, dy: Int): Boolean {
        val device = hid ?: return false
        val target = host ?: return false
        return device.sendReport(target, HidReports.ID_MOUSE, HidReports.mouseMove(dx, dy))
    }

    fun refreshHosts() {
        _hosts.value = bondedHosts().map { it.toHost() }
    }

    // ── Profile and registration ─────────────────────────────────────────────

    private fun open() {
        val adapter = adapter ?: return set(HidState.Unsupported)
        if (!adapter.isEnabled) return set(HidState.BluetoothOff)
        set(HidState.Starting)
        if (hid != null) return register()
        if (proxyRequested) return
        if (!adapter.getProfileProxy(context, profileListener, BluetoothProfile.HID_DEVICE)) {
            return set(HidState.Unsupported)
        }
        proxyRequested = true
        main.postDelayed(proxyTimeout, PROXY_TIMEOUT_MS)
    }

    /**
     * A watch without the HID Device profile still hands out a proxy, which
     * then never connects.
     */
    private val proxyTimeout = Runnable {
        if (running && hid == null && adapter?.isEnabled == true) {
            log("HID profile did not connect: unsupported")
            set(HidState.Unsupported)
        }
    }

    private val profileListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile != BluetoothProfile.HID_DEVICE) return
            main.removeCallbacks(proxyTimeout)
            val device = proxy as BluetoothHidDevice
            if (!running || (hid != null && hid !== device)) {
                adapter?.closeProfileProxy(profile, device)
                return
            }
            log("HID profile ready")
            hid = device
            register()
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile != BluetoothProfile.HID_DEVICE) return
            log("HID profile lost")
            hid?.let { adapter?.closeProfileProxy(profile, it) }
            hid = null
            proxyRequested = false
            registered = false
            registering = false
            host = null
            clearAttempt()
            // With Bluetooth on the profile restarted; off, the state receiver
            // opens it again once Bluetooth is back.
            if (running && adapter?.isEnabled == true) open()
        }
    }

    private fun register() {
        val device = hid ?: return
        if (registered || registering) return
        registering = true
        // Android lets one app at a time be a HID device.
        if (!device.registerApp(SDP, null, null, { main.post(it) }, callback)) {
            registering = false
            log("HID registration refused")
            set(HidState.Unavailable)
        }
    }

    private val callback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            registering = false
            this@HidConnection.registered = registered
            if (!running) return
            if (!registered) {
                // Another app took the profile, or Bluetooth is going off (the
                // state receiver reports that). start() registers again when
                // the app comes back.
                log("HID app unregistered")
                host = null
                clearAttempt()
                main.removeCallbacks(reconnectRunnable)
                if (adapter?.isEnabled == true) set(HidState.Unavailable)
                return
            }
            log("HID app registered, last host ${pluggedDevice?.address}")
            val connected = hid?.connectedDevices?.firstOrNull()
            when {
                connected != null -> onConnected(connected)
                pluggedDevice != null -> tryConnect(pluggedDevice)
                else -> reconnect()
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
            log("${device.address}: state $state")
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> onConnected(device)
                BluetoothProfile.STATE_DISCONNECTED -> onDisconnected(device)
            }
        }

        override fun onGetReport(device: BluetoothDevice, type: Byte, id: Byte, bufferSize: Int) {
            hid?.replyReport(device, type, id, ByteArray(bufferSize))
        }
    }

    // ── Connection ───────────────────────────────────────────────────────────

    private fun onConnected(device: BluetoothDevice) {
        host = device
        clearAttempt()
        connectedAtMs = SystemClock.elapsedRealtime()
        // retries is reset only once the link has held (onDisconnected).
        main.removeCallbacks(reconnectRunnable)
        rememberHost(device.address)
        refreshHosts()
        set(HidState.Connected(device.toHost()))
    }

    private fun onDisconnected(device: BluetoothDevice) {
        val wasHost = host?.address == device.address
        // Android reports a failed attempt more than once.
        if (!wasHost && attempt != device.address) return
        val now = SystemClock.elapsedRealtime()
        // A computer that answered but did not take the keyboard refused it;
        // one that is off or away never answers. On a Galaxy Watch6 both end
        // 3-6 s after connect(), so only a link that came and went at once
        // (already up, or dropped right after connecting) is told by time.
        val since = if (wasHost) connectedAtMs else attemptAtMs
        val refused = (!wasHost && attemptReached) || now - since < REFUSED_WITHIN_MS
        val justPaired = device.address == pairedAddress && now - pairedAtMs < PAIRED_GRACE_MS
        clearAttempt()
        if (wasHost) {
            host = null
        } else {
            // The HID service can stay "connecting" after a refusal.
            hid?.disconnect(device)
        }
        if (refused && justPaired) {
            log("${device.address} refused the keyboard right after pairing, retrying")
            retries = 0
        } else if (refused) {
            log("${device.address} refused the keyboard")
            // Retry every 8 s at most, so a computer paired again connects soon.
            retries = retries.coerceAtMost(2)
            set(HidState.Refused(device.toHost()))
        } else if (wasHost) {
            retries = 0
            set(HidState.Waiting(null))
        }
        scheduleReconnect()
    }

    private fun tryConnect(device: BluetoothDevice) {
        val hid = hid ?: return
        if (!running || !registered || host != null) return
        // An attempt is still running; its result schedules the next one.
        if (attempt != null) return
        attempt = device.address
        attemptAtMs = SystemClock.elapsedRealtime()
        attemptReached = false
        if (!hid.connect(device)) {
            log("connect(${device.address}) failed at once")
            clearAttempt()
            scheduleReconnect()
            return
        }
        // A refused computer stays reported as refused while it is retried.
        val current = _state.value
        if (current !is HidState.Refused || current.host.address != device.address) {
            set(HidState.Waiting(device.toHost()))
        }
        main.postDelayed(attemptTimeout, ATTEMPT_TIMEOUT_MS)
    }

    /** No state callback came for the attempt: take it as failed. */
    private val attemptTimeout = Runnable {
        val address = attempt ?: return@Runnable
        if (host != null) return@Runnable
        log("connect($address) timed out")
        val device = bonded(address)
        if (device != null) {
            onDisconnected(device)
        } else {
            clearAttempt()
            scheduleReconnect()
        }
    }

    private fun clearAttempt() {
        attempt = null
        attemptAtMs = 0L
        attemptReached = false
        main.removeCallbacks(attemptTimeout)
    }

    /**
     * Tries the bonded computers in turn, the last used first. Without one it
     * waits: a computer that pairs with the watch connects by itself.
     */
    private fun reconnect() {
        if (!running || !registered || host != null) return
        val candidates = bondedHosts()
        if (candidates.isEmpty()) return set(HidState.Waiting(null))
        val justPaired = candidates.find {
            it.address == pairedAddress && SystemClock.elapsedRealtime() - pairedAtMs < PAIRED_GRACE_MS
        }
        tryConnect(justPaired ?: candidates[rotation++ % candidates.size])
    }

    private val reconnectRunnable = Runnable { reconnect() }

    /** Every 2, 4, 8, 16, then 32 s: the remote keeps trying while it is open. */
    private fun scheduleReconnect() {
        if (!running || host != null) return
        main.removeCallbacks(reconnectRunnable)
        main.postDelayed(reconnectRunnable, BASE_RETRY_MS shl retries.coerceAtMost(4))
        retries++
    }

    // ── Hosts ────────────────────────────────────────────────────────────────

    /**
     * Bonded computers and anything the watch was a keyboard for before. The
     * phone, headphones and cars are never HID hosts, and connecting to one
     * as a keyboard would send it our key presses.
     */
    private fun bondedHosts(): List<BluetoothDevice> {
        val adapter = adapter?.takeIf { it.isEnabled } ?: return emptyList()
        val known = prefs.getStringSet(KEY_HOSTS, null).orEmpty()
        val last = prefs.getString(KEY_LAST_HOST, null)
        return adapter.bondedDevices.orEmpty()
            .filter {
                it.address in known ||
                    it.bluetoothClass?.majorDeviceClass == BluetoothClass.Device.Major.COMPUTER
            }
            .sortedWith(compareByDescending<BluetoothDevice> { it.address == last }.thenBy { it.label() })
    }

    private fun bonded(address: String): BluetoothDevice? =
        adapter?.bondedDevices.orEmpty().find { it.address == address }

    private fun rememberHost(address: String) {
        val known = prefs.getStringSet(KEY_HOSTS, null).orEmpty()
        prefs.edit {
            putString(KEY_LAST_HOST, address)
            putStringSet(KEY_HOSTS, known + address)
        }
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothAdapter.ACTION_STATE_CHANGED ->
                    when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
                        BluetoothAdapter.STATE_ON -> if (running) {
                            refreshHosts()
                            open()
                        }
                        BluetoothAdapter.STATE_TURNING_OFF, BluetoothAdapter.STATE_OFF -> {
                            host = null
                            registered = false
                            registering = false
                            clearAttempt()
                            main.removeCallbacks(reconnectRunnable)
                            set(HidState.BluetoothOff)
                        }
                    }
                BluetoothDevice.ACTION_BOND_STATE_CHANGED -> refreshHosts()
                BluetoothDevice.ACTION_ACL_CONNECTED -> {
                    val device = intent.bluetoothDevice() ?: return
                    if (device.address == attempt) attemptReached = true
                }
                // The end of an attempt the HID service never reports.
                BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                    val device = intent.bluetoothDevice() ?: return
                    if (device.address == attempt && host == null) onDisconnected(device)
                }
            }
        }
    }

    private fun set(state: HidState) {
        _state.value = state
    }

    private fun BluetoothDevice.toHost() = Host(address, label())

    companion object {
        private const val TAG = "QuickRemoteHid"
        private const val KEY_LAST_HOST = "last_host"
        private const val KEY_HOSTS = "hosts"
        private const val PROXY_TIMEOUT_MS = 5_000L
        private const val REFUSED_WITHIN_MS = 3_000L
        private const val ATTEMPT_TIMEOUT_MS = 15_000L
        private const val BASE_RETRY_MS = 2_000L
        private const val PAIRED_SETTLE_MS = 4_000L
        private const val PAIRED_GRACE_MS = 20_000L

        private val SDP = BluetoothHidDeviceAppSdpSettings(
            "QuickRemote",
            "QuickRemote Watch",
            "QuickRemote",
            BluetoothHidDevice.SUBCLASS1_COMBO,
            HidReports.DESCRIPTOR,
        )

        private fun log(message: String) = Log.d(TAG, message)
    }
}

/** The name the user gave the device, else its own, else its address. */
@SuppressLint("MissingPermission")
fun BluetoothDevice.label(): String = alias ?: name ?: address

/** The device a Bluetooth broadcast is about. */
fun Intent.bluetoothDevice(): BluetoothDevice? =
    IntentCompat.getParcelableExtra(this, BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
