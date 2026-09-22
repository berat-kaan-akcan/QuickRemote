import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/websocket_service.dart';
import '../../../utils/throttler.dart';
import 'package:text_scroll/text_scroll.dart';

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
                      _NowPlayingWithControls(
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
                      _VolumePanel(
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
                      _MediaControlPanel(
                        isConnected: ws.isConnected,
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

// ─── Glassmorphism Panel ──────────────────────────────────────────────────
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Color borderColor;

  const _GlassPanel({
    required this.child,
    this.gradientColors = const [Colors.white10, Colors.white12],
    this.borderColor = Colors.white12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Premium Media Button ──────────────────────────────────────────────────
class _PremiumMediaBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool large;
  final bool glow;
  final VoidCallback? onTap;

  const _PremiumMediaBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.large = false,
    this.glow = false,
    this.onTap,
  });

  @override
  State<_PremiumMediaBtn> createState() => _PremiumMediaBtnState();
}

class _PremiumMediaBtnState extends State<_PremiumMediaBtn>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 16 : 14,
              vertical: widget.large ? 12 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.2),
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: widget.glow ? 0.4 : 0.1),
                  blurRadius: widget.glow ? 16 : 8,
                  spreadRadius: widget.glow ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.color,
                  size: widget.large ? 24 : 20,
                ),
                if (widget.large) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PPT Medya Kontrol Paneli ───────────────────────────────────────────────
