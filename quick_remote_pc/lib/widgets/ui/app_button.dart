import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'pressable.dart';

enum AppButtonVariant {
  /// The one main action of a screen: the brand gradient (or the tone's
  /// solid color) with a soft glow.
  primary,

  /// A solid fill in the tone's color, without the glow.
  solid,

  /// Tinted background and text in the tone's color.
  tonal,

  /// Outline only.
  outline,

  /// Text and icon only.
  ghost,
}

/// The app's button. Null [onPressed] disables it; [loading] shows a spinner
/// in place of the icon and ignores taps.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.onLongPress,
    this.variant = AppButtonVariant.primary,
    this.tone = AppTone.primary,
    this.loading = false,
    this.expand = true,
    this.height = 54,
    this.semanticLabel,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final AppButtonVariant variant;
  final AppTone tone;
  final bool loading;

  /// Fills the available width.
  final bool expand;
  final double height;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final toneColor = p.tone(tone);
    final (solidFill, onSolid) = p.solid(tone);
    final radius = AppRadius.all(height >= 52 ? AppRadius.md : AppRadius.sm);

    Color fg;
    BoxDecoration decoration;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.solid:
        final disabled = onPressed == null;
        fg = disabled ? p.textMuted : onSolid;
        final glow = variant == AppButtonVariant.primary && !disabled;
        decoration = BoxDecoration(
          color: disabled ? p.surfaceSunken : (tone == AppTone.primary && glow ? null : solidFill),
          gradient: !disabled && tone == AppTone.primary && glow ? p.primaryGradient : null,
          borderRadius: radius,
          border: disabled ? Border.all(color: p.border) : null,
          boxShadow: glow ? AppShadows.glow(solidFill, strength: 0.8) : null,
        );
      case AppButtonVariant.tonal:
        fg = toneColor;
        decoration = BoxDecoration(
          color: toneColor.withValues(alpha: p.isDark ? 0.16 : 0.10),
          borderRadius: radius,
          border: Border.all(color: toneColor.withValues(alpha: p.isDark ? 0.30 : 0.24)),
        );
      case AppButtonVariant.outline:
        fg = tone == AppTone.neutral ? p.textPrimary : toneColor;
        decoration = BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: tone == AppTone.neutral ? p.borderStrong : toneColor.withValues(alpha: 0.6)),
        );
      case AppButtonVariant.ghost:
        fg = tone == AppTone.neutral ? p.textSecondary : toneColor;
        decoration = BoxDecoration(borderRadius: radius);
    }

    final iconSize = height >= 52 ? 22.0 : 18.0;
    final leading = loading
        ? SizedBox.square(
            dimension: iconSize - 2,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : icon == null
            ? null
            : Icon(icon, color: fg, size: iconSize);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: AppSpace.xs + 2)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (height >= 52 ? AppType.label : AppType.labelSmall).copyWith(color: fg),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpace.xs),
          Icon(trailingIcon, color: fg, size: iconSize - 2),
        ],
      ],
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      onLongPress: enabled ? onLongPress : null,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      hoveredScale: 1.02,
      dimWhenDisabled: variant != AppButtonVariant.primary && variant != AppButtonVariant.solid,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: height >= 52 ? AppSpace.lg : AppSpace.md),
        decoration: decoration,
        child: content,
      ),
    );
  }
}

/// A round icon-only button (close, settings, reconnect, media transport).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = AppSpace.minTouch,
    this.iconSize = 22,
    this.color,
    this.background,
    this.border = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  /// Icon color; the secondary text color by default.
  final Color? color;
  final Color? background;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onPressed,
      tooltip: tooltip,
      semanticLabel: tooltip,
      pressedScale: 0.9,
      hoveredScale: 1.08,
      borderRadius: AppRadius.all(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: border ? Border.all(color: p.border) : null,
        ),
        child: Icon(icon, size: iconSize, color: color ?? p.textSecondary),
      ),
    );
  }
}
