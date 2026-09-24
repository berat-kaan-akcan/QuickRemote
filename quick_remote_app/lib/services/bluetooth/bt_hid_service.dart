import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Flutter ↔ Android Kotlin bridge for Bluetooth Classic HID.
///
/// Allows the phone to act as a Bluetooth keyboard + mouse + consumer device.
/// Only available on Android (API 28+). Use [isSupported()] to check before calling.
///
/// Includes auto-reconnect: when connection drops, the native side will
/// automatically attempt to reconnect to the last known device. The Flutter
/// side also schedules a re-advertising call as a fallback.
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

  /// Whether the user has explicitly started advertising (wants BT active).
  bool _advertisingRequested = false;
  bool get isAdvertisingRequested => _advertisingRequested;

  /// Timer for Flutter-side reconnect fallback.
  Timer? _reconnectTimer;

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
    _advertisingRequested = true;
    _cancelReconnectTimer();
    _setState(BtHidConnectionState.advertising);
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (e) => _setState(BtHidConnectionState.error),
    );
    await _methodChannel.invokeMethod('startAdvertising');
  }

  /// Stop advertising and disconnect. Cancels auto-reconnect.
  Future<void> stopAdvertising() async {
    _advertisingRequested = false;
    _cancelReconnectTimer();
    await _methodChannel.invokeMethod('stopAdvertising');
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _connectedDeviceName = null;
    _setState(BtHidConnectionState.disconnected);
  }

  /// Call when the app resumes from background to ensure connection.
  /// If advertising was requested but we're disconnected, re-trigger.
  Future<void> ensureConnected() async {
    if (!_advertisingRequested) return;
    if (_state == BtHidConnectionState.connected) return;

    // Re-start advertising — native side will try reconnecting
    // to the last known device automatically.
    _setState(BtHidConnectionState.advertising);
    try {
      await _methodChannel.invokeMethod('startAdvertising');
    } catch (_) {
      // Ignore — native side might already be advertising
    }
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
  /// [buttons]: bitmask — 1=left held, 2=right held, 4=middle held. Default 0.
  /// Callers should use fire-and-forget pattern (no await) for lowest latency.
  Future<void> sendMouseMove(int dx, int dy, {int buttons = 0}) {
    return _methodChannel.invokeMethod(
        'sendMouseMove', {'dx': dx, 'dy': dy, 'buttons': buttons});
  }

  /// Press and hold a mouse button without releasing.
  /// [button]: bitmask — 1=left, 2=right, 4=middle.
  Future<void> sendMouseDown({int button = 1}) {
    return _methodChannel.invokeMethod('sendMouseDown', {'button': button});
  }

  /// Release all mouse buttons.
  Future<void> sendMouseUp() {
    return _methodChannel.invokeMethod('sendMouseUp');
  }

  /// Send a mouse click (press + release). [button]: 1=left, 2=right, 4=middle.
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
      _cancelReconnectTimer();
      _setState(BtHidConnectionState.connected);
    } else if (event == 'disconnected') {
      _connectedDeviceName = null;
      _setState(BtHidConnectionState.disconnected);
      // Schedule Flutter-side reconnect fallback
      _scheduleReconnect();
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

  /// Schedule a reconnect attempt from Flutter side as a fallback.
  /// The native side also has its own reconnect logic.
  void _scheduleReconnect() {
    if (!_advertisingRequested) return;
    _cancelReconnectTimer();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_advertisingRequested &&
          _state != BtHidConnectionState.connected) {
        ensureConnected();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void dispose() {
    _cancelReconnectTimer();
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
