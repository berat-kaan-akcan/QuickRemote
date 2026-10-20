import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_language.dart';
import '../../providers/settings_provider.dart';
import '../../services/problem_report.dart';
import '../../services/websocket_service.dart';
import '../../utils/ui/app_snackbar.dart';
import '../../utils/ui/app_bottom_sheet.dart';
import '../../utils/ui/app_top_bar.dart';
import '../../widgets/ui/ui.dart';
import 'theme_screen.dart';
import 'timer_settings_screen.dart';
import 'presentation_history_screen.dart';
import 'widgets/settings_rows.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppTopBar(title: l10n.settingsTitle),
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.page,
                  0,
                  AppSpace.page,
                  MediaQuery.paddingOf(context).bottom + AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(
                      child: SettingsSectionLabel(
                        l10n.settingsSectionPresentation,
                      ),
                    ),
                    FadeSlideIn(
                      index: 1,
                      child: SettingsGroup(
                        children: [
                          SettingsRow(
                            icon: Icons.timer_outlined,
                            title: l10n.settingsTimerTitle,
                            subtitle: l10n.settingsTimerSubtitle,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TimerSettingsScreen(),
                              ),
                            ),
                          ),
                          SettingsRow(
                            icon: Icons.draw_outlined,
                            iconColor: p.success,
                            title: l10n.settingsKeepInkTitle,
                            subtitle: l10n.settingsKeepInkSubtitle,
                            alignTop: true,
                            value: settings.keepInkOnSlideChange,
                            onChanged: settings.setKeepInkOnSlideChange,
                          ),
                          SettingsRow(
                            icon: Icons.image_outlined,
                            iconColor: p.info,
                            title: l10n.settingsSlidePreviewTitle,
                            subtitle: l10n.settingsSlidePreviewSubtitle,
                            alignTop: true,
                            value: settings.slidePreview,
                            onChanged: settings.setSlidePreview,
                          ),
                          SettingsRow(
                            icon: Icons.insights_rounded,
                            iconColor: p.accentText,
                            title: l10n.settingsHistoryTitle,
                            subtitle: l10n.settingsHistorySubtitle,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PresentationHistoryScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    FadeSlideIn(
                      index: 2,
                      child: SettingsSectionLabel(l10n.settingsSectionGeneral),
                    ),
                    FadeSlideIn(
                      index: 3,
                      child: SettingsGroup(
                        children: [
                          SettingsRow(
                            icon: Icons.palette_outlined,
                            iconColor: p.violetText,
                            title: l10n.settingsThemeTitle,
                            subtitle: settings.colorTheme.followsMode
                                ? l10n.settingsThemeSubtitle(
                                    colorThemeName(l10n, settings.colorTheme),
                                    themeModeName(l10n, settings.themeMode),
                                  )
                                : colorThemeName(l10n, settings.colorTheme),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ThemeScreen(),
                              ),
                            ),
                          ),
                          SettingsRow(
                            icon: Icons.language_rounded,
                            iconColor: p.info,
                            title: l10n.settingsLanguageTitle,
                            subtitle: _languageName(context, settings.language),
                            onTap: () => _showLanguagePicker(context, settings),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    FadeSlideIn(
                      index: 4,
                      child: SettingsSectionLabel(l10n.settingsSectionHelp),
                    ),
                    FadeSlideIn(
                      index: 5,
                      child: SettingsGroup(
                        children: [
                          SettingsRow(
                            icon: Icons.bug_report_outlined,
                            iconColor: p.warning,
                            title: l10n.settingsShareLogTitle,
                            subtitle: l10n.settingsShareLogSubtitle,
                            alignTop: true,
                            onTap: () => _shareLog(context, settings),
                          ),
                          SettingsRow(
                            icon: Icons.open_in_new_rounded,
                            iconColor: p.info,
                            title: l10n.settingsReportProblemTitle,
                            subtitle: l10n.settingsReportProblemSubtitle,
                            alignTop: true,
                            onTap: () => _reportProblem(context, settings),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpace.xl),
                    Opacity(
                      opacity: 0.7,
                      child: Column(
                        children: [
                          const BrandTile(size: 36, shadow: false),
                          const SizedBox(height: 6),
                          Text(
                            l10n.homeTagline,
                            textAlign: TextAlign.center,
                            style: AppType.bodySmall.copyWith(
                              color: p.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The programs of the connected PC, for the log and the issue.
  static String _presenters(BuildContext context) {
    final service = context.read<WebSocketService>();
    return service.isConnected && service.presenters.isNotEmpty
        ? service.presenters.join(', ')
        : '-';
  }

  static Future<void> _shareLog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final shared = await ProblemReport.shareLog(
      presenters: _presenters(context),
      btTarget: settings.btTarget.name,
    );
    if (shared == true || !context.mounted) return;
    AppSnackbar.show(
      context,
      message: shared == null
          ? context.l10n.logShareEmpty
          : context.l10n.logShareFailed,
      type: shared == null ? SnackbarType.info : SnackbarType.error,
    );
  }

  static Future<void> _reportProblem(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final opened = await ProblemReport.openIssue(
      context.l10n,
      presenters: _presenters(context),
      btTarget: settings.btTarget.name,
    );
    if (opened || !context.mounted) return;
    AppSnackbar.show(
      context,
      message: context.l10n.issueOpenFailed,
      type: SnackbarType.error,
    );
  }

  static String _languageName(BuildContext context, AppLanguage language) =>
      language == AppLanguage.system
      ? context.l10n.languageSystem
      : language.nativeName;

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final p = ctx.palette;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBottomSheet.buildHeader(
              ctx.l10n.settingsLanguageTitle,
              icon: Icons.language_rounded,
              iconColor: p.info,
            ),
            const SizedBox(height: AppSpace.sm),
            for (final language in AppLanguage.values) ...[
              RadioRow(
                label: _languageName(ctx, language),
                selected: language == settings.language,
                onTap: () {
                  settings.setLanguage(language);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: AppSpace.xs),
            ],
            const SizedBox(height: AppSpace.xxs),
            Text(
              ctx.l10n.languageSystemNote,
              style: AppType.bodySmall.copyWith(
                color: p.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
