import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_language.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui/app_bottom_sheet.dart';
import 'timer_settings_screen.dart';
import 'presentation_history_screen.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.settingsTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMenuTile(
            context,
            icon: Icons.timer_outlined,
            title: l10n.settingsTimerTitle,
            subtitle: l10n.settingsTimerSubtitle,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerSettingsScreen())),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context,
            icon: Icons.history_rounded,
            title: l10n.settingsHistoryTitle,
            subtitle: l10n.settingsHistorySubtitle,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresentationHistoryScreen())),
          ),
          const SizedBox(height: 12),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => _buildSwitchTile(
              context,
              icon: Icons.draw_outlined,
              title: l10n.settingsKeepInkTitle,
              subtitle: l10n.settingsKeepInkSubtitle,
              value: settings.keepInkOnSlideChange,
              onChanged: settings.setKeepInkOnSlideChange,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => _buildMenuTile(
              context,
              icon: Icons.language_rounded,
              title: l10n.settingsLanguageTitle,
              subtitle: _languageName(context, settings.language),
              onTap: () => _showLanguagePicker(context, settings),
            ),
          ),
        ],
      ),
    );
  }

  static String _languageName(BuildContext context, AppLanguage language) =>
      language == AppLanguage.system ? context.l10n.languageSystem : language.nativeName;

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheet.buildTitle(ctx.l10n.settingsLanguageTitle, icon: Icons.language_rounded),
          const SizedBox(height: 16),
          for (final language in AppLanguage.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_languageName(ctx, language), style: const TextStyle(color: Colors.white, fontSize: 16)),
              trailing: language == settings.language
                  ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setLanguage(language);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
