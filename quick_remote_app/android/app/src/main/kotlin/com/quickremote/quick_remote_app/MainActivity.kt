package com.quickremote.quick_remote_app

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
                    btHidService.startAdvertising()
                    result.success(null)
                }

                "stopAdvertising" -> {
                    btHidService.stopAdvertising()
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

                // sendMouseMove(dx: Int, dy: Int)
                "sendMouseMove" -> {
                    val dx = call.argument<Int>("dx") ?: 0
                    val dy = call.argument<Int>("dy") ?: 0
                    btHidService.sendMouseReport(0, dx, dy)
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

    // ── Volume key handling (unchanged) ────────────────────────────────────
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isIntercepting) {
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                volumeMethodChannel?.invokeMethod("onVolumeUp", null)
                return true
            } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                volumeMethodChannel?.invokeMethod("onVolumeDown", null)
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        btHidService.stopAdvertising()
        super.onDestroy()
    }
}
