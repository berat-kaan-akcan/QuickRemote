import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../models/presentation_analytics.dart';
import 'websocket/websocket_client.dart';
import 'websocket/presentation_state.dart';
import 'websocket/analytics_tracker.dart';
import 'websocket/failure.dart';
import 'websocket/thumbnail_requests.dart';

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
  // Slide pictures, also sent after every connect.
  bool _slidePreview = true;

  late final ThumbnailRequests _thumbnails = ThumbnailRequests(
    send: (slide) => sendDirect(RemoteCommands.slideThumb(slide)),
    onFailed: notifyListeners,
  );

  WebSocketService() {
    _client = WebSocketClient(
      onConnectionStateChanged: (state) {
        if (state == AppConnectionState.disconnected || state == AppConnectionState.failed) {
          _state.reset();
          _thumbnails.reset();
        } else if (state == AppConnectionState.connected) {
          // Not on the auth message: the client counts as connected only after it.
          sendSettings();
        }
        notifyListeners();
      },
      onMessage: _handleMessage,
      onImage: handleImage,
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

  /// The connected PC's name; null from a PC that does not tell it.
  String? get pcName => isConnected ? _state.pcName : null;

  /// What the remote calls the PC: its name, also while reconnecting, else
  /// its address.
  String get pcLabel => _state.pcName ?? serverAddress;

  // ─── Presentation State ─────────────────────────────────────────────────────

  int get currentSlide => _state.currentSlide;
  int get totalSlides => _state.totalSlides;
  String get slideNotes => _state.slideNotes;
  bool get isPptRunning => _state.isPptRunning;
  /// Every program the PC controls ('powerpoint', 'impress', 'wps').
  List<String> get presenters => _state.presenters;

  /// The program running the show ('powerpoint', 'impress', 'wps').
  String get presenter => _state.presenter;

  /// The PC's system ('windows' or 'linux'); null from an older PC.
  String? get pcPlatform => _state.platform;
  bool get pptHasMedia => _state.pptHasMedia;

  /// What is in front on the PC and which tools work there; null from a PC
  /// that does not tell (the remote then guesses as before).
  PresenterCaps? get presenterCaps => _state.caps;

  /// The kind of window in front on the PC (a [FrontWindow] value); null
  /// when unknown.
  String? get frontWindow => _state.caps?.front;
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

  /// The laser works without a slideshow (the PC's overlay draws it).
  bool get toolsAnywhere => _state.toolsAnywhere;

  /// The laser can be a magnifier (the PC's overlay has one).
  bool get zoomAvailable => _state.zoomAvailable;

  // 🖼️ Slide pictures 🖼️

  /// Whether slide pictures can come: the PC sends them and the setting is on.
  bool get previewsAvailable => _state.previewsSupported && _slidePreview;
  Uint8List? get currentSlideImage => previewsAvailable ? _state.currentSlideImage : null;
  Uint8List? get nextSlideImage => previewsAvailable ? _state.nextSlideImage : null;
  Uint8List? thumbnail(int slide) => previewsAvailable ? _state.thumbnail(slide) : null;

  /// The PC's screen, live, where it has no slide to name: a PDF viewer or
  /// browser in full screen, or a show it cannot read (SlideImageKind.screen).
  Uint8List? get screenImage => previewsAvailable ? _state.screenImage : null;

  /// Asks the PC for slide [slide]'s thumbnail unless there is a picture of
  /// it; it comes through [thumbnail] and a notification.
  void requestThumbnail(int slide) {
    if (!previewsAvailable || _state.thumbnail(slide) != null) return;
    _thumbnails.request(slide);
  }

  /// The slide list no longer shows [slide].
  void cancelThumbnail(int slide) => _thumbnails.cancel(slide);

  /// Whether slide [slide]'s thumbnail did not come in time.
  bool thumbnailFailed(int slide) => _thumbnails.failed(slide);

  /// Whether a picture of this deck has come, so its place stays in the
  /// layout while the next one loads.
  bool get hasSlideImages => previewsAvailable && _state.hasSlideImages;

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

    if (message['type'] == 'OVERLAY') {
      // The PC's Laser setting changed while connected.
      _state.toolsAnywhere = message['overlay'] == true;
      _state.zoomAvailable = message['zoom'] == true;
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
        final caps = _state.caps;
        final screen = _state.rawScreenImage;
        _state.reset();
        // The STATUS just before may have told what is in front now.
        _state.caps = caps;
        _state.rawScreenImage = screen;
        _state.updateCaps(message, keep: true);
        _thumbnails.reset();
        notifyListeners();
        return;
      }
      
      final oldSlide = _state.currentSlide;
      final oldDeck = _state.deck;
      _state.updateFromSlideState(message);
      if (_state.deck != oldDeck) _thumbnails.reset();
      
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
    sendDirect(RemoteCommands.keepInk(keep));
  }

  /// The phone's PC-side settings, which the PC does not store: sent after
  /// every connect.
  @visibleForTesting
  void sendSettings() {
    sendDirect(RemoteCommands.keepInk(_keepInkOnSlideChange));
    // A PC without previews would only log an unknown command.
    if (_state.previewsSupported) sendDirect(RemoteCommands.slidePreview(_slidePreview));
  }

  /// Sends a command without [sendCommand]'s optimistic state changes (a
  /// setting, a thumbnail request); nothing goes out while disconnected.
  @protected
  void sendDirect(String command) => _client.sendCommand(command);

  @visibleForTesting
  void handleMessage(Map<String, dynamic> message) => _handleMessage(message);

  @visibleForTesting
  void handleImage(SlideImageFrame frame) {
    if (frame.kind != SlideImageKind.screen) _thumbnails.arrived(frame.slide);
    if (_state.addImage(frame)) notifyListeners();
  }

  /// Turns the slide pictures on or off, and tells the PC when it changed
  /// while connected.
  void setSlidePreview(bool on) {
    if (on == _slidePreview) return;
    _slidePreview = on;
    if (!on) _state.clearImages();
    if (_state.previewsSupported) sendDirect(RemoteCommands.slidePreview(on));
    notifyListeners();
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
    _thumbnails.reset();
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
    _thumbnails.reset();
    _client.disconnect();
    super.dispose();
  }
}
