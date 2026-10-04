import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Step-by-step pairing guide for the computer, Windows or Linux.
class BtPairingGuide extends StatefulWidget {
  const BtPairingGuide({super.key});

  @override
  State<BtPairingGuide> createState() => _BtPairingGuideState();
}

class _BtPairingGuideState extends State<BtPairingGuide> {
  bool _linuxGuide = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final steps = _linuxGuide
        ? [
            context.l10n.btLinuxStep1,
            context.l10n.btLinuxStep2,
            context.l10n.btLinuxStep3,
            context.l10n.btStepPickPhone,
            context.l10n.btStepConfirm,
          ]
        : [
            context.l10n.btWindowsStep1,
            context.l10n.btWindowsStep2,
            context.l10n.btWindowsStep3,
            context.l10n.btStepPickPhone,
            context.l10n.btStepConfirm,
          ];

    return AppCard(
      elevated: true,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.computer_rounded, color: p.info, size: 36),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  context.l10n.btOnYourComputer,
                  style: AppType.titleSmall.copyWith(color: p.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AppSegmented<bool>(
            color: p.info,
            segments: const [
              AppSegment(value: false, label: 'Windows', icon: Icons.window_rounded),
              AppSegment(value: true, label: 'Linux', icon: Icons.terminal_rounded),
            ],
            selected: _linuxGuide,
            onChanged: (v) => setState(() => _linuxGuide = v),
          ),
          const SizedBox(height: AppSpace.lg),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.base),
            child: Column(
              key: ValueKey(_linuxGuide),
              children: [
                for (final (i, text) in steps.indexed)
                  _step(context, i + 1, text, last: i == steps.length - 1),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          InlineAlert(
            dense: true,
            tone: AppTone.info,
            icon: Icons.info_outline_rounded,
            message: context.l10n.btPairOnce,
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int number, String text, {required bool last}) {
    final p = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: p.info.withValues(alpha: p.isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: p.info.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppType.labelSmall.copyWith(color: p.info, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: p.info.withValues(alpha: 0.22),
                      borderRadius: AppRadius.all(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3, bottom: last ? AppSpace.xs : AppSpace.md),
              child: Text(
                text,
                style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
