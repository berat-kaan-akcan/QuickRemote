import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presentation_analytics.dart';

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
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  String _serverAddress = '';
  Timer? _reconnectTimer;

  // Reconnect state
  String? _lastHost;
  int? _lastPort;
  String? _lastPin;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _connectionState == AppConnectionState.connected;
  AppConnectionState get connectionState => _connectionState;
  String get serverAddress => _serverAddress;

  // Slide state
  int _currentSlide = 0;
  int _totalSlides = 0;
  String _slideNotes = '';
  bool _isPptRunning = true;

  // Command error state (for COMMAND_FAILED from PC)
  String? _lastCommandError;

  // Analytics tracking
  PresentationAnalytics? _analytics;
  bool _isTracking = false;
  /// Set when tracking auto-stops (presentation ended naturally).
  /// UI should read once and clear via [clearCompletedAnalytics].
  PresentationAnalytics? _completedAnalytics;

  int get currentSlide => _currentSlide;
  int get totalSlides => _totalSlides;
  String get slideNotes => _slideNotes;
  bool get isPptRunning => _isPptRunning;
  bool get isTracking => _isTracking;
  PresentationAnalytics? get analytics => _analytics;
  PresentationAnalytics? get completedAnalytics => _completedAnalytics;

  void clearCompletedAnalytics() {
    _completedAnalytics = null;
  }

  /// Non-null when the PC reports a command failure. Read once and clear.
  String? get lastCommandError => _lastCommandError;
  void clearCommandError() {
    _lastCommandError = null;
  }

  /// Start tracking slide analytics for a new presentation.
  void startTracking() {
    final now = DateTime.now();
    _analytics = PresentationAnalytics(
      id: now.toIso8601String(),
      startTime: now,
      totalSlideCount: _totalSlides,
    );
    _isTracking = true;

    // Record the current slide as the first entry
    if (_currentSlide > 0) {
      _analytics!.slideRecords.add(SlideRecord(
        slideNumber: _currentSlide,
        enteredAt: now,
      ));
    }
    debugPrint('Analytics: tracking started');
  }

  /// Stop tracking and return the completed analytics.
  PresentationAnalytics? stopTracking() {
    if (!_isTracking || _analytics == null) return null;

    final now = DateTime.now();
    // Close the last open slide record
    if (_analytics!.slideRecords.isNotEmpty) {
      final last = _analytics!.slideRecords.last;
      last.exitedAt ??= now;
    }
    _analytics!.endTime = now;
    _analytics = PresentationAnalytics(
      id: _analytics!.id,
      startTime: _analytics!.startTime,
      endTime: now,
      totalSlideCount: _totalSlides > 0 ? _totalSlides : _analytics!.totalSlideCount,
      slideRecords: _analytics!.slideRecords,
    );
    _isTracking = false;

    debugPrint('Analytics: tracking stopped, ${_analytics!.slideRecords.length} records');
    return _analytics;
  }

  /// Auto-stop tracking when the presentation ends naturally
  /// (slideshow closed or PowerPoint not running).
  /// Sets [_completedAnalytics] so the UI can react via listener.
  void _autoStopTracking() {
    if (!_isTracking || _analytics == null) return;
    final result = stopTracking();
    if (result != null && result.slideRecords.isNotEmpty) {
      _completedAnalytics = result;
      debugPrint('Analytics: auto-stopped, ready for UI pickup');
    }
  }

  /// Connect to the PC companion app via WebSocket.
  /// Waits for auth response before reporting success.
  Future<ConnectionResult> connect(String host, int port, {String? pin}) async {
    // Client-side PIN validation
    if (pin == null || pin.isEmpty) {
      return const ConnectionResult(
        success: false,
        error: ConnectionError.wrongPin,
        message: 'PIN kodu boş olamaz.',
      );
    }

    // Cancel any pending reconnect
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _connectionState = _reconnectAttempts > 0
        ? AppConnectionState.reconnecting
        : AppConnectionState.connecting;
    notifyListeners();

    _serverAddress = '$host:$port';
    _lastHost = host;
    _lastPort = port;
    _lastPin = pin;

    try {
      final uri = Uri.parse('wss://$host:$port');
      final prefs = await SharedPreferences.getInstance();
      final key = 'cert_fingerprint_$host';
      final expectedFingerprint = prefs.getString(key);
      bool isCertMismatch = false;
      String? actualFingerprintCapture;

      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String callbackHost, int callbackPort) {
        final bytes = cert.der;
        final actualFingerprint = sha256.convert(bytes).toString();

        if (expectedFingerprint == null) {
          // TOFU: Trust On First Use
          prefs.setString(key, actualFingerprint);
          return true;
        } else if (expectedFingerprint == actualFingerprint) {
          return true;
        } else {
          isCertMismatch = true;
          actualFingerprintCapture = actualFingerprint;
          return false;
        }
      };

      WebSocket ws;
      try {
        ws = await WebSocket.connect(uri.toString(), customClient: httpClient).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw const SocketException('Connection timed out'),
        );
      } on HandshakeException catch (_) {
        if (isCertMismatch) {
          _connectionState = AppConnectionState.certMismatch;
          notifyListeners();
          return ConnectionResult(
            success: false,
            error: ConnectionError.certMismatch,
            message: 'Sertifika değişti! Olası MITM saldırısı veya cihaz formatlanmış olabilir.',
            newFingerprint: actualFingerprintCapture,
            mismatchHost: host,
          );
        }
        rethrow;
      }

      _channel = IOWebSocketChannel(ws);

      // Use a Completer to wait for auth result before returning success.
      final authCompleter = Completer<ConnectionResult>();
      bool authResolved = false;

      // Send PIN auth
      _channel!.sink.add(jsonEncode({'auth': pin}));

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            // Handle auth response from server
            if (message['type'] == 'auth') {
              if (message['status'] == 'fail') {
                debugPrint('Auth failed: wrong PIN');
                _connectionState = AppConnectionState.disconnected;
                notifyListeners();
                _channel?.sink.close();
                if (!authResolved) {
                  authResolved = true;
                  authCompleter.complete(
                    const ConnectionResult(
                      success: false,
                      error: ConnectionError.wrongPin,
                      message: 'PIN kodu yanlış.',
                    ),
                  );
                }
                return;
              }
              // Auth successful
              debugPrint('Auth successful');
              _connectionState = AppConnectionState.connected;
              _reconnectAttempts = 0;
              notifyListeners();
              if (!authResolved) {
                authResolved = true;
                authCompleter.complete(const ConnectionResult.ok());
              }
              return;
            }

            if (message['type'] == 'ping') {
              _channel?.sink.add(jsonEncode({'type': 'pong'}));
              return;
            }

            if (message['type'] == 'SLIDE_STATE') {
              if (message.containsKey('data') && message['data'] == null) {
                // Presentation ended (slideshow closed)
                _autoStopTracking();
                _currentSlide = 0;
                _totalSlides = 0;
                _slideNotes = '';
                notifyListeners();
                return;
              }
              _isPptRunning = true;
              final newSlide = message['current'] as int? ?? 0;
              final newTotal = message['total'] as int? ?? 0;
              _slideNotes = message['notes'] as String? ?? '';

              // Track slide change for analytics
              if (_isTracking && _analytics != null && newSlide != _currentSlide && newSlide > 0) {
                final now = DateTime.now();
                // Close previous slide record
                if (_analytics!.slideRecords.isNotEmpty) {
                  final last = _analytics!.slideRecords.last;
                  last.exitedAt ??= now;
                }
                // Open new slide record
                _analytics!.slideRecords.add(SlideRecord(
                  slideNumber: newSlide,
                  enteredAt: now,
                ));
                debugPrint('Analytics: slide $newSlide entered');
              }

              _currentSlide = newSlide;
              _totalSlides = newTotal;
              notifyListeners();
              return;
            }

            if (message['type'] == 'STATUS') {
              if (message['state'] == 'POWERPOINT_NOT_RUNNING') {
                _autoStopTracking();
                _isPptRunning = false;
                notifyListeners();
              } else if (message['state'] == 'COMMAND_FAILED') {
                _lastCommandError = message['detail'] as String? ?? 'İşlem başarısız oldu.';
                notifyListeners();
              }
              return;
            }

            debugPrint('Server: $message');
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        },
        onDone: () {
          final wasConnected = isConnected;
          debugPrint('WebSocket disconnected');
          if (!authResolved) {
            authResolved = true;
            authCompleter.complete(
              const ConnectionResult(
                success: false,
                error: ConnectionError.unknown,
                message: 'Bağlantı beklenmedik şekilde kapandı.',
              ),
            );
          }
          // Auto-reconnect if was previously connected
          if (wasConnected) {
            _scheduleReconnect();
          } else {
            _connectionState = AppConnectionState.disconnected;
            _currentSlide = 0;
            _totalSlides = 0;
            _slideNotes = '';
            _isPptRunning = true;
            notifyListeners();
          }
        },
        onError: (error) {
          final wasConnected = isConnected;
          debugPrint('WebSocket error: $error');
          if (!authResolved) {
            authResolved = true;
            authCompleter.complete(
              ConnectionResult(
                success: false,
                error: ConnectionError.unknown,
                message: 'WebSocket hatası: $error',
              ),
            );
          }
          // Auto-reconnect if was previously connected
          if (wasConnected) {
            _scheduleReconnect();
          } else {
            _connectionState = AppConnectionState.disconnected;
            _currentSlide = 0;
            _totalSlides = 0;
            _slideNotes = '';
            _isPptRunning = true;
            notifyListeners();
          }
        },
      );

      // If no PIN was sent, we're already connected
      if (authResolved) {
        return const ConnectionResult.ok();
      }

      // Wait for auth response with timeout
      return await authCompleter.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('Auth response timeout');
          _connectionState = AppConnectionState.disconnected;
          notifyListeners();
          _channel?.sink.close();
          return const ConnectionResult(
            success: false,
            error: ConnectionError.timeout,
            message: 'Kimlik doğrulama zaman aşımına uğradı.',
          );
        },
      );
    } on SocketException catch (e) {
      debugPrint('Connection failed (socket): $e');
      _connectionState = AppConnectionState.disconnected;
      notifyListeners();
      return ConnectionResult(
        success: false,
        error: ConnectionError.serverNotFound,
        message: 'Sunucuya ulaşılamadı: ${e.message}',
      );
    } on TimeoutException catch (_) {
      debugPrint('Connection failed (timeout)');
      _connectionState = AppConnectionState.disconnected;
      notifyListeners();
      return const ConnectionResult(
        success: false,
        error: ConnectionError.timeout,
        message: 'Bağlantı zaman aşımına uğradı.',
      );
    } catch (e) {
      debugPrint('Connection failed: $e');
      _connectionState = AppConnectionState.disconnected;
      notifyListeners();
      return ConnectionResult(
        success: false,
        error: ConnectionError.unknown,
        message: 'Bilinmeyen hata: $e',
      );
    }
  }

  /// Schedule an automatic reconnect attempt.
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _connectionState = AppConnectionState.failed;
      notifyListeners();
      return;
    }
    if (_lastHost == null || _lastPort == null) return;

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    debugPrint(
      'Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
    );

    if (_connectionState != AppConnectionState.reconnecting) {
      _connectionState = AppConnectionState.reconnecting;
      notifyListeners();
    }

    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (isConnected) return; // Already reconnected
      debugPrint('Attempting reconnect...');
      final result = await connect(_lastHost!, _lastPort!, pin: _lastPin);
      if (!result.success && !isConnected) {
        _scheduleReconnect();
      }
    });
  }

  /// Send a command to the PC.
  void sendCommand(String command) {
    if (isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'command': command}));
        debugPrint('Sent: $command');
      } catch (e) {
        debugPrint('Failed to send command: $e');
      }
    }
  }



  /// Send TOUCH or LASER data in binary format to reduce overhead
  void sendTouchOrLaser(String type, double dx, double dy) {
    if (isConnected && _channel != null) {
      try {
        final bytes = ByteData(9);
        bytes.setUint8(0, type == 'TOUCH' ? 0 : 1);
        bytes.setFloat32(1, dx, Endian.little);
        bytes.setFloat32(5, dy, Endian.little);
        _channel!.sink.add(bytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('Failed to send binary data: $e');
      }
    }
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = _maxReconnectAttempts; // Prevent auto-reconnect
    await _channel?.sink.close();
    _channel = null;
    _connectionState = AppConnectionState.disconnected;
    notifyListeners();
  }

  /// Manually trigger a reconnect.
  void manualReconnect() {
    if (_lastHost != null && _lastPort != null) {
      _reconnectAttempts = 0;
      connect(_lastHost!, _lastPort!, pin: _lastPin);
    }
  }

  /// Accept a new certificate fingerprint for a host and reconnect.
  /// Called when the user explicitly approves a cert mismatch via the dialog.
  /// This preserves TOFU: the update only happens with user consent.
  Future<ConnectionResult> acceptCertificateAndReconnect(
    String host,
    String newFingerprint, {
    required int port,
    String? pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cert_fingerprint_$host';
    await prefs.setString(key, newFingerprint);
    debugPrint('Certificate fingerprint updated for $host (user-approved)');
    return connect(host, port, pin: pin);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
