import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../models/presentation_analytics.dart';
import 'websocket/websocket_client.dart';
import 'websocket/presentation_state.dart';
import 'websocket/analytics_tracker.dart';
import 'websocket/failure.dart';

export 'websocket/failure.dart';

/// Describes why a connection attempt failed.
enum ConnectionError {
  none,
  /// No PIN was given.
  pinEmpty,
  wrongPin,
  timeout,
  /// The PC did not answer the PIN in time.
  authTimeout,
  serverNotFound,
  /// The certificate differs from the one pinned earlier; the user may accept it.
  certMismatch,
  /// The certificate differs from the fingerprint in the scanned QR code.
  /// Never overridable: the QR code comes straight from the PC screen.
  certRejected,
  /// First connection to this address without the QR code: the user has to
  /// compare the security code with the PC before the PIN is sent.
  unverified,
  /// The PC refuses pairing for now after too many wrong PINs.
  rateLimited,
  /// The user removed this phone on the PC (close code 4005).
  closedByPc,
  /// The PC closed the socket before answering the PIN.
  closed,
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
  /// Untranslated detail for [error] (a socket or exception message).
  final String? detail;
  /// Non-null only when error == certMismatch or unverified.
  final String? newFingerprint;
  /// The host whose certificate mismatched.
  final String? mismatchHost;

  const ConnectionResult({
    required this.success,
    this.error = ConnectionError.none,
    this.detail,
    this.newFingerprint,
    this.mismatchHost,
  });

  const ConnectionResult.ok()
    : success = true,
      error = ConnectionError.none,
      detail = null,
      newFingerprint = null,
      mismatchHost = null;

  ConnectionFailure get failure => ConnectionFailure(error, detail);
}

/// WebSocket client service for connecting to PC companion app.
/// Acts as a Facade over WebSocketClient, PresentationState, and AnalyticsTracker.
class WebSocketService extends ChangeNotifier {
  late final WebSocketClient _client;
  final PresentationState _state = PresentationState();
  final AnalyticsTracker _analytics = AnalyticsTracker();

  // COMMAND_FAILED from the PC, or a lost connection
  Failure? _lastCommandError;

  // The PC does not store this setting: it is sent after every connect.
  bool _keepInkOnSlideChange = false;

  WebSocketService() {
    _client = WebSocketClient(
      onConnectionStateChanged: (state) {
        if (state == AppConnectionState.disconnected || state == AppConnectionState.failed) {
          _state.reset();
        } else if (state == AppConnectionState.connected) {
          // Not on the auth message: the client counts as connected only after it.
          _client.sendCommand(RemoteCommands.keepInk(_keepInkOnSlideChange));
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
  List<String> get presenterNames => _state.presenterNames;
  bool get pptHasMedia => _state.pptHasMedia;
  bool get pptIsMediaPlaying => _state.pptIsMediaPlaying;
  
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
  Failure? get lastCommandError => _lastCommandError;
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
    if (message['type'] == 'auth') {
      _state.updatePresenters(message);
      notifyListeners();
      return;
    }

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
        _lastCommandError = RemoteFailure.fromStatus(message);
      }
      
      notifyListeners();
      return;
    }
  }

  /// Connect to the PC companion app via WebSocket.
  /// Waits for auth response before reporting success.
  /// [certFingerprint] (hex SHA-256, from the QR code) pins the certificate
  /// for this connection instead of trusting it on first use.
  Future<ConnectionResult> connect(String host, int port, {String? pin, String? certFingerprint}) {
    _client.resetReconnectAttempts();
    return _client.connect(host, port, pin: pin, expectedFingerprint: certFingerprint);
  }

  /// Sets the "keep the ink on slide change" setting, and sends it to the PC
  /// when it changed while connected.
  void setKeepInkOnSlideChange(bool keep) {
    if (keep == _keepInkOnSlideChange) return;
    _keepInkOnSlideChange = keep;
    _client.sendCommand(RemoteCommands.keepInk(keep));
  }

  /// Send a command to the PC.
  void sendCommand(String command) {
    bool stateChanged = false;
    
    // Optimistic UI updates
    if (command == RemoteCommands.mediaPlayPause) {
      _state.pptIsMediaPlaying = !_state.pptIsMediaPlaying;
      stateChanged = true;
    } else if (command == RemoteCommands.sysMediaPlayPause) {
      _state.isPlaying = !_state.isPlaying;
      stateChanged = true;
    } else if (command == RemoteCommands.mediaRewind) {
      _state.pptIsMediaPlaying = false; 
      stateChanged = true;
    }
    
    if (stateChanged) {
      notifyListeners();
    }
    
    _client.sendCommand(command);
  }

  /// Send TOUCH or LASER data in binary format to reduce overhead
  void sendTouchOrLaser(String type, double dx, double dy) {
    _client.sendTouchOrLaser(type, dx, dy);
  }

  Future<void> disconnect() async {
    _lastCommandError = null;
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
  /// This preserves TOFU: the update only happens with user consent, and is
  /// stored only after the PC accepts the PIN.
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
