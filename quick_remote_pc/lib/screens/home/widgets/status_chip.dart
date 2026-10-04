import 'package:flutter/material.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class StatusChip extends StatelessWidget {
  final bool isRunning;
  final int clientCount;

  const StatusChip({super.key, required this.isRunning, required this.clientCount});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Running with no phone yet: waiting, not an error.
    final color = !isRunning
        ? p.textMuted
        : clientCount == 0
            ? p.warning
            : p.success;
    return StatusPill(
      color: color,
      label: isRunning ? context.l10n.clientsConnected(clientCount) : context.l10n.serverOff,
    );
  }
}
