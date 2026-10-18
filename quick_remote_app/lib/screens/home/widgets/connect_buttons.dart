import 'dart:io';
import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Connect with the QR code or, on Android, over Bluetooth: two tiles side
/// by side.
class ConnectButtons extends StatelessWidget {
  const ConnectButtons({
    super.key,
    required this.connecting,
    required this.onScan,
    required this.onBluetooth,
  });

  final bool connecting;
  final VoidCallback onScan;
  final VoidCallback onBluetooth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ConnectTile(
            primary: true,
            icon: Icons.qr_code_scanner_rounded,
            label: connecting ? context.l10n.homeConnecting : context.l10n.homeConnectQr,
            busy: connecting,
            onTap: connecting ? null : onScan,
          ),
        ),
        if (Platform.isAndroid) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ConnectTile(
              primary: false,
              icon: Icons.bluetooth_rounded,
              label: context.l10n.homeConnectBluetooth,
              onTap: connecting ? null : onBluetooth,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConnectTile extends StatelessWidget {
  const _ConnectTile({
    required this.primary,
    required this.icon,
    required this.label,
    this.busy = false,
    this.onTap,
  });

  final bool primary;
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.lg);
    final fg = primary ? p.onPrimary : p.textPrimary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      dimWhenDisabled: !busy,
      pressedScale: 0.97,
      borderRadius: radius,
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: primary
              ? LinearGradient(
                  begin: const Alignment(-0.8, -1),
                  end: const Alignment(0.8, 1),
                  colors: [p.primaryBright, p.primary, p.primaryDeep],
                  stops: const [0, 0.6, 1],
                )
              : null,
          color: primary ? null : p.surface,
          borderRadius: radius,
          border: primary ? null : Border.all(color: p.border),
          boxShadow: primary ? AppShadows.glow(p.primaryBright, strength: 1.2) : null,
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              busy
                  ? SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                    )
                  : Icon(icon, color: primary ? fg : p.info, size: 26),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(color: fg, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
