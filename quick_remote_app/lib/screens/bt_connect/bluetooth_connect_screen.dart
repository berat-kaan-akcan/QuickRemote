import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/bluetooth/bt_hid_service.dart';
import '../bt_remote/bt_remote_screen.dart';
import 'widgets/bt_pairing_guide.dart';
import 'widgets/bt_status_views.dart';
import 'widgets/glowing_dots.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

/// Bluetooth Classic HID connection screen.
/// Registers the phone as a BT HID device and guides the user through
/// Windows-side pairing, then navigates to [BtRemoteScreen] on success.
class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen>
    with SingleTickerProviderStateMixin {
  final _bt = BtHidService.instance;
  StreamSubscription<BtHidConnectionState>? _sub;
  late AnimationController _pulseController;

  BtHidConnectionState _state = BtHidConnectionState.disconnected;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sub = _bt.stateStream.listen(_onStateChanged);
    _startAdvertising();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The breathing texts hold still when the system asks for less motion.
    if (AppMotion.reduced(context)) {
      _pulseController.stop();
      _pulseController.value = 1;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    // Don't stop advertising if we successfully connected (screen popped but BT still active)
    if (_state != BtHidConnectionState.connected) {
      _bt.stopAdvertising();
    }
    super.dispose();
  }

  Future<void> _startAdvertising() async {
    final supported = await _bt.isSupported();
    if (!mounted) return;

    if (!supported) {
      setState(() {
        _state = BtHidConnectionState.unsupported;
        _errorMessage = context.l10n.btUnsupportedLong;
      });
      return;
    }

    // Only CONNECT is needed: the PC finds and pairs the phone. Below
    // Android 12 permission_handler reports it as granted.
    final statuses = await [Permission.bluetoothConnect].request();

    final connectStatus = statuses[Permission.bluetoothConnect];
    if (connectStatus == PermissionStatus.denied ||
        connectStatus == PermissionStatus.permanentlyDenied) {
      if (!mounted) return;
      setState(() {
        _state = BtHidConnectionState.error;
        _errorMessage = context.l10n.btPermissionDenied;
      });
      return;
    }

    await _bt.startAdvertising();
  }

  void _onStateChanged(BtHidConnectionState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      if (state == BtHidConnectionState.error) {
        _errorMessage = context.l10n.btErrorRetry;
      }
    });
    if (state == BtHidConnectionState.connected) {
      // Small delay so user sees "Bağlandı!" before navigating
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_state != BtHidConnectionState.connected) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BtRemoteScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.homeConnectBluetooth),
      ),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        accent: p.info,
        child: SafeArea(
          child: ContentWidth(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final body = switch (_state) {
      BtHidConnectionState.unsupported => BtUnsupportedView(
        message: _errorMessage,
      ),
      BtHidConnectionState.error => BtErrorView(
        message: _errorMessage,
        onRetry: _retry,
      ),
      BtHidConnectionState.connected => BtConnectedView(
        deviceName: _bt.connectedDeviceName,
      ),
      _ => _buildWaiting(),
    };
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.slow),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      child: KeyedSubtree(
        key: ValueKey(switch (_state) {
          BtHidConnectionState.unsupported || BtHidConnectionState.error || BtHidConnectionState.connected => _state,
          _ => null,
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: body,
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    final p = context.palette;
    final retrying = _state == BtHidConnectionState.disconnected;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated BT icon
              Center(
                child: RadarPulse(
                  color: p.info,
                  size: 220,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color.lerp(p.info, Colors.white, 0.15)!, p.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: AppShadows.glow(p.info),
                    ),
                    child: const Icon(
                      Icons.bluetooth_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),

              // Status text
              Center(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) => Opacity(
                        opacity: 0.6 + (_pulseController.value * 0.4),
                        child: Text(
                          _state == BtHidConnectionState.advertising
                              ? context.l10n.btWaitingPairing
                              : retrying
                              ? context.l10n.btWaitingConnection
                              : context.l10n.btPreparing,
                          textAlign: TextAlign.center,
                          style: AppType.headline.copyWith(
                            color: retrying ? p.warning : p.textPrimary,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (_state == BtHidConnectionState.advertising)
                      GlowingDots(animation: _pulseController)
                    else if (retrying)
                      StatusPill(
                        color: p.warning,
                        icon: Icons.warning_amber_rounded,
                        label: context.l10n.btNotConnectedRetrying,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // Step-by-step pairing guide card (Windows / Linux)
              const FadeSlideIn(index: 1, child: BtPairingGuide()),

              const Spacer(),
              const SizedBox(height: AppSpace.lg),

              // Cancel button
              AppButton(
                label: context.l10n.cancel,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ],
    );
  }

  void _retry() {
    setState(() {
      _state = BtHidConnectionState.disconnected;
      _errorMessage = null;
    });
    _startAdvertising();
  }
}
