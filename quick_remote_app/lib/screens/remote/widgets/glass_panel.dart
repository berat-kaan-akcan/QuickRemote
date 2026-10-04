import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

/// A media panel washed in its [accent] color.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final Color accent;

  const GlassPanel({
    super.key,
    required this.child,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tint: accent,
      radius: AppRadius.xl,
      elevated: true,
      padding: const EdgeInsets.all(AppSpace.md),
      child: child,
    );
  }
}
