import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_typography.dart';

/// Colors of the logo tile (brand/tools/draw_logo.py). The launcher icon is
/// always [dark]; inside the app the tile follows the theme ([of]).
@immutable
class BrandColors {
  const BrandColors({
    required this.tileTop,
    required this.tileBottom,
    this.tileLight,
    required this.edge,
    required this.keyFill,
    required this.keyBorder,
    required this.keyChevron,
    required this.next,
    required this.nextGlow,
    this.nextChevron = AppColors.white,
  });

  final Color tileTop;
  final Color tileBottom;

  /// A light from the top left corner, if any.
  final Color? tileLight;
  final Color edge;

  /// The small Previous key.
  final Color keyFill;
  final Color keyBorder;
  final Color keyChevron;

  /// The large Next key's gradient, from its top left, and the glow under it.
  final List<Color> next;
  final Color nextGlow;

  /// The chevron on the Next key: the color on the theme's primary.
  final Color nextChevron;

  static final dark = BrandColors(
    tileTop: AppColors.logoTileTop,
    tileBottom: AppColors.ink,
    tileLight: AppColors.cobaltBright.withValues(alpha: 0.22),
    edge: AppColors.white.withValues(alpha: 0.06),
    keyFill: AppColors.inkRaised,
    keyBorder: AppColors.logoKeyBorder,
    keyChevron: AppColors.logoKeyChevron,
    next: const [
      AppColors.cobaltBright,
      AppColors.cobalt,
      AppColors.cobaltDeep,
    ],
    nextGlow: AppColors.cobaltBright.withValues(alpha: 0.75),
  );

  static final light = BrandColors(
    tileTop: AppColors.paperSurface,
    tileBottom: AppColors.paperSunken,
    edge: AppColors.paperBorder,
    keyFill: AppColors.paperSurface,
    keyBorder: AppColors.paperBorder,
    keyChevron: AppColors.inkTextSecondary,
    next: const [
      AppColors.cobaltBright,
      AppColors.cobalt,
      AppColors.cobaltDeep,
    ],
    nextGlow: AppColors.cobaltBright.withValues(alpha: 0.45),
  );

  /// The tile in the theme's colors: Cobalt's own, else made of the
  /// palette (the Next key in its primary).
  static BrandColors of(BuildContext context) {
    final p = context.palette;
    if (identical(p, AppPalette.dark)) return dark;
    if (identical(p, AppPalette.light)) return light;
    return BrandColors(
      tileTop: Color.lerp(p.background, p.primaryBright, 0.08)!,
      tileBottom: p.background,
      tileLight: p.isDark ? p.primaryBright.withValues(alpha: 0.18) : null,
      edge: p.isDark ? AppColors.white.withValues(alpha: 0.06) : p.border,
      keyFill: p.surfaceRaised,
      keyBorder: p.borderStrong,
      keyChevron: p.textSecondary,
      next: [p.primaryBright, p.primary, p.primaryDeep],
      nextGlow: p.primaryBright.withValues(alpha: p.isDark ? 0.6 : 0.45),
      nextChevron: p.onPrimary,
    );
  }
}

/// The app icon (brand/logo/app-icon.svg): the app's own Next key, large,
/// with the small Previous key beside it and the laser dot in the corner,
/// on a rounded tile.
///
/// [progress] builds it up: the Previous key, then the Next key, then the
/// dot (the splash animates it); 1 is the finished icon.
class BrandTile extends StatelessWidget {
  const BrandTile({
    super.key,
    this.size = 56,
    this.progress = 1,
    this.shadow = true,
  });

  final double size;
  final double progress;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: shadow
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(
                  size * BrandTilePainter.radius / 512,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.palette.shadow,
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.09),
                    spreadRadius: -size * 0.04,
                  ),
                ],
              )
            : null,
        child: CustomPaint(
          painter: BrandTilePainter(
            colors: BrandColors.of(context),
            progress: progress,
          ),
        ),
      ),
    );
  }
}

class BrandTilePainter extends CustomPainter {
  BrandTilePainter({required this.colors, this.progress = 1});

  final BrandColors colors;
  final double progress;

  // Geometry in the units of the 512 px icon, as in brand/tools/draw_logo.py:
  // the mark is drawn around (256, 260) and placed 1.12 times larger.
  static const radius = 118.0;
  static const _markCenter = Offset(256, 260);
  static const _markScale = 1.12;
  static const _prev = Rect.fromLTWH(70, 196, 100, 150);
  static const _next = Rect.fromLTWH(196, 158, 200, 236);
  static const _laser = Offset(420, 116);
  static const _laserRadius = 28.0;

