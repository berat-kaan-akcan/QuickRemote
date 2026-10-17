import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// "Media control" heading of the Wi-Fi and Bluetooth media tabs.
class MediaTitle extends StatelessWidget {
  const MediaTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Row(
        children: [
          IconBadge(icon: Icons.queue_music_rounded, color: p.primaryText, size: 40),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              context.l10n.mediaControlTitle,
              style: AppType.headline.copyWith(color: p.textPrimary, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored label above a media panel.
class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const SectionLabel({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpace.xxs),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Text(label, style: AppType.overline.copyWith(color: p.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The heading of a section of the Wi-Fi media tab: an icon, the name in
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
