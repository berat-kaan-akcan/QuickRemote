import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Size;
import '../services/websocket_server.dart';

/// Provider wrapper for WebSocketServer so it can notify listeners.
class WebSocketServerProvider extends ChangeNotifier {
  final WebSocketServer server = WebSocketServer();
  String _localIP = '...';
  bool _isRunning = false;
  bool _isStarting = false;
  int _clientCount = 0;
  String _lastCommand = '';
  bool _laserActive = false;
  double _laserX = 0;
  double _laserY = 0;
  String _pin = '';
  bool _isPublicNetwork = false;
  String? _startError;
  bool _mdnsAvailable = true;

  /// Stream controller for laser position updates (used by LaserOverlay).
  final StreamController<ui.Offset> _laserPositionController =
      StreamController<ui.Offset>.broadcast();

  String get localIP => _localIP;
  bool get isRunning => _isRunning;
  bool get isStarting => _isStarting;
  int get clientCount => _clientCount;
  String get lastCommand => _lastCommand;
  int get port => server.port;
  bool get laserActive => _laserActive;
  double get laserX => _laserX;
  double get laserY => _laserY;
  String get pin => _pin;
  bool get publicNetwork => _isPublicNetwork;
  String? get startError => _startError;
  bool get mdnsAvailable => _mdnsAvailable;
  Stream<ui.Offset> get laserPositionStream => _laserPositionController.stream;

  WebSocketServerProvider() {
    server.isRunning.addListener(_onRunningChanged);
    server.clientCount.addListener(_onClientCountChanged);
    server.lastCommand.addListener(_onLastCommandChanged);
    server.laserActive.addListener(_onLaserChanged);
    server.pin.addListener(_onPinChanged);
    server.isPublicNetwork.addListener(_onPublicNetworkChanged);
    server.localIP.addListener(_onLocalIPChanged);
    server.startError.addListener(_onStartErrorChanged);
    server.mdnsAvailable.addListener(_onMdnsChanged);
    server.onMouseMove = _onMouseMove;
    _init();
  }

  Future<void> _init() async {
    _localIP = await server.getLocalIP();
    notifyListeners();
  }

  void _onLocalIPChanged() {
    _localIP = server.localIP.value;
    notifyListeners();
  }

  void _onRunningChanged() {
    _isRunning = server.isRunning.value;
    notifyListeners();
  }

  void _onClientCountChanged() {
    _clientCount = server.clientCount.value;
    notifyListeners();
  }

  void _onLastCommandChanged() {
    _lastCommand = server.lastCommand.value;
    notifyListeners();
  }

  void _onLaserChanged() {
    _laserActive = server.laserActive.value;
    notifyListeners();
  }

  void _onPinChanged() {
    _pin = server.pin.value;
    notifyListeners();
  }

  void _onPublicNetworkChanged() {
    _isPublicNetwork = server.isPublicNetwork.value;
    notifyListeners();
  }

  void _onStartErrorChanged() {
    _startError = server.startError.value;
    notifyListeners();
  }

  void _onMdnsChanged() {
    _mdnsAvailable = server.mdnsAvailable.value;
    notifyListeners();
  }

  void _onMouseMove(double x, double y) {
    _laserX = x;
    _laserY = y;
    // Feed laser position stream for the overlay trail
    if (_laserActive) {
      _laserPositionController.add(ui.Offset(x, y));
    }
    notifyListeners();
  }

  Future<void> startServer() async {
    _isStarting = true;
    notifyListeners();
    final futures = await Future.wait([
      server.start(),
      server.getLocalIP(),
    ]);
    _localIP = futures[1] as String;
    _isStarting = false;
    notifyListeners();
  }

  Future<void> stopServer() async {
    await server.stop();
    notifyListeners();
  }

  void triggerSlideStateUpdate() {
    server.triggerSlideStateUpdate();
  }

  @override
  void dispose() {
    server.isRunning.removeListener(_onRunningChanged);
    server.clientCount.removeListener(_onClientCountChanged);
    server.lastCommand.removeListener(_onLastCommandChanged);
    server.laserActive.removeListener(_onLaserChanged);
    server.pin.removeListener(_onPinChanged);
    server.isPublicNetwork.removeListener(_onPublicNetworkChanged);
    server.localIP.removeListener(_onLocalIPChanged);
    server.startError.removeListener(_onStartErrorChanged);
    server.mdnsAvailable.removeListener(_onMdnsChanged);
    server.onMouseMove = null;
    _laserPositionController.close();
    server.stop();
    super.dispose();
  }
}
