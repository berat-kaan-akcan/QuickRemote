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
      padding: const EdgeInsets.fromLTRB(11, 5, 6, 5),
      constraints: const BoxConstraints(minHeight: 42),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.09 : 0.07),
        borderRadius: AppRadius.all(13),
        border: Border.all(color: color.withValues(alpha: p.isDark ? 0.24 : 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppType.bodySmall.copyWith(color: color, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35),
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
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: p.isDark ? 0.18 : 0.14),
                  borderRadius: AppRadius.all(9),
                ),
                child: busy
                    ? SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color),
                      )
                    : Text(
                        action!,
                        style: AppType.labelSmall.copyWith(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
