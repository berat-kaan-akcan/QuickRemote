import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/bluetooth/bt_hid_service.dart';
import 'bt_remote_screen.dart';

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
        _errorMessage =
            'Bu cihaz Bluetooth HID özelliğini desteklemiyor.\nWiFi modunu kullanın.';
      });
      return;
    }

    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.bluetoothScan,
    ].request();

    final connectStatus = statuses[Permission.bluetoothConnect];
    if (connectStatus == PermissionStatus.denied || connectStatus == PermissionStatus.permanentlyDenied) {
      if (!mounted) return;
      setState(() {
        _state = BtHidConnectionState.error;
        _errorMessage = 'Bluetooth izni reddedildi. Ayarlardan izin vermelisiniz.';
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
        _errorMessage = 'Bluetooth hatası. Tekrar deneyin.';
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bluetooth ile Bağlan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -60, left: -60,
            child: _buildBlob(const Color(0xFF1565C0), 280),
          ),
          Positioned(
            bottom: -80, right: -60,
            child: _buildBlob(const Color(0xFF006064), 240),
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
        BtHidConnectionState.unsupported => _buildUnsupported(),
        BtHidConnectionState.error       => _buildError(),
        BtHidConnectionState.connected   => _buildConnected(),
        _                                => _buildWaiting(),
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
                  colors: [Color(0xFF1565C0), Color(0xFF006064)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(
                      alpha: 0.3 + _pulseController.value * 0.3,
                    ),
                    blurRadius: 30 + _pulseController.value * 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.bluetooth_rounded, color: Colors.white, size: 60),
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
                        ? 'Eşleştirme bekleniyor...'
                        : _state == BtHidConnectionState.disconnected
                            ? 'Bağlantı bekleniyor...'
                            : 'Hazırlanıyor...',
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
                  child: _GlowingDots(animation: _pulseController),
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
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Bağlanılmadı, tekrar deneniyor',
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

        // Step-by-step Windows guide card
        _buildStepsCard(),

        const Spacer(),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('İptal'),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.computer_rounded,
                      color: Colors.white.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Bilgisayarınızda şunları yapın:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep(1, 'Windows Ayarlar\'ı açın'),
              _buildStep(2, 'Bluetooth ve diğer cihazlar\'a gidin'),
              _buildStep(3, '"Cihaz ekle" butonuna basın'),
              _buildStep(4, 'Listeden telefonunuzun adını seçin'),
              _buildStep(5, 'Eşleştirmeyi onaylayın'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF64B5F6), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'İlk bağlantıda yalnızca bir kez eşleştirme gerekir. Sonraki bağlantılarda otomatik bağlanır.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.bluetooth_connected_rounded,
              color: Color(0xFF4CAF50),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bağlandı!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bt.connectedDeviceName ?? 'Bilinmeyen cihaz',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Uzaktan kontrol açılıyor...',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled_rounded,
                color: Colors.white38, size: 72),
            const SizedBox(height: 24),
            const Text(
              'Desteklenmiyor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Bu cihaz Bluetooth HID\'i desteklemiyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.wifi_rounded),
              label: const Text('WiFi Modunu Kullan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64B5F6),
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF5252), size: 64),
          const SizedBox(height: 20),
          const Text(
            'Hata',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Bluetooth hatası oluştu.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _state = BtHidConnectionState.disconnected;
                _errorMessage = null;
              });
              _startAdvertising();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingDots extends StatelessWidget {
  final Animation<double> animation;
  const _GlowingDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // dalgalanma efekti için basit bir sinüs hesabı
            final val = math.sin((animation.value * math.pi) + (index * math.pi / 4)).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 8 + (val * 4),
              height: 8 + (val * 4),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.3 + (val * 0.7)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64B5F6).withValues(alpha: val * 0.6),
                    blurRadius: 4 + (val * 8),
                    spreadRadius: val * 3,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
