import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'glass_panel.dart';
import 'media_transport_row.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

class NowPlayingCard extends StatefulWidget {
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

  const NowPlayingCard({
    super.key,
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
  State<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard> {
  late int _localPositionMs;
  Timer? _ticker;
  DateTime? _lastTickTime;

  String? _thumbnailSource;
  Uint8List? _thumbnailBytes;

  /// Decodes the base64 thumbnail only when it changes. The card rebuilds every
  /// 250 ms while playing, and fresh bytes on each build made Image.memory
  /// decode the picture again every time. Returns null for invalid data.
  Uint8List? get _thumbnail {
    final source = widget.thumbnailBase64;
    if (source != _thumbnailSource) {
      _thumbnailSource = source;
      _thumbnailBytes = null;
      if (source != null && source.isNotEmpty) {
        try {
          _thumbnailBytes = base64Decode(source);
        } on FormatException {
          _thumbnailBytes = null;
        }
      }
    }
    return _thumbnailBytes;
  }

  @override
  void initState() {
    super.initState();
    _localPositionMs = widget.positionMs;
    _updateTicker();
  }

  @override
  void didUpdateWidget(covariant NowPlayingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.mediaRose; // Rose
    
    final thumbnail = _thumbnail;
    final placeholderIcon = Icon(
      widget.hasMedia ? Icons.music_note_rounded : Icons.music_off_rounded,
      color: Colors.white,
      size: 20,
    );
    final displayTitle = widget.hasMedia ? (widget.title?.isNotEmpty == true ? widget.title! : context.l10n.unknownMedia) : context.l10n.noMedia;
    final displayArtist = widget.hasMedia ? (widget.artist?.isNotEmpty == true ? widget.artist! : context.l10n.unknownArtist) : context.l10n.nothingPlaying;

    return GlassPanel(
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
                        ? const [AppColors.mediaViolet, AppColors.mediaPink]
                        : const [Colors.white24, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: widget.hasMedia ? [
                    BoxShadow(
                      color: AppColors.mediaPink.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: thumbnail != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          thumbnail,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => placeholderIcon,
                        ),
                      )
                    : placeholderIcon,
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
          if (widget.hasMedia && widget.durationMs > 0) ...[
            const SizedBox(height: 16),
            _ProgressRow(positionMs: _localPositionMs, durationMs: widget.durationMs, color: accent),
          ],
          const SizedBox(height: 16),
          MediaTransportRow(
            playIcon: widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            playLabel: widget.isPlaying ? context.l10n.mediaPause : context.l10n.mediaPlay,
            onPrev: widget.isConnected ? widget.onPrev : null,
            onPlayPause: widget.isConnected ? widget.onPlayPause : null,
            onNext: widget.isConnected ? widget.onNext : null,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.positionMs, required this.durationMs, required this.color});

  final int positionMs;
  final int durationMs;
  final Color color;

  static String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const timeStyle = TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600);
    return Row(
      children: [
        Text(_formatDuration(positionMs), style: timeStyle),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (positionMs / durationMs).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(_formatDuration(durationMs), style: timeStyle),
      ],
    );
  }
}
