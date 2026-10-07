package com.quickremote.quick_remote_app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.util.Log
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executor

/**
 * BluetoothHidService — registers the Android phone as a Bluetooth Classic HID device
 * (keyboard + mouse + consumer control). Bridges to Flutter via MethodChannel in MainActivity.
 *
 * Requires API 28+ (Android 9).
 */
@SuppressLint("MissingPermission")
class BluetoothHidService(private val context: Context) {

    companion object {
        private const val TAG = "BluetoothHidService"

        // ── Report IDs ────────────────────────────────────────────────────────
        const val REPORT_ID_KEYBOARD: Byte = 1
        const val REPORT_ID_MOUSE: Byte = 2
        const val REPORT_ID_CONSUMER: Byte = 3

        // ── HID Usage / Key codes ─────────────────────────────────────────────
        // Keyboard modifier bits
        const val MOD_LCTRL: Int = 0x01
        const val MOD_LSHIFT: Int = 0x02
        const val MOD_LALT: Int = 0x04
        const val MOD_LGUI: Int = 0x08  // Win key

        // HID key codes
        const val KEY_A: Int = 0x04
        const val KEY_B: Int = 0x05
        const val KEY_E: Int = 0x08
        const val KEY_I: Int = 0x0C
        const val KEY_L: Int = 0x0F
        const val KEY_P: Int = 0x13
        const val KEY_W: Int = 0x1A
        const val KEY_F5: Int = 0x3E
        const val KEY_ESCAPE: Int = 0x29
        const val KEY_RETURN: Int = 0x28
        const val KEY_PAGE_UP: Int = 0x4B
        const val KEY_PAGE_DOWN: Int = 0x4E
        const val KEY_HOME: Int = 0x4A
        const val KEY_END_KEY: Int = 0x4D

        // Consumer control usage IDs (16-bit)
        const val CONSUMER_VOLUME_UP: Int = 0x00E9
        const val CONSUMER_VOLUME_DOWN: Int = 0x00EA
        const val CONSUMER_MUTE: Int = 0x00E2
        const val CONSUMER_PLAY_PAUSE: Int = 0x00CD
        const val CONSUMER_NEXT_TRACK: Int = 0x00B5
        const val CONSUMER_PREV_TRACK: Int = 0x00B6
        const val CONSUMER_STOP: Int = 0x00B7

        // Mouse buttons
        const val MOUSE_BUTTON_LEFT: Int = 0x01
        const val MOUSE_BUTTON_RIGHT: Int = 0x02
        const val MOUSE_BUTTON_MIDDLE: Int = 0x04

        // ── HID Report Descriptor ─────────────────────────────────────────────
        // Keyboard (Report ID 1) + Mouse (Report ID 2) + Consumer (Report ID 3)
        val HID_REPORT_DESCRIPTOR: ByteArray = byteArrayOf(
            // ── Keyboard ──────────────────────────────────────────────────────
            0x05.toByte(), 0x01.toByte(),  // Usage Page (Generic Desktop)
            0x09.toByte(), 0x06.toByte(),  // Usage (Keyboard)
            0xA1.toByte(), 0x01.toByte(),  // Collection (Application)
            0x85.toByte(), REPORT_ID_KEYBOARD, //   Report ID (1)
            0x05.toByte(), 0x07.toByte(),  //   Usage Page (Key Codes)
            0x19.toByte(), 0xE0.toByte(),  //   Usage Minimum (224 = Left Control)
            0x29.toByte(), 0xE7.toByte(),  //   Usage Maximum (231 = Right GUI)
            0x15.toByte(), 0x00.toByte(),  //   Logical Minimum (0)
            0x25.toByte(), 0x01.toByte(),  //   Logical Maximum (1)
            0x75.toByte(), 0x01.toByte(),  //   Report Size (1)
            0x95.toByte(), 0x08.toByte(),  //   Report Count (8) — modifier bits
            0x81.toByte(), 0x02.toByte(),  //   Input (Data, Variable, Absolute)
            0x95.toByte(), 0x01.toByte(),  //   Report Count (1)
            0x75.toByte(), 0x08.toByte(),  //   Report Size (8) — reserved byte
            0x81.toByte(), 0x01.toByte(),  //   Input (Constant)
            0x95.toByte(), 0x06.toByte(),  //   Report Count (6) — key array
            0x75.toByte(), 0x08.toByte(),  //   Report Size (8)
            0x15.toByte(), 0x00.toByte(),  //   Logical Minimum (0)
            0x25.toByte(), 0x65.toByte(),  //   Logical Maximum (101)
            0x05.toByte(), 0x07.toByte(),  //   Usage Page (Key Codes)
            0x19.toByte(), 0x00.toByte(),  //   Usage Minimum (0)
            0x29.toByte(), 0x65.toByte(),  //   Usage Maximum (101)
            0x81.toByte(), 0x00.toByte(),  //   Input (Data, Array)
            0xC0.toByte(),                 // End Collection

            // ── Mouse ─────────────────────────────────────────────────────────
            0x05.toByte(), 0x01.toByte(),  // Usage Page (Generic Desktop)
            0x09.toByte(), 0x02.toByte(),  // Usage (Mouse)
            0xA1.toByte(), 0x01.toByte(),  // Collection (Application)
            0x09.toByte(), 0x01.toByte(),  //   Usage (Pointer)
            0xA1.toByte(), 0x00.toByte(),  //   Collection (Physical)
            0x85.toByte(), REPORT_ID_MOUSE, //    Report ID (2)
            0x05.toByte(), 0x09.toByte(),  //     Usage Page (Buttons)
            0x19.toByte(), 0x01.toByte(),  //     Usage Minimum (1)
            0x29.toByte(), 0x03.toByte(),  //     Usage Maximum (3)
            0x15.toByte(), 0x00.toByte(),  //     Logical Minimum (0)
            0x25.toByte(), 0x01.toByte(),  //     Logical Maximum (1)
            0x95.toByte(), 0x03.toByte(),  //     Report Count (3)
            0x75.toByte(), 0x01.toByte(),  //     Report Size (1)
            0x81.toByte(), 0x02.toByte(),  //     Input (Data, Variable, Absolute)
            0x95.toByte(), 0x01.toByte(),  //     Report Count (1)
            0x75.toByte(), 0x05.toByte(),  //     Report Size (5) — padding
            0x81.toByte(), 0x01.toByte(),  //     Input (Constant)
            0x05.toByte(), 0x01.toByte(),  //     Usage Page (Generic Desktop)
            0x09.toByte(), 0x30.toByte(),  //     Usage (X)
            0x09.toByte(), 0x31.toByte(),  //     Usage (Y)
            0x15.toByte(), 0x81.toByte(),  //     Logical Minimum (-127)
            0x25.toByte(), 0x7F.toByte(),  //     Logical Maximum (127)
            0x75.toByte(), 0x08.toByte(),  //     Report Size (8)
            0x95.toByte(), 0x02.toByte(),  //     Report Count (2)
            0x81.toByte(), 0x06.toByte(),  //     Input (Data, Variable, Relative)
            0xC0.toByte(),                 //   End Collection
            0xC0.toByte(),                 // End Collection

            // ── Consumer Control ──────────────────────────────────────────────
            0x05.toByte(), 0x0C.toByte(),  // Usage Page (Consumer)
            0x09.toByte(), 0x01.toByte(),  // Usage (Consumer Control)
            0xA1.toByte(), 0x01.toByte(),  // Collection (Application)
            0x85.toByte(), REPORT_ID_CONSUMER, // Report ID (3)
            0x15.toByte(), 0x00.toByte(),  //   Logical Minimum (0)
            0x26.toByte(), 0xFF.toByte(), 0x03.toByte(), // Logical Maximum (1023)
            0x19.toByte(), 0x00.toByte(),  //   Usage Minimum (0)
            0x2A.toByte(), 0xFF.toByte(), 0x03.toByte(), // Usage Maximum (1023)
            0x75.toByte(), 0x10.toByte(),  //   Report Size (16)
            0x95.toByte(), 0x01.toByte(),  //   Report Count (1)
            0x81.toByte(), 0x00.toByte(),  //   Input (Data, Array)
            0xC0.toByte()                  // End Collection
        )

        // SDP settings for HID device registration
        val SDP_SETTINGS = BluetoothHidDeviceAppSdpSettings(
            "QuickRemote",
            "QuickRemote BT Controller",
            "QuickRemote",
            BluetoothHidDevice.SUBCLASS1_COMBO,
            HID_REPORT_DESCRIPTOR
        )
    }

