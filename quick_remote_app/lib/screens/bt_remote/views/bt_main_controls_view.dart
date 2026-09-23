import 'package:flutter/material.dart';

import '../../remote/widgets/shared_buttons.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 0: Main Controls View  (WiFi MainControlsView ile aynı tasarım)
// ═════════════════════════════════════════════════════════════════════════════

class BtMainControlsView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;
  final String? activeScreen;

  const BtMainControlsView({
    super.key,
    required this.send,
    required this.isConnected,
    required this.activeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // BT bilgi bandı (slayt sayısı yerine)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bluetooth_connected_rounded,
                            color: Color(0xFF64B5F6),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bluetooth HID Modu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          // Başlat / Bitir
                          Row(
                            children: [
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Başlat',
                                  color: const Color(0xFF4CAF50),
                                  onTap: !isConnected ? null : () => send('START'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.stop_rounded,
                                  label: 'Bitir',
                                  color: const Color(0xFFFF5252),
                                  onTap: !isConnected ? null : () => send('END'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Siyah Ekran / Beyaz Ekran
                          Row(
                            children: [
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.visibility_off_rounded,
                                  label: 'Siyah Ekran',
                                  color: Colors.grey,
                                  isActive: activeScreen == 'BLACK',
                                  onTap: !isConnected ? null : () => send('BLACK_SCREEN'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ActionButton(
                                  icon: Icons.visibility_rounded,
                                  label: 'Beyaz Ekran',
                                  color: Colors.white,
                                  isActive: activeScreen == 'WHITE',
                                  onTap: !isConnected ? null : () => send('WHITE_SCREEN'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Geri / İleri
                          Row(
                            children: [
                              Expanded(
                                child: SlideButton(
                                  icon: Icons.arrow_back_rounded,
                                  label: 'Geri',
                                  onTap: !isConnected ? null : () => send('PREV'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SlideButton(
                                  icon: Icons.arrow_forward_rounded,
                                  label: 'İleri',
                                  isPrimary: true,
                                  onTap: !isConnected ? null : () => send('NEXT'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
