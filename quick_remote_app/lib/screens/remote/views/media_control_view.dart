import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/websocket_service.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/volume_panel.dart';
import '../widgets/ppt_media_controls.dart';

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
      widget.ws.sendCommand('REFRESH_STATE');
    }
  }

  void _send(String command) {
    HapticFeedback.mediumImpact();
    widget.ws.sendCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Medya Kontrolü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Şu An Çalan (Now Playing) + Medya Kontrolleri
                      const _SectionLabel(
                        icon: Icons.album_rounded,
                        label: 'Şu An Çalan',
                        color: Color(0xFFF43F5E), // Rose color
                      ),
                      const SizedBox(height: 8),
                      NowPlayingCard(
                        hasMedia: ws.hasMedia,
                        title: ws.mediaTitle,
                        artist: ws.mediaArtist,
                        thumbnailBase64: ws.mediaThumbnailBase64,
                        positionMs: ws.positionMs,
                        durationMs: ws.durationMs,
                        isPlaying: ws.isPlaying,
                        isConnected: ws.isConnected,
                        onPlayPause: () => _send('SYSTEM_MEDIA_PLAY_PAUSE'),
                        onNext: () => _send('SYSTEM_MEDIA_NEXT'),
                        onPrev: () => _send('SYSTEM_MEDIA_PREV'),
                        onStop: () => _send('SYSTEM_MEDIA_STOP'),
                      ),
                      const SizedBox(height: 24),


                      // Sistem Sesi
                      const _SectionLabel(
                        icon: Icons.volume_up_rounded,
                        label: 'Sistem Sesi',
                        color: Color(0xFF0EA5E9),
                      ),
                      const SizedBox(height: 8),
                      VolumePanel(
                        isConnected: ws.isConnected,
                        volume: ws.systemVolume,
                        muted: ws.systemMuted,
                        onVolumeUp: () => _send('VOLUME_UP'),
                        onVolumeDown: () => _send('VOLUME_DOWN'),
                        onMute: () => _send('VOLUME_MUTE'),
                        onSetVolume: (v) => _send('VOLUME_SET:$v'),
                      ),
                      const SizedBox(height: 20),

                      // PPT Video (Her zaman görünür)
                      const _SectionLabel(
                        icon: Icons.smart_display_rounded,
                        label: 'Slayt Medyası',
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(height: 8),
                      PptMediaControls(
                        isConnected: ws.isConnected,
                        isPlaying: ws.pptIsMediaPlaying,
                        onPlayPause: () => _send('MEDIA_PLAY_PAUSE'),
                        onRewind: () => _send('MEDIA_REWIND'),
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
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}


