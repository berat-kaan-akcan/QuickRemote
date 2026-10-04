import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../services/background_session.dart';
import '../../services/bluetooth/bt_hid_service.dart';
import '../../services/bluetooth/bt_key_mapping.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui/app_dialog.dart';
import '../../utils/ui/app_snackbar.dart';
import '../remote/widgets/remote_chrome.dart';
import 'views/bt_main_controls_view.dart';
import 'views/bt_touchpad_view.dart';
import 'views/bt_media_view.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

// ─── BT Remote Screen ────────────────────────────────────────────────────────
// WiFi remote screen ile aynı tasarım; BT HID'de çalışmayan özellikler
// (slayt sayısı, notlar, kalem rengi, volume slider, now-playing, PPT video)
// kaldırıldı. View'lar ayrı dosyalarda:
//   - bt_remote/views/bt_main_controls_view.dart  (Tab 0)
//   - bt_remote/views/bt_touchpad_view.dart        (Tab 1)
//   - bt_remote/views/bt_media_view.dart            (Tab 2)
// ─────────────────────────────────────────────────────────────────────────────

class BtRemoteScreen extends StatefulWidget {
  const BtRemoteScreen({super.key});

  @override
  State<BtRemoteScreen> createState() => _BtRemoteScreenState();
}

class _BtRemoteScreenState extends State<BtRemoteScreen>
    with WidgetsBindingObserver {
  final _bt = BtHidService.instance;
  StreamSubscription<BtHidConnectionState>? _sub;

  /// 0 = Kontroller, 1 = Touchpad, 2 = Medya
  int _currentTab = 0;
  String? _activeScreen; // 'BLACK' | 'WHITE' | null
  bool _isIntentionalDisconnect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    BackgroundSession.acquire();
    _sub = _bt.stateStream.listen(_onBtState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    WakelockPlus.disable();
    BackgroundSession.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana geldi — bağlantıyı kontrol et
      if (!_bt.isConnected && _bt.isAdvertisingRequested) {
        _bt.ensureConnected();
      }
    }
  }

  void _onBtState(BtHidConnectionState state) {
    if (!mounted) return;
    setState(() {});
    if (state == BtHidConnectionState.disconnected) {
      if (!_isIntentionalDisconnect) {
        AppSnackbar.show(
          context,
          message: context.l10n.btConnectionLost,
          type: SnackbarType.warning,
          duration: const Duration(seconds: 3),
        );
      }
    } else if (state == BtHidConnectionState.connected) {
      AppSnackbar.show(
        context,
        message: context.l10n.btConnectedTo(_bt.connectedDeviceName ?? ''),
        type: SnackbarType.success,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ── Command dispatch ───────────────────────────────────────────────────────

  Future<void> _send(String command) async {
    HapticFeedback.mediumImpact();

    // Update local screen toggle state
    if (command == RemoteCommands.blackScreen) {
      setState(() => _activeScreen = _activeScreen == 'BLACK' ? null : 'BLACK');
    } else if (command == RemoteCommands.whiteScreen) {
      setState(() => _activeScreen = _activeScreen == 'WHITE' ? null : 'WHITE');
    } else if ([RemoteCommands.next, RemoteCommands.prev, RemoteCommands.start, RemoteCommands.end].contains(command)) {
      setState(() => _activeScreen = null);
    }

    final target = context.read<SettingsProvider>().btTarget;
    final action = BtKeyMapping.forCommand(command, target: target);
    if (action != null) {
      await action.execute(_bt);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = _bt.isConnected;

    Widget body;
    if (_currentTab == 1) {
      final settings = context.watch<SettingsProvider>();
      body = BtTouchpadView(
        bt: _bt,
        send: _send,
        isConnected: isConnected,
        target: settings.btTarget,
        onTargetChanged: settings.setBtTarget,
      );
    } else if (_currentTab == 2) {
      body = BtMediaView(send: _send, isConnected: isConnected);
    } else {
      body = BtMainControlsView(
        send: _send,
        isConnected: isConnected,
        activeScreen: _activeScreen,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentTab != 0) {
          setState(() => _currentTab = 0);
          return;
        }
        final shouldPop = await _showExitDialog();
        if (shouldPop) {
          _isIntentionalDisconnect = true;
          await _bt.stopAdvertising();
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(isConnected),
        // Only the new tab fades in; the old one leaves at once.
        body: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.base),
          switchInCurve: AppMotion.enter,
          layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
          child: KeyedSubtree(key: ValueKey(_currentTab), child: body),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isConnected) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: AppSpace.md,
      title: RemoteHeader(
        subtitle: Row(
          children: [
            Icon(Icons.bluetooth_rounded, color: context.palette.info, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _bt.connectedDeviceName ?? 'Bluetooth HID',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        isConnected: isConnected,
        onClose: () async {
          final nav = Navigator.of(context);
          final shouldPop = await _showExitDialog();
          if (shouldPop && mounted) {
            _isIntentionalDisconnect = true;
            await _bt.stopAdvertising();
            nav.pop();
          }
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return RemoteBottomNav(
      currentTab: _currentTab,
      onTap: (index) {
        HapticFeedback.lightImpact();
        setState(() => _currentTab = index);
      },
    );
  }

  Future<bool> _showExitDialog() async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: context.l10n.disconnectTitle,
      content: context.l10n.btDisconnectContent,
      confirmText: context.l10n.disconnectTitle,
      tone: AppTone.danger,
      icon: Icons.bluetooth_disabled_rounded,
      iconTone: AppTone.warning,
    );
    if (confirmed) HapticFeedback.mediumImpact();
    return confirmed;
  }
}
