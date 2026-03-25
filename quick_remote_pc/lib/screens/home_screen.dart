import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketServerProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.devices, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QuickRemote',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'PC Companion',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      isRunning: provider.isRunning,
                      clientCount: provider.clientCount,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // QR Code Section
                Expanded(
                  child: provider.isRunning
                      ? _RunningView(provider: provider)
                      : _StoppedView(),
                ),

                const SizedBox(height: 16),

                // Start/Stop Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (provider.isRunning) {
                        await provider.stopServer();
                      } else {
                        await provider.startServer();
                      }
                    },
                    icon: Icon(
                      provider.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      provider.isRunning ? 'Sunucuyu Durdur' : 'Sunucuyu Başlat',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: provider.isRunning
                          ? theme.colorScheme.error
                          : const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isRunning;
  final int clientCount;

  const _StatusChip({required this.isRunning, required this.clientCount});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRunning
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : const Color(0xFFFF5252).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRunning
              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
              : const Color(0xFFFF5252).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isRunning ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isRunning ? '$clientCount bağlı' : 'Kapalı',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isRunning ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  final WebSocketServerProvider provider;

  const _RunningView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = 'quickremote://${provider.localIP}:${provider.port}:${provider.pin}';

    return Column(
      children: [
        // QR Code Card
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Reserve space for text + spacing (~60px)
                final availableForQR = (constraints.maxHeight - 60).clamp(80.0, 300.0);
                final qrSize = availableForQR.clamp(80.0, 180.0);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF6C63FF),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2D2B55),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Telefonunuzla QR kodu tarayın',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.localIP}:${provider.port}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6C63FF),
                          fontFamily: 'Consolas',
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // PIN display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, color: Color(0xFFFF9800), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'PIN: ${provider.pin}',
                              style: const TextStyle(
                                color: Color(0xFFFF9800),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Consolas',
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Laser indicator
        if (provider.laserActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF1744).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF1744),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lazer Aktif',
                  style: TextStyle(
                    color: Color(0xFFFF1744),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        if (!provider.laserActive)
          const SizedBox(height: 4),

        // Last Command
        if (provider.lastCommand.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCommandIcon(provider.lastCommand),
                  color: const Color(0xFF6C63FF),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Son komut: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Flexible(
                  child: Text(
                    _getCommandLabel(provider.lastCommand),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C63FF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getCommandIcon(String command) {
    switch (command) {
      case 'NEXT':
        return Icons.arrow_forward_rounded;
      case 'PREV':
        return Icons.arrow_back_rounded;
      case 'START':
        return Icons.play_arrow_rounded;
      case 'END':
        return Icons.stop_rounded;
      case 'LOCK':
        return Icons.lock_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }

  String _getCommandLabel(String command) {
    switch (command) {
      case 'NEXT':
        return 'Slayt İleri ➡️';
      case 'PREV':
        return '⬅️ Slayt Geri';
      case 'START':
        return '▶️ Sunum Başlat';
      case 'END':
        return '⏹️ Sunumu Bitir';
      case 'LOCK':
        return '🔒 PC Kilitle';
      default:
        return command;
    }
  }
}

class _StoppedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sunucu kapalı',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Telefonunuzdan bağlanmak için\nsunucuyu başlatın',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
