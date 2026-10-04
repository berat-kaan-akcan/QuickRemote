import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../remote/widgets/glass_panel.dart';
import '../../remote/widgets/media_labels.dart';
import '../widgets/volume_pill_button.dart';
import '../../remote/widgets/media_transport_row.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

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
    final p = context.palette;
    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: MediaTitle()),
              const SizedBox(height: AppSpace.md),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sistem Medya Kontrolleri
                        FadeSlideIn(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(
                                icon: Icons.album_rounded,
                                label: context.l10n.systemMedia,
                                color: p.accent,
                              ),
                              const SizedBox(height: AppSpace.xs),
                              _buildSystemMediaPanel(context),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),

                        // Sistem Sesi
                        FadeSlideIn(
                          index: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(
                                icon: Icons.volume_up_rounded,
                                label: context.l10n.systemVolume,
                                color: p.info,
                              ),
                              const SizedBox(height: AppSpace.xs),
                              _buildVolumePanel(context),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),

                        // BT mod uyarısı
                        FadeSlideIn(
                          index: 3,
                          child: InlineAlert(
                            tone: AppTone.info,
                            icon: Icons.info_outline_rounded,
                            message: context.l10n.btMediaLimits,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMediaPanel(BuildContext context) {
    final p = context.palette;
    return GlassPanel(
      accent: p.accent,
      child: Column(
        children: [
          // Medya bilgisi yok uyarısı
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.all(AppRadius.md),
                  color: p.surfaceSunken,
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.music_note_rounded, color: p.textMuted, size: 26),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.systemMedia,
                      style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 16.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.btNoMediaInfo,
                      style: AppType.bodySmall.copyWith(color: p.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
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
    final p = context.palette;
    final accent = p.info;
    return GlassPanel(
      accent: accent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            VolumePillButton(
              icon: Icons.remove_rounded,
              color: accent,
              isLeft: true,
              onTap: isConnected ? () => send(RemoteCommands.volumeDown) : null,
            ),
            Container(width: 1, height: 28, color: p.border),
            VolumePillButton(
              icon: Icons.volume_off_rounded,
              color: accent,
              label: context.l10n.volumeMuted,
              onTap: isConnected ? () => send(RemoteCommands.volumeMute) : null,
            ),
            Container(width: 1, height: 28, color: p.border),
            VolumePillButton(
              icon: Icons.add_rounded,
              color: accent,
              isRight: true,
              onTap: isConnected ? () => send(RemoteCommands.volumeUp) : null,
            ),
          ],
        ),
      ),
    );
  }
}
