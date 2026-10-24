import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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
    // The camera kept sending frames while the screen slid away, which made
    // the way back stutter. Paused, the preview keeps its last frame.
    unawaited(_controller.pause());
    _sweep.stop();
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
              errorBuilder: (context, error) => ScanErrorView(error: error.errorCode),
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

            // Header, pinned to the top: the expanding Stack would otherwise
            // stretch it over the screen and the Row would center vertically.
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, 0),
                  child: Row(
                    children: [
                      _GlassCircleButton(
                        icon: Icons.close_rounded,
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          context.l10n.scanTitle,
                          style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Under the frame, which the overlay centers 24 px above the middle.
            Positioned(
              left: AppSpace.xl,
              right: AppSpace.xl,
              top: size.height / 2 - 24 + frame / 2 + AppSpace.lg,
              child: FadeSlideIn(
                child: Text(
                  context.l10n.scanHint,
                  textAlign: TextAlign.center,
                  style: AppType.label.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the camera when it cannot start: a refused permission
/// gets a way to Settings, anything else a plain note. Both point back to
/// typing the address, so the user is never left on a black screen.
class ScanErrorView extends StatelessWidget {
  const ScanErrorView({super.key, required this.error, this.onOpenSettings});

  final MobileScannerErrorCode error;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final denied = error == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: AppColors.black,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_rounded, color: AppColors.white, size: 56),
                const SizedBox(height: AppSpace.md),
                Semantics(
                  header: true,
                  child: Text(
                    denied ? l10n.scanPermissionTitle : l10n.scanUnavailableTitle,
                    textAlign: TextAlign.center,
                    style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  denied ? l10n.scanPermissionDenied : l10n.scanUnavailable,
                  textAlign: TextAlign.center,
                  style: AppType.label.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSpace.lg),
                if (denied)
                  AppButton(
                    label: l10n.scanOpenSettings,
                    icon: Icons.settings_rounded,
                    onPressed: onOpenSettings ?? openAppSettings,
                  ),
                AppButton(
                  label: l10n.scanGoBack,
                  variant: AppButtonVariant.ghost,
                  tone: AppTone.neutral,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
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
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      tooltip: tooltip,
      semanticLabel: tooltip,
      pressedScale: 0.9,
      minTarget: 48,
      borderRadius: radius,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.4),
          borderRadius: radius,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}

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
