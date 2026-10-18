import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_language.dart';
import '../../../l10n/turkish_locative.dart';
import '../../../widgets/ui/ui.dart';

/// The media on the current slide (a video or a sound in the show): which
/// slide, whether it plays, rewind and play or pause.
class SlideMediaPanel extends StatelessWidget {
  const SlideMediaPanel({
    super.key,
    required this.slide,
    required this.hasMedia,
    required this.isPlaying,
    required this.playStateKnown,
    required this.canRewind,
    required this.onPlayPause,
    required this.onRewind,
  });

  /// The slide the show is on; 0 when unknown.
  final int slide;
  final bool hasMedia;
  final bool isPlaying;

  /// False where the program does not report it (WPS on Windows): one
  /// "Play / Pause" key.
  final bool playStateKnown;
  final bool canRewind;

  /// Null fades the key (no slideshow, not connected).
  final VoidCallback? onPlayPause;
  final VoidCallback? onRewind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final playing = playStateKnown && isPlaying;
    final (playIcon, playLabel) = !playStateKnown
        ? (Icons.play_circle_outline_rounded, context.l10n.mediaPlayPause)
        : playing
            ? (Icons.pause_circle_rounded, context.l10n.mediaPause)
            : (Icons.play_circle_rounded, context.l10n.mediaPlay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasMedia && slide > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.all(AppRadius.sm),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.primaryDeep, p.primaryBright, p.accent],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                  child: Icon(Icons.perm_media_rounded, color: p.onPrimary),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.slideMediaOnSlide(slide, turkishLocative(slide)),
                        style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
                      ),
                      Text(
                        !playStateKnown
                            ? context.l10n.slideMediaStateUnknown
                            : playing
                                ? context.l10n.slideMediaPlaying
                                : context.l10n.slideMediaNotPlaying,
                        style: AppType.bodySmall.copyWith(
                          color: playing ? p.success : p.textSecondary,
                          fontWeight: playing ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        Row(
          children: [
            Expanded(
              flex: 10,
              child: AppButton(
                label: context.l10n.mediaRewind,
                height: 48,
                icon: Icons.replay_rounded,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                onPressed: canRewind && onRewind != null
                    ? () {
                        HapticFeedback.lightImpact();
                        onRewind!();
                      }
                    : null,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              flex: 13,
              child: AppButton(
                label: playLabel,
                height: 48,
                icon: playIcon,
                onPressed: onPlayPause == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onPlayPause!();
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
