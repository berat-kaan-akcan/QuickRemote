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

    /** Callback to Flutter: "connected" | "disconnected" | "unsupported" | "error:<msg>" */
    var onStateChanged: ((String) -> Unit)? = null

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
        val mgr = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = mgr.adapter

        if (bluetoothAdapter?.isEnabled != true) {
            onStateChanged?.invoke("error:bluetooth_disabled")
            return
        }

        bluetoothAdapter!!.getProfileProxy(context, profileListener, BluetoothProfile.HID_DEVICE)
    }

    /** Disconnect from host and unregister HID app. */
    fun stopAdvertising() {
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
                Log.d(TAG, "HID already connected to ${device.name}")
                onStateChanged?.invoke("connected:${device.name ?: device.address}")
            }

            registerHidApp()
        }

        override fun onServiceDisconnected(profile: Int) {
            hidDevice = null
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
                    Log.d(TAG, "Making discoverable")
                    makeDiscoverable()
                }
            } else {
                Log.d(TAG, "HID app unregistered")
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedHost = device
                    Log.d(TAG, "HID connected to ${device.name}")
                    onStateChanged?.invoke("connected:${device.name ?: device.address}")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    if (connectedHost?.address == device.address) {
                        connectedHost = null
                    }
                    Log.d(TAG, "HID disconnected from ${device.name}")
                    onStateChanged?.invoke("disconnected")
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
