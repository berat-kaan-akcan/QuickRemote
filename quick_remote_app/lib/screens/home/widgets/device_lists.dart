import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/discovery_service.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'spinning_refresh_icon.dart';

/// PCs found over mDNS under a section heading, filling the space it is
/// given. The recent connections are not listed: a found PC that is one of
/// them only carries a "saved" mark. Needs a bounded height (an [Expanded]).
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.wifi_find_rounded, color: p.primaryText, size: 18),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        context.l10n.homeNetworkDevices.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.overline.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: discovery.isDiscovering
                        ? null
                        : () => discovery.startScanning(),
                    dimWhenDisabled: false,
                    minTarget: 48,
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
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                switchInCurve: AppMotion.enter,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: discovery.devices.isEmpty
                    ? _EmptyBox(
                        key: ValueKey(discovery.isDiscovering),
                        searching: discovery.isDiscovering,
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
          color: saved ? null : p.surfaceRaised,
          gradient: saved
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.alphaBlend(
                      p.primaryText.withValues(alpha: p.isDark ? 0.12 : 0.08),
                      p.surfaceRaised,
                    ),
                    p.surfaceRaised,
                  ],
                )
              : null,
          borderRadius: radius,
          border: Border.all(
            color: saved
                ? p.primaryText.withValues(alpha: p.isDark ? 0.5 : 0.4)
                : p.border,
          ),
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

/// The page with the PC app's installers; a phone with no browser does
/// nothing, there is no better answer.
Future<void> _openPcDownload() async {
  try {
    await launchUrl(Uri.parse('${AppLog.repository}/releases/latest'), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Could not open the download page: $e');
  }
}

/// No PC (yet): a dashed box filling the list's space, saying that the
/// search runs or that it found nothing, with a rescan key then.
class _EmptyBox extends StatelessWidget {
  const _EmptyBox({super.key, required this.searching, required this.onRescan});

  final bool searching;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _DashedBorder(color: p.border, radius: AppRadius.lg),
      // Scrolls when the box is short (landscape, large text); Center keeps it
      // in the middle otherwise.
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: searching
                      ? p.primaryText.withValues(alpha: p.isDark ? 0.12 : 0.08)
                      : p.surfaceSunken,
                ),
                child: Icon(
                  searching ? Icons.wifi_find_rounded : Icons.wifi_off_rounded,
                  color: searching ? p.primaryText : p.textMuted,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                searching
                    ? context.l10n.homeSearching
                    : context.l10n.homeNoDevices,
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
                  height: 1.45,
                ),
              ),
              if (!searching) ...[
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  label: context.l10n.homeRescan,
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.tonal,
                  expand: false,
                  height: 48,
                  onPressed: onRescan,
                ),
                AppButton(
                  label: context.l10n.homeGetPcApp,
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.ghost,
                  expand: false,
                  height: 48,
                  onPressed: _openPcDownload,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle drawn with dashes.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    const dash = 7.0, gap = 5.0;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
