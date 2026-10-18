import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../widgets/ui/ui.dart';
import 'bt_make_visible_button.dart';
import 'glowing_dots.dart';

/// Waiting for a computer to pair: the phone made visible, the steps on the
/// computer (Windows or Linux), what to check when it does not connect.
/// The steps name the phone as the computer lists it, when Android tells.
class BtPairingView extends StatefulWidget {
  const BtPairingView({super.key, required this.dots, required this.onCancel});

  final Animation<double> dots;
  final VoidCallback onCancel;

  @override
  State<BtPairingView> createState() => _BtPairingViewState();
}

class _BtPairingViewState extends State<BtPairingView> {
  bool _linuxGuide = false;
  String? _phoneName;

  @override
  void initState() {
    super.initState();
    BtHidService.instance.localName().then((name) {
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() => _phoneName = name.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final pick = _phoneName == null
        ? l10n.btStepPickPhone
        : l10n.btStepPickPhoneNamed(_phoneName!);
    final steps = _linuxGuide
        ? [l10n.btLinuxStep1, l10n.btLinuxStep2, pick, l10n.btStepConfirm]
        : [l10n.btWindowsStep1, l10n.btWindowsStep2, pick, l10n.btStepConfirm];

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: AppRadius.all(AppRadius.lg),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.info.withValues(alpha: 0.14),
                          border: Border.all(
                            color: p.info.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.bluetooth_searching_rounded,
                          color: p.info,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.btWaitingPairing,
                              style: AppType.titleSmall.copyWith(
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            GlowingDots(animation: widget.dots),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              // Before the steps: the computer lists the phone only while visible.
              const FadeSlideIn(index: 1, child: BtMakeVisibleButton()),
              const SizedBox(height: AppSpace.md),
              Text(
                l10n.btOnYourComputer.toUpperCase(),
                style: AppType.overline.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpace.sm),
              BtSystemTabs(
                linux: _linuxGuide,
                onChanged: (v) => setState(() => _linuxGuide = v),
              ),
              const SizedBox(height: AppSpace.sm),
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                child: Column(
                  key: ValueKey(_linuxGuide),
                  children: [
                    for (final (i, text) in steps.indexed)
                      _step(context, i + 1, text),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: AppSpace.md),
              const BtTroubleshooting(),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                label: l10n.cancel,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                onPressed: widget.onCancel,
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ],
    );
  }

  Widget _step(BuildContext context, int number, String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: p.info.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppType.labelSmall.copyWith(color: p.info, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: AppType.bodySmall.copyWith(
                  color: p.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Windows or Linux, for the steps on the computer.
class BtSystemTabs extends StatelessWidget {
  const BtSystemTabs({super.key, required this.linux, required this.onChanged});

  final bool linux;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget tab(String label, bool value) {
      final on = linux == value;
      return Expanded(
        child: Pressable(
          onTap: () => onChanged(value),
          selected: on,
          semanticLabel: label,
          pressedScale: 0.97,
          borderRadius: AppRadius.all(AppRadius.sm),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.base),
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? p.surfaceRaised : p.surfaceRaised.withValues(alpha: 0),
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: on ? AppShadows.soft(p) : null,
            ),
            child: Text(
              label,
              style: AppType.labelSmall.copyWith(color: on ? p.textPrimary : p.textSecondary, fontSize: 12.5),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.surfaceSunken, borderRadius: AppRadius.all(AppRadius.md)),
      child: Row(children: [tab('Windows', false), const SizedBox(width: 3), tab('Linux', true)]),
    );
  }
}

/// What to check when the phone does not connect, folded away until asked.
class BtTroubleshooting extends StatefulWidget {
  const BtTroubleshooting({super.key});

  @override
  State<BtTroubleshooting> createState() => _BtTroubleshootingState();
}

class _BtTroubleshootingState extends State<BtTroubleshooting> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final tips = [
      l10n.btTroubleNearby,
      l10n.btTroubleNotListed,
      l10n.btTroubleAlreadyPaired,
      l10n.btTroubleBlocked,
      l10n.btTroubleSeveral,
      l10n.btTroubleOtherApp,
    ];
    final radius = AppRadius.all(AppRadius.sm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: Pressable(
            onTap: () => setState(() => _open = !_open),
            pressedScale: 1,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.base),
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: radius,
                border: Border.all(color: _open ? p.primaryText : p.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: _open ? p.primaryText : p.textMuted,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.btTroubleTitle,
                      style: AppType.titleSmall.copyWith(
                        color: p.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: AppMotion.of(context, AppMotion.base),
                    child: Icon(Icons.expand_more_rounded, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.base),
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: Column(
                    children: [
                      for (final text in tips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: p.info,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Expanded(
                                child: Text(
                                  text,
                                  style: AppType.bodySmall.copyWith(
                                    color: p.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
