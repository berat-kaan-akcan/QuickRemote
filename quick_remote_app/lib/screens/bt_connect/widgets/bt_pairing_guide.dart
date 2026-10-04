import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.computer_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.btOnYourComputer,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Windows'),
                    icon: Icon(Icons.window_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Linux'),
                    icon: Icon(Icons.terminal_rounded, size: 16),
                  ),
                ],
                selected: {_linuxGuide},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    setState(() => _linuxGuide = s.first),
                style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: AppColors.bluetooth.withValues(
                    alpha: 0.5,
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 16),
              if (_linuxGuide) ...[
                _step(1, context.l10n.btLinuxStep1),
                _step(2, context.l10n.btLinuxStep2),
                _step(3, context.l10n.btLinuxStep3),
                _step(4, context.l10n.btStepPickPhone),
                _step(5, context.l10n.btStepConfirm),
              ] else ...[
                _step(1, context.l10n.btWindowsStep1),
                _step(2, context.l10n.btWindowsStep2),
                _step(3, context.l10n.btWindowsStep3),
                _step(4, context.l10n.btStepPickPhone),
                _step(5, context.l10n.btStepConfirm),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bluetooth.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.bluetooth.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.bluetoothLight,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.btPairOnce,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.4,
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
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.bluetooth.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.bluetoothLight.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.bluetoothLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
