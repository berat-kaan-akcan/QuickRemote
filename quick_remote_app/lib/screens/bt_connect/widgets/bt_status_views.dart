import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'bt_make_visible_button.dart';
import 'bt_pairing_guide.dart';

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

/// The phone's Bluetooth is off. The screen goes on by itself once it is on.
class BtOffView extends StatelessWidget {
  const BtOffView({super.key, required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: FadeSlideIn(
          child: EmptyState(
            icon: Icons.bluetooth_disabled_rounded,
            tone: AppTone.warning,
            title: context.l10n.btOffTitle,
            message: context.l10n.btOffBody,
            action: AppButton(
              label: context.l10n.btTurnOn,
              icon: Icons.bluetooth_rounded,
              variant: AppButtonVariant.solid,
              tone: AppTone.info,
              expand: false,
              onPressed: onTurnOn,
            ),
          ),
        ),
      ),
    );
  }
}

/// Something went wrong; the user can try again, or do what [actionLabel]
/// says (e.g. open the settings for a refused permission).
class BtErrorView extends StatelessWidget {
  const BtErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
    this.actionLabel,
    this.actionIcon,
  });

  final String? message;
  final VoidCallback onRetry;
  final String? title;
  final String? actionLabel;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: FadeSlideIn(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            tone: AppTone.danger,
            title: title ?? context.l10n.errorTitle,
            message: message ?? context.l10n.btErrorOccurred,
            action: AppButton(
              label: actionLabel ?? context.l10n.tryAgain,
              icon: actionIcon ?? Icons.refresh_rounded,
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

/// The computer refused the phone as a keyboard: it was paired with the phone
/// while QuickRemote was not open. The phone keeps trying, so the remote opens
/// by itself once the user has done this on the computer.
class BtHostSetupView extends StatefulWidget {
  const BtHostSetupView({super.key});

  @override
  State<BtHostSetupView> createState() => _BtHostSetupViewState();
}

class _BtHostSetupViewState extends State<BtHostSetupView> {
  bool _linux = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmptyState(
                icon: Icons.keyboard_rounded,
                tone: AppTone.warning,
                compact: true,
                title: context.l10n.btHostUnawareTitle,
                message: context.l10n.btHostUnawareBody,
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                elevated: true,
                radius: AppRadius.xl,
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSegmented<bool>(
                      color: p.info,
                      segments: const [
                        AppSegment(value: false, label: 'Windows', icon: Icons.window_rounded),
                        AppSegment(value: true, label: 'Linux', icon: Icons.terminal_rounded),
                      ],
                      selected: _linux,
                      onChanged: (v) => setState(() => _linux = v),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      _linux ? context.l10n.btHostUnawareLinux : context.l10n.btHostUnawareWindows,
                      style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14),
                    ),
                    // Adding the phone again needs it visible.
                    const SizedBox(height: AppSpace.md),
                    const BtMakeVisibleButton(),
                    if (_linux) ...[
                      const SizedBox(height: AppSpace.md),
                      InlineAlert(
                        dense: true,
                        tone: AppTone.info,
                        icon: Icons.auto_fix_high_rounded,
                        message: context.l10n.btHostUnawareAuto,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              // The phone cannot tell why the computer refused: the same
              // refusal comes from a blocked phone.
              const BtTroubleshooting(),
              const SizedBox(height: AppSpace.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.textMuted),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Flexible(
                    child: Text(
                      context.l10n.btHostUnawareWaiting,
                      style: AppType.bodySmall.copyWith(color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
