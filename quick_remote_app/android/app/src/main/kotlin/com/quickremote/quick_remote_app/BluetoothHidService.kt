package com.quickremote.quick_remote_app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
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

    /** Callback to Flutter: "connected" | "disconnected" | "unsupported" | "error:<msg>" */
    var onStateChanged: ((String) -> Unit)? = null

    // ── Auto-reconnect ───────────────────────────────────────────────────────

    private var lastConnectedAddress: String? = null
    private var reconnectHandler: android.os.Handler? = null
    private var reconnectAttempt = 0
    private val maxReconnectAttempts = 5
    private val baseReconnectDelayMs = 2000L

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

    /** Start HID registration and become discoverable. */
    fun startAdvertising() {
        if (!isSupported()) {
            onStateChanged?.invoke("unsupported")
            return
        }
        isAdvertisingRequested = true
        reconnectAttempt = 0
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

        // If we already have a HID proxy and it's registered, try to reconnect
        if (hidDevice != null && isRegistered) {
            Log.d(TAG, "HID already registered, attempting reconnect")
            tryReconnectToLastDevice()
            return
        }

        bluetoothAdapter!!.getProfileProxy(context, profileListener, BluetoothProfile.HID_DEVICE)
    }

    /** Disconnect from host and unregister HID app. */
    fun stopAdvertising() {
        isAdvertisingRequested = false
        cancelReconnect()

        connectedHost?.let { host ->
            hidDevice?.disconnect(host)
        }
        hidDevice?.unregisterApp()
        hidDevice = null
        connectedHost = null
        isRegistered = false
        bluetoothAdapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, hidDevice)
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
        if (reconnectAttempt >= maxReconnectAttempts) {
            Log.d(TAG, "Max reconnect attempts reached ($maxReconnectAttempts)")
            return
        }

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
                val result = hid.connect(target)
                Log.d(TAG, "Reconnect attempt result: $result")
                if (!result) {
                    // connect() failed immediately — schedule another try
                    scheduleReconnect()
                }
                // If result is true, wait for onConnectionStateChanged callback
                return
            }
        }

        // No last device or not bonded — try any bonded device
        val bonded = bluetoothAdapter?.bondedDevices ?: emptySet()
        for (device in bonded) {
            Log.d(TAG, "Trying bonded device: ${device.name ?: device.address}")
            val result = hid.connect(device)
            if (result) {
                Log.d(TAG, "Connect initiated to ${device.name}")
                return
            }
        }

        // Nothing worked — schedule another attempt
        scheduleReconnect()
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

            registerHidApp()
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
                    val connectResult = hidDevice?.connect(pluggedDevice)
                    Log.d(TAG, "Connect result: $connectResult")
                } else if (connectedHost == null) {
                    // Try to reconnect to last known device first
                    tryReconnectToLastDevice()
                }
            } else {
                Log.d(TAG, "HID app unregistered")
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedHost = device
                    saveLastDevice(device.address)
                    cancelReconnect()
                    Log.d(TAG, "HID connected to ${device.name}")
                    onStateChanged?.invoke("connected:${device.name ?: device.address}")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    val wasConnected = connectedHost?.address == device.address
                    if (wasConnected) {
                        connectedHost = null
                    }
                    Log.d(TAG, "HID disconnected from ${device.name}")
                    onStateChanged?.invoke("disconnected")

                    // Auto-reconnect if still requested
                    if (wasConnected && isAdvertisingRequested) {
                        Log.d(TAG, "Connection lost, will attempt auto-reconnect")
                        scheduleReconnect()
                    }
                }
            }
        }

        override fun onGetReport(device: BluetoothDevice, type: Byte, id: Byte, bufferSize: Int) {
            hidDevice?.replyReport(device, type, id, ByteArray(bufferSize))
        }
    }

    @SuppressLint("MissingPermission")
    private fun registerHidApp() {
        val executor: Executor = Executor { it.run() }
        hidDevice?.registerApp(SDP_SETTINGS, null, null, executor, hidCallback)
    }

    @SuppressLint("MissingPermission")
    private fun makeDiscoverable() {
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
            putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}
