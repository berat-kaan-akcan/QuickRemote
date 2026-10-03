import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../utils/ui/app_snackbar.dart';
import '../l10n/app_language.dart';

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

    // The value carries the PIN, so it is not logged.
    final (payload, error) = PairingPayload.parse(barcode.rawValue!);
    if (payload == null) {
      _showQrError(switch (error) {
        PairingError.notQuickRemote => context.l10n.qrNotQuickRemote,
        PairingError.missingHost => context.l10n.qrMissingHost,
        PairingError.invalidPort => context.l10n.qrInvalidPort,
        PairingError.invalidPin => context.l10n.qrInvalidPin,
        PairingError.invalidFingerprint => context.l10n.qrInvalidFingerprint,
        _ => context.l10n.qrBadFormat,
      });
      return;
    }

    final fingerprint = payload.certFingerprint;
    _scanned = true;
    Navigator.of(context).pop({
      'host': payload.host,
      'port': payload.port,
      'pin': payload.pin,
      if (fingerprint != null) 'fingerprint': PairingPayload.fingerprintToHex(fingerprint),
    });
  }

  void _showQrError(String message) {
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: message,
      type: SnackbarType.error,
      duration: const Duration(seconds: 3),
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
                        context.l10n.scanTitle,
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
                  context.l10n.scanHint,
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
