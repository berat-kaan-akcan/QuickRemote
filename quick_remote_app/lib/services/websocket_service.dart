import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/presentation_analytics.dart';
import 'websocket/websocket_client.dart';
import 'websocket/presentation_state.dart';
import 'websocket/analytics_tracker.dart';

/// Describes why a connection attempt failed.
enum ConnectionError {
  none,
  wrongPin,
  timeout,
  serverNotFound,
  certMismatch,
  unknown,
}

/// Represents the overall state of the connection.
enum AppConnectionState {
  disconnected,
  connecting,
  reconnecting,
  connected,
  failed,
  certMismatch,
}

/// Result of a [WebSocketService.connect] call.
class ConnectionResult {
  final bool success;
  final ConnectionError error;
  final String? message;
  /// Non-null only when error == certMismatch.
  final String? newFingerprint;
  /// The host whose certificate mismatched.
  final String? mismatchHost;

  const ConnectionResult({
    required this.success,
    this.error = ConnectionError.none,
    this.message,
    this.newFingerprint,
    this.mismatchHost,
  });

  const ConnectionResult.ok()
    : success = true,
      error = ConnectionError.none,
      message = null,
      newFingerprint = null,
      mismatchHost = null;
}

/// WebSocket client service for connecting to PC companion app.
/// Acts as a Facade over WebSocketClient, PresentationState, and AnalyticsTracker.
class WebSocketService extends ChangeNotifier {
  late final WebSocketClient _client;
  final PresentationState _state = PresentationState();
  final AnalyticsTracker _analytics = AnalyticsTracker();

  // Command error state (for COMMAND_FAILED from PC)
  String? _lastCommandError;

  WebSocketService() {
    _client = WebSocketClient(
      onConnectionStateChanged: (state) {
        if (state == AppConnectionState.disconnected || state == AppConnectionState.failed) {
          _state.reset();
        }
        notifyListeners();
      },
      onMessage: _handleMessage,
      onAuthResolved: (error) {
        if (error != null) {
          _lastCommandError = error;
          notifyListeners();
        }
      },
    );
  }

  // ─── Network & Connection State ─────────────────────────────────────────────
  
  bool get isConnected => _client.isConnected;
  AppConnectionState get connectionState => _client.connectionState;
  String get serverAddress => _client.serverAddress;

  // ─── Presentation State ─────────────────────────────────────────────────────

  int get currentSlide => _state.currentSlide;
  int get totalSlides => _state.totalSlides;
  String get slideNotes => _state.slideNotes;
  bool get isPptRunning => _state.isPptRunning;
  
  bool get hasMedia => _state.hasMedia;
  String? get mediaTitle => _state.mediaTitle;
  String? get mediaArtist => _state.mediaArtist;
  String? get mediaThumbnailBase64 => _state.mediaThumbnailBase64;
  int get positionMs => _state.positionMs;
  int get durationMs => _state.durationMs;
  bool get isPlaying => _state.isPlaying;
  int get systemVolume => _state.systemVolume;
  bool get systemMuted => _state.systemMuted;

  // 📈 Analytics Tracker 📈

  bool get isTracking => _analytics.isTracking;
  PresentationAnalytics? get analytics => _analytics.analytics;
  PresentationAnalytics? get completedAnalytics => _analytics.completedAnalytics;

  // ⚠️ Command Errors ⚠️

  /// Non-null when the PC reports a command failure. Read once and clear.
  String? get lastCommandError => _lastCommandError;
  void clearCommandError() {
    _lastCommandError = null;
  }

  void clearCompletedAnalytics() {
    _analytics.clearCompletedAnalytics();
  }

  // 🛠️ Actions 🛠️

  /// Start tracking slide analytics for a new presentation.
  void startTracking() {
    _analytics.startTracking(_state.totalSlides, _state.currentSlide);
  }

  /// Stop tracking and return the completed analytics.
  PresentationAnalytics? stopTracking() {
    return _analytics.stopTracking(_state.totalSlides);
  }

  void _autoStopTracking() {
    _analytics.autoStopTracking(_state.totalSlides);
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (message['type'] == 'SMTC_STATE') {
      _state.updateFromSmtcState(message);
      notifyListeners();
      return;
    }

    if (message['type'] == 'SLIDE_STATE') {
      if (message.containsKey('data') && message['data'] == null) {
        // Presentation ended (slideshow closed)
        _autoStopTracking();
        _state.reset();
        notifyListeners();
        return;
      }
      
      final oldSlide = _state.currentSlide;
      _state.updateFromSlideState(message);
      
      if (!_analytics.isTracking) {
        _analytics.startTracking(_state.totalSlides, _state.currentSlide);
      } else {
        _analytics.recordSlideChange(_state.currentSlide, oldSlide);
      }
      
      notifyListeners();
      return;
    }

    if (message['type'] == 'STATUS') {
      _state.updateFromStatus(message);
      
      final stateStr = message['state'] as String?;
      if (stateStr == 'POWERPOINT_NOT_RUNNING') {
        _autoStopTracking();
      } else if (stateStr == 'COMMAND_FAILED') {
        _lastCommandError = message['detail'] as String? ?? 'İşlem başarısız oldu.';
      }
      
      notifyListeners();
      return;
    }
  }

  /// Connect to the PC companion app via WebSocket.
  /// Waits for auth response before reporting success.
  Future<ConnectionResult> connect(String host, int port, {String? pin}) {
    return _client.connect(host, port, pin: pin);
  }

  /// Send a command to the PC.
  void sendCommand(String command) {
    _client.sendCommand(command);
  }

  /// Send TOUCH or LASER data in binary format to reduce overhead
  void sendTouchOrLaser(String type, double dx, double dy) {
    _client.sendTouchOrLaser(type, dx, dy);
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    await _client.disconnect();
    _state.reset();
    notifyListeners();
  }

  /// Manually trigger a reconnect.
  void manualReconnect() {
    _client.manualReconnect();
  }

  /// Accept a new certificate fingerprint for a host and reconnect.
  /// Called when the user explicitly approves a cert mismatch via the dialog.
  /// This preserves TOFU: the update only happens with user consent.
  Future<ConnectionResult> acceptCertificateAndReconnect(
    String host,
    String newFingerprint, {
    required int port,
    String? pin,
  }) {
    return _client.acceptCertificateAndReconnect(
      host,
      newFingerprint,
      port: port,
      pin: pin,
    );
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
