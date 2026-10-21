import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_language.dart';
import '../../services/websocket_service.dart';
import '../../utils/ui/app_top_bar.dart';
import '../../widgets/ui/ui.dart';
import 'capability_table.dart';
import 'widgets/settings_rows.dart';

/// Settings → What works where: the connection, the computer and the
/// program are picked, and the features show as works, partly or not. The
/// compare view puts every program of that computer side by side.
class CapabilitiesScreen extends StatefulWidget {
  const CapabilitiesScreen({super.key});

  @override
  State<CapabilitiesScreen> createState() => _CapabilitiesScreenState();
}

class _CapabilitiesScreenState extends State<CapabilitiesScreen> {
  CapLink _link = CapLink.wifi;
  late CapOs _os;
  CapProgram? _program;
  bool _compare = false;

  @override
  void initState() {
    super.initState();
    // The connected PC's system, else Windows.
    final platform = context.read<WebSocketService>().pcPlatform;
    _os = platform == 'linux' ? CapOs.linux : CapOs.windows;
  }

  List<CapProgram> get _programs => CapabilityTable.programs(_link, _os);

  /// The picked program, or the first one where it is not offered.
  CapProgram get _selected {
    final programs = _programs;
    return programs.contains(_program) ? _program! : programs.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Scaffold(
      appBar: AppTopBar(title: l10n.capTitle),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            MediaQuery.paddingOf(context).bottom + AppSpace.md,
          ),
          children: [
            FadeSlideIn(
              child: Text(
                l10n.capIntro,
                style: AppType.bodySmall.copyWith(color: p.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FadeSlideIn(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsSectionLabel(l10n.capConnection),
                  AppSegmented<CapLink>(
                    segments: [
                      AppSegment(
                        value: CapLink.wifi,
                        label: 'Wi-Fi',
                        icon: Icons.wifi_rounded,
                      ),
                      AppSegment(
                        value: CapLink.bluetooth,
                        label: 'Bluetooth',
                        icon: Icons.bluetooth_rounded,
                      ),
                    ],
                    selected: _link,
                    onChanged: (v) => setState(() => _link = v),
                  ),
                  SettingsSectionLabel(l10n.capComputer),
                  AppSegmented<CapOs>(
                    segments: const [
                      AppSegment(value: CapOs.windows, label: 'Windows'),
                      AppSegment(value: CapOs.linux, label: 'Linux'),
                    ],
                    selected: _os,
                    onChanged: (v) => setState(() => _os = v),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppSegmented<bool>(
                    segments: [
                      AppSegment(
                        value: false,
                        label: l10n.capViewOne,
                        icon: Icons.checklist_rounded,
                      ),
                      AppSegment(
                        value: true,
                        label: l10n.capViewCompare,
                        icon: Icons.table_chart_outlined,
                      ),
                    ],
                    selected: _compare,
                    onChanged: (v) => setState(() => _compare = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FadeSlideIn(
              index: 2,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                child: _compare
                    ? _CompareTable(
                        key: ValueKey(('compare', _link, _os)),
                        link: _link,
                        os: _os,
                      )
                    : Column(
                        key: const ValueKey('one'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: AppSpace.xs,
                            runSpacing: AppSpace.xs,
                            children: [
                              for (final program in _programs)
                                _ProgramChip(
                                  label: capProgramName(l10n, program),
                                  selected: program == _selected,
                                  onTap: () =>
                                      setState(() => _program = program),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.sm),
                          _FeatureList(
                            link: _link,
                            os: _os,
                            program: _selected,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            const _Legend(),
            const SizedBox(height: AppSpace.sm),
            Text(
              _link == CapLink.wifi
                  ? l10n.capFootnoteWifi
                  : l10n.capFootnoteBluetooth,
              style: AppType.bodySmall.copyWith(
                color: p.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A program's name; the two Linux WPS are told apart.
String capProgramName(AppLocalizations l10n, CapProgram program) =>
    switch (program) {
      CapProgram.powerpoint => 'PowerPoint',
      CapProgram.impress => 'Impress',
      CapProgram.wps => 'WPS',
      CapProgram.wpsApp => l10n.capProgramWpsApp,
      CapProgram.wpsOwn => l10n.capProgramWpsOwn,
      CapProgram.pdf => l10n.capProgramPdf,
    };

/// The program's name in a compare column, in two short lines at most.
String _shortProgramName(AppLocalizations l10n, CapProgram program) =>
    switch (program) {
      CapProgram.wpsApp => l10n.capShortWpsApp,
      CapProgram.wpsOwn => l10n.capShortWpsOwn,
      CapProgram.pdf => 'PDF',
      _ => capProgramName(l10n, program),
    };

String capFeatureName(AppLocalizations l10n, CapFeature feature) =>
    switch (feature) {
      CapFeature.nextPrev => l10n.capNextPrev,
      CapFeature.startEnd => l10n.capStartEnd,
      CapFeature.goTo => l10n.capGoTo,
      CapFeature.laser => l10n.capLaser,
      CapFeature.ink => l10n.capInk,
      CapFeature.eraser => l10n.capEraser,
      CapFeature.blank => l10n.capBlank,
      CapFeature.slideInfo => l10n.capSlideInfo,
      CapFeature.preview => l10n.capPreview,
      CapFeature.slideMedia => l10n.capSlideMedia,
      CapFeature.spotlight => l10n.capSpotlight,
      CapFeature.volume => l10n.capVolume,
    };

IconData _featureIcon(CapFeature feature) => switch (feature) {
  CapFeature.nextPrev => Icons.swap_horiz_rounded,
  CapFeature.startEnd => Icons.slideshow_rounded,
  CapFeature.goTo => Icons.format_list_numbered_rounded,
  CapFeature.laser => Icons.highlight_alt_rounded,
  CapFeature.ink => Icons.edit_rounded,
  CapFeature.eraser => Icons.auto_fix_normal_rounded,
  CapFeature.blank => Icons.contrast_rounded,
  CapFeature.slideInfo => Icons.notes_rounded,
  CapFeature.preview => Icons.image_outlined,
  CapFeature.slideMedia => Icons.smart_display_outlined,
  CapFeature.spotlight => Icons.flare_rounded,
  CapFeature.volume => Icons.volume_up_rounded,
};

String capNoteText(AppLocalizations l10n, CapNote note) => switch (note) {
  CapNote.overlay => l10n.capNoteOverlay,
  CapNote.focus => l10n.capNoteFocus,
  CapNote.fullscreen => l10n.capNoteFullscreen,
  CapNote.noJump => l10n.capNoteNoJump,
  CapNote.firstSlide => l10n.capNoteFirstSlide,
  CapNote.showOnly => l10n.capNoteShowOnly,
  CapNote.screenOnly => l10n.capNoteScreenOnly,
  CapNote.fullscreenOnly => l10n.capNoteFullscreenOnly,
  CapNote.playOnly => l10n.capNotePlayOnly,
  CapNote.mediaReload => l10n.capNoteMediaReload,
  CapNote.noMagnifier => l10n.capNoteNoMagnifier,
  CapNote.wpsArrow => l10n.capNoteWpsArrow,
  CapNote.highlighterFocus => l10n.capNoteHighlighterFocus,
  CapNote.cursor => l10n.capNoteCursor,
  CapNote.penOnly => l10n.capNotePenOnly,
  CapNote.clearOnly => l10n.capNoteClearOnly,
  CapNote.wpsEraser => l10n.capNoteWpsEraser,
  CapNote.noAnswer => l10n.capNoteNoAnswer,
  CapNote.keysOnly => l10n.capNoteKeysOnly,
  CapNote.wpsNoMedia => l10n.capNoteWpsNoMedia,
};

String _levelName(AppLocalizations l10n, CapLevel level) => switch (level) {
  CapLevel.yes => l10n.capLevelYes,
  CapLevel.partial => l10n.capLevelPartial,
  CapLevel.no => l10n.capLevelNo,
};

/// The mark of a level: a green tick, an amber half, a faded cross.
class _LevelMark extends StatelessWidget {
  const _LevelMark(this.level, {this.size = 22});

  final CapLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, color) = switch (level) {
      CapLevel.yes => (Icons.check_circle_rounded, p.success),
      CapLevel.partial => (Icons.timelapse_rounded, p.warning),
      CapLevel.no => (Icons.cancel_rounded, p.textMuted),
    };
    return Icon(
      icon,
      color: color,
      size: size,
      semanticLabel: _levelName(context.l10n, level),
    );
  }
}

class _ProgramChip extends StatelessWidget {
  const _ProgramChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      borderRadius: AppRadius.all(AppRadius.pill),
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surface,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(color: selected ? p.primary : p.border),
        ),
        child: ExcludeSemantics(
          child: Text(
            label,
            style: AppType.label.copyWith(
              color: selected ? p.onPrimary : p.textPrimary,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// One program's features, each with its mark and, where it matters, why.
class _FeatureList extends StatelessWidget {
  const _FeatureList({
    required this.link,
    required this.os,
    required this.program,
  });

  final CapLink link;
  final CapOs os;
  final CapProgram program;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return SettingsGroup(
      children: [
        for (final feature in CapFeature.values)
          Builder(
            builder: (context) {
              final cell = CapabilityTable.cell(link, os, program, feature);
              final note = cell.note;
              final faded = cell.level == CapLevel.no;
              return MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _featureIcon(feature),
                        size: 20,
                        color: faded ? p.textMuted : p.textSecondary,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capFeatureName(l10n, feature),
                              style: AppType.label.copyWith(
                                color: faded ? p.textSecondary : p.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            if (note != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                capNoteText(l10n, note),
                                style: AppType.bodySmall.copyWith(
                                  color: p.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _LevelMark(cell.level),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Every program of the link and computer side by side. A mark with a note
/// is ringed and says the note when tapped.
class _CompareTable extends StatelessWidget {
  const _CompareTable({super.key, required this.link, required this.os});

  final CapLink link;
  final CapOs os;

  static const double _column = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final programs = CapabilityTable.programs(link, os);
    Widget header() => Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
          for (final program in programs)
            SizedBox(
              width: _column,
              child: Text(
                _shortProgramName(l10n, program),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppType.labelSmall.copyWith(
                  color: p.textPrimary,
                  fontSize: 11.5,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
    return SettingsGroup(
      children: [
        header(),
        for (final feature in CapFeature.values)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    capFeatureName(l10n, feature),
                    style: AppType.label.copyWith(
                      color: p.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final program in programs)
                  SizedBox(
                    width: _column,
                    child: _CompareCell(
                      program: capProgramName(l10n, program),
                      cell: CapabilityTable.cell(link, os, program, feature),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompareCell extends StatelessWidget {
  const _CompareCell({required this.program, required this.cell});

  final String program;
  final CapCell cell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final note = cell.note;
    final mark = Center(child: _LevelMark(cell.level, size: 24));
    if (note == null) return SizedBox(height: 36, child: mark);
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      message: '$program: ${capNoteText(l10n, note)}',
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: p.border, width: 1.5),
              ),
            ),
            mark,
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    Widget item(CapLevel level) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: _LevelMark(level, size: 18)),
        const SizedBox(width: 6),
        Text(
          _levelName(l10n, level),
          style: AppType.bodySmall.copyWith(color: p.textSecondary),
        ),
      ],
    );
    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.xs,
      children: [for (final level in CapLevel.values) item(level)],
    );
  }
}
