import 'dart:async';
import 'package:flutter/services.dart';
import '../../../services/websocket_service.dart';

class HardwareKeyHandler {
  final WebSocketService wsRef;
  final void Function(String command) onCommand;
  bool _isAttached = false;
  
  static const MethodChannel _channel = MethodChannel('com.quickremote.quick_remote_app/volume_keys');

  HardwareKeyHandler({required this.wsRef, required this.onCommand}) {
    // Listen for events from native Android
    _channel.setMethodCallHandler((call) async {
      if (!_isAttached || !wsRef.isConnected) return;
      
      if (call.method == 'onVolumeUp') {
        onCommand('NEXT');
        HapticFeedback.selectionClick();
      } else if (call.method == 'onVolumeDown') {
        onCommand('PREV');
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> attach() async {
    if (_isAttached) return;
    _isAttached = true;
    
    // Tell Android to start intercepting volume keys and block system UI
    try {
      await _channel.invokeMethod('startIntercepting');
    } catch (e) {
      // Ignore if not on Android
    }
  }

  void detach() {
    if (!_isAttached) return;
    _isAttached = false;
    
    // Restore normal volume key behavior
    try {
      _channel.invokeMethod('stopIntercepting');
    } catch (e) {
      // Ignore
    }
  }
}
