import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/bluetooth/bt_hid_service.dart';
import '../bt_remote/bt_remote_screen.dart';
import 'widgets/bt_pairing_guide.dart';
import 'widgets/bt_status_views.dart';
import 'widgets/glowing_dots.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.homeConnectBluetooth,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -60,
            left: -60,
            child: _buildBlob(AppColors.bluetooth, 280),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _buildBlob(AppColors.bluetoothDark, 240),
          ),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12 + _pulseController.value * 0.06),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 80 + _pulseController.value * 20,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: switch (_state) {
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
      },
    );
  }

  Widget _buildWaiting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Animated BT icon
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.bluetooth, AppColors.bluetoothDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bluetooth.withValues(
                      alpha: 0.3 + _pulseController.value * 0.3,
                    ),
                    blurRadius: 30 + _pulseController.value * 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bluetooth_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Status text
        Center(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Opacity(
                  opacity: 0.5 + (_pulseController.value * 0.5),
                  child: Text(
                    _state == BtHidConnectionState.advertising
                        ? context.l10n.btWaitingPairing
                        : _state == BtHidConnectionState.disconnected
                        ? context.l10n.btWaitingConnection
                        : context.l10n.btPreparing,
                    style: TextStyle(
                      color: _state == BtHidConnectionState.disconnected
                          ? Colors.orangeAccent
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_state == BtHidConnectionState.advertising)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: GlowingDots(animation: _pulseController),
                )
              else if (_state == BtHidConnectionState.disconnected)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Opacity(
                      opacity: 0.4 + (_pulseController.value * 0.6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            context.l10n.btNotConnectedRetrying,
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Step-by-step pairing guide card (Windows / Linux)
        const BtPairingGuide(),

        const Spacer(),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(context.l10n.cancel),
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
