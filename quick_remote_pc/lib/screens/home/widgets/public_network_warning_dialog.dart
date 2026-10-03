import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/websocket_server.dart';

class PublicNetworkWarningDialog extends StatefulWidget {
  final WebSocketServer server;

  const PublicNetworkWarningDialog({super.key, required this.server});

  @override
  State<PublicNetworkWarningDialog> createState() => _PublicNetworkWarningDialogState();
}

class _PublicNetworkWarningDialogState extends State<PublicNetworkWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFFFF9800), size: 48),
      title: const Text(
        'Ortak Ağ Uyarısı',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Platform.isLinux
                ? 'Bu ağ, güvenlik duvarında güvenilmeyen ağ olarak tanımlı. Bu ağdaki '
                    'diğer kişiler QuickRemote sunucunuzu görebilir.\n\n'
                    'Güvenilir bir ağda olduğunuzdan emin olun.'
                : 'Şu an ortak bir ağdasınız. Bu ağdaki diğer kişiler '
                    'QuickRemote sunucunuzu görebilir.\n\n'
                    'Güvenilir bir ağda olduğunuzdan emin olun.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.server.openNetworkSettings(),
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Ağ Ayarlarını Aç', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00BCD4),
                side: const BorderSide(color: Color(0xFF00BCD4), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _dontShowAgain,
                  activeColor: const Color(0xFFFF9800),
                  side: const BorderSide(color: Colors.white54),
                  onChanged: (val) {
                    setState(() => _dontShowAgain = val ?? false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                  child: const Text(
                    'Bu uyarıyı bir daha gösterme',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (context.mounted) Navigator.of(context).pop(false);
          },
          child: const Text('Sunucuyu Durdur', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () async {
            if (_dontShowAgain) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hide_public_network_warning', true);
            }
            if (context.mounted) Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
