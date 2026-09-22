import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/websocket_service.dart';
import 'settings/settings_screen.dart';
import 'analytics_report_screen.dart';
import '../providers/settings_provider.dart';

import 'remote/utils/hardware_key_handler.dart';
import 'remote/utils/remote_dialogs.dart';
import 'remote/views/main_controls_view.dart';
import 'remote/views/touchpad_view.dart';
import 'remote/views/media_control_view.dart';

/// Main remote control screen for presentation control.
/// Has three views: main controls, touchpad mode, and media controls.
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  /// 0 = Kontroller, 1 = Touchpad, 2 = Medya
  int _currentTab = 0;
  final GlobalKey _presentationTimerKeyMain = GlobalKey();
  final GlobalKey _presentationTimerKeyTouchpad = GlobalKey();

  late WebSocketService _wsRef;
  late HardwareKeyHandler _hardwareKeyHandler;
  bool _wasConnected = true;
  bool _wsRefReady = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wsRef = context.read<WebSocketService>();
      _wasConnected = _wsRef.isConnected;
      _wsRef.addListener(_onConnectionChanged);
      
      _hardwareKeyHandler = HardwareKeyHandler(
        wsRef: _wsRef,
        onCommand: (command) => _wsRef.sendCommand(command),
      );
      _hardwareKeyHandler.attach();

      _wsRefReady = true;
    });
  }

  void _onConnectionChanged() {
    if (!mounted) return;

    // Check for auto-completed analytics (presentation ended naturally)
    if (_wsRef.completedAnalytics != null) {
      final analytics = _wsRef.completedAnalytics!;
      _wsRef.clearCompletedAnalytics();

      // Save to history
      final settings = context.read<SettingsProvider>();
      settings.savePresentationAnalytics(analytics);

      // Show report
      AnalyticsReportScreen.showAsBottomSheet(context, analytics);
    }

    // Check for command errors
    if (_wsRef.lastCommandError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_wsRef.lastCommandError!),
          backgroundColor: const Color(0xFFFF5252),
          duration: const Duration(seconds: 3),
        ),
      );
      _wsRef.clearCommandError();
    }

    if (_wasConnected && !_wsRef.isConnected) {
      _wasConnected = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı koptu, otomatik bağlanılıyor...'),
          backgroundColor: Color(0xFFFF9800),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (!_wasConnected && _wsRef.isConnected) {
      _wasConnected = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeniden bağlanıldı!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_wsRefReady) {
      _hardwareKeyHandler.detach();
      _wsRef.removeListener(_onConnectionChanged);
    }
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();

    Widget body;
    if (ws.connectionState == AppConnectionState.failed) {
      body = _buildFailedView(ws);
    } else if (_currentTab == 1) {
      body = TouchpadView(
        ws: ws,
        presentationTimerKey: _presentationTimerKeyTouchpad,
      );
    } else if (_currentTab == 2) {
      body = MediaControlView(ws: ws);
    } else {
      body = MainControlsView(
        ws: ws,
        presentationTimerKey: _presentationTimerKeyMain,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentTab != 0) {
          if (_currentTab == 1 && ws.isConnected) ws.sendCommand('MODE_ARROW');
          setState(() => _currentTab = 0);
          return;
        }
        final shouldPop = await RemoteDialogs.showExitDialog(context);
        if (shouldPop) {
          if (_wsRefReady) ws.removeListener(_onConnectionChanged);
          ws.disconnect();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(ws),
        body: body,
        bottomNavigationBar: _buildBottomNav(ws),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WebSocketService ws) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: _buildHeader(context, ws),
    );
  }

  Widget _buildBottomNav(WebSocketService ws) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.white38,
        currentIndex: _currentTab.clamp(0, 2),
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (_currentTab == 1 && index != 1 && ws.isConnected) {
            ws.sendCommand('MODE_ARROW');
          }
          setState(() => _currentTab = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad_rounded),
            label: 'Kontroller',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app_rounded),
            label: 'Touchpad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music_rounded),
            label: 'Medya',
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView(WebSocketService ws) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Bağlantı Kurulamadı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sunucuya ulaşılamıyor. Lütfen PC uygulamasının açık olduğundan emin olun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ws.manualReconnect(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yeniden Bağlan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ws.removeListener(_onConnectionChanged);
              ws.disconnect();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WebSocketService ws) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QuickRemote',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                ws.serverAddress,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        if (!ws.isConnected && ws.connectionState != AppConnectionState.failed)
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: () {
              ws.manualReconnect();
            },
            tooltip: 'Yeniden Bağlan',
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ws.isConnected
                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                : const Color(0xFFFF5252).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ws.isConnected
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                  : const Color(0xFFFF5252).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ws.connectionState == AppConnectionState.reconnecting ||
                  ws.connectionState == AppConnectionState.connecting)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 5),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF5252),
                    ),
                  ),
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: ws.isConnected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                ws.isConnected
                    ? 'Bağlı'
                    : (ws.connectionState == AppConnectionState.reconnecting ||
                              ws.connectionState ==
                                  AppConnectionState.connecting
                          ? 'Bağlanıyor...'
                          : 'Kopuk'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ws.isConnected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.settings_rounded,
            color: Colors.white54,
            size: 22,
          ),
          tooltip: 'Ayarlar',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white54,
            size: 22,
          ),
          tooltip: 'Kapat',
          onPressed: () async {
            final shouldPop = await RemoteDialogs.showExitDialog(context);
            if (shouldPop) {
              ws.removeListener(_onConnectionChanged);
              ws.disconnect();
              if (context.mounted) Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