  static double _phase(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  static Paint _chevron(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    const box = Rect.fromLTWH(0, 0, 512, 512);
    final tile = RRect.fromRectAndRadius(box, const Radius.circular(radius));
    canvas.save();
    canvas.scale(size.width / 512);

    canvas.save();
    canvas.clipRRect(tile);
    canvas.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.tileTop, colors.tileBottom],
        ).createShader(box),
    );
    final light = colors.tileLight;
    if (light != null) {
      canvas.drawRect(
        box,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.8, -1),
            radius: 0.9,
            colors: [light, light.withValues(alpha: 0)],
          ).createShader(box),
      );
    }
    canvas.translate(256, 256);
    canvas.scale(_markScale);
    canvas.translate(-_markCenter.dx, -_markCenter.dy);
    _paintPrev(canvas, Curves.easeOutCubic.transform(_phase(progress, 0, 0.4)));
    _paintNext(canvas, _phase(progress, 0.15, 0.62));
    _paintLaser(canvas, _phase(progress, 0.62, 1));
    canvas.restore();

    canvas.drawRRect(
      tile.deflate(1.5),
      Paint()
        ..color = colors.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
  }

  /// Draws [draw] faded in by [t] and scaled by [scale] about [center].
  static void _appear(
    Canvas canvas,
    double t,
    double scale,
    Offset center,
    Rect bounds,
    void Function() draw,
  ) {
    if (t <= 0) return;
    canvas.save();
    if (t < 1) {
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      canvas.translate(-center.dx, -center.dy);
      canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, t));
    }
    draw();
    if (t < 1) canvas.restore();
    canvas.restore();
  }

  void _paintPrev(Canvas canvas, double t) {
    _appear(canvas, t, 0.8 + 0.2 * t, _prev.center, _prev.inflate(8), () {
      final key = RRect.fromRectAndRadius(
        _prev,
        Radius.circular(_prev.width * 0.3),
      );
      canvas.drawRRect(key, Paint()..color = colors.keyFill);
      canvas.drawRRect(
        key,
        Paint()
          ..color = colors.keyBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      final c = _prev.center;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + 12, c.dy - 26)
          ..lineTo(c.dx - 14, c.dy)
          ..lineTo(c.dx + 12, c.dy + 26),
        _chevron(colors.keyChevron, 18),
      );
    });
  }

  void _paintNext(Canvas canvas, double t) {
    final pop = Curves.easeOutBack.transform(t);
    _appear(
      canvas,
      Curves.easeOut.transform(t),
      0.7 + 0.3 * pop,
      _next.center,
      _next.inflate(90),
      () {
        final key = RRect.fromRectAndRadius(
          _next,
          Radius.circular(_next.width * 0.26),
        );
        canvas.drawRRect(
          key.shift(const Offset(0, 22)),
          Paint()
            ..color = colors.nextGlow
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
        );
        canvas.drawRRect(
          key,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: const Alignment(0.1, 1),
              colors: colors.next,
              stops: const [0, 0.55, 1],
            ).createShader(_next),
        );
        canvas.drawRRect(
          key,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: 0.28),
                AppColors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.3],
            ).createShader(_next),
        );
        final c = _next.center;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 22, c.dy - 44)
            ..lineTo(c.dx + 22, c.dy)
            ..lineTo(c.dx - 22, c.dy + 44),
          _chevron(colors.nextChevron, 32),
        );
      },
    );
  }

  /// The laser dot pops in with an overshoot, then its glow.
  void _paintLaser(Canvas canvas, double t) {
    if (t <= 0) return;
    final pop = Curves.easeOutBack.transform(t);
    final glow = _laserRadius * 2.6 * Curves.easeOut.transform(t);
    canvas.drawCircle(
      _laser,
      glow,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.laser.withValues(alpha: 0.75),
                AppColors.laser.withValues(alpha: 0.25),
                AppColors.laser.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 1],
            ).createShader(
              Rect.fromCircle(center: _laser, radius: glow < 1 ? 1 : glow),
            ),
    );
    canvas.drawCircle(
      _laser,
      _laserRadius * pop,
      Paint()..color = AppColors.laser,
    );
  }

  @override
  bool shouldRepaint(BrandTilePainter old) =>
      old.colors != colors || old.progress != progress;
}

/// "QuickRemote" set in the brand face: "Quick" bold, "Remote" medium in
/// the primary color.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 20,
    this.color,
    this.accentColor,
    this.suffix,
  });

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
      TextSpan(
        children: [
          TextSpan(
            text: 'Quick',
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: 'Remote',
            style: base.copyWith(
              fontWeight: FontWeight.w500,
              color: accentColor ?? p.primaryText,
            ),
          ),
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: base.copyWith(
                fontWeight: FontWeight.w500,
                color: p.textMuted,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      semanticsLabel: suffix == null ? 'QuickRemote' : 'QuickRemote $suffix',
    );
  }
}

/// The icon followed by the wordmark (brand/logo/lockup-*.svg).
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.height = 36});

  /// Height of the icon; the type follows it.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandTile(size: height, shadow: false),
        SizedBox(width: height * 0.22),
        Flexible(child: BrandWordmark(fontSize: height * 0.53)),
      ],
    );
  }
}
