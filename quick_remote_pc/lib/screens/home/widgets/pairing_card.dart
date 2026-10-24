import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../providers/server_provider.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';
import 'home_card.dart';

/// The QR code, host, port, security code and PIN a phone pairs with. In the
/// narrow window the code sits beside the details with the PIN below; in the
/// wide one the code is larger and everything else stands beside it.
class PairingCard extends StatelessWidget {
  const PairingCard({
    super.key,
    required this.provider,
    required this.revealed,
    required this.onRevealChanged,
    this.wide = false,
  });

  final WebSocketServerProvider provider;

  /// The user asked to see the QR code and PIN after a phone paired.
  final bool revealed;
  final ValueChanged<bool> onRevealChanged;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    // Once a phone has paired, the code stays hidden until asked for: the
    // screen is often projected, and anyone who scans it can pair.
    final hidden = provider.pairedOnce && !revealed;
    final starting = provider.isStarting;
    final p = context.palette;
    final l10n = context.l10n;

    final tile = _QrTile(
      size: wide ? 220 : 150,
      starting: starting,
      hidden: hidden,
      data: _qrData,
      onReveal: () => onRevealChanged(true),
    );
    final caption = Text(
      starting
          ? l10n.loadingNetwork
          : hidden
          ? l10n.showCodeToPair
          : l10n.scanToConnect,
      style: AppType.titleSmall.copyWith(
        color: p.textPrimary,
        fontSize: wide ? 16 : 14,
        height: 1.35,
      ),
    );
    final hide = provider.pairedOnce && revealed && !starting
        ? _HideCode(onTap: () => onRevealChanged(false))
        : null;
    final host = starting
        ? Text(
            Platform.localHostname,
            style: AppType.bodySmall.copyWith(
              color: p.textSecondary,
              fontSize: 12,
            ),
          )
        : _HostName(fontSize: wide ? 18 : 16);
    final chips = starting ? null : _Chips(provider: provider);
    final security = starting
        ? null
        : _SecurityCode(fingerprint: provider.certFingerprint);
    final pin = _PinBoxes(
      pin: provider.pin,
      hidden: hidden,
      starting: starting,
      scale: wide ? 1 : 0.95,
    );

    if (wide) {
      return HomeCard(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile,
            const SizedBox(width: 30),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, child) in [
                    caption,
                    ?hide,
                    host,
                    ?chips,
                    ?security,
                    pin,
                  ].indexed) ...[if (i > 0) const SizedBox(height: 14), child],
                ],
              ),
            ),
          ],
        ),
      );
    }
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              tile,
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, child) in [
                      caption,
                      ?hide,
                      host,
                      ?chips,
                    ].indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpace.xs),
                      child,
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: pin),
          ),
          if (security != null) ...[
            const SizedBox(height: AppSpace.sm),
            Center(child: security),
          ],
        ],
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

/// The white tile: the QR code, the button that shows it again, or a
/// spinner while the server starts.
class _QrTile extends StatelessWidget {
  const _QrTile({
    required this.size,
    required this.starting,
    required this.hidden,
    required this.data,
    required this.onReveal,
  });

  final double size;
  final bool starting;
  final bool hidden;
  final String data;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedSwitcher(
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
        key: ValueKey(
          starting
              ? 'starting'
              : hidden
              ? 'hidden'
              : 'qr',
        ),
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: starting ? p.surfaceSunken : AppColors.white,
          borderRadius: AppRadius.all(HomeCard.radius),
          border: starting || !p.isDark ? Border.all(color: p.border) : null,
          boxShadow: starting
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(
                      alpha: p.isDark ? 0.6 : 0.35,
                    ),
                    blurRadius: 30,
                    spreadRadius: -14,
                    offset: const Offset(0, 14),
                  ),
                ],
        ),
        child: SizedBox.square(
          dimension: size,
          child: starting
              ? const _StartingIndicator()
              : hidden
              ? _HiddenCode(size: size, onReveal: onReveal)
              : _QrCode(data: data, size: size),
        ),
      ),
    );
  }
}

class _StartingIndicator extends StatelessWidget {
  const _StartingIndicator();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: SizedBox.square(
        dimension: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
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
      ),
    );
  }
}

class _QrCode extends StatelessWidget {
  const _QrCode({required this.data, required this.size});

