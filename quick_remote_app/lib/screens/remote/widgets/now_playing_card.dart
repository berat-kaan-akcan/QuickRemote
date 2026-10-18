import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:flutter/services.dart';
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

    final thumbnail = _thumbnail;
    final placeholderIcon = Icon(
      widget.hasMedia ? Icons.music_note_rounded : Icons.music_off_rounded,
      color: widget.hasMedia ? AppColors.white : p.textMuted,
    );
    final displayTitle = widget.hasMedia ? (widget.title?.isNotEmpty == true ? widget.title! : context.l10n.unknownMedia) : context.l10n.noMedia;
    final displayArtist = widget.hasMedia ? (widget.artist?.isNotEmpty == true ? widget.artist! : context.l10n.unknownArtist) : context.l10n.nothingPlaying;
    final connected = widget.isConnected;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Album art, or a tile in the status colors.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.all(AppRadius.sm),
                  gradient: widget.hasMedia
                      ? LinearGradient(
                          colors: [p.success, p.info],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.hasMedia ? null : p.surfaceSunken,
                ),
                child: thumbnail != null
                    ? ClipRRect(
                        borderRadius: AppRadius.all(AppRadius.sm),
                        child: Image.memory(
                          thumbnail,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => placeholderIcon,
                        ),
                      )
                    : placeholderIcon,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextScroll(
                      '$displayTitle    ',
                      style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
                      velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                      delayBefore: const Duration(milliseconds: 2000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      mode: TextScrollMode.bouncing,
                      fadedBorder: true,
                      fadedBorderWidth: 0.05,
                    ),
                    const SizedBox(height: 2),
                    TextScroll(
                      '$displayArtist    ',
                      style: AppType.bodySmall.copyWith(color: p.textSecondary),
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
            const SizedBox(height: AppSpace.sm),
            _ProgressBar(positionMs: _localPositionMs, durationMs: widget.durationMs),
          ],
          const SizedBox(height: AppSpace.sm),
          // Nothing playing: the keys stay usable (a player may resume) but fade.
          AnimatedOpacity(
            duration: AppMotion.of(context, AppMotion.base),
            opacity: widget.hasMedia ? 1 : 0.4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundKey(icon: Icons.skip_previous_rounded, label: context.l10n.actionPrev, onTap: connected ? widget.onPrev : null),
                  _RoundKey(
                    icon: widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: widget.isPlaying ? context.l10n.mediaPause : context.l10n.mediaPlay,
                    onTap: connected ? widget.onPlayPause : null,
                    main: true,
                  ),
                  _RoundKey(icon: Icons.skip_next_rounded, label: context.l10n.actionNext, onTap: connected ? widget.onNext : null),
                  _RoundKey(icon: Icons.stop_rounded, label: context.l10n.mediaStop, onTap: connected ? widget.onStop : null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundKey extends StatelessWidget {
  const _RoundKey({required this.icon, required this.label, this.onTap, this.main = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Play or pause: large, in the text color (white on the dark theme).
  final bool main;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = main ? 62.0 : 48.0;
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      semanticLabel: label,
      tooltip: label,
      pressedScale: 0.9,
      borderRadius: AppRadius.all(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: main ? p.textPrimary : p.surfaceRaised,
          border: main ? null : Border.all(color: p.border),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.fast),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(icon, key: ValueKey(icon), color: main ? p.background : p.textPrimary, size: main ? 32 : 24),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.positionMs, required this.durationMs});

  final int positionMs;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: AppRadius.all(AppRadius.pill),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: p.surfaceSunken)),
            FractionallySizedBox(
              widthFactor: (positionMs / durationMs).clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(decoration: BoxDecoration(gradient: p.primaryGradient)),
            ),
          ],
        ),
      ),
    );
  }
}