    // ── State ─────────────────────────────────────────────────────────────────
    
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var hidDevice: BluetoothHidDevice? = null
    private var connectedHost: BluetoothDevice? = null
    private var isRegistered = false

    /** True while the user explicitly wants BT HID active. */
    private var isAdvertisingRequested = false

    /**
     * Callback to Flutter: "connected:<name>" | "disconnected" | "unsupported" |
     * "target:<name>" (the computer being tried) | "refreshing" |
     * "host_unaware" | "error:<msg>"
     */
    var onStateChanged: ((String) -> Unit)? = null

    // ── Auto-reconnect ───────────────────────────────────────────────────────

    private var lastConnectedAddress: String? = null
    private var reconnectHandler: android.os.Handler? = null
    private var reconnectAttempt = 0
    private val baseReconnectDelayMs = 2000L

    // ── Refused by the host ──────────────────────────────────────────────────
    // A computer paired while our HID record was not registered refuses the
    // keyboard: BlueZ drops it at once ("Could not parse HID SDP record") or
    // refuses it ("unknown device"), and only the computer can read our SDP
    // records again. QuickRemote PC does that when we connect to its repair
    // service (BtHidRepair in the shared package); without it the user has to,
    // and Flutter shows how ("host_unaware").
    private var repairUuid: UUID? = null
    private var connectAttemptAtMs = 0L
    private var connectedAtMs = 0L
    private var repairRequestedAtMs = 0L
    /** QuickRemote PC took the repair request; it is not sent again this session. */
    private var repairDelivered = false
    /** Paging a computer that is off or away takes 5 s or more; a refusal comes at once. */
    private val refusedWithinMs = 3000L
    /** An attempt older than this is taken as lost (no state callback came). */
    private val attemptTimeoutMs = 15000L
    /** Refusals this soon after a delivered request mean the PC is still reading our records. */
    private val repairGraceMs = 15000L
    /** Without QuickRemote PC the request is repeated this often, in case it gets started. */
    private val repairRetryMs = 30000L

