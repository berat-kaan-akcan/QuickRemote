import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR Code scanner screen to connect to PC companion app.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!;
    debugPrint('QR Scanned: $value');

    // Expected format: quickremote://192.168.1.x:8090:1234
    if (!value.startsWith('quickremote://')) {
      _showQrError('Geçersiz QR kodu. "quickremote://" formatı bekleniyor.');
      return;
    }

    final address = value.replaceFirst('quickremote://', '');
    final parts = address.split(':');

    if (parts.length < 2) {
      _showQrError('QR kodu beklenen formatta değil.\nFormat: quickremote://IP:PORT:PIN');
      return;
    }

    final host = parts[0].trim();
    if (host.isEmpty) {
      _showQrError('QR kodunda IP adresi eksik.');
      return;
    }

    // Flexible host format check (IPv4, IPv6, hostname)
    final hostRegex = RegExp(r'^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}|localhost|([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}|\[[a-fA-F0-9:]+\]|[a-zA-Z0-9-]+)$');
    if (!hostRegex.hasMatch(host)) {
      _showQrError('QR kodundaki IP/Host adresi geçersiz: $host');
      return;
    }

    final port = int.tryParse(parts[1]);
    if (port == null || port < 1 || port > 65535) {
      _showQrError('QR kodunda geçersiz port numarası: ${parts[1]}');
      return;
    }

    final pin = parts.length >= 3 ? parts[2] : '';

    _scanned = true;
    Navigator.of(context).pop({'host': host, 'port': port, 'pin': pin});
  }

  void _showQrError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF5252),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Scan frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      Text(
                        'QR Kodu Tara',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 32),
                const SizedBox(height: 8),
                Text(
                  'PC ekranındaki QR kodu tarayın',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
