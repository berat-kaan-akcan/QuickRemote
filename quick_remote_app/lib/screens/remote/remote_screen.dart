import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../l10n/app_language.dart';
import '../../l10n/failure_text.dart';
import '../../services/background_session.dart';
import '../../services/presentation_timer_controller.dart';
import '../../services/wear/wear_bridge.dart';
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
import 'widgets/program_sheet.dart';
import 'utils/show_info.dart';
import '../../models/draw_tool.dart';
import '../../services/websocket/presentation_state.dart';
import '../../widgets/status_view.dart';
import '../../widgets/ui/ui.dart';

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

  /// The ink (BGR) last sent to the pen and the highlighter on this
  /// connection; the PC does not tell its own.
  final Map<DrawTool, int> _inks = {};

  late WebSocketService _wsRef;
  late WearBridge _wear;
  late HardwareKeyHandler _hardwareKeyHandler;
  bool _wasConnected = true;
  bool _wsRefReady = false;
  bool _canPop = false;
  String? _persistentError;
  bool _reportOpen = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    BackgroundSession.acquire();
    WifiLowLatency.acquire();
    bindTimerToSettings(context, _timer);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wsRef = context.read<WebSocketService>();
      // The watch shows this timer and vibrates with it.
      _wear = context.read<WearBridge>()..attachTimer(_timer);
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
      _reportOpen = true;
      AnalyticsReportScreen.showAsBottomSheet(context, analytics)
          .whenComplete(() => _reportOpen = false);
    }

    // A new show puts the last one's report away: it is in the history, and
    // the presenter needs the remote, not a report left open over it.
    if (_reportOpen && _wsRef.isPptRunning) {
      _reportOpen = false;
      Navigator.of(context)
          .popUntil((route) => route.settings.name != AnalyticsReportScreen.sheetRouteName);
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
      _wear.detachTimer();
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
    final program = remoteProgram(ws, context.watch<SettingsProvider>());

    Widget body;
    if (ws.connectionState == AppConnectionState.failed || _canPop) {
      body = _buildFailedView(ws);
    } else if (_currentTab == 1) {
      body = TouchpadView(
        ws: ws,
        timer: _timer,
        inks: _inks,
        onInk: (tool, bgr) => setState(() => _inks[tool] = bgr),
      );
    } else if (_currentTab == 2) {
      body = MediaControlView(ws: ws);
    } else {
      body = MainControlsView(
        ws: ws,
        timer: _timer,
        program: program,
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
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(ws, program),
        // Only the new tab fades in; the old one leaves at once, so it never
        // takes a touch meant for the new one.
        body: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.base),
          switchInCurve: AppMotion.enter,
          layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
          child: KeyedSubtree(
            key: ValueKey(ws.connectionState == AppConnectionState.failed || _canPop ? -1 : _currentTab),
            child: body,
          ),
        ),
        bottomNavigationBar: _buildBottomNav(ws),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WebSocketService ws, String program) {
    final connecting = ws.connectionState == AppConnectionState.reconnecting ||
        ws.connectionState == AppConnectionState.connecting;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: AppSpace.md,
      title: RemoteHeader(
        title: ws.pcLabel,
        subtitle: Text(PresentationState.shortNameOf(program)),
        onSubtitleTap: () => ProgramSheet.show(context),
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
    final p = context.palette;
    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
        child: StatusView(
          icon: Icons.wifi_off_rounded,
          color: p.danger,
          title: context.l10n.remoteConnectFailedTitle,
          message: _persistentError ?? context.l10n.remoteServerUnreachable,
          actions: [
            AppButton(
              label: context.l10n.remoteBackHome,
              icon: Icons.home_rounded,
              onPressed: () => _performExit(skipDialog: true),
            ),
          ],
        ),
      ),
    );
  }
}