  final String data;
  final double size;

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
            size: size,
            padding: EdgeInsets.zero,
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
            child: BrandTile(size: size * 0.21, shadow: false),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the QR code once a phone has paired.
class _HiddenCode extends StatelessWidget {
  const _HiddenCode({required this.size, required this.onReveal});

  final double size;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.qr_code_2_rounded,
          size: size * 0.39,
          color: AppColors.qrInk.withValues(alpha: 0.16),
        ),
        SizedBox(height: size * 0.06),
        // Always on the white tile, so the light palette in both themes.
        Theme(
          data: Theme.of(
            context,
          ).copyWith(extensions: const [AppPalette.light]),
          child: AppButton(
            label: context.l10n.showCode,
            icon: Icons.visibility_rounded,
            variant: AppButtonVariant.solid,
            expand: false,
            height: 42,
            onPressed: onReveal,
          ),
        ),
      ],
    );
  }
}

/// Hides the code again after it was shown to pair another phone.
class _HideCode extends StatelessWidget {
  const _HideCode({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = context.l10n.hideCode;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.96,
      borderRadius: AppRadius.all(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 15,
              color: p.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppType.labelSmall.copyWith(
                  color: p.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostName extends StatelessWidget {
  const _HostName({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.computer_outlined, size: 17, color: p.textMuted),
        const SizedBox(width: 6),
        // The phone lists the PC by this name, so it shrinks rather than
        // losing its end: Windows' default names (DESKTOP-XXXXXXX) are 15
        // characters, one too many for the narrow window's card.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              Platform.localHostname,
              maxLines: 1,
              style: AppType.title.copyWith(
                color: p.textPrimary,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The IP and the port; the port in amber when it is not the usual 8090.
class _Chips extends StatelessWidget {
  const _Chips({required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _InfoChip(label: 'IP', value: provider.localIP, color: p.textSecondary),
        _InfoChip(
          label: 'Port',
          value: '${provider.port}',
          color: provider.port != 8090 ? p.warning : p.textSecondary,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

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
        borderRadius: AppRadius.all(9),
        border: Border.all(
          color: color == p.textSecondary
              ? p.border
              : color.withValues(alpha: 0.5),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: AppType.labelSmall.copyWith(
                color: p.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: AppType.mono.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The code phones connecting without the QR code ask the user to compare.
class _SecurityCode extends StatelessWidget {
  const _SecurityCode({required this.fingerprint});

  final String? fingerprint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fingerprint = this.fingerprint;
    final hex = fingerprint == null
        ? null
        : PairingPayload.fingerprintToHex(fingerprint);
    if (hex == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_rounded, size: 14, color: p.success),
        const SizedBox(width: 6),
        Flexible(
          child: SelectableText(
            context.l10n.securityCode(PairingPayload.verificationCode(hex)),
            maxLines: 1,
            style: AppType.mono.copyWith(color: p.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// The six-digit PIN in separate boxes; dots while hidden.
class _PinBoxes extends StatelessWidget {
  const _PinBoxes({
    required this.pin,
    required this.hidden,
    required this.starting,
    this.scale = 1,
  });

  final String pin;
  final bool hidden;
  final bool starting;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final digits = List.generate(6, (i) => i < pin.length ? pin[i] : '');
    final label = starting
        ? 'PIN: ...'
        : hidden
        ? 'PIN: ••••••'
        : 'PIN: $pin';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        // The boxes are drawn digits with a spoken label above: at large
        // text sizes the row shrinks instead of running out of the card.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, color: p.accentText, size: 17),
              const SizedBox(width: 6),
              Text(
                'PIN',
                style: AppType.overline.copyWith(
                  color: p.accentText,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              for (var i = 0; i < 6; i++) ...[
                if (i == 3) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.base),
                  width: 36 * scale,
                  height: 46 * scale,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: p.isDark ? 0.12 : 0.08),
                    borderRadius: AppRadius.all(10),
                    border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.base),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      starting
                          ? '·'
                          : hidden
                          ? '•'
                          : digits[i],
                      key: ValueKey('${starting}_${hidden}_${digits[i]}'),
                      style: AppType.numeric.copyWith(
                        color: p.textPrimary,
                        fontSize: 24 * scale,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
