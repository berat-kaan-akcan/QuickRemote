import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Shown for a moment before the remote opens.
class BtConnectedView extends StatelessWidget {
  const BtConnectedView({super.key, required this.deviceName});

  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: AppMotion.reduced(context) ? 1 : 0, end: 1),
            duration: AppMotion.of(context, AppMotion.slow),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(scale: t, child: child),
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.success.withValues(alpha: p.isDark ? 0.14 : 0.10),
                border: Border.all(color: p.success.withValues(alpha: 0.4), width: 2),
                boxShadow: AppShadows.glow(p.success),
              ),
              child: Icon(Icons.bluetooth_connected_rounded, color: p.success, size: 60),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            context.l10n.btConnected,
            style: AppType.headline.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            deviceName ?? context.l10n.unknownDevice,
            style: AppType.titleSmall.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: p.textMuted),
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                context.l10n.btOpeningRemote,
                style: AppType.bodySmall.copyWith(color: p.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The phone cannot act as a Bluetooth keyboard and mouse.
class BtUnsupportedView extends StatelessWidget {
  const BtUnsupportedView({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: FadeSlideIn(
          child: EmptyState(
            icon: Icons.bluetooth_disabled_rounded,
            tone: AppTone.neutral,
            title: context.l10n.btUnsupported,
            message: message ?? context.l10n.btUnsupportedShort,
            action: AppButton(
              label: context.l10n.btUseWifi,
              icon: Icons.wifi_rounded,
              variant: AppButtonVariant.tonal,
              tone: AppTone.info,
              expand: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Something went wrong; the user can try again.
class BtErrorView extends StatelessWidget {
  const BtErrorView({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: FadeSlideIn(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            tone: AppTone.danger,
            title: context.l10n.errorTitle,
            message: message ?? context.l10n.btErrorOccurred,
            action: AppButton(
              label: context.l10n.tryAgain,
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.solid,
              tone: AppTone.info,
              expand: false,
              onPressed: onRetry,
            ),
          ),
        ),
      ),
    );
  }
}
