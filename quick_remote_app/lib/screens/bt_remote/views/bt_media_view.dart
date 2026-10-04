import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../remote/widgets/glass_panel.dart';
import '../../remote/widgets/media_labels.dart';
import '../widgets/volume_pill_button.dart';
import '../../remote/widgets/media_transport_row.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 2: Media View  (WiFi MediaControlView ile aynı tasarım)
// BT HID'de çalışmayan özellikler kaldırıldı:
//   - Now Playing kartı (title, artist, thumbnail, progress) → yok
//   - Volume slider (VOLUME_SET komutu PC app gerektirir) → sadece +/- butonlar
//   - PPT Video kontrolleri (MEDIA_PLAY_PAUSE, MEDIA_REWIND) → yok
//   - REFRESH_STATE → yok
// ═════════════════════════════════════════════════════════════════════════════

class BtMediaView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;

  const BtMediaView({super.key, required this.send, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MediaTitle(),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sistem Medya Kontrolleri
                      SectionLabel(
                        icon: Icons.album_rounded,
                        label: context.l10n.systemMedia,
                        color: AppColors.mediaRose,
                      ),
                      const SizedBox(height: 8),
                      _buildSystemMediaPanel(context),
                      const SizedBox(height: 24),

                      // Sistem Sesi
                      SectionLabel(
                        icon: Icons.volume_up_rounded,
                        label: context.l10n.systemVolume,
                        color: AppColors.mediaSky,
                      ),
                      const SizedBox(height: 8),
                      _buildVolumePanel(context),
                      const SizedBox(height: 24),

                      // BT mod uyarısı
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bluetooth.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.bluetooth.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.bluetoothLight, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l10n.btMediaLimits,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMediaPanel(BuildContext context) {
    const accent = AppColors.mediaRose;
    return GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
      child: Column(
        children: [
          // Medya bilgisi yok uyarısı
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Colors.white24, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.systemMedia,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.btNoMediaInfo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MediaTransportRow(
            playIcon: Icons.play_arrow_rounded,
            playLabel: context.l10n.mediaPlayPause,
            onPrev: isConnected ? () => send(RemoteCommands.sysMediaPrev) : null,
            onPlayPause: isConnected ? () => send(RemoteCommands.sysMediaPlayPause) : null,
            onNext: isConnected ? () => send(RemoteCommands.sysMediaNext) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumePanel(BuildContext context) {
    const accent = AppColors.mediaSkyLight;
    return GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              VolumePillButton(
                icon: Icons.remove_rounded,
                color: accent,
                isLeft: true,
                onTap: isConnected ? () => send(RemoteCommands.volumeDown) : null,
              ),
              Container(width: 1, height: 28, color: accent.withValues(alpha: 0.2)),
              VolumePillButton(
                icon: Icons.volume_off_rounded,
                color: accent,
                onTap: isConnected ? () => send(RemoteCommands.volumeMute) : null,
              ),
              Container(width: 1, height: 28, color: accent.withValues(alpha: 0.2)),
              VolumePillButton(
                icon: Icons.add_rounded,
                color: accent,
                isRight: true,
                onTap: isConnected ? () => send(RemoteCommands.volumeUp) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
