import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../providers/server_provider.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';

/// The QR code, host, port, security code and PIN a phone pairs with.
class PairingCard extends StatelessWidget {
  const PairingCard({
    super.key,
    required this.provider,
    required this.revealed,
    required this.onRevealChanged,
  });

  final WebSocketServerProvider provider;

  /// The user asked to see the QR code and PIN after a phone paired.
  final bool revealed;
  final ValueChanged<bool> onRevealChanged;

  @override
  Widget build(BuildContext context) {
    // Once a phone has paired, the code stays hidden until asked for: the
    // screen is often projected, and anyone who scans it can pair.
    final hidden = provider.pairedOnce && !revealed;
    final p = context.palette;

    return AppCard(
      elevated: true,
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg, horizontal: AppSpace.xl),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.slow),
                switchInCurve: AppMotion.enter,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(provider.isStarting ? 'starting' : hidden ? 'hidden' : 'qr'),
                  padding: const EdgeInsets.all(AppSpace.md - 2),
                  decoration: BoxDecoration(
                    color: provider.isStarting ? p.surfaceSunken : AppColors.white,
                    borderRadius: AppRadius.all(AppRadius.xl),
                    border: Border.all(color: p.border),
                    boxShadow: provider.isStarting ? null : AppShadows.soft(p),
                  ),
                  child: provider.isStarting
                      ? const _StartingIndicator()
                      : hidden
                          ? _HiddenCode(onReveal: () => onRevealChanged(true))
                          : _QrCode(data: _qrData),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                provider.isStarting
                    ? context.l10n.loadingNetwork
                    : hidden
                        ? context.l10n.showCodeToPair
                        : context.l10n.scanToConnect,
                textAlign: TextAlign.center,
                style: AppType.titleSmall.copyWith(color: p.textPrimary),
              ),
              if (provider.pairedOnce && revealed)
                TextButton.icon(
                  onPressed: () => onRevealChanged(false),
                  icon: const Icon(Icons.visibility_off_rounded, size: 16),
                  label: Text(context.l10n.hideCode),
                  style: TextButton.styleFrom(
                    foregroundColor: p.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const SizedBox(height: AppSpace.md),
              _ConnectionInfo(provider: provider),
              const SizedBox(height: AppSpace.md),
              _PinBoxes(
                pin: provider.pin,
                hidden: hidden,
                starting: provider.isStarting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _qrData => PairingPayload(
        host: provider.localIP,
        port: provider.port,
        pin: provider.pin,
        certFingerprint: provider.certFingerprint,
      ).encode();
}

class _StartingIndicator extends StatelessWidget {
  const _StartingIndicator();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 196,
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(p.primaryText),
              backgroundColor: p.primaryText.withValues(alpha: 0.15),
            ),
          ),
          const BrandTile(size: 52, shadow: false),
        ],
      ),
    );
  }
}

class _QrCode extends StatelessWidget {
  const _QrCode({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.l10n.scanToConnect,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            size: 196,
            backgroundColor: AppColors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.cobalt,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: AppColors.qrInk,
            ),
          ),
          // A white margin keeps the modules around the logo readable.
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.all(14),
            ),
            child: const BrandTile(size: 42, shadow: false),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the QR code once a phone has paired.
class _HiddenCode extends StatelessWidget {
  const _HiddenCode({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      height: 196,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 76, color: AppColors.qrInk.withValues(alpha: 0.18)),
          const SizedBox(height: AppSpace.sm),
          // Always on the white tile, so the light palette in both themes.
          Theme(
            data: Theme.of(context).copyWith(extensions: const [AppPalette.light]),
            child: AppButton(
              label: context.l10n.showCode,
              icon: Icons.visibility_rounded,
              variant: AppButtonVariant.solid,
              expand: false,
              height: 44,
              onPressed: onReveal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Host name, IP, port and the security code phones compare.
class _ConnectionInfo extends StatelessWidget {
  const _ConnectionInfo({required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Phones connecting without the QR code ask the user to compare this.
    final fingerprint = provider.certFingerprint;
    final fingerprintHex = fingerprint == null ? null : PairingPayload.fingerprintToHex(fingerprint);
    final portColor = provider.port != 8090 ? p.warning : p.primaryText;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.computer_rounded, size: 18, color: p.textMuted),
            const SizedBox(width: AppSpace.xs),
            Text(
              Platform.localHostname,
              style: AppType.title.copyWith(color: p.textPrimary, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoChip(label: 'IP', value: provider.localIP, color: p.textSecondary),
            const SizedBox(width: AppSpace.xs),
            _InfoChip(label: 'Port', value: '${provider.port}', color: portColor),
          ],
        ),
        if (fingerprintHex != null) ...[
          const SizedBox(height: AppSpace.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, size: 14, color: p.success),
              const SizedBox(width: 6),
              SelectableText(
                context.l10n.securityCode(PairingPayload.verificationCode(fingerprintHex)),
                style: AppType.mono.copyWith(color: p.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(color: color == p.textSecondary ? p.border : color.withValues(alpha: 0.5)),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label  ', style: AppType.labelSmall.copyWith(color: p.textMuted, fontSize: 11)),
          TextSpan(text: value, style: AppType.mono.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

/// The six-digit PIN in separate boxes; dots while hidden.
class _PinBoxes extends StatelessWidget {
  const _PinBoxes({required this.pin, required this.hidden, required this.starting});

  final String pin;
  final bool hidden;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final digits = List.generate(6, (i) => i < pin.length ? pin[i] : '');
    final label = starting ? 'PIN: ...' : hidden ? 'PIN: ••••••' : 'PIN: $pin';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: p.accentText, size: 18),
            const SizedBox(width: 6),
            Text('PIN', style: AppType.overline.copyWith(color: p.accentText)),
            const SizedBox(width: AppSpace.sm),
            for (var i = 0; i < 6; i++) ...[
              if (i == 3) const SizedBox(width: AppSpace.xs),
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.base),
                width: 36,
                height: 46,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: p.isDark ? 0.12 : 0.08),
                  borderRadius: AppRadius.all(AppRadius.sm),
                  border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.base),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    starting ? '·' : hidden ? '•' : digits[i],
                    key: ValueKey('${starting}_${hidden}_${digits[i]}'),
                    style: AppType.numeric.copyWith(color: p.textPrimary, fontSize: 24, letterSpacing: 0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
