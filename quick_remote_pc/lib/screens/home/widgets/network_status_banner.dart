import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/server/network_manager.dart';
import '../../../services/websocket_server.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

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
    final p = context.palette;
    final (color, icon) = switch (trust) {
      NetworkTrust.trusted => (p.success, Icons.shield_rounded),
      NetworkTrust.untrusted => (p.warning, Icons.wifi_tethering_rounded),
      NetworkTrust.unknown => (p.textMuted, Icons.help_outline_rounded),
    };
    // Linux has no network profiles; the trust level is the firewalld zone.
    final text = Platform.isLinux
        ? switch (trust) {
            NetworkTrust.trusted => context.l10n.networkTrusted,
            NetworkTrust.untrusted => context.l10n.networkUntrusted,
            NetworkTrust.unknown => context.l10n.networkZoneUnknown,
          }
        : switch (trust) {
            NetworkTrust.trusted => context.l10n.networkPrivate,
            NetworkTrust.untrusted => context.l10n.networkPublic,
            NetworkTrust.unknown => context.l10n.networkUnreadable,
          };
    final duration = AppMotion.of(context, AppMotion.base);

    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.standard,
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.xs, AppSpace.xs),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.12 : 0.08),
        borderRadius: AppRadius.all(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: p.isDark ? 0.30 : 0.24)),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: duration,
            child: Icon(icon, key: ValueKey(trust), color: color, size: 20),
          ),
          const SizedBox(width: AppSpace.sm - 2),
          Expanded(
            child: AnimatedSwitcher(
              duration: duration,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                text,
                key: ValueKey(text),
                style: AppType.labelSmall.copyWith(color: color, fontSize: 13),
              ),
            ),
          ),
          if (trust == NetworkTrust.untrusted)
            AppButton(
              label: context.l10n.settingsTitle,
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.tonal,
              tone: AppTone.warning,
              expand: false,
              height: 34,
              onPressed: () => server.openNetworkSettings(),
            ),
        ],
      ),
    );
  }
}
