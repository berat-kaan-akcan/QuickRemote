import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_language.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/websocket/presentation_state.dart';
import '../../../services/websocket_service.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../widgets/ui/ui.dart';
import '../utils/show_info.dart';

/// The programs the PC controls, opened from the header's program line. The
/// PC uses the one whose show runs by itself; while none runs the user may
/// mark one, which only names it in the remote (nothing is sent).
class ProgramSheet {
  ProgramSheet._();

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => const _ProgramList(),
    );
  }
}

class _ProgramList extends StatelessWidget {
  const _ProgramList();

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();
    final settings = context.watch<SettingsProvider>();
    final p = context.palette;
    final marked = remoteProgram(ws, settings);
    final running = ws.isPptRunning;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.programSheetTitle,
          style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          context.l10n.programSheetBody(ws.pcLabel),
          style: AppType.bodySmall.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        for (final program in ws.presenters) ...[
          ProgramOption(
            program: program,
            selected: program == marked,
            status: running && program == ws.presenter
                ? (ws.currentSlide > 0
                      ? context.l10n.programShowOpenSlide(ws.currentSlide)
                      : context.l10n.programShowOpen)
                : context.l10n.programShowClosed,
            live: running && program == ws.presenter,
            onTap: running
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    settings.setPresenterFor(ws.serverAddress, program);
                  },
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        const SizedBox(height: AppSpace.xxs),
        _Note(
          icon: Icons.picture_as_pdf_outlined,
          text: context.l10n.programPdfNote,
        ),
        const SizedBox(height: AppSpace.xs),
        _Note(
          icon: Icons.bluetooth_rounded,
          text: context.l10n.programBluetoothNote,
        ),
        const SizedBox(height: AppSpace.md),
        AppButton(
          label: context.l10n.ok,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// A program to pick: its icon, name, a line under it and a radio.
class ProgramOption extends StatelessWidget {
  const ProgramOption({
    super.key,
    required this.program,
    required this.selected,
    required this.status,
    this.live = false,
    this.onTap,
  });

  final String program;
  final bool selected;
  final String status;

  /// The status in green (its show runs).
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, color) = switch (program) {
      'wps' => (Icons.co_present_rounded, p.danger),
      'impress' => (Icons.present_to_all_rounded, p.success),
      _ => (Icons.slideshow_rounded, p.accent),
    };
    final radius = AppRadius.all(AppRadius.md);
    return Pressable(
      onTap: onTap,
      dimWhenDisabled: false,
      selected: selected,
      semanticLabel: '${PresentationState.nameOf(program)}, $status',
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? p.primaryBright : p.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              IconBadge(icon: icon, color: color, size: 38),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PresentationState.nameOf(program),
                      style: AppType.titleSmall.copyWith(
                        color: p.textPrimary,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      status,
                      style: AppType.bodySmall.copyWith(
                        color: live ? p.success : p.textSecondary,
                        fontWeight: live ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.base),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? p.primaryBright : p.textMuted,
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: p.textMuted, size: 18),
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
    );
  }
}
