import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/discovery_service.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
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
        final p = context.palette;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: context.l10n.homeNetworkDevices,
              icon: Icons.wifi_rounded,
              count: discovery.devices.length,
              trailing: Pressable(
                onTap: discovery.isDiscovering ? null : () => discovery.startScanning(),
                dimWhenDisabled: false,
                pressedScale: 0.9,
                tooltip: context.l10n.homeRescan,
                semanticLabel: context.l10n.homeRescan,
                borderRadius: AppRadius.all(AppRadius.pill),
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(child: SpinningRefreshIcon(isSpinning: discovery.isDiscovering)),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.base),
              switchInCurve: AppMotion.enter,
              child: discovery.devices.isEmpty
                  ? discovery.isDiscovering
                      ? const _SearchingPlaceholder(key: ValueKey('searching'))
                      : AppCard(
                          key: const ValueKey('empty'),
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.xl, horizontal: AppSpace.md),
                          child: EmptyState(
                            compact: true,
                            icon: Icons.wifi_find_rounded,
                            title: context.l10n.homeNoDevices,
                            action: AppButton(
                              label: context.l10n.homeRescan,
                              icon: Icons.refresh_rounded,
                              variant: AppButtonVariant.tonal,
                              expand: false,
                              height: 44,
                              onPressed: () => discovery.startScanning(),
                            ),
                          ),
                        )
                  : Column(
                      key: const ValueKey('devices'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, dev) in discovery.devices.indexed)
                          Padding(
                            key: ValueKey('${dev.ip}:${dev.port}'),
                            padding: const EdgeInsets.only(bottom: AppSpace.xs),
                            child: FadeSlideIn(
                              index: i,
                              child: AppListTile(
                                onTap: () => onDiscoveredTap(dev),
                                leading: _OnlineBadge(color: p.primaryText),
                                title: dev.name.isEmpty ? context.l10n.unknownPc : dev.name,
                                subtitle: '${dev.ip}:${dev.port}',
                                monoSubtitle: true,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (recentDevices.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                title: context.l10n.homeRecent,
                icon: Icons.history_rounded,
                count: recentDevices.length,
              ),
              for (final (index, dev) in recentDevices.indexed)
                Padding(
                  key: ValueKey('recent_${dev['host']}:${dev['port']}'),
                  padding: const EdgeInsets.only(bottom: AppSpace.xs),
                  child: FadeSlideIn(
                    index: index,
                    child: AppListTile(
                      onTap: () => onRecentTap(dev),
                      icon: Icons.desktop_windows_rounded,
                      iconColor: p.textSecondary,
                      title: dev['name'] ?? dev['host'],
                      subtitle: '${dev['host']}:${dev['port']}',
                      monoSubtitle: true,
                      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xxs, AppSpace.sm),
                      trailing: AppIconButton(
                        icon: Icons.close_rounded,
                        tooltip: context.l10n.homeRemoveFromHistory,
                        iconSize: 20,
                        color: p.textMuted,
                        onPressed: () => onRecentRemove(index),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// A computer badge with a live dot: found on the network right now.
class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconBadge(icon: Icons.computer_rounded, color: color),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle),
              child: PulseDot(color: p.success, size: 9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two placeholder rows and a "searching" line while mDNS looks for PCs.
class _SearchingPlaceholder extends StatelessWidget {
  const _SearchingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget row(double titleWidth) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
            child: Row(
              children: [
                const Skeleton(width: 44, height: 44, radius: 14),
                const SizedBox(width: AppSpace.md - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: titleWidth, height: 14),
                      const SizedBox(height: 8),
                      const Skeleton(width: 120, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(150),
        row(110),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulseDot(color: p.primaryText, size: 8),
              const SizedBox(width: AppSpace.sm),
              Text(
                context.l10n.homeSearching,
                style: AppType.bodySmall.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