    private val prefs by lazy {
        context.getSharedPreferences("bt_hid_prefs", Context.MODE_PRIVATE)
    }

    private fun saveLastDevice(address: String) {
        lastConnectedAddress = address
        prefs.edit().putString("last_device_address", address).apply()
    }

    private fun loadLastDevice(): String? {
        lastConnectedAddress = prefs.getString("last_device_address", null)
        return lastConnectedAddress
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /** Returns true if BluetoothHidDevice profile is available on this device. */
    fun isSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val mgr = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            ?: return false
        return mgr.adapter != null
    }

    /**
     * Registers the phone as a HID device (which publishes our SDP record) and
     * connects to the last host. Making the phone visible to a computer that
     * searches for devices is a separate request (MainActivity). [repairUuid]
     * is the service QuickRemote PC offers to read our records again.
     */
    fun startAdvertising(repairUuid: String?) {
        if (!isSupported()) {
            onStateChanged?.invoke("unsupported")
            return
        }
        // A repeat call (app resume) keeps the counters: one repair request
        // per session.
        if (!isAdvertisingRequested) {
            reconnectAttempt = 0
            repairRequestedAtMs = 0L
            repairDelivered = false
        }
        this.repairUuid = repairUuid?.let { UUID.fromString(it) }
        isAdvertisingRequested = true
        loadLastDevice()

        val mgr = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = mgr.adapter

        if (bluetoothAdapter?.isEnabled != true) {
            onStateChanged?.invoke("error:bluetooth_disabled")
            return
        }

        if (reconnectHandler == null) {
            reconnectHandler = android.os.Handler(android.os.Looper.getMainLooper())
        }

        if (hidDevice != null) {
            if (isRegistered) {
                Log.d(TAG, "HID already registered, attempting reconnect")
                tryReconnectToLastDevice()
            } else {
                // Android dropped the registration while the app was in the
                // background (see onAppStatusChanged).
                registerOrReport()
            }
            return
        }

        bluetoothAdapter!!.getProfileProxy(context, profileListener, BluetoothProfile.HID_DEVICE)
    }

