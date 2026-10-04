import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';

/// Previous, play/pause and next under a thin divider.
class MediaTransportRow extends StatelessWidget {
  const MediaTransportRow({
    super.key,
    required this.playIcon,
    required this.playLabel,
    this.onPrev,
    this.onPlayPause,
    this.onNext,
  });

  final IconData playIcon;
  final String playLabel;

  /// Null disables the button.
  final VoidCallback? onPrev;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.only(top: AppSpace.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundButton(icon: Icons.skip_previous_rounded, label: context.l10n.actionPrev, onTap: onPrev),
          const SizedBox(width: AppSpace.xl),
          _RoundButton(icon: playIcon, label: playLabel, onTap: onPlayPause, primary: true),
          const SizedBox(width: AppSpace.xl),
          _RoundButton(icon: Icons.skip_next_rounded, label: context.l10n.actionNext, onTap: onNext),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = primary ? 68.0 : 52.0;
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
          gradient: primary ? p.primaryGradient : null,
          color: primary ? null : p.surfaceSunken,
          border: primary ? null : Border.all(color: p.border),
          boxShadow: primary && onTap != null ? AppShadows.glow(p.primary) : null,
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.fast),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: primary ? AppColors.white : p.textPrimary,
            size: primary ? 36 : 26,
          ),
        ),
      ),
    );
  }
}
