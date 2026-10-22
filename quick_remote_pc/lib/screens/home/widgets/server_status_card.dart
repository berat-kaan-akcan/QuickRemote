import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/app_language.dart';
import '../../../providers/server_provider.dart';
import '../../../services/server/network_manager.dart';
import '../../../widgets/ui/ui.dart';
import 'home_card.dart';

/// The server at a glance: off, starting, or on with the network's trust and
/// how many phones are connected. On a public network it is amber and opens
/// the system's network settings.
class ServerStatusCard extends StatelessWidget {
  const ServerStatusCard({super.key, required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final duration = AppMotion.of(context, AppMotion.base);

    if (!provider.isRunning) {
      final starting = provider.isStarting;
      return _Frame(
        tint: null,
        badge: starting
            ? const _StartingBadge()
            : _Badge(color: p.textMuted, fill: p.surfaceSunken),
        title: starting ? l10n.serverStarting : l10n.serverStopped,
        subtitle: Text(
          starting ? l10n.loadingNetwork : l10n.serverStoppedSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.bodySmall.copyWith(
            color: p.textSecondary,
            fontSize: 12,
          ),
        ),
      );
    }

    final trust = provider.networkTrust;
    final (color, icon) = switch (trust) {
      NetworkTrust.trusted => (p.success, Icons.shield_rounded),
      NetworkTrust.untrusted => (p.warning, Icons.wifi_tethering_rounded),
      NetworkTrust.unknown => (p.textMuted, Icons.help_rounded),
    };
    // Linux has no network profiles; the trust level is the firewalld zone.
    final network = Platform.isLinux
        ? switch (trust) {
            NetworkTrust.trusted => l10n.networkTrusted,
            NetworkTrust.untrusted => l10n.networkUntrusted,
            NetworkTrust.unknown => l10n.networkZoneUnknown,
          }
        : switch (trust) {
            NetworkTrust.trusted => l10n.networkPrivate,
            NetworkTrust.untrusted => l10n.networkPublic,
            NetworkTrust.unknown => l10n.networkUnreadable,
          };
    final phones = provider.clientCount == 0
        ? l10n.waitingForPhone
        : l10n.phonesConnected(provider.clientCount);
    final small = AppType.bodySmall.copyWith(
      color: p.textSecondary,
      fontSize: 12,
    );

    return _Frame(
      tint: trust == NetworkTrust.trusted ? p.success : color,
      gradient: trust == NetworkTrust.trusted,
      badge: _Badge(color: p.success, fill: p.success.withValues(alpha: 0.18)),
      title: l10n.serverRunning,
      subtitle: AnimatedSwitcher(
        duration: duration,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, ?current],
        ),
        // Beside the Settings key there is no room for both on one line.
        child: Column(
          key: ValueKey('$trust$phones'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    network,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                if (trust != NetworkTrust.untrusted)
                  Flexible(child: Text(' · $phones', maxLines: 1, overflow: TextOverflow.ellipsis, style: small)),
              ],
            ),
            if (trust == NetworkTrust.untrusted) Text(phones, maxLines: 1, overflow: TextOverflow.ellipsis, style: small),
          ],
        ),
      ),
      action: trust == NetworkTrust.untrusted
          ? AppButton(
              label: l10n.settingsTitle,
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.tonal,
              tone: AppTone.warning,
              expand: false,
              height: 34,
              onPressed: () => provider.server.openNetworkSettings(),
            )
          : null,
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.tint,
    required this.badge,
    required this.title,
    required this.subtitle,
    this.gradient = false,
    this.action,
  });

  /// Colors the card; null leaves it the plain surface.
  final Color? tint;

  /// A soft green fade instead of a flat wash.
  final bool gradient;
  final Widget badge;
  final String title;
  final Widget subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = this.tint;
    final dark = p.isDark;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.standard,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: tint == null
            ? p.surface
            : (gradient
                  ? null
                  : Color.alphaBlend(tint.withValues(alpha: 0.10), p.surface)),
        gradient: tint != null && gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    tint.withValues(alpha: dark ? 0.13 : 0.10),
                    p.surface,
                  ),
                  Color.alphaBlend(
                    tint.withValues(alpha: dark ? 0.03 : 0.02),
                    p.surface,
                  ),
                ],
              )
            : null,
        borderRadius: AppRadius.all(HomeCard.radius),
        border: Border.all(
          color: tint == null
              ? p.border
              : tint.withValues(alpha: gradient ? 0.30 : 0.35),
        ),
      ),
      child: Row(
        children: [
          badge,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.title.copyWith(
                    color: p.textPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: AppSpace.xs), Flexible(child: action!)],
        ],
      ),
    );
  }
}

/// The power sign in a circle.
class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.fill});

  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.base),
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(Icons.power_settings_new_rounded, size: 30, color: color),
    );
  }
}

/// The power sign inside a turning ring while the server starts.
class _StartingBadge extends StatelessWidget {
  const _StartingBadge();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(p.primaryText),
              backgroundColor: p.primaryText.withValues(alpha: 0.18),
            ),
          ),
          Icon(
            Icons.power_settings_new_rounded,
            size: 26,
            color: p.primaryText,
          ),
        ],
      ),
    );
  }
}
