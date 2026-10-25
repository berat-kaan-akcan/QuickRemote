import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';

/// Start and End as one button: green Start while no show runs, red End
/// while one does. [compact] above the touchpad.
class ShowToggleButton extends StatelessWidget {
  const ShowToggleButton({
    super.key,
    required this.running,
    required this.startLabel,
    required this.endLabel,
    this.startIcon = Icons.play_arrow_rounded,
    this.onTap,
    this.compact = false,
  });

  final bool running;
  final String startLabel;
  final String endLabel;
  final IconData startIcon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.lg);
    final fg = running ? p.danger : p.onSuccess;
    final label = running ? endLabel : startLabel;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.97,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        height: compact ? 50 : 58,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        decoration: BoxDecoration(
          gradient: running ? null : p.successGradient,
          color: running ? p.danger.withValues(alpha: p.isDark ? 0.13 : 0.09) : null,
          borderRadius: radius,
          border: Border.all(
            color: running ? p.danger.withValues(alpha: 0.45) : p.success.withValues(alpha: 0),
            width: 1.5,
          ),
          boxShadow: running ? null : AppShadows.glow(p.success, strength: 0.8),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(running ? Icons.stop_rounded : startIcon, color: fg, size: compact ? 24 : 28),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.title.copyWith(color: fg, fontSize: compact ? 15 : 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tall Previous and Next keys of the controls tab, as high as the space
/// left under them. Next is the large one: the brand gradient with a glow.
class BigSlideButton extends StatelessWidget {
  const BigSlideButton({super.key, required this.next, required this.label, this.onTap});

  final bool next;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.xl);
    final fg = next ? p.onPrimary : p.textSecondary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.965,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          gradient: next
              ? LinearGradient(
                  begin: const Alignment(-0.6, -1),
                  end: const Alignment(0.6, 1),
                  colors: [p.primaryBright, p.primary, p.primaryDeep],
                  stops: const [0, 0.55, 1],
                )
              : null,
          color: next ? null : p.surface,
          borderRadius: radius,
          border: next ? null : Border.all(color: p.border),
          boxShadow: next && onTap != null ? AppShadows.glow(p.primaryBright, strength: 1.6) : null,
        ),
        foregroundDecoration: next
            ? BoxDecoration(
                borderRadius: radius,
                border: Border(top: BorderSide(color: AppColors.white.withValues(alpha: 0.25))),
              )
            : null,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(next ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: fg, size: next ? 52 : 34),
              const SizedBox(height: AppSpace.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: next
                    ? AppType.title.copyWith(color: fg, fontSize: 18, fontWeight: FontWeight.w700)
                    : AppType.label.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Previous and Next row under the touchpad: an outlined Previous and a
/// filled Next.
class SlideNavRow extends StatelessWidget {
  const SlideNavRow({
    super.key,
    required this.prevLabel,
    required this.nextLabel,
    this.onPrev,
    this.onNext,
  });

  final String prevLabel;
  final String nextLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.md);
    Widget content(IconData icon, String label, Color color, {required bool iconFirst}) {
      final text = Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.label.copyWith(color: color, fontSize: 16),
        ),
      );
      final glyph = Icon(icon, color: color, size: 24);
      return ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconFirst
              ? [glyph, const SizedBox(width: AppSpace.xs), text]
              : [text, const SizedBox(width: AppSpace.xs), glyph],
        ),
      );
    }

    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Pressable(
              onTap: onPrev,
              semanticLabel: prevLabel,
              pressedScale: 0.965,
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: p.border, width: 1.5),
                ),
                child: content(Icons.arrow_back_rounded, prevLabel, p.textPrimary, iconFirst: true),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            flex: 3,
            child: Pressable(
              onTap: onNext,
              semanticLabel: nextLabel,
              pressedScale: 0.965,
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [p.primary, p.primaryBright],
                  ),
                  borderRadius: radius,
                  boxShadow: onNext != null ? AppShadows.glow(p.primary) : null,
                ),
                child: content(Icons.arrow_forward_rounded, nextLabel, p.onPrimary, iconFirst: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small black or white square: the color the audience will see.
class ScreenKey extends StatelessWidget {
  const ScreenKey({super.key, required this.white, required this.label, required this.active, this.onTap});

  final bool white;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      tooltip: label,
      selected: active,
      pressedScale: 0.9,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: radius,
          border: Border.all(color: active ? p.primaryText : p.border, width: active ? 2 : 1),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: white ? AppColors.white : AppColors.black,
            borderRadius: AppRadius.all(5),
            // White needs an edge on the light theme's pale key.
            border: white && p.isDark ? null : Border.all(color: p.borderStrong),
          ),
        ),
      ),
    );
  }
}

/// Start and End side by side, for the Bluetooth remote: a keyboard gets no
/// answer, so it cannot tell whether a show runs.
class StartEndPair extends StatelessWidget {
  const StartEndPair({super.key, this.onStart, this.onEnd, this.height = 52, this.iconsOnly = false});

  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final double height;

  /// Only the play and stop icons (the names stay for screen readers): beside
  /// the timer there is no room for "Başlat" (it showed "Başl…").
  final bool iconsOnly;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget key(IconData icon, String label, Color color, VoidCallback? onTap) {
      final radius = AppRadius.all(AppRadius.md);
      return Expanded(
        child: Pressable(
          onTap: onTap,
          semanticLabel: label,
          tooltip: iconsOnly ? label : null,
          pressedScale: 0.97,
          borderRadius: radius,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: p.isDark ? 0.12 : 0.09),
              borderRadius: radius,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: iconsOnly ? 28 : 24),
                  if (!iconsOnly) ...[
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.title.copyWith(color: color, fontSize: 15, fontWeight: FontWeight.w700),
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

    return Row(
      children: [
        key(Icons.play_arrow_rounded, context.l10n.actionStart, p.success, onStart),
        const SizedBox(width: AppSpace.sm),
        key(Icons.stop_rounded, context.l10n.actionEnd, p.danger, onEnd),
      ],
    );
  }
}
