import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'glass_panel.dart';
import 'media_transport_row.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';

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
    final p = context.palette;
    final accent = p.accent;

    final thumbnail = _thumbnail;
    final placeholderIcon = Icon(
      widget.hasMedia ? Icons.music_note_rounded : Icons.music_off_rounded,
      color: AppColors.white,
      size: 26,
    );
    final displayTitle = widget.hasMedia ? (widget.title?.isNotEmpty == true ? widget.title! : context.l10n.unknownMedia) : context.l10n.noMedia;
    final displayArtist = widget.hasMedia ? (widget.artist?.isNotEmpty == true ? widget.artist! : context.l10n.unknownArtist) : context.l10n.nothingPlaying;

    return GlassPanel(
      accent: accent,
      child: Column(
        children: [
          Row(
            children: [
              // Album art, or a gradient tile in the brand colors.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.all(AppRadius.md),
                  gradient: widget.hasMedia
                      ? const LinearGradient(
                          colors: [AppColors.cobaltBright, AppColors.laser],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.hasMedia ? null : p.textMuted.withValues(alpha: 0.35),
                  boxShadow: widget.hasMedia ? AppShadows.glow(accent, strength: 0.5) : null,
                ),
                child: thumbnail != null
                    ? ClipRRect(
                        borderRadius: AppRadius.all(AppRadius.md),
                        child: Image.memory(
                          thumbnail,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => placeholderIcon,
                        ),
                      )
                    : placeholderIcon,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextScroll(
                      '$displayTitle    ',
                      style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 16.5),
                      velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                      delayBefore: const Duration(milliseconds: 2000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      mode: TextScrollMode.bouncing,
                      fadedBorder: true,
                      fadedBorderWidth: 0.05,
                    ),
                    const SizedBox(height: 4),
                    TextScroll(
                      '$displayArtist    ',
                      style: AppType.bodySmall.copyWith(color: p.textSecondary, fontWeight: FontWeight.w500),
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
              const SizedBox(width: AppSpace.xs),
              _EqualizerBars(playing: widget.hasMedia && widget.isPlaying, color: accent),
            ],
          ),
          if (widget.hasMedia && widget.durationMs > 0) ...[
            const SizedBox(height: AppSpace.md),
            _ProgressRow(positionMs: _localPositionMs, durationMs: widget.durationMs, color: accent),
          ],
          const SizedBox(height: AppSpace.md),
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

/// Three bars that dance while something plays and rest when it stops.
class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars({required this.playing, required this.color});

  final bool playing;
  final Color color;

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.playing && !AppMotion.reduced(context);
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 20,
          height: 18,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _EqualizerPainter(
                t: _c.value,
                color: widget.color.withValues(alpha: widget.playing ? 1 : 0.35),
                still: !widget.playing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  _EqualizerPainter({required this.t, required this.color, required this.still});

  final double t;
  final Color color;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const phases = [0.0, 0.33, 0.66];
    final bw = size.width / 5;
    for (var i = 0; i < 3; i++) {
      final wave = still ? 0.3 : 0.35 + 0.65 * (0.5 + 0.5 * math.sin((t + phases[i]) * 2 * math.pi)).abs();
      final h = size.height * wave;
      final x = i * bw * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, bw, h), Radius.circular(bw / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter old) => old.t != t || old.color != color || old.still != still;
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
    final p = context.palette;
    final timeStyle = AppType.mono.copyWith(color: p.textMuted, fontSize: 11.5);
    return Row(
      children: [
        Text(_formatDuration(positionMs), style: timeStyle),
        const SizedBox(width: AppSpace.sm - 2),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.all(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (positionMs / durationMs).clamp(0.0, 1.0),
              backgroundColor: p.surfaceSunken,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm - 2),
        Text(_formatDuration(durationMs), style: timeStyle),
      ],
    );
  }
}
