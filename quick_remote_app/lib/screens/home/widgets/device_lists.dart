import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/discovery_service.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'spinning_refresh_icon.dart';

/// PCs found over mDNS, in a card. The recent connections are not listed:
/// a found PC that is one of them only carries a "saved" mark.
class DeviceLists extends StatelessWidget {
  const DeviceLists({
    super.key,
    required this.onDiscoveredTap,
    required this.isSaved,
  });

  final void Function(DiscoveredDevice device) onDiscoveredTap;

  /// A recent connection with a PIN: a tap connects without asking for one.
  final bool Function(DiscoveredDevice device) isSaved;

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryService>(
      builder: (context, discovery, child) {
        final p = context.palette;
        final empty = discovery.devices.isEmpty && !discovery.isDiscovering;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ListCard(
              icon: Icons.wifi_find_rounded,
              title: context.l10n.homeNetworkDevices,
              centered: empty,
              trailing: Pressable(
                onTap: discovery.isDiscovering
                    ? null
                    : () => discovery.startScanning(),
                dimWhenDisabled: false,
                pressedScale: 0.9,
                tooltip: context.l10n.homeRescan,
                semanticLabel: context.l10n.homeRescan,
                borderRadius: AppRadius.all(AppRadius.pill),
                child: SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: SpinningRefreshIcon(
                      isSpinning: discovery.isDiscovering,
                    ),
                  ),
                ),
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                switchInCurve: AppMotion.enter,
                child: discovery.devices.isEmpty
                    ? discovery.isDiscovering
                          ? const _SearchingPlaceholder(
                              key: ValueKey('searching'),
                            )
                          : _NothingFound(
                              key: const ValueKey('empty'),
                              onRescan: () => discovery.startScanning(),
                            )
                    : Column(
                        key: const ValueKey('devices'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, dev) in discovery.devices.indexed)
                            Padding(
                              key: ValueKey('${dev.ip}:${dev.port}'),
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : AppSpace.xs,
                              ),
                              child: FadeSlideIn(
                                index: i,
                                child: _PcRow(
                                  onTap: () => onDiscoveredTap(dev),
                                  badge: IconBadge(
                                    icon: Icons.computer_rounded,
                                    color: p.primaryText,
                                    size: 38,
                                  ),
                                  title: dev.name.isEmpty
                                      ? context.l10n.unknownPc
                                      : dev.name,
                                  subtitle: '${dev.ip}:${dev.port}',
                                  saved: isSaved(dev),
                                  trailing: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: p.primaryText,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A card with an icon and capitals over its rows.
class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.centered = false,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  /// The heading in the middle, over a message rather than rows.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final header = Row(
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(icon, color: p.primaryText, size: 18),
        const SizedBox(width: AppSpace.xs),
        Flexible(
          fit: centered ? FlexFit.loose : FlexFit.tight,
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: AppType.overline.copyWith(color: p.textSecondary),
            ),
          ),
        ),
        if (trailing != null) ...[
          if (centered) const SizedBox(width: AppSpace.xs),
          trailing!,
        ],
      ],
    );
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: centered ? Center(child: header) : header,
          ),
          const SizedBox(height: AppSpace.xs),
          child,
        ],
      ),
    );
  }
}

/// A PC in a list: its badge, name and address, and an action.
class _PcRow extends StatelessWidget {
  const _PcRow({
    required this.onTap,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.saved = false,
  });

  final VoidCallback onTap;
  final Widget badge;
  final String title;
  final String subtitle;
  final Widget trailing;

  /// Shows the "saved" mark: connects with the saved PIN.
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.md);
    return Pressable(
      onTap: onTap,
      semanticLabel: saved
          ? '$title, $subtitle, ${context.l10n.homeSavedHint}'
          : '$title, $subtitle',
      pressedScale: 0.98,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: radius,
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: badge),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.titleSmall.copyWith(
                        color: p.textPrimary,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.mono.copyWith(
                        color: p.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (saved) ...[
              const SizedBox(width: AppSpace.xs),
              const ExcludeSemantics(child: _SavedMark()),
              const SizedBox(width: AppSpace.xs),
            ],
            trailing,
            const SizedBox(width: AppSpace.xxs),
          ],
        ),
      ),
    );
  }
}

/// "Saved": the PC is a recent connection and a tap uses its saved PIN.
class _SavedMark extends StatelessWidget {
  const _SavedMark();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: context.l10n.homeSavedHint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: p.primaryText.withValues(alpha: p.isDark ? 0.14 : 0.10),
          borderRadius: AppRadius.all(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_rounded, size: 12, color: p.primaryText),
            const SizedBox(width: 4),
            Text(
              context.l10n.homeSaved,
              maxLines: 1,
              style: AppType.labelSmall.copyWith(
                color: p.primaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nothing found on the network, and why that may be.
class _NothingFound extends StatelessWidget {
  const _NothingFound({super.key, required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        0,
        AppSpace.xs,
        AppSpace.xs,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: AppRadius.all(AppRadius.md),
            ),
            child: Icon(Icons.wifi_off_rounded, color: p.textMuted, size: 30),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            context.l10n.homeNoDevices,
            textAlign: TextAlign.center,
            style: AppType.titleSmall.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            context.l10n.homeNoDevicesHint,
            textAlign: TextAlign.center,
            style: AppType.bodySmall.copyWith(
              color: p.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: context.l10n.homeRescan,
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.tonal,
            expand: false,
            height: 42,
            onPressed: onRescan,
          ),
        ],
      ),
    );
  }
}

/// A "searching" line and two placeholder rows while mDNS looks for PCs.
class _SearchingPlaceholder extends StatelessWidget {
  const _SearchingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget row(double titleWidth) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: AppRadius.all(AppRadius.md),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            const Skeleton(width: 38, height: 38, radius: 13),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: titleWidth, height: 11),
                  const SizedBox(height: 6),
                  const Skeleton(width: 90, height: 9),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Icon(Icons.radar_rounded, color: p.primaryText, size: 18),
              const SizedBox(width: AppSpace.xs),
              Text(
                context.l10n.homeSearching,
                style: AppType.bodySmall.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        row(150),
        row(110),
      ],
    );
  }
}
