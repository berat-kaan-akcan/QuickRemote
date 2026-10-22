import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_language.dart';
import '../../../providers/laser_overlay_provider.dart';
import '../../../services/overlay/laser_overlay.dart';
import '../../../widgets/ui/ui.dart';

/// Whose laser shows in a place.
enum LaserDrawer { program, quickRemote, none }

/// Where the laser can be used, the rows of the settings table.
enum LaserPlace { powerPoint, impress, wps, pdf, outsideShow }

/// Whose laser shows in [place] with [mode], as `OverlayInputService` decides:
/// auto leaves PowerPoint and WPS their own (`OverlayInputService.ownLaser`),
/// never lets the overlay draw, and without the overlay the server drops the
/// laser outside a slideshow (a PDF viewer is no slideshow).
LaserDrawer laserDrawer(LaserOverlayMode mode, LaserPlace place) {
  final inShow = place == LaserPlace.powerPoint || place == LaserPlace.impress || place == LaserPlace.wps;
  return switch (mode) {
    LaserOverlayMode.always => LaserDrawer.quickRemote,
    LaserOverlayMode.never => inShow ? LaserDrawer.program : LaserDrawer.none,
    LaserOverlayMode.auto =>
      place == LaserPlace.powerPoint || place == LaserPlace.wps ? LaserDrawer.program : LaserDrawer.quickRemote,
  };
}

/// Settings → Laser: who draws the laser, each choice with a line saying
/// what it does, and a table of whose laser shows where.
class LaserSettingSection extends StatelessWidget {
  const LaserSettingSection({super.key});

  static const _icons = {
    LaserOverlayMode.auto: Icons.auto_awesome_rounded,
    LaserOverlayMode.always: Icons.layers_rounded,
    LaserOverlayMode.never: Icons.slideshow_rounded,
  };

  static String title(AppLocalizations l10n, LaserOverlayMode mode) => switch (mode) {
    LaserOverlayMode.auto => l10n.laserOverlayAuto,
    LaserOverlayMode.always => l10n.laserOverlayAlways,
    LaserOverlayMode.never => l10n.laserOverlayNever,
  };

  static String _detail(AppLocalizations l10n, LaserOverlayMode mode) => switch (mode) {
    LaserOverlayMode.auto => l10n.laserOverlayAutoDetail,
    LaserOverlayMode.always => l10n.laserOverlayAlwaysDetail,
    LaserOverlayMode.never => l10n.laserOverlayNeverDetail,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final laser = context.watch<LaserOverlayProvider>();
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.adjust_rounded, size: 20, color: p.textSecondary),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                l10n.settingsLaser,
                style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Semantics(
          container: true,
          label: l10n.settingsLaser,
          child: Column(
            children: [
              for (final mode in LaserOverlayMode.values) ...[
                _LaserOption(
                  icon: _icons[mode]!,
                  title: title(l10n, mode),
                  detail: _detail(l10n, mode),
                  selected: laser.mode == mode,
                  onTap: () => laser.setMode(mode),
                ),
                if (mode != LaserOverlayMode.values.last) const SizedBox(height: AppSpace.xxs + 2),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        _LaserTable(selected: laser.mode),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.laserOverlayNote,
          style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _LaserOption extends StatelessWidget {
  const _LaserOption({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      selected: selected,
      pressedScale: 0.98,
      borderRadius: radius,
      semanticLabel: '$title. $detail',
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs + 2),
        decoration: BoxDecoration(
          color: selected ? p.primary.withValues(alpha: 0.12) : p.surfaceSunken,
          borderRadius: radius,
          border: Border.all(color: selected ? p.primary : p.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? p.primaryText : p.textSecondary),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? p.primaryText : p.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rows: the places; columns: the three choices; the chosen one tinted.
class _LaserTable extends StatelessWidget {
  const _LaserTable({required this.selected});

  final LaserOverlayMode selected;

  static String _place(AppLocalizations l10n, LaserPlace place) => switch (place) {
    LaserPlace.powerPoint => 'PowerPoint',
    LaserPlace.impress => 'Impress',
    LaserPlace.wps => 'WPS',
    LaserPlace.pdf => l10n.laserTablePdf,
    LaserPlace.outsideShow => l10n.laserTableOutsideShow,
  };

  static String _column(AppLocalizations l10n, LaserOverlayMode mode) => switch (mode) {
    LaserOverlayMode.auto => l10n.laserTableAuto,
    LaserOverlayMode.always => l10n.laserTableAlways,
    LaserOverlayMode.never => l10n.laserTableNever,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final small = AppType.bodySmall.copyWith(fontSize: 11.5);

    Widget cell(LaserOverlayMode mode, Widget child) => Container(
      color: mode == selected ? p.primary.withValues(alpha: 0.10) : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs, vertical: 5),
      alignment: Alignment.center,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );

    String word(LaserDrawer drawer) => switch (drawer) {
      LaserDrawer.program => l10n.laserTableProgram,
      LaserDrawer.quickRemote => 'QuickRemote',
      LaserDrawer.none => '—',
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.25)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(horizontalInside: BorderSide(color: p.border, width: 0.6)),
        children: [
          TableRow(
            decoration: BoxDecoration(color: p.surfaceSunken),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 5),
                child: Text(l10n.laserTableWhere, style: small.copyWith(color: p.textMuted)),
              ),
              for (final mode in LaserOverlayMode.values)
                cell(
                  mode,
                  Text(
                    _column(l10n, mode),
                    maxLines: 1,
                    style: small.copyWith(color: p.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          for (final place in LaserPlace.values)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 5),
                  child: Text(_place(l10n, place), style: small.copyWith(color: p.textPrimary)),
                ),
                for (final mode in LaserOverlayMode.values)
                  cell(
                    mode,
                    Text(
                      word(laserDrawer(mode, place)),
                      maxLines: 1,
                      style: small.copyWith(
                        color: switch (laserDrawer(mode, place)) {
                          LaserDrawer.quickRemote => p.primaryText,
                          LaserDrawer.program => p.textPrimary,
                          LaserDrawer.none => p.textMuted,
                        },
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
