import 'dart:io';
import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The fixed area at the bottom of the home screen: the wide QR key and,
/// under it, two square tiles for Bluetooth (Android only) and manual entry.
class ConnectDock extends StatelessWidget {
  const ConnectDock({
    super.key,
    required this.connecting,
    required this.onScan,
    required this.onBluetooth,
    required this.onManual,
  });

  final bool connecting;
  final VoidCallback onScan;
  final VoidCallback onBluetooth;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    const top = Radius.circular(26);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpace.page,
        14,
        AppSpace.page,
        MediaQuery.paddingOf(context).bottom + AppSpace.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: top),
        border: Border(top: BorderSide(color: p.border)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.surface, p.surface.withValues(alpha: 0.92)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QrKey(
            label: connecting ? l10n.homeConnecting : l10n.homeConnectQr,
            busy: connecting,
            onTap: connecting ? null : onScan,
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (Platform.isAndroid) ...[
                  Expanded(
                    child: _SquareTile(
                      icon: Icons.bluetooth_rounded,
                      iconColor: p.info,
                      label: l10n.homeConnectBluetooth,
                      onTap: connecting ? null : onBluetooth,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _SquareTile(
                    icon: Icons.keyboard_alt_outlined,
                    iconColor: p.primaryText,
                    label: l10n.homeManualConnection,
                    onTap: connecting ? null : onManual,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The main way in: full width, the brand gradient, QR icon and an arrow.
class _QrKey extends StatelessWidget {
  const _QrKey({required this.label, required this.busy, this.onTap});

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.lg);
    final fg = p.onPrimary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      dimWhenDisabled: !busy,
      pressedScale: 0.98,
      borderRadius: radius,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.8, -1),
            end: const Alignment(0.8, 1),
            colors: [p.primaryBright, p.primary, p.primaryDeep],
            stops: const [0, 0.6, 1],
          ),
          borderRadius: radius,
          boxShadow: AppShadows.glow(p.primaryBright, strength: 1.2),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              busy
                  ? SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: fg,
                      ),
                    )
                  : Icon(Icons.qr_code_scanner_rounded, color: fg, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: fg, fontSize: 16.5),
                ),
              ),
              if (!busy) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(Icons.arrow_forward_rounded, color: fg, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A square-ish tile: the icon over a short label, both centred.
class _SquareTile extends StatelessWidget {
  const _SquareTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.lg);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.97,
      borderRadius: radius,
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: radius,
          border: Border.all(color: p.border),
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(
                  color: p.textPrimary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
