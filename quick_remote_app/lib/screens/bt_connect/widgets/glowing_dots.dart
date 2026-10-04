import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

class GlowingDots extends StatelessWidget {
  final Animation<double> animation;
  const GlowingDots({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final color = context.palette.info;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              // dalgalanma efekti için basit bir sinüs hesabı
              final val = math
                  .sin((animation.value * math.pi) + (index * math.pi / 4))
                  .abs();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 8 + (val * 3),
                height: 8 + (val * 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3 + (val * 0.7)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: val * 0.5),
                      blurRadius: 4 + (val * 6),
                      spreadRadius: val * 2,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Rings that ripple out of [child], like a signal looking for a partner.
/// Still rings when motion is reduced.
class RadarPulse extends StatefulWidget {
  const RadarPulse({super.key, required this.child, required this.color, this.size = 220});

  final Widget child;
  final Color color;
  final double size;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _RadarPainter(_c.value, widget.color),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    const minR = 56.0;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1;
      final r = minR + (maxR - minR) * Curves.easeOut.transform(phase);
      final alpha = (1 - phase) * 0.5;
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: alpha * 0.25));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.color != color;
}
