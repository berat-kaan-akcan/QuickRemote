import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/bluetooth/bt_hid_service.dart';
import '../services/bluetooth/bt_key_mapping.dart';
import '../utils/ui/app_snackbar.dart';
import 'settings/settings_screen.dart';
import 'bt_remote/views/bt_main_controls_view.dart';
import 'bt_remote/views/bt_touchpad_view.dart';
import 'bt_remote/views/bt_media_view.dart';

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
    _sub = _bt.stateStream.listen(_onBtState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    WakelockPlus.disable();
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
          message: 'Bluetooth bağlantısı koptu. Yeniden bağlanılıyor...',
          type: SnackbarType.warning,
          duration: const Duration(seconds: 3),
        );
      }
    } else if (state == BtHidConnectionState.connected) {
      AppSnackbar.show(
        context,
        message: 'Bluetooth bağlandı: ${_bt.connectedDeviceName ?? ""}',
        type: SnackbarType.success,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ── Command dispatch ───────────────────────────────────────────────────────

  Future<void> _send(String command) async {
    HapticFeedback.mediumImpact();

    // Update local screen toggle state
    if (command == 'BLACK_SCREEN') {
      setState(() => _activeScreen = _activeScreen == 'BLACK' ? null : 'BLACK');
    } else if (command == 'WHITE_SCREEN') {
      setState(() => _activeScreen = _activeScreen == 'WHITE' ? null : 'WHITE');
    } else if (['NEXT', 'PREV', 'START', 'END'].contains(command)) {
      setState(() => _activeScreen = null);
    }

    final action = BtKeyMapping.forCommand(command);
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
      body = BtTouchpadView(bt: _bt, send: _send, isConnected: isConnected);
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
        backgroundColor: const Color(0xFF0F172A),
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(isConnected),
        body: body,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isConnected) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: _buildHeader(isConnected),
    );
  }

  Widget _buildHeader(bool isConnected) {
    return Row(
      children: [
        // Logo
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
              Row(
                children: [
                  const Icon(Icons.bluetooth_rounded, color: Color(0xFF64B5F6), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _bt.connectedDeviceName ?? 'Bluetooth HID',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Connection status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (isConnected
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF5252))
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isConnected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252))
                  .withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isConnected ? 'Bağlı' : 'Kopuk',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isConnected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Settings button
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 22),
          tooltip: 'Ayarlar',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        // Close button
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
          tooltip: 'Kapat',
          onPressed: () async {
            final nav = Navigator.of(context);
            final shouldPop = await _showExitDialog();
            if (shouldPop && mounted) {
              _isIntentionalDisconnect = true;
              await _bt.stopAdvertising();
              nav.pop();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
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

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB74D), size: 40),
            title: const Text('Bağlantıyı Kes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text(
              'Bluetooth bağlantısı kesilecek ve ana ekrana dönülecek.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal', style: TextStyle(color: Colors.white54)),
              ),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(ctx).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Bağlantıyı Kes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
