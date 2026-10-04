import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../l10n/app_language.dart';
import '../../l10n/failure_text.dart';
import '../../services/background_session.dart';
import '../../services/presentation_timer_controller.dart';
import '../../services/wifi_low_latency.dart';
import '../../services/websocket_service.dart';
import '../analytics/analytics_report_screen.dart';
import '../../providers/settings_provider.dart';

import 'utils/hardware_key_handler.dart';
import 'utils/remote_dialogs.dart';
import '../../utils/ui/app_snackbar.dart';
import '../../widgets/presentation_timer.dart';
import 'views/main_controls_view.dart';
import 'widgets/remote_chrome.dart';
import 'views/touchpad_view.dart';
import 'views/media_control_view.dart';
import '../../theme/app_colors.dart';

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
  /// Shared by the tabs that show the timer, so switching tabs keeps it running.
  final PresentationTimerController _timer = PresentationTimerController();

  late WebSocketService _wsRef;
  late HardwareKeyHandler _hardwareKeyHandler;
  bool _wasConnected = true;
  bool _wsRefReady = false;
  bool _canPop = false;
  String? _persistentError;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    BackgroundSession.acquire();
    WifiLowLatency.acquire();
    bindTimerToSettings(context, _timer);

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

    if (_wsRef.connectionState == AppConnectionState.connecting ||
        _wsRef.connectionState == AppConnectionState.reconnecting) {
      _persistentError = null;
    }

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
    final failure = _wsRef.lastCommandError;
    if (failure != null) {
      final message = context.l10n.failure(failure);
      _persistentError = message;
      AppSnackbar.show(
        context,
        message: message,
        type: SnackbarType.error,
        duration: const Duration(seconds: 3),
      );
      _wsRef.clearCommandError();
    }

    if (_wasConnected && !_wsRef.isConnected) {
      _wasConnected = false;
      // A failed connection is not retried, so don't promise that.
      if (_wsRef.connectionState != AppConnectionState.failed) {
        AppSnackbar.show(
          context,
          message: context.l10n.remoteConnectionLost,
          type: SnackbarType.warning,
          duration: const Duration(seconds: 3),
        );
      }
    } else if (!_wasConnected && _wsRef.isConnected) {
      _wasConnected = true;
      _persistentError = null; // Clear stale errors on reconnect
      AppSnackbar.show(
        context,
        message: context.l10n.remoteReconnected,
        type: SnackbarType.success,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _performExit({bool skipDialog = false}) async {
    if (!skipDialog) {
      final shouldPop = await RemoteDialogs.showExitDialog(context);
      if (!shouldPop) return;
    }

    if (_wsRefReady) {
      _wsRef.removeListener(_onConnectionChanged);
    }
    _wsRef.disconnect();
    
    if (mounted) {
      setState(() => _canPop = true);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    if (_wsRefReady) {
      _hardwareKeyHandler.detach();
      _wsRef.removeListener(_onConnectionChanged);
    }
    _timer.dispose();
    WakelockPlus.disable();
    BackgroundSession.release();
    WifiLowLatency.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();

    Widget body;
    if (ws.connectionState == AppConnectionState.failed || _canPop) {
      body = _buildFailedView(ws);
    } else if (_currentTab == 1) {
      body = TouchpadView(
        ws: ws,
        timer: _timer,
      );
    } else if (_currentTab == 2) {
      body = MediaControlView(ws: ws);
    } else {
      body = MainControlsView(
        ws: ws,
        timer: _timer,
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Tab 0'da değilsek, sadece sekmeyi değiştirip çıkışı iptal ediyoruz (Sistem geri tuşu davranışı).
        if (_currentTab != 0) {
          if (_currentTab == 1 && ws.isConnected) ws.sendCommand(RemoteCommands.modeArrow);
          setState(() => _currentTab = 0);
          return;
        }
        
        // Tab 0'daysak gerçek çıkış işlemini başlatıyoruz.
        await _performExit(skipDialog: false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(ws),
        body: body,
        bottomNavigationBar: _buildBottomNav(ws),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WebSocketService ws) {
    final connecting = ws.connectionState == AppConnectionState.reconnecting ||
        ws.connectionState == AppConnectionState.connecting;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: RemoteHeader(
        subtitle: Text(
          ws.serverAddress,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        isConnected: ws.isConnected,
        isConnecting: connecting,
        onReconnect: !ws.isConnected && ws.connectionState != AppConnectionState.failed
            ? ws.manualReconnect
            : null,
        onClose: () => _performExit(skipDialog: false),
      ),
    );
  }

  Widget _buildBottomNav(WebSocketService ws) {
    return RemoteBottomNav(
      currentTab: _currentTab,
      onTap: (index) {
        HapticFeedback.lightImpact();
        if (_currentTab == 1 && index != 1 && ws.isConnected) {
          ws.sendCommand(RemoteCommands.modeArrow);
        }
        setState(() => _currentTab = index);
      },
    );
  }

  Widget _buildFailedView(WebSocketService ws) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            context.l10n.remoteConnectFailedTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _persistentError ?? context.l10n.remoteServerUnreachable,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _performExit(skipDialog: true),
            icon: const Icon(Icons.home_rounded),
            label: Text(context.l10n.remoteBackHome),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
