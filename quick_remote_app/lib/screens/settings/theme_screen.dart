import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_language.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_color_theme.dart';
import '../../utils/ui/app_top_bar.dart';
import '../../widgets/ui/ui.dart';
import 'widgets/settings_rows.dart';

/// The name of a color theme.
String colorThemeName(AppLocalizations l10n, AppColorTheme theme) =>
    switch (theme) {
      AppColorTheme.cobalt => l10n.themeCobalt,
      AppColorTheme.oled => l10n.themeOled,
      AppColorTheme.highContrast => l10n.themeHighContrast,
      AppColorTheme.mint => l10n.themeMint,
      AppColorTheme.violet => l10n.themeViolet,
      AppColorTheme.sunset => l10n.themeSunset,
    };

/// The name of a light/dark mode.
String themeModeName(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l10n.themeModeSystem,
  ThemeMode.light => l10n.themeModeLight,
  ThemeMode.dark => l10n.themeModeDark,
};

/// Settings → Theme: the light/dark mode, which only Cobalt has, and the
/// color theme, each as a small preview in its own colors.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final settings = context.watch<SettingsProvider>();
    final selected = settings.colorTheme;
    final note = switch (selected) {
      AppColorTheme.cobalt => l10n.themeCobaltNote,
      AppColorTheme.sunset => l10n.themeLightOnlyNote,
      _ => l10n.themeDarkOnlyNote,
    };
    // Cobalt's card shows the look Cobalt would have now.
    final cobaltBrightness = switch (settings.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    final cards = [
      for (final theme in AppColorTheme.values)
        _ThemeCard(
          name: colorThemeName(l10n, theme),
          preview: theme.paletteFor(cobaltBrightness),
          selected: theme == selected,
          onTap: () => settings.setColorTheme(theme),
        ),
    ];
    return Scaffold(
      appBar: AppTopBar(title: l10n.settingsThemeTitle),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            MediaQuery.paddingOf(context).bottom + AppSpace.md,
          ),
          children: [
            FadeSlideIn(child: SettingsSectionLabel(l10n.themeModeHeader)),
            FadeSlideIn(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModeTabs(
                    mode: settings.themeMode,
                    enabled: selected.followsMode,
                    onChanged: settings.setThemeMode,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    note,
                    style: AppType.bodySmall.copyWith(
                      color: p.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            FadeSlideIn(
              index: 2,
              child: SettingsSectionLabel(l10n.themeColorHeader),
            ),
            FadeSlideIn(
              index: 3,
              child: Column(
                children: [
                  for (var i = 0; i < cards.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[i]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: i + 1 < cards.length
                              ? cards[i + 1]
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// System, light and dark, faded and still when the theme has one look.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final ThemeMode mode;
  final bool enabled;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    Widget tab(ThemeMode value) {
      final on = mode == value;
      final label = themeModeName(l10n, value);
      return Expanded(
        child: Pressable(
          onTap: enabled ? () => onChanged(value) : null,
          dimWhenDisabled: false,
          selected: on,
          semanticLabel: label,
          pressedScale: 0.97,
          borderRadius: AppRadius.all(AppRadius.sm),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.base),
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? p.surfaceRaised
                  : p.surfaceRaised.withValues(alpha: 0),
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: on ? AppShadows.soft(p) : null,
            ),
            child: Text(
              label,
              style: AppType.labelSmall.copyWith(
                color: on ? p.textPrimary : p.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.base),
      opacity: enabled ? 1 : 0.35,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: AppRadius.all(AppRadius.md),
        ),
        child: Row(
          children: [
            tab(ThemeMode.system),
            const SizedBox(width: 3),
            tab(ThemeMode.light),
            const SizedBox(width: 3),
            tab(ThemeMode.dark),
          ],
        ),
      ),
    );
  }
}

/// A color theme: a small screen in its colors and its name.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.name,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final AppPalette preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = preview;
    final radius = AppRadius.all(AppRadius.md);
    final block = BorderRadius.circular(5);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: name,
      pressedScale: 0.97,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? p.primaryText : p.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 84,
                  padding: const EdgeInsets.all(AppSpace.xs),
                  decoration: BoxDecoration(
                    color: t.background,
                    borderRadius: AppRadius.all(AppRadius.sm),
                    border: Border.all(
                      color: t.isDark
                          ? t.textPrimary.withValues(alpha: 0.06)
                          : t.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: t.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 46,
                            height: 7,
                            decoration: BoxDecoration(
                              color: t.textPrimary.withValues(alpha: 0.8),
                              borderRadius: block,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: t.primaryGradient,
                                  borderRadius: block,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: t.surface,
                                  borderRadius: block,
                                  border: Border.all(color: t.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: t.surfaceRaised,
                          borderRadius: block,
                          border: Border.all(color: t.border),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(
                      color: p.textPrimary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: p.primaryText,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: p.background,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
