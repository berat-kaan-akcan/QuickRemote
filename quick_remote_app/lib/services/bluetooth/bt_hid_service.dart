import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Flutter ↔ Android Kotlin bridge for Bluetooth Classic HID.
///
/// Allows the phone to act as a Bluetooth keyboard + mouse + consumer device.
/// Only available on Android (API 28+). Use [isSupported()] to check before calling.
///
/// iOS: BluetoothHidDevice is not available via public API on iOS — this class
///      will always return false for [isSupported()] on iOS.
class BtHidService {
  static const _methodChannel =
      MethodChannel('com.quickremote.quick_remote_app/bt_hid');
  static const _eventChannel =
      EventChannel('com.quickremote.quick_remote_app/bt_hid_events');

  // ── Singleton ──────────────────────────────────────────────────────────────
  static final BtHidService instance = BtHidService._();
  BtHidService._();

  // ── State ──────────────────────────────────────────────────────────────────
  BtHidConnectionState _state = BtHidConnectionState.disconnected;
  BtHidConnectionState get connectionState => _state;
  bool get isConnected => _state == BtHidConnectionState.connected;

  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  StreamSubscription<dynamic>? _eventSubscription;
  final _stateController = StreamController<BtHidConnectionState>.broadcast();
  Stream<BtHidConnectionState> get stateStream => _stateController.stream;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns true if this platform/device supports Bluetooth Classic HID.
  /// Always false on iOS.
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _methodChannel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Register the phone as a BT HID device and become discoverable.
  /// Listen to [stateStream] for connection state changes.
  Future<void> startAdvertising() async {
    _setState(BtHidConnectionState.advertising);
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (e) => _setState(BtHidConnectionState.error),
    );
    await _methodChannel.invokeMethod('startAdvertising');
  }

  /// Stop advertising and disconnect.
  Future<void> stopAdvertising() async {
    await _methodChannel.invokeMethod('stopAdvertising');
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _connectedDeviceName = null;
    _setState(BtHidConnectionState.disconnected);
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────

  /// Send a single key press + release.
  Future<void> sendKey(int keyCode, {int modifier = 0}) {
    return _methodChannel.invokeMethod('sendKeyReport', {
      'modifier': modifier,
      'keyCodes': [keyCode],
    });
  }

  /// Send a key combo: hold [modifiers], press [keyCode], release all.
  Future<void> sendKeyCombo(List<int> modifiers, int keyCode) {
    final modifier = modifiers.fold(0, (acc, m) => acc | m);
    return _methodChannel.invokeMethod('sendKeyReport', {
      'modifier': modifier,
      'keyCodes': [keyCode],
    });
  }

  // ── Mouse ──────────────────────────────────────────────────────────────────

  /// Send relative mouse movement. Values clamped to -127..127 on native side.
  Future<void> sendMouseMove(int dx, int dy) {
    return _methodChannel.invokeMethod('sendMouseMove', {'dx': dx, 'dy': dy});
  }

  /// Send a mouse click. [button]: 1=left, 2=right, 4=middle.
  Future<void> sendMouseClick({int button = 1}) {
    return _methodChannel.invokeMethod('sendMouseClick', {'button': button});
  }

  // ── Consumer Control ───────────────────────────────────────────────────────

  /// Send a consumer control usage ID (volume, media).
  Future<void> sendConsumerControl(int usageId) {
    return _methodChannel
        .invokeMethod('sendConsumerControl', {'usageId': usageId});
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _onNativeEvent(dynamic raw) {
    final event = raw as String;
    if (event.startsWith('connected:')) {
      _connectedDeviceName = event.substring('connected:'.length);
      _setState(BtHidConnectionState.connected);
    } else if (event == 'disconnected') {
      _connectedDeviceName = null;
      _setState(BtHidConnectionState.disconnected);
    } else if (event == 'unsupported') {
      _setState(BtHidConnectionState.unsupported);
    } else if (event.startsWith('error:')) {
      _setState(BtHidConnectionState.error);
    }
  }

  void _setState(BtHidConnectionState state) {
    if (_state != state) {
      _state = state;
      _stateController.add(state);
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _stateController.close();
  }
}

/// Connection state of the Bluetooth Classic HID transport.
enum BtHidConnectionState {
  /// Not advertising, not connected.
  disconnected,

  /// Registered and discoverable, waiting for host to connect.
  advertising,

  /// Connected to a host device (PC).
  connected,

  /// Device does not support BluetoothHidDevice (or non-Android).
  unsupported,

  /// An error occurred.
  error,
}
