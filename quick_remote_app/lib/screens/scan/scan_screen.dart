import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../utils/ui/app_snackbar.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/ui.dart';

/// QR Code scanner screen to connect to PC companion app.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  /// Moves the laser line through the frame.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
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
    final size = MediaQuery.sizeOf(context);
    final frame = (size.shortestSide * 0.7).clamp(220.0, 320.0);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnnotatedRegion(
        value: AppTheme.overlayStyle(AppPalette.dark),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // Scrim with the frame cut out, corners and the laser line.
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) => CustomPaint(
                  painter: _ScannerOverlayPainter(
                    frame: frame,
                    sweep: AppMotion.reduced(context) ? null : _sweep.value,
                  ),
                ),
              ),
            ),

            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Row(
                  children: [
                    _GlassCircleButton(
                      icon: Icons.close_rounded,
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.scanTitle,
                        textAlign: TextAlign.center,
                        style: AppType.title.copyWith(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpace.minTouch),
                  ],
                ),
              ),
            ),

            // Bottom instruction
            Positioned(
              left: AppSpace.xl,
              right: AppSpace.xl,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpace.xxl,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.72),
                        borderRadius: AppRadius.all(AppRadius.lg),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          const IconBadge(icon: Icons.qr_code_2_rounded, color: AppColors.cobaltLight, size: 40),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              context.l10n.scanHint,
                              style: AppType.body.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onTap,
      color: AppColors.white,
      background: AppColors.ink.withValues(alpha: 0.55),
    );
  }
}

/// Darkens the camera outside a rounded frame, draws the frame's corners in
/// the brand color and a laser line at [sweep] (0 top, 1 bottom).
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.frame, required this.sweep});

  final double frame;
  final double? sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: size.center(const Offset(0, -24)), width: frame, height: frame);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.xl));

    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(scrim, Paint()..color = AppColors.scannerScrim);

    // Corner brackets.
    const len = 34.0;
    const r = AppRadius.xl;
    final corner = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    void bracket(Offset o, double sx, double sy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + sy * (r + len - 12))
        ..lineTo(o.dx, o.dy + sy * r)
        ..arcToPoint(Offset(o.dx + sx * r, o.dy), radius: const Radius.circular(r), clockwise: sx * sy > 0)
        ..lineTo(o.dx + sx * (r + len - 12), o.dy);
      canvas.drawPath(path, corner);
    }

    bracket(rect.topLeft, 1, 1);
    bracket(rect.topRight, -1, 1);
    bracket(rect.bottomLeft, 1, -1);
    bracket(rect.bottomRight, -1, -1);

    // The laser line with a soft glow, fading at its ends.
    final t = sweep;
    if (t != null) {
      final y = rect.top + 18 + (rect.height - 36) * Curves.easeInOut.transform(t);
      final lineRect = Rect.fromLTRB(rect.left + 18, y - 12, rect.right - 18, y + 12);
      final fade = LinearGradient(colors: [
        AppColors.laser.withValues(alpha: 0),
        AppColors.laser,
        AppColors.laser.withValues(alpha: 0),
      ]);
      canvas.drawRect(
        lineRect,
        Paint()
          ..shader = fade.createShader(lineRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..color = AppColors.laser.withValues(alpha: 0.35),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(lineRect.left, y - 1.5, lineRect.right, y + 1.5), const Radius.circular(2)),
        Paint()..shader = fade.createShader(lineRect),
      );
    }
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) => old.frame != frame || old.sweep != sweep;
}
