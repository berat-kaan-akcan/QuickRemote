import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import 'pressable.dart';

/// A surface card: the app's container for grouped content.
///
/// [tint] washes the card in a color (media panels, stats). [glass] blurs
/// what lies behind it; it costs a blur pass, so only floating chrome uses it.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.onTap,
    this.onLongPress,
    this.tint,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.elevated = false,
    this.glass = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? tint;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// Adds the soft shadow of a raised card.
  final bool elevated;
  final bool glass;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = AppRadius.all(radius);
    final base = color ?? (glass ? p.glass : p.surface);
    final tint = this.tint;

    final decoration = BoxDecoration(
      color: tint == null ? base : null,
      gradient: tint == null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(tint.withValues(alpha: p.isDark ? 0.17 : 0.10), base),
                Color.alphaBlend(tint.withValues(alpha: p.isDark ? 0.05 : 0.03), base),
              ],
            ),
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor ??
            (tint != null
                ? tint.withValues(alpha: p.isDark ? 0.26 : 0.22)
                : glass
                    ? p.glassBorder
                    : p.border),
      ),
      boxShadow: elevated ? AppShadows.soft(p) : null,
    );

    Widget card = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (glass) {
      card = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: card,
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      card = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        pressedScale: 0.98,
        hoveredScale: 1.01,
        borderRadius: borderRadius,
        semanticLabel: semanticLabel,
        child: card,
      );
    }
    return card;
  }
}

/// An icon on a tinted rounded square: leads list rows and card headers.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// A solid gradient badge with a white icon, for the strongest emphasis.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? null : color.withValues(alpha: p.isDark ? 0.16 : 0.11),
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.18)!, color],
              )
            : null,
        borderRadius: AppRadius.all(size * 0.32),
        boxShadow: filled ? AppShadows.glow(color, strength: 0.5) : null,
      ),
      child: Icon(icon, color: filled ? Colors.white : color, size: size * 0.5),
    );
  }
}

/// Keeps phone layouts readable on tablets and in landscape.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = AppSpace.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// The page background: the theme color with two faint, fixed light pools in
/// the brand colors. Painted once; nothing in it animates.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child, this.accent});

  final Widget child;

  /// Replaces the cobalt pool (the Bluetooth screens use the info color).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _AmbientPainter(
        background: p.background,
        primary: accent ?? p.primary,
        secondary: p.accent,
        strength: p.isDark ? 1 : 0.55,
      ),
      child: child,
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.strength,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    void pool(Offset center, double radius, Color color, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha * strength), color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    final w = size.width;
    final h = size.height;
    pool(Offset(w * 0.05, h * 0.02), w * 0.95, primary, 0.22);
    pool(Offset(w * 1.05, h * 0.55), w * 0.7, secondary, 0.07);
    pool(Offset(w * 0.2, h * 1.02), w * 0.8, primary, 0.10);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.background != background ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.strength != strength;
}
