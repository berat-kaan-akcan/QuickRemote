import 'package:flutter/material.dart';

import 'premium_media_btn.dart';

/// Previous, play/pause and next under a thin divider.
class MediaTransportRow extends StatelessWidget {
  const MediaTransportRow({
    super.key,
    required this.playIcon,
    required this.playLabel,
    this.onPrev,
    this.onPlayPause,
    this.onNext,
  });

  final IconData playIcon;
  final String playLabel;

  /// Null disables the button.
  final VoidCallback? onPrev;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          PremiumMediaBtn(icon: Icons.skip_previous_rounded, label: '', color: Colors.white, onTap: onPrev),
          const SizedBox(width: 8),
          Expanded(
            child: PremiumMediaBtn(
              icon: playIcon,
              label: playLabel,
              color: Colors.white,
              large: true,
              glow: true,
              onTap: onPlayPause,
            ),
          ),
          const SizedBox(width: 8),
          PremiumMediaBtn(icon: Icons.skip_next_rounded, label: '', color: Colors.white, onTap: onNext),
        ],
      ),
    );
  }
}
