import 'dart:io';
import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The fixed area at the bottom of the home screen: the wide QR key and,
/// under it, two square tiles for Bluetooth (Android only) and manual entry.
///
/// The keys are large; on a short screen (under [compactBelow] logical
/// pixels tall) they shrink back so the found PCs above keep some room.
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

  /// Screen height below which the keys take their smaller size.
  static const compactBelow = 700.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).height < compactBelow;
    const top = Radius.circular(26);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpace.page,
        compact ? 14 : AppSpace.md,
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
            compact: compact,
            onTap: connecting ? null : onScan,
          ),
          SizedBox(height: compact ? 10 : AppSpace.sm),
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
                      compact: compact,
                      onTap: connecting ? null : onBluetooth,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : AppSpace.sm),
                ],
                Expanded(
                  child: _SquareTile(
                    icon: Icons.keyboard_alt_outlined,
                    iconColor: p.primaryText,
                    label: l10n.homeManualConnection,
                    compact: compact,
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
  const _QrKey({
    required this.label,
    required this.busy,
    required this.compact,
    this.onTap,
  });

  final String label;
  final bool busy;
  final bool compact;
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
        constraints: BoxConstraints(minHeight: compact ? 64 : 80),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : AppSpace.lg,
          vertical: 10,
        ),
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
                      dimension: compact ? 26 : 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: fg,
                      ),
                    )
                  : Icon(
                      Icons.qr_code_scanner_rounded,
                      color: fg,
                      size: compact ? 28 : 34,
                    ),
              SizedBox(width: compact ? 14 : AppSpace.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(
                    color: fg,
                    fontSize: compact ? 16.5 : 18,
                  ),
                ),
              ),
              if (!busy) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: fg,
                  size: compact ? 22 : 26,
                ),
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
    required this.compact,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool compact;
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
        constraints: BoxConstraints(minHeight: compact ? 84 : 112),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: compact ? 10 : AppSpace.sm,
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
              Icon(icon, color: iconColor, size: compact ? 26 : 34),
              SizedBox(height: compact ? 6 : AppSpace.xs),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(
                  color: p.textPrimary,
                  fontSize: compact ? 12.5 : 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
