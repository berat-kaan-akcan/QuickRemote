import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

/// The heading of a section of the media tabs: an icon, the name in
/// capitals and, on the right, a figure such as the volume.
class MediaSectionHeader extends StatelessWidget {
  const MediaSectionHeader({super.key, required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, color: p.primaryText, size: 18),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(label.toUpperCase(), style: AppType.overline.copyWith(color: p.textSecondary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
