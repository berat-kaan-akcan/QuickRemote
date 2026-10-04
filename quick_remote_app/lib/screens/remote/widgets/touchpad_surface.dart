import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

extension DrawToolStyle on DrawTool {
  Color colorIn(AppPalette p) => switch (this) {
        DrawTool.laser => p.toolLaser,
        DrawTool.pen => p.toolPen,
        DrawTool.highlighter => p.toolHighlighter,
        DrawTool.eraser => p.toolEraser,
      };

  IconData get icon => switch (this) {
        DrawTool.laser => Icons.highlight_rounded,
        DrawTool.pen => Icons.edit_rounded,
        DrawTool.highlighter => Icons.border_color_rounded,
        DrawTool.eraser => Icons.auto_fix_high_rounded,
      };
}

/// The touchpad's look, shared by the Wi-Fi and Bluetooth remotes: a quiet
/// dotted panel with a hint, lit in the tool's color while a finger is down,
/// with a glow under the finger.
class TouchpadSurface extends StatelessWidget {
  const TouchpadSurface({
    super.key,
    required this.isDrawActive,
    required this.activeTool,
    this.laserLabel,
    this.touch,
  });

  final bool isDrawActive;
  final DrawTool activeTool;

  /// Replaces "Laser" where the laser is just the mouse cursor.
  final String? laserLabel;

  /// Where the finger is, in the surface's coordinates; repaints only the
  /// glow layer.
  final ValueListenable<Offset?>? touch;

  String _label(BuildContext context, DrawTool tool) => switch (tool) {
        DrawTool.laser => laserLabel ?? context.l10n.toolLaser,
        DrawTool.pen => context.l10n.toolPen,
        DrawTool.highlighter => context.l10n.toolHighlighter,
        DrawTool.eraser => context.l10n.toolEraser,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final toolColor = activeTool.colorIn(p);
    final radius = AppRadius.all(AppRadius.xl);

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: radius,
              border: Border.all(color: p.border, width: 1.5),
              boxShadow: AppShadows.soft(p),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(painter: _DotGridPainter(p.textMuted.withValues(alpha: p.isDark ? 0.22 : 0.20))),
            ),
          ),
        ),
        // Fades in instead of animating the border, so a touch repaints
        // only this layer.
        AnimatedOpacity(
          duration: AppMotion.of(context, const Duration(milliseconds: 180)),
          opacity: isDrawActive ? 1.0 : 0.0,
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: toolColor, width: 2.5),
                gradient: RadialGradient(
                  radius: 1.2,
                  colors: [
                    toolColor.withValues(alpha: p.isDark ? 0.10 : 0.06),
                    toolColor.withValues(alpha: p.isDark ? 0.02 : 0.01),
                  ],
                ),
                boxShadow: [BoxShadow(color: toolColor.withValues(alpha: 0.22), blurRadius: 24, spreadRadius: -2)],
              ),
            ),
          ),
        ),
        if (touch != null)
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(painter: _TouchGlowPainter(touch!, toolColor)),
            ),
          ),
        IgnorePointer(
          child: Center(
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.fast),
              child: isDrawActive
                  ? Column(
                      key: const ValueKey('active'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeTool.icon, color: toolColor.withValues(alpha: 0.4), size: 48),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          _label(context, activeTool),
                          style: AppType.titleSmall.copyWith(color: toolColor.withValues(alpha: 0.6)),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.surfaceSunken,
                            border: Border.all(color: p.border),
                          ),
                          child: Icon(Icons.touch_app_rounded, color: p.textMuted, size: 30),
                        ),
                        const SizedBox(height: AppSpace.md),
                        _HintRow(
                          count: 1,
                          text: context.l10n.tapForTool(_label(context, DrawTool.laser)),
                        ),
                        const SizedBox(height: 6),
                        _HintRow(count: 2, text: context.l10n.doubleTapSelected),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.count, required this.text});

  final int count;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(color: p.textMuted, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: AppType.bodySmall.copyWith(color: p.textMuted, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 22.0;
    final paint = Paint()..color = color;
    for (var y = gap; y < size.height; y += gap) {
      for (var x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

class _TouchGlowPainter extends CustomPainter {
  _TouchGlowPainter(this.touch, this.color) : super(repaint: touch);

  final ValueListenable<Offset?> touch;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final at = touch.value;
    if (at == null) return;
    const r = 56.0;
    final rect = Rect.fromCircle(center: at, radius: r);
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: 0.32),
          color.withValues(alpha: 0),
        ]).createShader(rect),
    );
    canvas.drawCircle(at, 7, Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_TouchGlowPainter old) => old.touch != touch || old.color != color;
}
