import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/ui/ui.dart';

/// A media button tinted in [color]: a square icon button, or with [large]
/// a wide pill with its label. [glow] fills it in the color.
class PremiumMediaBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool large;
  final bool glow;
  final VoidCallback? onTap;

  const PremiumMediaBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.large = false,
    this.glow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    final filled = glow && enabled;
    final onColor = readableOn(color);
    final fg = filled ? onColor : color;
    final radius = AppRadius.all(AppRadius.lg);

    return Pressable(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      semanticLabel: label.isEmpty ? null : label,
      pressedScale: 0.92,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        height: 56,
        width: large ? null : 56,
        padding: EdgeInsets.symmetric(horizontal: large ? AppSpace.lg : 0),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: p.isDark ? 0.14 : 0.10),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.28)),
          boxShadow: filled ? AppShadows.glow(color, strength: 0.6) : null,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: large ? 26 : 24),
              if (large) ...[
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(color: fg),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
