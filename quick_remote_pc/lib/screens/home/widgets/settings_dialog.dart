import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_language.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/ui/ui.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languages = context.watch<LanguageProvider>();
    final p = context.palette;
    return AlertDialog(
      title: Row(
        children: [
          IconBadge(icon: Icons.settings_rounded, color: p.primaryText, size: 40),
          const SizedBox(width: AppSpace.sm),
          Text(
            l10n.settingsTitle,
            style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
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
                  child: Text(
                    l10n.settingsLanguageTitle,
                    style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: AppRadius.all(AppRadius.sm),
                    border: Border.all(color: p.border),
                  ),
                  child: DropdownButton<AppLanguage>(
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
                          child: Text(language == AppLanguage.system ? l10n.languageSystem : language.nativeName),
                        ),
                    ],
                    onChanged: (language) {
                      if (language != null) languages.setLanguage(language);
                    },
                  ),
                ),
              ],
            ),
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
