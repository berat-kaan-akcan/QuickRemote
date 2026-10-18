import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'bt_make_visible_button.dart';
import 'bt_pairing_guide.dart';
import 'glowing_dots.dart';

/// The small print under an action.
class BtActionHint extends StatelessWidget {
  const BtActionHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppType.bodySmall.copyWith(
        color: context.palette.textSecondary,
        fontSize: 12,
      ),
    );
  }
}

/// Waiting for the phone or the computer: a pulsing Bluetooth icon, what is
/// going on, the dots, and Cancel.
class BtWaitingView extends StatelessWidget {
  const BtWaitingView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.dots,
    required this.onCancel,
  });

  final IconData icon;
  final String title;
  final String message;
  final Animation<double> dots;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RadarPulse(
                      color: p.info,
                      size: 240,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.info.withValues(alpha: 0.14),
                        ),
                        child: Icon(icon, color: p.info, size: 56),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppType.headline.copyWith(
                        color: p.textPrimary,
                        fontSize: 23,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    GlowingDots(animation: dots),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppType.bodySmall.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: context.l10n.cancel,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                onPressed: onCancel,
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ],
    );
  }
}

/// The computer refused the phone as a keyboard: it was paired with the phone
/// while QuickRemote was not open. The phone keeps trying, so the remote opens
/// by itself once the user has done this on the computer.
class BtHostSetupView extends StatefulWidget {
  const BtHostSetupView({super.key, required this.dots});

  final Animation<double> dots;

  @override
  State<BtHostSetupView> createState() => _BtHostSetupViewState();
}

class _BtHostSetupViewState extends State<BtHostSetupView> {
  bool _linux = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(
                    icon: Icons.keyboard_hide_rounded,
                    color: p.warning,
                    size: 42,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      context.l10n.btHostUnawareTitle,
                      style: AppType.titleSmall.copyWith(
                        color: p.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                context.l10n.btHostUnawareBody,
                style: AppType.bodySmall.copyWith(
                  color: p.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              BtSystemTabs(
                linux: _linux,
                onChanged: (v) => setState(() => _linux = v),
              ),
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: AppRadius.all(AppRadius.lg),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  _linux
                      ? context.l10n.btHostUnawareLinux
                      : context.l10n.btHostUnawareWindows,
                  style: AppType.bodySmall.copyWith(
                    color: p.textPrimary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              // Only QuickRemote PC on Linux makes the computer read the
              // phone's records again (BtHidRepair).
              if (_linux) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_fix_high_rounded,
                      color: p.success,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        context.l10n.btHostUnawareAuto,
                        style: AppType.bodySmall.copyWith(
                          color: p.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Adding the phone again needs it visible.
              const SizedBox(height: AppSpace.md),
              const BtMakeVisibleButton(),
              const Spacer(),
              const SizedBox(height: AppSpace.md),
              // The phone cannot tell why the computer refused: the same
              // refusal comes from a blocked phone.
              const BtTroubleshooting(),
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: AppRadius.all(AppRadius.lg),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    GlowingDots(animation: widget.dots),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        context.l10n.btHostUnawareWaiting,
                        style: AppType.bodySmall.copyWith(
                          color: p.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ],
    );
  }
}
