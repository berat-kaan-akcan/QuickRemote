import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.settings_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Ayarlar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text(
              'Ortak Ağ Uyarılarını Gizle',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            subtitle: const Text(
              'Ortak ağlara bağlanırken güvenlik uyarısı gösterme.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            value: _hideWarning,
            activeTrackColor: const Color(0xFF00BCD4).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF00BCD4),
            onChanged: _saveSettings,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