    /** Disconnect from host and unregister HID app. */
    fun stopAdvertising() {
        isAdvertisingRequested = false
        cancelReconnect()

        val hid = hidDevice
        connectedHost?.let { host ->
            hid?.disconnect(host)
        }
        hid?.unregisterApp()
        // Close before dropping the reference: closeProfileProxy(…, null) is a
        // no-op, which leaked one profile proxy per stop.
        if (hid != null) {
            bluetoothAdapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, hid)
        }
        hidDevice = null
        connectedHost = null
        isRegistered = false
    }

    /** Send a keyboard report: modifier byte + up-to-6 key codes. */
    fun sendKeyReport(modifier: Int, keyCodes: List<Int>) {
        val host = connectedHost ?: return
        val dev = hidDevice ?: return
        val report = ByteArray(8)
        report[0] = modifier.toByte()
        report[1] = 0  // reserved
        keyCodes.take(6).forEachIndexed { i, code -> report[2 + i] = code.toByte() }
        dev.sendReport(host, REPORT_ID_KEYBOARD.toInt(), report)
        // Key up
        dev.sendReport(host, REPORT_ID_KEYBOARD.toInt(), ByteArray(8))
    }

    /** Send a mouse movement/button report (relative). dx/dy clamped to -127..127. */
    fun sendMouseReport(buttons: Int, dx: Int, dy: Int) {
        val host = connectedHost ?: return
        val dev = hidDevice ?: return
        val report = ByteArray(3)
        report[0] = buttons.toByte()
        report[1] = dx.coerceIn(-127, 127).toByte()
        report[2] = dy.coerceIn(-127, 127).toByte()
        dev.sendReport(host, REPORT_ID_MOUSE.toInt(), report)
    }

    /** Send a mouse click (down then up). */
    fun sendMouseClick(button: Int) {
        sendMouseReport(button, 0, 0)
        sendMouseReport(0, 0, 0)
    }

    /** Send a consumer control (volume, media) report. */
    fun sendConsumerReport(usageId: Int) {
        val host = connectedHost ?: return
        val dev = hidDevice ?: return
        val report = ByteArray(2)
        report[0] = (usageId and 0xFF).toByte()
        report[1] = ((usageId shr 8) and 0xFF).toByte()
        dev.sendReport(host, REPORT_ID_CONSUMER.toInt(), report)
        // Release
        dev.sendReport(host, REPORT_ID_CONSUMER.toInt(), ByteArray(2))
    }

    // ── Auto-reconnect logic ─────────────────────────────────────────────────

    private fun scheduleReconnect() {
        if (!isAdvertisingRequested) return
        if (connectedHost != null) return
        // No attempt limit: the connect screen keeps saying it is waiting,
        // so it has to keep trying (every 32 s at most). A host that refused
        // us connects on the next attempt once it has read our records again.
        val delay = baseReconnectDelayMs * (1L shl reconnectAttempt.coerceAtMost(4))
        reconnectAttempt++
        Log.d(TAG, "Scheduling reconnect attempt $reconnectAttempt in ${delay}ms")

        reconnectHandler?.postDelayed({
            if (isAdvertisingRequested && connectedHost == null) {
                tryReconnectToLastDevice()
            }
        }, delay)
    }

    private fun tryReconnectToLastDevice() {
        val hid = hidDevice ?: return
        if (connectedHost != null) return
        // Unregistered, connect() fails; registering again tries anew.
        if (!isRegistered) return
        // An attempt is still running (e.g. the app came back meanwhile); its
        // result schedules the next one. Paging gives up within ~10 s.
        if (connectAttemptAtMs != 0L &&
            SystemClock.elapsedRealtime() - connectAttemptAtMs < attemptTimeoutMs) return

        // First check if already connected (e.g. OS reconnected in background)
        val connectedDevices = hid.connectedDevices
        if (connectedDevices.isNotEmpty()) {
            val device = connectedDevices.first()
            connectedHost = device
            saveLastDevice(device.address)
            reconnectAttempt = 0
            Log.d(TAG, "Already connected to ${device.name}")
            onStateChanged?.invoke("connected:${device.name ?: device.address}")
            return
        }

        // Try last known device
        val targetAddress = lastConnectedAddress
        if (targetAddress != null) {
            val bonded = bluetoothAdapter?.bondedDevices ?: emptySet()
            val target = bonded.find { it.address == targetAddress }
            if (target != null) {
                Log.d(TAG, "Attempting reconnect to ${target.name ?: target.address}")
                val result = connectHost(hid, target)
                Log.d(TAG, "Reconnect attempt result: $result")
                if (!result) {
                    // connect() failed immediately — schedule another try
                    scheduleReconnect()
                }
                // If result is true, wait for onConnectionStateChanged callback
                return
            }
        }

        // No last device or not bonded: connect on our own only to the one
        // bonded computer. Headsets, cars and watches are never HID hosts, and
        // with several computers a guess would send our key presses to
        // whichever comes first; the right one connects to us instead (and is
        // the last device from then on).
        val computers = (bluetoothAdapter?.bondedDevices ?: emptySet()).filter {
            it.bluetoothClass?.majorDeviceClass == BluetoothClass.Device.Major.COMPUTER
        }
        if (computers.size == 1) {
            val device = computers.first()
            Log.d(TAG, "Trying the bonded computer: ${device.name ?: device.address}")
            if (connectHost(hid, device)) {
                Log.d(TAG, "Connect initiated to ${device.name}")
                return
            }
        } else if (computers.size > 1) {
            Log.d(TAG, "${computers.size} bonded computers: waiting for one to connect")
        }

        // Nothing worked — schedule another attempt
        scheduleReconnect()
    }

    private fun connectHost(hid: BluetoothHidDevice, host: BluetoothDevice): Boolean {
        connectAttemptAtMs = SystemClock.elapsedRealtime()
        val result = hid.connect(host)
        if (result) {
            onStateChanged?.invoke("target:${host.name ?: host.address}")
        } else {
            connectAttemptAtMs = 0L
        }
        return result
    }

    /** [host] refused the keyboard: has QuickRemote PC read our records again. */
    private fun onHostRefused(host: BluetoothDevice) {
        Log.d(TAG, "${host.name ?: host.address} refused the HID link")
        // Retry every 8 s at most, so the remote opens soon after the fix.
        reconnectAttempt = reconnectAttempt.coerceAtMost(2)
        val uuid = repairUuid
        val sinceRequest = SystemClock.elapsedRealtime() - repairRequestedAtMs
        if (repairRequestedAtMs != 0L) {
            if (repairDelivered) {
                // Within the grace period the PC is still at it; after it,
                // the request did not help.
                if (sinceRequest >= repairGraceMs) onStateChanged?.invoke("host_unaware")
                return
            }
            if (sinceRequest < repairRetryMs) return
        }
        if (uuid == null) {
            onStateChanged?.invoke("host_unaware")
            return
        }
        repairRequestedAtMs = SystemClock.elapsedRealtime()
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
        Thread {
            // Connecting is the whole request (nothing is sent). It fails at
            // once when the computer does not offer the service.
            val delivered = try {
                host.createRfcommSocketToServiceRecord(uuid).use { it.connect() }
                true
            } catch (e: IOException) {
                Log.d(TAG, "No QuickRemote PC repair service: ${e.message}")
                false
            }
            mainHandler.post {
                if (!isAdvertisingRequested || connectedHost != null) return@post
                if (delivered) {
                    Log.d(TAG, "QuickRemote PC reads our records again")
                    repairDelivered = true
                    repairRequestedAtMs = SystemClock.elapsedRealtime()
                    reconnectAttempt = 0
                    onStateChanged?.invoke("refreshing")
                } else {
                    onStateChanged?.invoke("host_unaware")
                }
            }
        }.start()
    }

    private fun cancelReconnect() {
        reconnectHandler?.removeCallbacksAndMessages(null)
        reconnectAttempt = 0
    }

    // ── Profile Listener ──────────────────────────────────────────────────────

    private val profileListener = object : BluetoothProfile.ServiceListener {
        @SuppressLint("MissingPermission")
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile != BluetoothProfile.HID_DEVICE) return
            val hid = proxy as BluetoothHidDevice
            hidDevice = hid

            // Check if we are already connected to a host (e.g. Windows auto-connected)
            val devices = hid.connectedDevices
            if (devices.isNotEmpty()) {
                val device = devices.first()
                connectedHost = device
                saveLastDevice(device.address)
                Log.d(TAG, "HID already connected to ${device.name}")
                onStateChanged?.invoke("connected:${device.name ?: device.address}")
            }

            registerOrReport()
        }

        override fun onServiceDisconnected(profile: Int) {
            hidDevice = null
            // Profile proxy disconnected — try to re-acquire if still requested
            if (isAdvertisingRequested) {
                Log.d(TAG, "Profile proxy lost, re-acquiring...")
                bluetoothAdapter?.getProfileProxy(context, this, BluetoothProfile.HID_DEVICE)
            }
        }
    }

    private val hidCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            isRegistered = registered
            if (registered) {
                Log.d(TAG, "HID app registered")
                if (pluggedDevice != null && connectedHost == null) {
                    Log.d(TAG, "Connecting to plugged device: ${pluggedDevice.name ?: pluggedDevice.address}")
                    val connectResult = hidDevice?.let { connectHost(it, pluggedDevice) }
                    Log.d(TAG, "Connect result: $connectResult")
                } else if (connectedHost == null) {
                    // Try to reconnect to last known device first
                    tryReconnectToLastDevice()
                }
            } else {
                Log.d(TAG, "HID app unregistered")
                // Android drops the registration of an app that leaves the
                // foreground without a foreground service. Registering again
                // works only in the foreground; otherwise startAdvertising
                // does it when the app comes back (BtHidService.ensureConnected).
                if (isAdvertisingRequested && hidDevice != null && registerHidApp()) {
                    Log.d(TAG, "Registering the HID app again")
                }
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedHost = device
                    connectAttemptAtMs = 0L
                    connectedAtMs = SystemClock.elapsedRealtime()
                    saveLastDevice(device.address)
                    // Keep reconnectAttempt: it is reset only once the link
                    // has held (see STATE_DISCONNECTED).
                    reconnectHandler?.removeCallbacksAndMessages(null)
                    Log.d(TAG, "HID connected to ${device.name}")
                    onStateChanged?.invoke("connected:${device.name ?: device.address}")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    val wasConnected = connectedHost?.address == device.address
                    // Android reports a failed attempt more than once.
                    if (!wasConnected && connectAttemptAtMs == 0L) return
                    val since = if (wasConnected) connectedAtMs else connectAttemptAtMs
                    val refused = SystemClock.elapsedRealtime() - since < refusedWithinMs
                    connectAttemptAtMs = 0L
                    Log.d(TAG, "HID disconnected from ${device.name}")
                    if (wasConnected) {
                        connectedHost = null
                        if (!refused) reconnectAttempt = 0
                    }
                    // A failed attempt changes nothing the user sees.
                    if (refused) {
                        onHostRefused(device)
                    } else if (wasConnected) {
                        onStateChanged?.invoke("disconnected")
                    }
                    scheduleReconnect()
                }
            }
        }

        override fun onGetReport(device: BluetoothDevice, type: Byte, id: Byte, bufferSize: Int) {
            hidDevice?.replyReport(device, type, id, ByteArray(bufferSize))
        }
    }

    /**
     * Registers, or tells Flutter it cannot: Android lets one app at a time
     * be a HID device, and only one in the foreground.
     */
    private fun registerOrReport() {
        if (registerHidApp()) return
        Log.d(TAG, "HID app registration refused")
        isAdvertisingRequested = false
        cancelReconnect()
        onStateChanged?.invoke("error:hid_unavailable")
    }

    @SuppressLint("MissingPermission")
    private fun registerHidApp(): Boolean {
        // Run the callbacks on the main thread, like every other access to
        // connectedHost / isRegistered, instead of on a binder thread.
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
        val executor = Executor { mainHandler.post(it) }
        return hidDevice?.registerApp(SDP_SETTINGS, null, null, executor, hidCallback) ?: false
    }
}
