import 'dart:math' as math;

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

/// The path of the finger on the touchpad, drawn in the tool's way: a short
/// tail behind the laser, the pen's line, the highlighter's band, the
/// eraser's ring. [fade] runs from 0 to 1 after the finger lifts.
class TouchTrail extends ChangeNotifier {
  final List<Offset> points = [];
  DrawTool tool = DrawTool.laser;

  /// The ink of the pen or highlighter; null draws in the tool's color.
  Color? ink;
  double fade = 0;

  /// The finger is down.
  bool touching = false;

  // Enough for a long stroke; older points drop off the start.
  static const _maxPoints = 400;

  void start(Offset at, DrawTool tool, Color? ink) {
    points
      ..clear()
      ..add(at);
    this.tool = tool;
    this.ink = ink;
    fade = 0;
    touching = true;
    notifyListeners();
  }

  void add(Offset at) {
    points.add(at);
    if (points.length > _maxPoints) points.removeAt(0);
    notifyListeners();
  }

  void end() {
    touching = false;
    notifyListeners();
  }

  void setFade(double value) {
    fade = value;
    if (value >= 1) points.clear();
    notifyListeners();
  }
}

/// The touchpad's look, shared by the Wi-Fi and Bluetooth remotes: a dotted
/// panel with the selected tool's chip, the two gestures along the bottom
/// and the finger's trail.
class TouchpadSurface extends StatelessWidget {
  const TouchpadSurface({
    super.key,
    required this.isDrawActive,
    required this.activeTool,
    this.selectedTool,
    this.laserLabel,
    this.laserIcon,
    this.laserColor,
    this.touch,
    this.trail,
    this.enabled = true,
  });

  final bool isDrawActive;

  /// The tool of the touch in progress.
  final DrawTool activeTool;

  /// The tool a double tap uses, named in the chip; [activeTool] if null.
  final DrawTool? selectedTool;

  /// Replaces "Laser" where the laser is the mouse cursor or the arrow.
  final String? laserLabel;
  final IconData? laserIcon;
  final Color? laserColor;

  /// Where the finger is, in the surface's coordinates; repaints only the
  /// glow layer. Used without a [trail].
  final ValueListenable<Offset?>? touch;
  final TouchTrail? trail;

  /// False while no slideshow runs: no chip, and a line saying the tools
  /// wait for one.
  final bool enabled;

  String _label(BuildContext context, DrawTool tool) => switch (tool) {
    DrawTool.laser => laserLabel ?? context.l10n.toolLaser,
    DrawTool.pen => context.l10n.toolPen,
    DrawTool.highlighter => context.l10n.toolHighlight,
    DrawTool.eraser => context.l10n.toolEraser,
  };

  IconData _icon(DrawTool tool) =>
      tool == DrawTool.laser ? laserIcon ?? tool.icon : tool.icon;

  Color _color(AppPalette p, DrawTool tool) =>
      tool == DrawTool.laser ? laserColor ?? tool.colorIn(p) : tool.colorIn(p);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.xl);
    final chipTool = selectedTool ?? activeTool;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: radius,
              border: Border.all(color: p.border),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(
                painter: _DotGridPainter(
                  p.primaryText.withValues(alpha: p.isDark ? 0.16 : 0.22),
                ),
              ),
            ),
          ),
        ),
        if (trail != null)
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(painter: _TrailPainter(trail!, p, laserColor)),
            ),
          )
        else if (touch != null)
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(
                painter: _TouchGlowPainter(touch!, _color(p, activeTool)),
              ),
            ),
          ),
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              AppSpace.sm,
              14,
              AppSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (enabled)
                  AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.fast),
                    child: _ToolChip(
                      key: ValueKey(chipTool),
                      icon: _icon(chipTool),
                      label: _label(context, chipTool),
                      color: chipTool == DrawTool.eraser
                          ? p.textSecondary
                          : _color(p, chipTool),
                      tinted: chipTool != DrawTool.eraser,
                    ),
                  ),
                Expanded(
                  child: enabled
                      ? const SizedBox.shrink()
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.draw_outlined,
                                  color: p.textMuted,
                                  size: 30,
                                ),
                                const SizedBox(height: AppSpace.xs),
                                Text(
                                  context.l10n.drawToolsNeedShow,
                                  textAlign: TextAlign.center,
                                  style: AppType.bodySmall.copyWith(
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                _HintRow(
                  count: 1,
                  text: context.l10n.tapForTool(
                    _label(context, DrawTool.laser),
                  ),
                ),
                const SizedBox(height: 6),
                _HintRow(count: 2, text: context.l10n.doubleTapSelected),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.tinted,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Edged in the tool's color; the eraser keeps the plain border.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(
          color: tinted ? color.withValues(alpha: 0.4) : p.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppType.labelSmall.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// "① Tap → Laser": a number in a dashed ring and the gesture.
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
        SizedBox.square(
          dimension: 20,
          child: CustomPaint(
            painter: _DashedRingPainter(p.textMuted),
            child: Center(
              child: Text(
                '$count',
                style: AppType.labelSmall.copyWith(
                  color: p.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Flexible(
          child: Text(
            text,
            style: AppType.bodySmall.copyWith(
              color: p.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => _dashedCircle(
    canvas,
    size.center(Offset.zero),
    size.width / 2 - 0.5,
    color,
    1,
  );

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

void _dashedCircle(
  Canvas canvas,
  Offset center,
  double radius,
  Color color,
  double width,
) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;
  final dashes = math.max(8, (radius * 2 * math.pi / 5).round());
  final step = 2 * math.pi / dashes;
  for (var i = 0; i < dashes; i++) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      i * step,
      step * 0.55,
      false,
      paint,
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
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.trail, this.palette, this.laserColor)
    : super(repaint: trail);

  final TouchTrail trail;
  final AppPalette palette;
  final Color? laserColor;

  // The laser's tail: its last points.
  static const _tail = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final points = trail.points;
    if (points.isEmpty) return;
    final alpha = 1 - trail.fade;
    if (alpha <= 0) return;
    final color = trail.ink ??
        (trail.tool == DrawTool.laser ? laserColor : null) ??
        trail.tool.colorIn(palette);
    final at = points.last;

    switch (trail.tool) {
      case DrawTool.laser:
        final tail = points.sublist(math.max(0, points.length - _tail));
        for (var i = 1; i < tail.length; i++) {
          final t = i / tail.length;
          canvas.drawLine(
            tail[i - 1],
            tail[i],
            Paint()
              ..color = color.withValues(alpha: 0.7 * t * alpha)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
        if (trail.touching) {
          canvas.drawCircle(
            at,
            30,
            Paint()
              ..color = color.withValues(alpha: 0.5 * alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
          );
          canvas.drawCircle(
            at,
            17,
            Paint()..color = color.withValues(alpha: 0.25 * alpha),
          );
          canvas.drawCircle(
            at,
            9,
            Paint()..color = color.withValues(alpha: alpha),
          );
        }
      case DrawTool.pen:
      case DrawTool.highlighter:
        final highlighter = trail.tool == DrawTool.highlighter;
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: (highlighter ? 0.45 : 1) * alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = highlighter ? 18 : 5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case DrawTool.eraser:
        if (trail.touching) {
          canvas.drawCircle(
            at,
            18,
            Paint()..color = palette.textPrimary.withValues(alpha: 0.08),
          );
          _dashedCircle(canvas, at, 18, palette.textPrimary, 2);
        }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.trail != trail ||
      old.palette != palette ||
      old.laserColor != laserColor;
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
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.drawCircle(at, 7, Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_TouchGlowPainter old) =>
      old.touch != touch || old.color != color;
}