class _MediaControlPanel extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;

  const _MediaControlPanel({
    required this.isConnected,
    required this.onPlayPause,
    required this.onRewind,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF34D399); // Lighter emerald for glassmorphism

    return _GlassPanel(
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
              _PremiumMediaBtn(
                icon: Icons.replay_rounded,
                label: 'Başa Sar',
                color: accent,
                onTap: isConnected ? onRewind : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumMediaBtn(
                  icon: Icons.play_circle_rounded,
                  label: 'Oynat / Duraklat',
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

// ─── Ses Slider Paneli ───────────────────────────────────────────────────────
class _VolumePanel extends StatefulWidget {
  final bool isConnected;
  final int volume; // 0-100, -1 = bilinmiyor
  final bool muted;
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final VoidCallback onMute;
  final void Function(int) onSetVolume;

  const _VolumePanel({
    required this.isConnected,
    required this.volume,
    required this.muted,
    required this.onVolumeUp,
    required this.onVolumeDown,
    required this.onMute,
    required this.onSetVolume,
  });

  @override
  State<_VolumePanel> createState() => _VolumePanelState();
}

class _VolumePanelState extends State<_VolumePanel> {
  double? _localVolume;
  Timer? _localVolumeTimeout;
  final EventThrottler _volumeThrottler = EventThrottler(
    delay: const Duration(milliseconds: 150),
  );

  double get _displayVolume {
    if (_localVolume != null) return _localVolume!;
    if (widget.volume >= 0) return widget.volume.toDouble();
    return 0.0;
  }

  @override
  void didUpdateWidget(covariant _VolumePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_localVolume != null &&
        widget.volume >= 0 &&
        (widget.volume - _localVolume!).abs() < 1) {
      _clearLocalVolume();
    }
  }

  void _setLocalVolume(double value, {bool sendImmediately = false}) {
    final clamped = value.clamp(0, 100).toDouble();
    setState(() => _localVolume = clamped);
    _localVolumeTimeout?.cancel();
    _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
    if (sendImmediately) {
      widget.onSetVolume(clamped.round());
    } else {
      _volumeThrottler.throttle(() => widget.onSetVolume(clamped.round()));
    }
  }

  void _clearLocalVolume() {
    _localVolumeTimeout?.cancel();
    _localVolumeTimeout = null;
    if (mounted && _localVolume != null) {
      setState(() => _localVolume = null);
    }
  }

  @override
  void dispose() {
    _volumeThrottler.cancel();
    _localVolumeTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF38BDF8); // Lighter blue
    final isMuted = widget.muted;
    final volStr = widget.volume >= 0 ? '%${_displayVolume.toInt()}' : '–';

    return _GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [
        accent.withValues(alpha: 0.15),
        accent.withValues(alpha: 0.05),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mute butonu
              GestureDetector(
                onTap: widget.isConnected
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onMute();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMuted
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMuted
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: isMuted ? Colors.redAccent : accent,
                        size: 16,
                        shadows: (!isMuted && _localVolume != null)
                            ? [Shadow(color: accent, blurRadius: 12)]
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMuted ? 'Sessiz' : 'Açık',
                        style: TextStyle(
                          color: isMuted ? Colors.redAccent : accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Yüzde Metni
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  volStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: widget.isConnected ? () {
                  final currentVol = _displayVolume;
                  final clamped = (currentVol - 2).clamp(0, 100).toDouble();
                  setState(() => _localVolume = clamped);
                  _localVolumeTimeout?.cancel();
                  _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
                  widget.onVolumeDown();
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_rounded, color: accent, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: accent.withValues(alpha: 0.2),
                    valueIndicatorColor: accent,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 4,
                    ),
                  ),
                  child: Slider(
                    value: _displayVolume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_displayVolume.toInt()}',
                    onChanged: widget.isConnected ? _setLocalVolume : null,
                    onChangeEnd: widget.isConnected
                        ? (v) => _setLocalVolume(v, sendImmediately: true)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.isConnected ? () {
                  final currentVol = _displayVolume;
                  final clamped = (currentVol + 2).clamp(0, 100).toDouble();
                  setState(() => _localVolume = clamped);
                  _localVolumeTimeout?.cancel();
                  _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
                  widget.onVolumeUp();
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: accent, size: 20),
                ),
              ),
            ],
          ),
        ],
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

class _NowPlayingWithControls extends StatefulWidget {
  final bool hasMedia;
  final String? title;
  final String? artist;
  final String? thumbnailBase64;
  final int positionMs;
  final int durationMs;
  final bool isPlaying;
  final bool isConnected;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onStop;

  const _NowPlayingWithControls({
    required this.hasMedia,
    this.title,
    this.artist,
    this.thumbnailBase64,
    this.positionMs = 0,
    this.durationMs = 0,
    required this.isPlaying,
    required this.isConnected,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrev,
    required this.onStop,
  });

  @override
  State<_NowPlayingWithControls> createState() => _NowPlayingWithControlsState();
}

class _NowPlayingWithControlsState extends State<_NowPlayingWithControls> {
  late int _localPositionMs;
  Timer? _ticker;
  DateTime? _lastTickTime;

  @override
  void initState() {
    super.initState();
    _localPositionMs = widget.positionMs;
    _updateTicker();
  }

  @override
  void didUpdateWidget(covariant _NowPlayingWithControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the server sends a new position, or the playing state changes, update the local timer.
    if (widget.positionMs != oldWidget.positionMs ||
        widget.isPlaying != oldWidget.isPlaying) {
      _localPositionMs = widget.positionMs;
      _updateTicker();
    }
  }

  void _updateTicker() {
    _ticker?.cancel();
    if (widget.isPlaying && widget.durationMs > 0) {
      _lastTickTime = DateTime.now();
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final now = DateTime.now();
        final diff = now.difference(_lastTickTime!).inMilliseconds;
        _lastTickTime = now;
        
        setState(() {
          _localPositionMs += diff;
          if (_localPositionMs > widget.durationMs) {
            _localPositionMs = widget.durationMs;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF43F5E); // Rose
    
    final displayTitle = widget.hasMedia ? (widget.title?.isNotEmpty == true ? widget.title! : 'Bilinmeyen Medya') : 'Medya Yok';
    final displayArtist = widget.hasMedia ? (widget.artist?.isNotEmpty == true ? widget.artist! : 'Bilinmeyen Sanatçı') : 'Şu an bir şey çalmıyor';

    return _GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [
        accent.withValues(alpha: 0.15),
        accent.withValues(alpha: 0.05),
      ],
      child: Column(
        children: [
          // ── Medya Bilgileri ──
          Row(
            children: [
              // Albüm Kapağı Placeholder (Küçültülmüş)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: widget.hasMedia
                        ? const [Color(0xFF8B5CF6), Color(0xFFEC4899)]
                        : const [Colors.white24, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: widget.hasMedia ? [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: (widget.thumbnailBase64 != null && widget.thumbnailBase64!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(widget.thumbnailBase64!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      )
                    : Icon(
                        widget.hasMedia ? Icons.music_note_rounded : Icons.music_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 20),
              // Şarkı Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextScroll(
                      '  $displayTitle  ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                      delayBefore: const Duration(milliseconds: 2000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      mode: TextScrollMode.bouncing,
                      fadedBorder: true,
                      fadedBorderWidth: 0.05,
                    ),
                    const SizedBox(height: 4),
                    TextScroll(
                      '  $displayArtist  ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                      delayBefore: const Duration(milliseconds: 2000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      mode: TextScrollMode.bouncing,
                      fadedBorder: true,
                      fadedBorderWidth: 0.05,
                    ),
                  ],
                ),
              ),

            ],
          ),
          // ── Progress Bar ──
          if (widget.hasMedia && widget.durationMs > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _formatDuration(_localPositionMs),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_localPositionMs / widget.durationMs).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(widget.durationMs),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          // ── Medya Kontrol Butonları ──
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                _PremiumMediaBtn(
                  icon: Icons.skip_previous_rounded,
                  label: '',
                  color: Colors.white,
                  onTap: widget.isConnected ? widget.onPrev : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PremiumMediaBtn(
                    icon: Icons.play_arrow_rounded,
                    label: 'Oynat / Duraklat',
                    color: Colors.white,
                    large: true,
                    glow: true,
                    onTap: widget.isConnected ? widget.onPlayPause : null,
                  ),
                ),
                const SizedBox(width: 8),
                _PremiumMediaBtn(
                  icon: Icons.skip_next_rounded,
                  label: '',
                  color: Colors.white,
                  onTap: widget.isConnected ? widget.onNext : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


