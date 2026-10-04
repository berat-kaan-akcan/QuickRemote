import 'package:flutter/material.dart';
import 'glass_panel.dart';
import 'premium_media_btn.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class PptMediaControls extends StatelessWidget {
  final bool isConnected;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;

  const PptMediaControls({
    super.key,
    required this.isConnected,
    this.isPlaying = false,
    required this.onPlayPause,
    required this.onRewind,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.success;

    return GlassPanel(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumMediaBtn(
                icon: Icons.replay_rounded,
                label: context.l10n.mediaRewind,
                color: accent,
                onTap: isConnected ? onRewind : null,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: PremiumMediaBtn(
                  icon: isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_rounded,
                  label: isPlaying ? context.l10n.mediaPause : context.l10n.mediaPlay,
                  color: accent,
                  large: true,
                  glow: true,
                  onTap: isConnected ? onPlayPause : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
