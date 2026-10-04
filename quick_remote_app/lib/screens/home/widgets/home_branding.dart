import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The top bar of the home screen: the brand lockup and the settings button.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        const Expanded(
          child: Align(alignment: Alignment.centerLeft, child: BrandLockup(height: 30)),
        ),
        AppIconButton(
          icon: Icons.settings_rounded,
          tooltip: context.l10n.homeSettingsTooltip,
          onPressed: onSettings,
          background: p.surface.withValues(alpha: 0.7),
          border: true,
        ),
      ],
    );
  }
}

/// The hero of the home screen: a slide with a laser dot sweeping across it,
/// the tagline and how to connect.
class HomeBranding extends StatelessWidget {
  const HomeBranding({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 132, width: double.infinity, child: SlideIllustration()),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          header: true,
          child: Text(
            context.l10n.homeTagline,
            style: AppType.headline.copyWith(color: p.textPrimary, fontSize: 26),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          context.l10n.homeHeroSubtitle,
          style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

/// A presentation slide drawn in the brand colors; a laser dot travels from
/// its title to its chart once, then rests there glowing.
class SlideIllustration extends StatelessWidget {
  const SlideIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: AppMotion.reduced(context) ? 1 : 0, end: 1),
        duration: AppMotion.of(context, const Duration(milliseconds: 1800)),
        curve: AppMotion.standard,
        builder: (context, t, _) => CustomPaint(painter: _SlidePainter(p, t)),
      ),
    );
  }
}

class _SlidePainter extends CustomPainter {
  _SlidePainter(this.p, this.t);

  final AppPalette p;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = math.min(size.width, h * 1.75);
    final left = (size.width - w) / 2;
    final slide = RRect.fromRectAndRadius(Rect.fromLTWH(left, 4, w, h - 8), const Radius.circular(16));

    // Card with a soft shadow.
    canvas.drawRRect(
      slide.shift(const Offset(0, 6)),
      Paint()
        ..color = p.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(slide, Paint()..color = p.surface);
    canvas.drawRRect(
      slide,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = p.border,
    );

    final x0 = slide.left + 18;
    final y0 = slide.top + 18;
    final line = Paint()..color = p.surfaceSunken;
    RRect bar(double x, double y, double bw, double bh) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, bh), Radius.circular(bh / 2));

    // Title and text lines.
    canvas.drawRRect(bar(x0, y0, w * 0.42, 10), Paint()..color = p.primaryText.withValues(alpha: 0.85));
    canvas.drawRRect(bar(x0, y0 + 22, w * 0.34, 7), line);
    canvas.drawRRect(bar(x0, y0 + 36, w * 0.28, 7), line);
    canvas.drawRRect(bar(x0, y0 + 50, w * 0.31, 7), line);

    // A small bar chart on the right.
    final chartBase = slide.bottom - 18;
    final chartX = slide.right - 18 - 3 * 18 - 2 * 8;
    final heights = [0.42, 0.7, 0.55];
    final colors = [p.info, p.primaryText, p.accent];
    for (var i = 0; i < 3; i++) {
      final bh = (h - 52) * heights[i] * (0.35 + 0.65 * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chartX + i * 26, chartBase - bh, 18, bh),
          const Radius.circular(5),
        ),
        Paint()..color = colors[i].withValues(alpha: 0.85),
      );
    }

    // The laser dot: from the title to the tallest bar.
    final from = Offset(x0 + w * 0.36, y0 + 5);
    final to = Offset(chartX + 26 + 9, chartBase - (h - 52) * 0.7 - 2);
    final ctrl = Offset((from.dx + to.dx) / 2, slide.bottom - 10);
    final u = t;
    final dot = Offset(
      (1 - u) * (1 - u) * from.dx + 2 * (1 - u) * u * ctrl.dx + u * u * to.dx,
      (1 - u) * (1 - u) * from.dy + 2 * (1 - u) * u * ctrl.dy + u * u * to.dy,
    );
    final glow = Rect.fromCircle(center: dot, radius: 22);
    canvas.drawCircle(
      dot,
      22,
      Paint()
        ..shader = RadialGradient(colors: [
          p.accent.withValues(alpha: 0.6),
          p.accent.withValues(alpha: 0),
        ]).createShader(glow),
    );
    canvas.drawCircle(dot, 5.5, Paint()..color = p.accent);
    canvas.drawCircle(dot, 2.2, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_SlidePainter old) => old.t != t || old.p != p;
}
