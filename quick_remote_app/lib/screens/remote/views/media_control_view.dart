import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../utils/show_info.dart';
import '../widgets/media_labels.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/slide_media_panel.dart';
import '../widgets/volume_panel.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The PC's volume, what plays on the PC and slide media, in that order.
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
    final show = ShowInfo.of(ws);
    // Without a slideshow the PC ignores slide media.
    final slideMedia = ws.isConnected && show.media;
    const padding = EdgeInsets.fromLTRB(
      AppSpace.page,
      AppSpace.xxs,
      AppSpace.page,
      AppSpace.lg,
    );
    return ContentWidth(
      // The panels start at the top, as the other tabs do, and scroll on a
      // short screen. Centred, they left a gap under the header that looked
      // like something was missing (2026-10-25).
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: VolumePanel(
                isConnected: ws.isConnected,
                volume: ws.systemVolume,
                muted: ws.systemMuted,
                onVolumeUp: () => _send(RemoteCommands.volumeUp),
                onVolumeDown: () => _send(RemoteCommands.volumeDown),
                onMute: () => _send(RemoteCommands.volumeMute),
                onSetVolume: (v) => _send(RemoteCommands.volumeSet(v)),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            FadeSlideIn(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MediaSectionHeader(
                    icon: Icons.album_rounded,
                    label: context.l10n.nowPlaying,
                  ),
                  const SizedBox(height: AppSpace.sm),
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
            const SizedBox(height: AppSpace.lg),
            FadeSlideIn(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MediaSectionHeader(
                    icon: Icons.smart_display_rounded,
                    label: context.l10n.slideMedia,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  SlideMediaPanel(
                    slide: ws.currentSlide,
                    hasMedia: show.media && ws.pptHasMedia,
                    isPlaying: ws.pptIsMediaPlaying,
                    playStateKnown: !show.windowsWps,
                    canRewind: show.rewind,
                    onPlayPause: slideMedia
                        ? () => _send(RemoteCommands.mediaPlayPause)
                        : null,
                    onRewind: slideMedia
                        ? () => _send(RemoteCommands.mediaRewind)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
