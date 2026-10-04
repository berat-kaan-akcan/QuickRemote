import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';

/// The big Previous / Next buttons. Next is the primary action: the brand
/// gradient with a glow.
class SlideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  /// 140 on the controls tab; smaller above the touchpad.
  final double height;

  const SlideButton({
    super.key,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onTap,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final compact = height < 110;
    final fg = isPrimary ? p.onPrimary : p.textPrimary;
    final radius = AppRadius.all(compact ? AppRadius.lg : AppRadius.xl);

    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.965,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        height: height,
        decoration: BoxDecoration(
          gradient: isPrimary ? p.primaryGradient : null,
          color: isPrimary ? null : p.surface,
          borderRadius: radius,
          border: isPrimary ? null : Border.all(color: p.border),
          boxShadow: isPrimary && onTap != null ? AppShadows.glow(p.primary) : AppShadows.soft(p),
        ),
        foregroundDecoration: isPrimary
            ? BoxDecoration(
                borderRadius: radius,
                gradient: RadialGradient(
                  center: const Alignment(-0.7, -0.9),
                  radius: 1.1,
                  colors: [AppColors.white.withValues(alpha: 0.16), AppColors.white.withValues(alpha: 0)],
                ),
              )
            : null,
        child: ExcludeSemantics(
          child: compact
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: fg, size: 28),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.title.copyWith(color: fg, fontSize: 17),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPrimary ? AppColors.white.withValues(alpha: 0.18) : p.surfaceSunken,
                      ),
                      child: Icon(icon, color: fg, size: 34),
                    ),
                    const SizedBox(height: AppSpace.sm - 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.title.copyWith(color: fg, fontSize: 18),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A tinted action (Start, End). Long-pressable when [onLongPress] is set,
/// which a small menu arrow hints at.
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onColor = readableOn(color);
    final contentColor = isActive ? onColor : color;
    final radius = AppRadius.all(AppRadius.lg);

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: label,
      selected: isActive ? true : null,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: p.isDark ? 0.13 : 0.09),
          borderRadius: radius,
          border: Border.all(color: isActive ? color : color.withValues(alpha: p.isDark ? 0.30 : 0.24)),
          boxShadow: isActive ? AppShadows.glow(color, strength: 0.6) : null,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentColor, size: 24),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: contentColor),
                ),
              ),
              if (onLongPress != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down_rounded, color: contentColor.withValues(alpha: 0.7), size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Black or white screen: shows the color the audience will see, and lights
/// up while that screen is on.
class ScreenToggleButton extends StatelessWidget {
  const ScreenToggleButton({
    super.key,
    required this.label,
    required this.white,
    required this.isActive,
    this.onTap,
  });

  final String label;

  /// White screen; black otherwise.
  final bool white;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final swatch = white ? AppColors.white : AppColors.black;
    final onSwatch = white ? AppColors.ink : AppColors.white;
    final fg = isActive ? onSwatch : p.textPrimary;
    final radius = AppRadius.all(AppRadius.lg);

    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      selected: isActive,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        decoration: BoxDecoration(
          color: isActive ? swatch : p.surface,
          borderRadius: radius,
          border: Border.all(color: isActive ? p.primaryText : p.border, width: isActive ? 2 : 1),
          boxShadow: isActive ? AppShadows.glow(p.primary, strength: 0.5) : null,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 16,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: AppRadius.all(4),
                  border: Border.all(color: isActive ? onSwatch.withValues(alpha: 0.5) : p.borderStrong),
                ),
              ),
              const SizedBox(width: AppSpace.xs + 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small Start / End buttons above the touchpad.
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Hints that a long press opens more choices.
  final bool showMenuHint;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.onLongPress,
    this.showMenuHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.md);
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: label,
      borderRadius: radius,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: p.isDark ? 0.13 : 0.09),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: p.isDark ? 0.30 : 0.24)),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpace.xxs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelSmall.copyWith(color: color, fontSize: 13),
                ),
              ),
              if (showMenuHint) ...[
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down_rounded, color: color.withValues(alpha: 0.7), size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
