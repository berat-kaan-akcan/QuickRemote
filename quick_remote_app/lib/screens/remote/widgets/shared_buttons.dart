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

/// Start and End as one button: green Start while no show runs, red End
/// while one does. [compact] above the touchpad.
class ShowToggleButton extends StatelessWidget {
  const ShowToggleButton({
    super.key,
    required this.running,
    required this.startLabel,
    required this.endLabel,
    this.startIcon = Icons.play_arrow_rounded,
    this.onTap,
    this.compact = false,
  });

  final bool running;
  final String startLabel;
  final String endLabel;
  final IconData startIcon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.lg);
    final fg = running ? p.danger : p.onSuccess;
    final label = running ? endLabel : startLabel;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.97,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        height: compact ? 50 : 58,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        decoration: BoxDecoration(
          gradient: running ? null : p.successGradient,
          color: running ? p.danger.withValues(alpha: p.isDark ? 0.13 : 0.09) : null,
          borderRadius: radius,
          border: Border.all(
            color: running ? p.danger.withValues(alpha: 0.45) : p.success.withValues(alpha: 0),
            width: 1.5,
          ),
          boxShadow: running ? null : AppShadows.glow(p.success, strength: 0.8),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(running ? Icons.stop_rounded : startIcon, color: fg, size: compact ? 24 : 28),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.title.copyWith(color: fg, fontSize: compact ? 15 : 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tall Previous and Next keys of the controls tab, as high as the space
/// left under them. Next is the large one: the brand gradient with a glow.
class BigSlideButton extends StatelessWidget {
  const BigSlideButton({super.key, required this.next, required this.label, this.onTap});

  final bool next;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.xl);
    final fg = next ? p.onPrimary : p.textSecondary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.965,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          gradient: next
              ? LinearGradient(
                  begin: const Alignment(-0.6, -1),
                  end: const Alignment(0.6, 1),
                  colors: [p.primaryBright, p.primary, p.primaryDeep],
                  stops: const [0, 0.55, 1],
                )
              : null,
          color: next ? null : p.surface,
          borderRadius: radius,
          border: next ? null : Border.all(color: p.border),
          boxShadow: next && onTap != null ? AppShadows.glow(p.primaryBright, strength: 1.6) : null,
        ),
        foregroundDecoration: next
            ? BoxDecoration(
                borderRadius: radius,
                border: Border(top: BorderSide(color: AppColors.white.withValues(alpha: 0.25))),
              )
            : null,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(next ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: fg, size: next ? 52 : 34),
              const SizedBox(height: AppSpace.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: next
                    ? AppType.title.copyWith(color: fg, fontSize: 18, fontWeight: FontWeight.w700)
                    : AppType.label.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Previous and Next row under the touchpad: an outlined Previous and a
/// filled Next.
class SlideNavRow extends StatelessWidget {
  const SlideNavRow({
    super.key,
    required this.prevLabel,
    required this.nextLabel,
    this.onPrev,
    this.onNext,
  });

  final String prevLabel;
  final String nextLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.md);
    Widget content(IconData icon, String label, Color color, {required bool iconFirst}) {
      final text = Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.label.copyWith(color: color, fontSize: 16),
        ),
      );
      final glyph = Icon(icon, color: color, size: 24);
      return ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconFirst
              ? [glyph, const SizedBox(width: AppSpace.xs), text]
              : [text, const SizedBox(width: AppSpace.xs), glyph],
        ),
      );
    }

    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Pressable(
              onTap: onPrev,
              semanticLabel: prevLabel,
              pressedScale: 0.965,
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: p.border, width: 1.5),
                ),
                child: content(Icons.arrow_back_rounded, prevLabel, p.textPrimary, iconFirst: true),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            flex: 3,
            child: Pressable(
              onTap: onNext,
              semanticLabel: nextLabel,
              pressedScale: 0.965,
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [p.primary, p.primaryBright],
                  ),
                  borderRadius: radius,
                  boxShadow: onNext != null ? AppShadows.glow(p.primary) : null,
                ),
                child: content(Icons.arrow_forward_rounded, nextLabel, p.onPrimary, iconFirst: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
