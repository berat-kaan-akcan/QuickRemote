import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The top bar of the home screen: the brand lockup and the settings key.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    final label = context.l10n.homeSettingsTooltip;
    return Row(
      children: [
        const Expanded(
          child: Align(alignment: Alignment.centerLeft, child: BrandLockup()),
        ),
        Pressable(
          onTap: onSettings,
          semanticLabel: label,
          tooltip: label,
          pressedScale: 0.9,
          minTarget: 48,
          borderRadius: radius,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: radius,
              border: Border.all(color: p.border),
            ),
            child: Icon(Icons.settings_rounded, color: p.textPrimary, size: 22),
          ),
        ),
      ],
    );
  }
}

/// The hero of the home screen: the tagline and how to connect.
class HomeBranding extends StatelessWidget {
  const HomeBranding({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.homeTagline,
            style: AppType.headline.copyWith(
              color: p.textPrimary,
              fontSize: 30,
              height: 1.12,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.homeHeroSubtitle,
          style: AppType.bodySmall.copyWith(
            color: p.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
