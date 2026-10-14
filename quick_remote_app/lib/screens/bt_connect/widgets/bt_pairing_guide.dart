import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../widgets/ui/ui.dart';
import 'bt_make_visible_button.dart';

/// Step-by-step pairing guide for the computer, Windows or Linux. It names
/// the phone as the computer lists it, when Android tells.
class BtPairingGuide extends StatefulWidget {
  const BtPairingGuide({super.key});

  @override
  State<BtPairingGuide> createState() => _BtPairingGuideState();
}

class _BtPairingGuideState extends State<BtPairingGuide> {
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
    final pick = _phoneName == null ? l10n.btStepPickPhone : l10n.btStepPickPhoneNamed(_phoneName!);
    final steps = _linuxGuide
        ? [l10n.btLinuxStep1, l10n.btLinuxStep2, pick, l10n.btStepConfirm]
        : [l10n.btWindowsStep1, l10n.btWindowsStep2, pick, l10n.btStepConfirm];

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
          const SizedBox(height: AppSpace.md),
          // Before the steps: the computer lists the phone only while visible.
          const BtMakeVisibleButton(),
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
      (Icons.bluetooth_searching_rounded, l10n.btTroubleNearby),
      (Icons.visibility_rounded, l10n.btTroubleNotListed),
      (Icons.link_off_rounded, l10n.btTroubleAlreadyPaired),
      (Icons.block_rounded, l10n.btTroubleBlocked),
      (Icons.devices_rounded, l10n.btTroubleSeveral),
      (Icons.keyboard_rounded, l10n.btTroubleOtherApp),
    ];
    return AppCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: Pressable(
              onTap: () => setState(() => _open = !_open),
              pressedScale: 1,
              borderRadius: AppRadius.all(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: p.textSecondary, size: 20),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        l10n.btTroubleTitle,
                        style: AppType.titleSmall.copyWith(color: p.textPrimary),
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
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
                    child: Column(
                      children: [
                        for (final (icon, text) in tips)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(icon, color: p.info, size: 18),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14),
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
      ),
    );
  }
}
