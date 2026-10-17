import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The top bar of the home screen: the brand lockup and the settings button.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        const Expanded(
          child: Align(alignment: Alignment.centerLeft, child: BrandLockup()),
        ),
        AppIconButton(
          icon: Icons.settings_rounded,
          tooltip: context.l10n.homeSettingsTooltip,
          onPressed: onSettings,
          background: p.surface.withValues(alpha: 0.7),
          border: true,
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
            style: AppType.headline.copyWith(color: p.textPrimary, fontSize: 26),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          context.l10n.homeHeroSubtitle,
          style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}
