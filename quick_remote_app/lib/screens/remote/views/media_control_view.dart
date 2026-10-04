import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../widgets/media_labels.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/volume_panel.dart';
import '../widgets/ppt_media_controls.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class MediaControlView extends StatefulWidget {
  final WebSocketService ws;

  const MediaControlView({super.key, required this.ws});

  @override
  State<MediaControlView> createState() => _MediaControlViewState();
}

class _MediaControlViewState extends State<MediaControlView> {
  @override
  void initState() {
    super.initState();
    if (widget.ws.isConnected) {
      widget.ws.sendCommand(RemoteCommands.refreshState);
    }
  }

  void _send(String command) {
    HapticFeedback.mediumImpact();
    widget.ws.sendCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
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
                        // Şu An Çalan (Now Playing) + Medya Kontrolleri
                        FadeSlideIn(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(
                                icon: Icons.album_rounded,
                                label: context.l10n.nowPlaying,
                                color: p.accent,
                              ),
                              const SizedBox(height: AppSpace.xs),
                              NowPlayingCard(
                                hasMedia: ws.hasMedia,
                                title: ws.mediaTitle,
                                artist: ws.mediaArtist,
                                thumbnailBase64: ws.mediaThumbnailBase64,
                                positionMs: ws.positionMs,
                                durationMs: ws.durationMs,
                                isPlaying: ws.isPlaying,
                                isConnected: ws.isConnected,
                                onPlayPause: () => _send(RemoteCommands.sysMediaPlayPause),
                                onNext: () => _send(RemoteCommands.sysMediaNext),
                                onPrev: () => _send(RemoteCommands.sysMediaPrev),
                                onStop: () => _send(RemoteCommands.sysMediaStop),
                              ),
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
                              VolumePanel(
                                isConnected: ws.isConnected,
                                volume: ws.systemVolume,
                                muted: ws.systemMuted,
                                onVolumeUp: () => _send(RemoteCommands.volumeUp),
                                onVolumeDown: () => _send(RemoteCommands.volumeDown),
                                onMute: () => _send(RemoteCommands.volumeMute),
                                onSetVolume: (v) => _send(RemoteCommands.volumeSet(v)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),

                        // PPT Video (Her zaman görünür)
                        FadeSlideIn(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(
                                icon: Icons.smart_display_rounded,
                                label: context.l10n.slideMedia,
                                color: p.success,
                              ),
                              const SizedBox(height: AppSpace.xs),
                              PptMediaControls(
                                isConnected: ws.isConnected,
                                isPlaying: ws.pptIsMediaPlaying,
                                onPlayPause: () => _send(RemoteCommands.mediaPlayPause),
                                onRewind: () => _send(RemoteCommands.mediaRewind),
                              ),
                            ],
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
}
