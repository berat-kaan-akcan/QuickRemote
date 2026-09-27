import 'package:flutter/material.dart';
import '../../../../services/websocket_server.dart';
import '../../../../widgets/hover_scale.dart';

class NetworkStatusBanner extends StatelessWidget {
  final bool isPublic;
  final WebSocketServer server;

  const NetworkStatusBanner({
    super.key,
    required this.isPublic,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);
    final icon = isPublic ? Icons.wifi_tethering_rounded : Icons.shield_rounded;
    final text = isPublic ? 'Ortak Ağ (Public)' : 'Güvenli Ağ (Private)';

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
            child: Icon(icon, key: ValueKey(isPublic), color: color, size: 20),
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
          if (isPublic) ...[
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
