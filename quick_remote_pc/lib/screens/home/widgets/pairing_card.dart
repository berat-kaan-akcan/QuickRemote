import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../providers/server_provider.dart';
import '../../../widgets/hover_glow_container.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HoverGlowContainer(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: provider.isStarting ? Colors.transparent : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: provider.isStarting
                          ? const _StartingIndicator()
                          : hidden
                              ? _HiddenCode(onReveal: () => onRevealChanged(true))
                              : _QrCode(data: _qrData),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.isStarting
                        ? context.l10n.loadingNetwork
                        : hidden
                            ? context.l10n.showCodeToPair
                            : context.l10n.scanToConnect,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (provider.pairedOnce && revealed)
                    TextButton.icon(
                      onPressed: () => onRevealChanged(false),
                      icon: const Icon(Icons.visibility_off_rounded, size: 16),
                      label: Text(context.l10n.hideCode),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _ConnectionInfo(provider: provider),
                  const SizedBox(height: 8),
                  _PinBadge(
                    text: provider.isStarting
                        ? 'PIN: ...'
                        : hidden
                            ? 'PIN: ••••••'
                            : 'PIN: ${provider.pin}',
                  ),
                ],
              ),
            ),
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

/// The round logo in the middle of the QR code and the spinner.
class _Logo extends StatelessWidget {
  const _Logo({required this.shadow});

  final BoxShadow shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [shadow],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _StartingIndicator extends StatelessWidget {
  const _StartingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            ),
          ),
          _Logo(
            shadow: BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          data: data,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          size: 184,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: AppColors.background,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: AppColors.background,
          ),
        ),
        _Logo(
          shadow: BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ),
      ],
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
      width: 184,
      height: 184,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.background.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: Text(context.l10n.showCode),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: Colors.white,
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
    // Phones connecting without the QR code ask the user to compare this.
    final fingerprint = provider.certFingerprint;
    final fingerprintHex = fingerprint == null ? null : PairingPayload.fingerprintToHex(fingerprint);
    final portColor = provider.port != 8090 ? AppColors.caution : AppColors.accent;

    return Column(
      children: [
        Text(
          Platform.localHostname,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'IP: ${provider.localIP}',
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Consolas',
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: portColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: portColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Port: ${provider.port}',
                style: TextStyle(
                  color: portColor,
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        if (fingerprintHex != null) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.securityCode(PairingPayload.verificationCode(fingerprintHex)),
            style: const TextStyle(color: Colors.white54, fontFamily: 'Consolas', fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Consolas',
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}
