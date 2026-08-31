import 'dart:async';
import 'package:flutter/material.dart' hide Size;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;
import 'screens/home_screen.dart';
import 'services/websocket_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: const ui.Size(420, 650),
    minimumSize: const ui.Size(380, 550),
    center: true,
    title: 'QuickRemote PC',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const QuickRemotePC());
}

class QuickRemotePC extends StatelessWidget {
  const QuickRemotePC({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebSocketServerProvider(),
      child: MaterialApp(
        title: 'QuickRemote PC',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Space Black
          colorSchemeSeed: const Color(0xFF005B96),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// Provider wrapper for WebSocketServer so it can notify listeners.
class WebSocketServerProvider extends ChangeNotifier {
  final WebSocketServer server = WebSocketServer();
  String _localIP = '...';
  bool _isRunning = false;
  int _clientCount = 0;
  String _lastCommand = '';
  bool _laserActive = false;
  double _laserX = 0;
  double _laserY = 0;
  String _pin = '';
  bool _isPublicNetwork = false;

  /// Stream controller for laser position updates (used by LaserOverlay).
  final StreamController<ui.Offset> _laserPositionController =
      StreamController<ui.Offset>.broadcast();

  String get localIP => _localIP;
  bool get isRunning => _isRunning;
  int get clientCount => _clientCount;
  String get lastCommand => _lastCommand;
  int get port => server.port;
  bool get laserActive => _laserActive;
  double get laserX => _laserX;
  double get laserY => _laserY;
  String get pin => _pin;
  bool get publicNetwork => _isPublicNetwork;
  Stream<ui.Offset> get laserPositionStream => _laserPositionController.stream;

  WebSocketServerProvider() {
    server.isRunning.addListener(_onRunningChanged);
    server.clientCount.addListener(_onClientCountChanged);
    server.lastCommand.addListener(_onLastCommandChanged);
    server.laserActive.addListener(_onLaserChanged);
    server.pin.addListener(_onPinChanged);
    server.isPublicNetwork.addListener(_onPublicNetworkChanged);
    server.onMouseMove = _onMouseMove;
    _init();
  }

  Future<void> _init() async {
    _localIP = await server.getLocalIP();
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
    await server.start();
    _localIP = await server.getLocalIP();
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
    server.onMouseMove = null;
    _laserPositionController.close();
    server.stop();
    super.dispose();
  }
}
