import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SlideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const SlideButton({
    super.key,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              height: 140,
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          AppColors.accent,
                        ],
                      )
                    : null,
                color: isPrimary ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: isPrimary
                    ? null
                    : Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final activeTextColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final contentColor = isActive ? activeTextColor : color;

    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? color : color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: contentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onLongPress != null) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: contentColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
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
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (showMenuHint) ...[
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down_rounded, color: color.withValues(alpha: 0.7), size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
