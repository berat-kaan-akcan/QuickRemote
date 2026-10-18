import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../widgets/ui/ui.dart';

/// Asks the user to compare the PC's security code before the PIN is sent:
/// the first connection without the QR code, or a certificate that changed
/// ([changed]). True when the user says the codes are the same.
Future<bool> showSecurityCodeDialog(BuildContext context, {required String code, required bool changed}) async {
  final result = await AppPopupTheme.showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SecurityCodeDialog(code: code, changed: changed),
  );
  return result ?? false;
}

class _SecurityCodeDialog extends StatelessWidget {
  const _SecurityCodeDialog({required this.code, required this.changed});

  final String code;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final tone = changed ? p.warning : p.success;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPopupTheme.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: IconBadge(
                  icon: changed ? Icons.shield_rounded : Icons.verified_user_rounded,
                  color: tone,
                  size: 52,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                changed ? l10n.certWarningTitle : l10n.verifyTitle,
                textAlign: TextAlign.center,
                style: AppType.title.copyWith(color: p.textPrimary, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                changed ? l10n.certWarningIntro : l10n.verifyIntro,
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: p.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: AppSpace.sm),
              CustomPaint(
                foregroundPainter: _DashedBorderPainter(color: p.primaryText, radius: AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 14),
                  decoration: BoxDecoration(color: p.surfaceSunken, borderRadius: AppRadius.all(AppRadius.md)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SelectableText(
                      code,
                      textAlign: TextAlign.center,
                      style: AppType.numeric.copyWith(color: p.textPrimary, fontSize: 18, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                changed ? l10n.certWarningNote : l10n.verifyNote,
                textAlign: TextAlign.center,
                style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: AppSpace.md),
              AppButton(
                label: changed ? l10n.certWarningConfirm : l10n.verifyConfirm,
                tone: changed ? AppTone.warning : AppTone.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: AppSpace.xs),
              AppButton(
                label: l10n.cancelAction,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                height: 44,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashed rounded border: the code is to be compared, not typed.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}
