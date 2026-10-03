import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The phone's name, sent with the PIN so the PC can tell connected phones
/// apart: the name the user gave it in the settings, else its model.
class DeviceName {
  DeviceName._();

  static const _channel = MethodChannel('com.quickremote.quick_remote_app/device');
  static Future<String?>? _name;

  static Future<String?> get() => _name ??= _load();

  static Future<String?> _load() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('name');
    } catch (e) {
      debugPrint('Device name unavailable: $e');
      return null;
    }
  }
}
