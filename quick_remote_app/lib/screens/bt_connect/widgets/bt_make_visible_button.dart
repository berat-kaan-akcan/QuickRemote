import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/app_language.dart';
import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../widgets/ui/ui.dart';

/// Makes the phone visible to a computer searching for devices, through
/// Android's own dialog. Otherwise the phone is visible only while Android's
/// Bluetooth settings are open, and the computer would not list it. While
/// visible, the button says for how long.
class BtMakeVisibleButton extends StatefulWidget {
  const BtMakeVisibleButton({super.key});

  @override
  State<BtMakeVisibleButton> createState() => _BtMakeVisibleButtonState();
}

class _BtMakeVisibleButtonState extends State<BtMakeVisibleButton> {
  /// The minutes Android made the phone visible for; null while it is not.
  int? _visibleMinutes;
  Timer? _visibleTimer;

  @override
  void dispose() {
    _visibleTimer?.cancel();
    super.dispose();
  }

  Future<void> _makeVisible() async {
    final l10n = context.l10n;
    // Android 12+: the Nearby devices group, normally granted already with
    // BLUETOOTH_CONNECT, so no dialog. Below, permission_handler reports it
    // as granted.
    final granted = await Permission.bluetoothAdvertise.request().isGranted;
    final seconds = granted
        ? await BtHidService.instance.requestDiscoverable()
        : 0;
    if (!mounted) return;
    if (seconds <= 0) {
      AppSnackbar.show(
        context,
        message: l10n.btVisibleRefused,
        type: SnackbarType.warning,
      );
      return;
    }
    _visibleTimer?.cancel();
    _visibleTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) setState(() => _visibleMinutes = null);
    });
    setState(() => _visibleMinutes = (seconds / 60).ceil());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final minutes = _visibleMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.base),
          child: minutes == null
              ? AppButton(
                  key: const ValueKey('make'),
                  label: context.l10n.btMakeVisible,
                  icon: Icons.visibility_outlined,
                  variant: AppButtonVariant.tonal,
                  tone: AppTone.info,
                  height: 46,
                  onPressed: _makeVisible,
                )
              : Semantics(
                  key: const ValueKey('visible'),
                  liveRegion: true,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.success.withValues(alpha: 0.12),
                      borderRadius: AppRadius.all(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: p.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            context.l10n.btVisibleFor(minutes),
                            style: AppType.label.copyWith(
                              color: p.success,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          context.l10n.btMakeVisibleHint,
          textAlign: TextAlign.center,
          style: AppType.bodySmall.copyWith(
            color: p.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
