import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_version.dart';
import '../../../l10n/app_language.dart';
import '../../../providers/appearance_provider.dart';
import '../../../providers/desktop_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/desktop/problem_report.dart';
import '../../../widgets/status_snack_bar.dart';
import '../../../widgets/ui/ui.dart';
import 'laser_setting_section.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _hideWarning = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideWarning = prefs.getBool('hide_public_network_warning') ?? false;
    });
  }

  Future<void> _saveSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_public_network_warning', value);
    setState(() {
      _hideWarning = value;
    });
  }

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final p = context.palette;
    return SwitchListTile(
      title: Text(title, style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5)),
      subtitle: Text(subtitle, style: AppType.bodySmall.copyWith(color: p.textSecondary)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Startup and tray; only where a [DesktopProvider] runs (not in tests that
  /// leave it out).
  List<Widget> _desktopSection(BuildContext context) {
    final desktop = context.watch<DesktopProvider?>();
    if (desktop == null) return const [];
    final l10n = context.l10n;
    final p = context.palette;
    final launchAtLogin = desktop.launchAtLogin;
    final checkUpdates = desktop.checkUpdates;
    return [
      Divider(color: p.border, height: AppSpace.lg),
      Row(
        children: [
          Icon(Icons.power_settings_new_rounded, size: 20, color: p.textSecondary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              l10n.settingsStartup,
              style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
            ),
          ),
        ],
      ),
      _switch(
        title: l10n.settingsCloseToTray,
        subtitle: desktop.trayShown ? l10n.settingsCloseToTraySubtitle : l10n.settingsNoTray,
        value: desktop.trayShown && desktop.closeToTray,
        onChanged: desktop.trayShown ? desktop.setCloseToTray : null,
      ),
      if (launchAtLogin != null)
        _switch(
          title: l10n.settingsLaunchAtLogin,
          subtitle: l10n.settingsLaunchAtLoginSubtitle,
          value: launchAtLogin,
          onChanged: (value) async {
            final ok = await desktop.setLaunchAtLogin(value);
            if (!ok && context.mounted) {
              showStatusSnackBar(context, context.l10n.autostartFailed, kind: StatusKind.error);
            }
          },
        ),
      _switch(
        title: l10n.settingsStartServerOnLaunch,
        subtitle: l10n.settingsStartServerOnLaunchSubtitle,
        value: desktop.startServerOnLaunch,
        onChanged: desktop.setStartServerOnLaunch,
      ),
      if (checkUpdates != null)
        _switch(
          title: l10n.settingsCheckUpdates,
          subtitle: l10n.settingsCheckUpdatesSubtitle,
          value: checkUpdates,
          onChanged: desktop.setCheckUpdates,
        ),
    ];
  }

  /// The local log and a GitHub issue; nothing is sent by the app.
  List<Widget> _troubleshootingSection(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return [
      Divider(color: p.border, height: AppSpace.lg),
      Row(
        children: [
          Icon(Icons.bug_report_outlined, size: 20, color: p.textSecondary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              l10n.settingsTroubleshooting,
              style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.sm),
      Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          AppButton(
            label: l10n.settingsExportLog,
            icon: Icons.save_alt_rounded,
            variant: AppButtonVariant.tonal,
            expand: false,
            height: 40,
            onPressed: () async {
              final saved = await ProblemReport.exportLog();
              if (saved == null || !context.mounted) return;
              showStatusSnackBar(
                context,
                saved ? context.l10n.logExported : context.l10n.logExportFailed,
                kind: saved ? StatusKind.success : StatusKind.error,
              );
            },
          ),
          AppButton(
            label: l10n.settingsReportProblem,
            icon: Icons.open_in_new_rounded,
            variant: AppButtonVariant.tonal,
            expand: false,
            height: 40,
            onPressed: () => ProblemReport.openIssue(context.l10n),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.xs + 1),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.settingsLogPrivacy,
          style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
        ),
      ),
    ];
  }

  /// The version and the licenses of the code and fonts that ship with it.
  List<Widget> _aboutSection(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return [
      Divider(color: p.border, height: AppSpace.lg),
      Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: p.textSecondary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              l10n.settingsAbout,
              style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.sm),
      Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SelectableText(
            l10n.settingsVersion(appVersion),
            style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
          ),
          AppButton(
            label: l10n.settingsLicenses,
            icon: Icons.description_outlined,
            variant: AppButtonVariant.tonal,
            expand: false,
            height: 40,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'QuickRemote PC',
              applicationVersion: appVersion,
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languages = context.watch<LanguageProvider>();
    final appearance = context.watch<AppearanceProvider>();
    final p = context.palette;
    return AlertDialog(
      // A short window scrolls the content instead of cutting it off.
      scrollable: true,
      title: Row(
        children: [
          IconBadge(icon: Icons.settings_rounded, color: p.primaryText, size: 40),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              l10n.settingsTitle,
              style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(
                l10n.settingsHidePublicNetworkWarning,
                style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
              ),
              subtitle: Text(
                l10n.settingsHidePublicNetworkWarningSubtitle,
                style: AppType.bodySmall.copyWith(color: p.textSecondary),
              ),
              value: _hideWarning,
              onChanged: _saveSettings,
              contentPadding: EdgeInsets.zero,
            ),
            Divider(color: p.border, height: AppSpace.lg),
            Row(
              children: [
                Icon(Icons.language_rounded, size: 20, color: p.textSecondary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.settingsLanguageTitle,
                    style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
                  ),
                ),
                // The names are cut with an ellipsis before the row overflows
                // (a narrow window, large text).
                Flexible(
                  flex: 2,
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: AppRadius.all(AppRadius.sm),
                    border: Border.all(color: p.border),
                  ),
                  child: DropdownButton<AppLanguage>(
                    isExpanded: true,
                    value: languages.language,
                    dropdownColor: p.surfaceRaised,
                    borderRadius: AppRadius.all(AppRadius.md),
                    underline: const SizedBox.shrink(),
                    icon: Icon(Icons.expand_more_rounded, color: p.textSecondary),
                    style: AppType.body.copyWith(color: p.textPrimary, fontSize: 14),
                    items: [
                      for (final language in AppLanguage.values)
                        DropdownMenuItem(
                          value: language,
                          child: Text(
                            language == AppLanguage.system ? l10n.languageSystem : language.nativeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (language) {
                      if (language != null) languages.setLanguage(language);
                    },
                  ),
                ),
                ),
              ],
            ),
            Divider(color: p.border, height: AppSpace.lg),
            Row(
              children: [
                Icon(Icons.contrast_rounded, size: 20, color: p.textSecondary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    l10n.settingsAppearance,
                    style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm - 3),
            AppSegmented<ThemeMode>(
              height: 40,
              selected: appearance.mode,
              onChanged: appearance.setMode,
              segments: [
                AppSegment(value: ThemeMode.system, label: l10n.appearanceSystem, icon: Icons.computer_rounded),
                AppSegment(value: ThemeMode.light, label: l10n.appearanceLight, icon: Icons.light_mode_rounded),
                AppSegment(value: ThemeMode.dark, label: l10n.appearanceDark, icon: Icons.dark_mode_rounded),
              ],
            ),
            const SizedBox(height: AppSpace.xs + 1),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.appearanceNote,
                style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
              ),
            ),
            if (Platform.isLinux || Platform.isWindows) ...[
              Divider(color: p.border, height: AppSpace.lg),
              const LaserSettingSection(),
            ],
            ..._desktopSection(context),
            ..._troubleshootingSection(context),
            ..._aboutSection(context),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: l10n.close,
          variant: AppButtonVariant.tonal,
          expand: false,
          height: 44,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
