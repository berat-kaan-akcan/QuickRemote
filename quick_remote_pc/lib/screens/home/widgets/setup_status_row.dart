import 'package:flutter/material.dart';
import '../../../widgets/hover_scale.dart';

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

  /// Another fix is running: the button shows "..." and does nothing.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(width: 8),
            HoverScale(
              scale: 1.1,
              onTap: busy ? () {} : onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  busy ? '...' : action!,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
