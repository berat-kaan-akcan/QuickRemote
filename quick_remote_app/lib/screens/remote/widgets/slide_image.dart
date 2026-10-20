import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';

/// A slide picture from the PC in a 16:9 frame with rounded corners and a
/// thin border. A new slide fades in over the last one; without a picture
/// the frame stays empty with a slide symbol.
///
/// [cover] ('BLACK' or 'WHITE') covers it in that color while the PC shows a
/// black or white screen, which the picture itself does not show.
class SlideImage extends StatelessWidget {
  const SlideImage({
    super.key,
    required this.slide,
    required this.image,
    this.cover,
    this.radius = AppRadius.sm,
    this.onTap,
    this.tooltip,
    this.label,
  });

  final int slide;
  final Uint8List? image;
  final String? cover;
  final double radius;
  final VoidCallback? onTap;
  final String? tooltip;

  /// What a screen reader says; "Preview of slide [slide]" when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = AppRadius.all(radius);
    final duration = AppMotion.of(context, AppMotion.base);
    final picture = image;
    final Widget frame = AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: p.border),
          ),
          child: ColoredBox(
            color: p.surfaceSunken,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  child: picture == null
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Icon(
                            Icons.slideshow_rounded,
                            color: p.textMuted,
                            size: 22,
                          ),
                        )
                      : Image.memory(
                          picture,
                          key: ValueKey(picture),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                ),
                AnimatedOpacity(
                  duration: duration,
                  opacity: cover == null ? 0 : 1,
                  child: ColoredBox(
                    // Fixed colors: they stand for the PC's black and white screens.
                    color: cover == 'WHITE' ? AppColors.white : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: label ?? context.l10n.slidePreviewLabel(slide),
      button: onTap != null,
      child: ExcludeSemantics(
        child: onTap == null
            ? frame
            : Pressable(
                onTap: onTap,
                tooltip: tooltip,
                pressedScale: 0.97,
                borderRadius: borderRadius,
                child: frame,
              ),
      ),
    );
  }
}
