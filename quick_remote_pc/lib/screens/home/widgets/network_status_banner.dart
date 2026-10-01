import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../services/server/network_manager.dart';
import '../../../../services/websocket_server.dart';
import '../../../../widgets/hover_scale.dart';

class NetworkStatusBanner extends StatelessWidget {
  final NetworkTrust trust;
  final WebSocketServer server;

  const NetworkStatusBanner({
    super.key,
    required this.trust,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (trust) {
      NetworkTrust.trusted => (const Color(0xFF4CAF50), Icons.shield_rounded),
      NetworkTrust.untrusted => (const Color(0xFFFF9800), Icons.wifi_tethering_rounded),
      NetworkTrust.unknown => (const Color(0xFF90A4AE), Icons.help_outline_rounded),
    };
    // Linux has no network profiles; the trust level is the firewalld zone.
    final text = Platform.isLinux
        ? switch (trust) {
            NetworkTrust.trusted => 'Yerel Ağ',
            NetworkTrust.untrusted => 'Güvenilmeyen Ağ (firewalld)',
            NetworkTrust.unknown => 'Ağ türü bilinmiyor (firewalld yok)',
          }
        : switch (trust) {
            NetworkTrust.trusted => 'Güvenli Ağ (Private)',
            NetworkTrust.untrusted => 'Ortak Ağ (Public)',
            NetworkTrust.unknown => 'Ağ türü okunamadı',
          };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(icon, key: ValueKey(trust), color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                text,
                key: ValueKey(text),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (trust == NetworkTrust.untrusted) ...[
            HoverScale(
              scale: 1.1,
              onTap: () => server.openNetworkSettings(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ayarlar',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
