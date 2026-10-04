import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_typography.dart';

/// The QuickRemote mark (brand/logo/mark-*.svg): a rounded "Q" ring, which
/// doubles as a slide, whose tail ends in a laser dot.
///
/// [progress] draws it in: the ring, then the tail, then the dot (the splash
/// animates it); 1 is the finished mark.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 32,
    this.color,
    this.dotColor = AppColors.laser,
    this.glow = true,
    this.progress = 1,
  });

  final double size;

  /// The ring and tail; the theme's primary text color by default.
  final Color? color;
  final Color dotColor;
  final bool glow;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: BrandMarkPainter(
            color: color ?? context.palette.primaryText,
            dotColor: dotColor,
            glow: glow,
            progress: progress,
          ),
        ),
      ),
    );
  }
}

class BrandMarkPainter extends CustomPainter {
  BrandMarkPainter({
    required this.color,
    required this.dotColor,
    this.glow = true,
    this.progress = 1,
  });

  final Color color;
  final Color dotColor;
  final bool glow;
  final double progress;

  // Geometry in the units of the 512 px icon; the mark spans -137..143.
  static const _min = -137.0;
  static const _span = 280.0;

  static double _phase(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / _span;
    canvas.save();
    canvas.scale(s);
    canvas.translate(-_min, -_min);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round;

    // Ring, drawn clockwise from its top-left corner.
    final ringT = Curves.easeInOutCubic.transform(_phase(progress, 0, 0.55));
    if (ringT > 0) {
      final ring = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(-118, -118, 200, 200),
          const Radius.circular(70),
        ));
      if (ringT >= 1) {
        canvas.drawPath(ring, stroke);
      } else {
        for (final metric in ring.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * ringT), stroke);
        }
      }
    }

    // Tail, leaving the ring through its bottom-right corner.
    final tailT = Curves.easeOutCubic.transform(_phase(progress, 0.45, 0.72));
    if (tailT > 0) {
      const from = Offset(16, 16);
      const to = Offset(74, 74);
      canvas.drawLine(from, Offset.lerp(from, to, tailT)!, stroke);
    }

    // The laser dot pops in with an overshoot, then its glow.
    final dotT = _phase(progress, 0.66, 1);
    if (dotT > 0) {
      const center = Offset(120, 120);
      final pop = Curves.easeOutBack.transform(dotT);
      if (glow) {
        final r = 64 * math.min(1.0, pop).toDouble();
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..shader = RadialGradient(colors: [
              dotColor.withValues(alpha: 0.75),
              dotColor.withValues(alpha: 0.22),
              dotColor.withValues(alpha: 0),
            ], stops: const [0, 0.45, 1])
                .createShader(Rect.fromCircle(center: center, radius: math.max(r, 1.0))),
        );
      }
      canvas.drawCircle(center, 23 * pop, Paint()..color = dotColor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.color != color || old.dotColor != dotColor || old.glow != glow || old.progress != progress;
}

/// The app icon: the white mark on the cobalt gradient tile.
class BrandTile extends StatelessWidget {
  const BrandTile({super.key, this.size = 56, this.progress = 1, this.shadow = true});

  final double size;
  final double progress;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 116 / 512),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cobaltBright, AppColors.cobaltDeep],
          ),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: AppColors.cobalt.withValues(alpha: 0.35),
                    blurRadius: size * 0.4,
                    offset: Offset(0, size * 0.12),
                    spreadRadius: -size * 0.08,
                  ),
                ]
              : null,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 116 / 512),
          gradient: RadialGradient(
            center: const Alignment(-0.56, -0.76),
            radius: 0.9,
            colors: [AppColors.white.withValues(alpha: 0.2), AppColors.white.withValues(alpha: 0)],
          ),
        ),
        alignment: Alignment.center,
        child: BrandMark(size: size * 280 / 512, color: AppColors.white, progress: progress),
      ),
    );
  }
}

/// "QuickRemote" set in the brand face: "Quick" bold, "Remote" medium in
/// the primary color.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 20, this.color, this.accentColor, this.suffix});

  final double fontSize;
  final Color? color;
  final Color? accentColor;

  /// A plain word after the name, such as "PC".
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = TextStyle(
      fontFamily: AppType.display,
      fontSize: fontSize,
      height: 1.1,
      letterSpacing: -0.02 * fontSize,
      color: color ?? p.textPrimary,
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Quick', style: base.copyWith(fontWeight: FontWeight.w700)),
        TextSpan(
          text: 'Remote',
          style: base.copyWith(fontWeight: FontWeight.w500, color: accentColor ?? p.primaryText),
        ),
        if (suffix != null)
          TextSpan(text: ' $suffix', style: base.copyWith(fontWeight: FontWeight.w500, color: p.textMuted)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      semanticsLabel: suffix == null ? 'QuickRemote' : 'QuickRemote $suffix',
    );
  }
}

/// The mark followed by the wordmark.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.height = 28});

  /// Height of the mark; the type follows it.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: height),
        SizedBox(width: height * 0.32),
        Flexible(child: BrandWordmark(fontSize: height * 0.72)),
      ],
    );
  }
}
