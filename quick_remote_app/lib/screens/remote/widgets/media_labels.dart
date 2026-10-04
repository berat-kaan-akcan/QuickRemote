import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';

/// "Media control" heading of the Wi-Fi and Bluetooth media tabs.
class MediaTitle extends StatelessWidget {
  const MediaTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          context.l10n.mediaControlTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
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
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
