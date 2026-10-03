import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_language.dart';
import '../../../providers/language_provider.dart';

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
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.settings_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            l10n.settingsTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text(
              l10n.settingsHidePublicNetworkWarning,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            subtitle: Text(
              l10n.settingsHidePublicNetworkWarningSubtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            value: _hideWarning,
            activeTrackColor: const Color(0xFF00BCD4).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF00BCD4),
            onChanged: _saveSettings,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.settingsLanguageTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              DropdownButton<AppLanguage>(
                value: languages.language,
                dropdownColor: const Color(0xFF1E293B),
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close, style: const TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
