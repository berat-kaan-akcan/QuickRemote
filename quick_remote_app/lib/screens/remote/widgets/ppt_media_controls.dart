import 'package:flutter/material.dart';
import 'glass_panel.dart';
import 'premium_media_btn.dart';

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
    const accent = Color(0xFF34D399); // Lighter emerald for glassmorphism

    return GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [
        accent.withValues(alpha: 0.15),
        accent.withValues(alpha: 0.05),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumMediaBtn(
                icon: Icons.replay_rounded,
                label: 'Başa Sar',
                color: accent,
                onTap: isConnected ? onRewind : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumMediaBtn(
                  icon: isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_rounded,
                  label: isPlaying ? 'Duraklat' : 'Oynat',
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
