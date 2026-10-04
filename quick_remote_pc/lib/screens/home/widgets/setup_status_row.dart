import 'package:flutter/material.dart';
import '../../../widgets/ui/ui.dart';

/// One line of the Linux setup panel, with an optional fix button.
class SetupStatusRow extends StatelessWidget {
  const SetupStatusRow({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.action,
    this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? action;
  final VoidCallback? onTap;

  /// Another fix is running: the button shows a spinner and does nothing.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, 6, 6, 6),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.11 : 0.07),
        borderRadius: AppRadius.all(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: p.isDark ? 0.28 : 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpace.sm - 2),
          Expanded(
            child: Text(
              text,
              style: AppType.labelSmall.copyWith(color: color, fontSize: 12.5, height: 1.35),
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(width: AppSpace.xs),
            Pressable(
              onTap: busy ? () {} : onTap,
              pressedScale: 0.94,
              hoveredScale: 1.04,
              borderRadius: AppRadius.all(AppRadius.sm),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: p.isDark ? 0.2 : 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: busy
                    ? SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color),
                      )
                    : Text(
                        action!,
                        style: AppType.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
