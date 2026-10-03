import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the phone's Wi-Fi out of power save while the Wi-Fi remote is open.
///
/// In power save the phone holds packets for up to a few hundred ms until
/// steady traffic wakes the radio, so the laser and touchpad stutter for the
/// first seconds of every gesture. Android applies the lock only while the
/// app is in front with the screen on.
class WifiLowLatency {
  WifiLowLatency._();

  static const _channel = MethodChannel('com.quickremote.quick_remote_app/wifi_lock');

  static Future<void> acquire() => _call('acquire');
  static Future<void> release() => _call('release');

  static Future<void> _call(String method) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method);
    } catch (e) {
      debugPrint('Wi-Fi lock $method failed: $e');
    }
  }
}
