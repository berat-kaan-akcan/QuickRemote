package com.quickremote.quick_remote_app

import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // ── Existing volume-key channel ────────────────────────────────────────
    private val VOLUME_CHANNEL = "com.quickremote.quick_remote_app/volume_keys"
    private var volumeMethodChannel: MethodChannel? = null
    private var isIntercepting = false

    // ── Bluetooth HID channel ─────────────────────────────────────────────
    private val BT_HID_METHOD_CHANNEL = "com.quickremote.quick_remote_app/bt_hid"
    private val BT_HID_EVENT_CHANNEL  = "com.quickremote.quick_remote_app/bt_hid_events"

    private lateinit var btHidService: BluetoothHidService

    /** Answer to the pending "requestDiscoverable" call. */
    private var pendingDiscoverable: MethodChannel.Result? = null
    private val REQUEST_DISCOVERABLE = 4711
    private val DISCOVERABLE_SECONDS = 300

    // ── Wi-Fi low latency channel ─────────────────────────────────────────
    private val WIFI_LOCK_CHANNEL = "com.quickremote.quick_remote_app/wifi_lock"
    private var wifiLock: WifiManager.WifiLock? = null

    private val DEVICE_CHANNEL = "com.quickremote.quick_remote_app/device"
    private var btEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Volume key channel (unchanged) ─────────────────────────────────
        volumeMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL
        )
        volumeMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startIntercepting" -> { isIntercepting = true; result.success(null) }
                "stopIntercepting"  -> { isIntercepting = false; result.success(null) }
                else                -> result.notImplemented()
            }
        }

        // ── Wi-Fi low latency ──────────────────────────────────────────────
        // An idle phone puts its Wi-Fi into power save, which holds incoming
        // and outgoing packets for up to a few hundred ms until traffic keeps
        // it awake: the first seconds of the laser stutter. The low latency
        // lock turns power save off while the app is in front with the
        // screen on, and Android lifts it by itself otherwise.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, WIFI_LOCK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> { acquireWifiLock(); result.success(null) }
                "release" -> { releaseWifiLock(); result.success(null) }
                else      -> result.notImplemented()
            }
        }

        // ── Device name, shown in the PC's list of connected phones ────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "name" -> result.success(deviceName())
                else   -> result.notImplemented()
            }
        }

        // ── Bluetooth HID service setup ────────────────────────────────────
        btHidService = BluetoothHidService(applicationContext)
        var lastState: String? = null
        
        btHidService.onStateChanged = { state ->
            lastState = state
            runOnUiThread { btEventSink?.success(state) }
        }

        // Method channel: commands from Flutter → native
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, BT_HID_METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(btHidService.isSupported())

                "startAdvertising" -> {
                    // A state from an earlier session must not be replayed:
                    // a stale "error:bluetooth_disabled" or "connected:…"
                    // would show an error or open the remote at once.
                    lastState = null
                    btHidService.startAdvertising(call.argument<String>("repairUuid"))
                    result.success(null)
                }

                // The system dialog that makes the phone visible to computers
                // searching for devices. Answers the seconds granted, 0 if refused.
                "requestDiscoverable" -> {
                    if (pendingDiscoverable != null) {
                        result.success(0)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                        .putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, DISCOVERABLE_SECONDS)
                    try {
                        pendingDiscoverable = result
                        startActivityForResult(intent, REQUEST_DISCOVERABLE)
                    } catch (e: Exception) {
                        // ActivityNotFoundException, or SecurityException
                        // without BLUETOOTH_ADVERTISE.
                        pendingDiscoverable = null
                        result.success(0)
                    }
                }

                "stopAdvertising" -> {
                    btHidService.stopAdvertising()
                    lastState = null
                    result.success(null)
                }

                // sendKeyReport(modifier: Int, keyCodes: List<Int>)
                "sendKeyReport" -> {
                    val modifier = call.argument<Int>("modifier") ?: 0
                    @Suppress("UNCHECKED_CAST")
                    val keyCodes = (call.argument<List<*>>("keyCodes") as? List<Int>) ?: emptyList()
                    btHidService.sendKeyReport(modifier, keyCodes)
                    result.success(null)
                }

                // sendMouseMove(dx: Int, dy: Int, buttons: Int?)
                "sendMouseMove" -> {
                    val dx = call.argument<Int>("dx") ?: 0
                    val dy = call.argument<Int>("dy") ?: 0
                    val buttons = call.argument<Int>("buttons") ?: 0
                    btHidService.sendMouseReport(buttons, dx, dy)
                    result.success(null)
                }

                // sendMouseDown(button: Int) — press and hold
                "sendMouseDown" -> {
                    val button = call.argument<Int>("button") ?: 1
                    btHidService.sendMouseReport(button, 0, 0)
                    result.success(null)
                }

                // sendMouseUp() — release all buttons
                "sendMouseUp" -> {
                    btHidService.sendMouseReport(0, 0, 0)
                    result.success(null)
                }

                // sendMouseClick(button: Int)  1=left, 2=right
                "sendMouseClick" -> {
                    val button = call.argument<Int>("button") ?: 1
                    btHidService.sendMouseClick(button)
                    result.success(null)
                }

                // sendConsumerControl(usageId: Int)
                "sendConsumerControl" -> {
                    val usageId = call.argument<Int>("usageId") ?: 0
                    btHidService.sendConsumerReport(usageId)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // Event channel: native → Flutter (connection state)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger, BT_HID_EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                btEventSink = events
                lastState?.let { state ->
                    events?.success(state)
                }
            }
            override fun onCancel(arguments: Any?) {
                btEventSink = null
            }
        })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_DISCOVERABLE) {
            // The result code is the granted duration; RESULT_CANCELED (0) if refused.
            pendingDiscoverable?.success(if (resultCode > 0) resultCode else 0)
            pendingDiscoverable = null
        }
    }

    // ── Volume key handling (unchanged) ────────────────────────────────────
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isIntercepting) {
            // Holding the key repeats the event; one press is one slide.
            // Repeats are still consumed so the system volume doesn't change.
            val firstPress = (event?.repeatCount ?: 0) == 0
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                if (firstPress) volumeMethodChannel?.invokeMethod("onVolumeUp", null)
                return true
            } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                if (firstPress) volumeMethodChannel?.invokeMethod("onVolumeDown", null)
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    /** The name the user gave the phone in its settings, else its model. */
    private fun deviceName(): String {
        val named = Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME)
        if (!named.isNullOrBlank()) return named
        val maker = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
        return if (Build.MODEL.startsWith(Build.MANUFACTURER, ignoreCase = true)) Build.MODEL
        else "$maker ${Build.MODEL}"
    }

    private fun acquireWifiLock() {
        if (wifiLock?.isHeld == true) return
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            WifiManager.WIFI_MODE_FULL_LOW_LATENCY
        } else {
            @Suppress("DEPRECATION")
            WifiManager.WIFI_MODE_FULL_HIGH_PERF
        }
        wifiLock = wifi.createWifiLock(mode, "QuickRemote:remote").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseWifiLock() {
        wifiLock?.let { if (it.isHeld) it.release() }
        wifiLock = null
    }

    override fun onDestroy() {
        releaseWifiLock()
        // lateinit: unset when the Activity dies before the engine was configured.
        if (::btHidService.isInitialized) btHidService.stopAdvertising()
        super.onDestroy()
    }
}
