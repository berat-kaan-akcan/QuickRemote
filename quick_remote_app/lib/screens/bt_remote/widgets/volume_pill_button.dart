import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../widgets/ui/ui.dart';

/// One segment of the Bluetooth volume pill: down, mute or up.
class VolumePillButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLeft;
  final bool isRight;
  final String? label;

  const VolumePillButton({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLeft = false,
    this.isRight = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: isLeft ? const Radius.circular(AppRadius.pill) : Radius.zero,
      right: isRight ? const Radius.circular(AppRadius.pill) : Radius.zero,
    );
    return Expanded(
      child: Pressable(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        semanticLabel: label,
        pressedScale: 0.9,
        borderRadius: radius,
        child: SizedBox.expand(
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}
