import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/discovery_service.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import 'spinning_refresh_icon.dart';

/// PCs found over mDNS, then the ones connected to before.
class DeviceLists extends StatelessWidget {
  const DeviceLists({
    super.key,
    required this.recentDevices,
    required this.onDiscoveredTap,
    required this.onRecentTap,
    required this.onRecentRemove,
  });

  final List<Map<String, dynamic>> recentDevices;
  final void Function(DiscoveredDevice device) onDiscoveredTap;
  final void Function(Map<String, dynamic> device) onRecentTap;
  final void Function(int index) onRecentRemove;

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryService>(
      builder: (context, discovery, child) {
        return Column(
          children: [
            // Discovered devices header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.homeNetworkDevices,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: discovery.isDiscovering
                      ? null
                      : () => discovery.startScanning(),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SpinningRefreshIcon(
                      isSpinning: discovery.isDiscovering,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scrollable device list
            Expanded(
              child: ListView(
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                children: [
                  // Discovered device items
                  if (discovery.devices.isEmpty)
                    if (discovery.isDiscovering)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              context.l10n.homeSearching,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              context.l10n.homeNoDevices,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => discovery.startScanning(),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                context.l10n.homeRescan,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                  else
                    ...discovery.devices.map(
                      (dev) => Padding(
                        key: ValueKey('${dev.ip}:${dev.port}'),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.hardEdge,
                          child: ListTile(
                            onTap: () => onDiscoveredTap(dev),
                            leading: const Icon(
                              Icons.computer_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              dev.name.isEmpty
                                  ? context.l10n.unknownPc
                                  : dev.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${dev.ip}:${dev.port}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Recent devices
                  if (recentDevices.isNotEmpty) ...[
                    Text(
                      context.l10n.homeRecent,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recentDevices.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dev = entry.value;
                      return Padding(
                        key: ValueKey('recent_${dev['host']}:${dev['port']}'),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.hardEdge,
                          child: ListTile(
                            onTap: () => onRecentTap(dev),
                            leading: const Icon(
                              Icons.history_rounded,
                              color: Colors.white54,
                            ),
                            title: Text(
                              dev['name'] ?? dev['host'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${dev['host']}:${dev['port']}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white24,
                                size: 20,
                              ),
                              tooltip: context.l10n.homeRemoveFromHistory,
                              onPressed: () => onRecentRemove(index),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
