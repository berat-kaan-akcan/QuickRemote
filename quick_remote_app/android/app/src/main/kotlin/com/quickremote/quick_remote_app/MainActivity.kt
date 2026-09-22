package com.quickremote.quick_remote_app

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.quickremote.quick_remote_app/volume_keys"
    private var methodChannel: MethodChannel? = null
    private var isIntercepting = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "startIntercepting") {
                isIntercepting = true
                result.success(null)
            } else if (call.method == "stopIntercepting") {
                isIntercepting = false
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isIntercepting) {
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                methodChannel?.invokeMethod("onVolumeUp", null)
                return true
            } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                methodChannel?.invokeMethod("onVolumeDown", null)
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
