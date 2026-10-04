import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_language.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui/app_bottom_sheet.dart';
import '../../widgets/ui/ui.dart';
import 'timer_settings_screen.dart';
import 'presentation_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            MediaQuery.paddingOf(context).bottom + AppSpace.xl,
          ),
          children: [
            FadeSlideIn(child: SectionHeader(title: l10n.settingsSectionPresentation)),
            FadeSlideIn(
              index: 1,
              child: AppListTile(
                icon: Icons.timer_outlined,
                title: l10n.settingsTimerTitle,
                subtitle: l10n.settingsTimerSubtitle,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerSettingsScreen())),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FadeSlideIn(
              index: 2,
              child: AppListTile(
                icon: Icons.insights_rounded,
                iconColor: p.accentText,
                title: l10n.settingsHistoryTitle,
                subtitle: l10n.settingsHistorySubtitle,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresentationHistoryScreen())),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FadeSlideIn(
              index: 3,
              child: Consumer<SettingsProvider>(
                builder: (context, settings, _) => AppSwitchTile(
                  icon: Icons.draw_outlined,
                  iconColor: p.success,
                  title: l10n.settingsKeepInkTitle,
                  subtitle: l10n.settingsKeepInkSubtitle,
                  value: settings.keepInkOnSlideChange,
                  onChanged: settings.setKeepInkOnSlideChange,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            FadeSlideIn(index: 4, child: SectionHeader(title: l10n.settingsSectionGeneral)),
            FadeSlideIn(
              index: 5,
              child: Consumer<SettingsProvider>(
                builder: (context, settings, _) => AppListTile(
                  icon: Icons.language_rounded,
                  iconColor: p.info,
                  title: l10n.settingsLanguageTitle,
                  subtitle: _languageName(context, settings.language),
                  onTap: () => _showLanguagePicker(context, settings),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxxl),
            FadeSlideIn(
              index: 6,
              child: Column(
                children: [
                  const BrandTile(size: 52),
                  const SizedBox(height: AppSpace.sm),
                  const BrandWordmark(fontSize: 20),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    l10n.homeTagline,
                    textAlign: TextAlign.center,
                    style: AppType.bodySmall.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _languageName(BuildContext context, AppLanguage language) =>
      language == AppLanguage.system ? context.l10n.languageSystem : language.nativeName;

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final p = ctx.palette;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheet.buildTitle(ctx.l10n.settingsLanguageTitle, icon: Icons.language_rounded),
            const SizedBox(height: AppSpace.lg),
            for (final language in AppLanguage.values) ...[
              _LanguageOption(
                label: _languageName(ctx, language),
                selected: language == settings.language,
                onTap: () {
                  settings.setLanguage(language);
                  Navigator.pop(ctx);
                },
                checkColor: p.primaryText,
              ),
              const SizedBox(height: AppSpace.xs),
            ],
          ],
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.checkColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      selected: selected,
      pressedScale: 0.98,
      borderRadius: AppRadius.all(AppRadius.md),
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          color: selected ? checkColor.withValues(alpha: p.isDark ? 0.14 : 0.08) : p.surfaceSunken,
          borderRadius: AppRadius.all(AppRadius.md),
          border: Border.all(color: selected ? checkColor.withValues(alpha: 0.5) : p.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppType.titleSmall.copyWith(color: p.textPrimary)),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.base),
              curve: Curves.easeOutBack,
              child: Icon(Icons.check_circle_rounded, color: checkColor),
            ),
          ],
        ),
      ),
    );
  }
}
