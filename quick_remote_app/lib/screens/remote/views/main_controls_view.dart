import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../../../services/presentation_timer_controller.dart';
import '../../../services/websocket/presentation_state.dart';
import '../../../widgets/presentation_timer.dart';
import '../widgets/shared_buttons.dart';
import '../widgets/slide_image.dart';
import '../presenter_view_screen.dart';
import '../utils/remote_dialogs.dart';
import '../utils/go_to_slide_sheet.dart';
import '../utils/show_info.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class MainControlsView extends StatefulWidget {
  final WebSocketService ws;
  final PresentationTimerController timer;

  /// The program the remote names ('powerpoint', 'impress', 'wps').
  final String program;

  const MainControlsView({
    super.key,
    required this.ws,
    required this.timer,
    required this.program,
  });

  @override
  State<MainControlsView> createState() => _MainControlsViewState();
}

class _MainControlsViewState extends State<MainControlsView> {
  String? _activeScreen; // 'BLACK' or 'WHITE' or null

  void _send(String command) {
    HapticFeedback.mediumImpact();

    if (command == RemoteCommands.blackScreen) {
      setState(() {
        _activeScreen = _activeScreen == 'BLACK' ? null : 'BLACK';
      });
    } else if (command == RemoteCommands.whiteScreen) {
      setState(() {
        _activeScreen = _activeScreen == 'WHITE' ? null : 'WHITE';
      });
    } else {
      if ([
            RemoteCommands.next,
            RemoteCommands.prev,
            RemoteCommands.start,
            RemoteCommands.end,
          ].contains(command) ||
          command.startsWith('START_AT')) {
        setState(() {
          _activeScreen = null;
        });
      }
    }

    widget.ws.sendCommand(command);
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final show = ShowInfo.of(ws);
    final connected = ws.isConnected;
    // With the slide's picture on the card, it and the note open the
    // presenter view; without, the note opens on its own.
    void openPresenterView() => PresenterViewScreen.open(context, timer: widget.timer, onSend: _send);
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.xxs,
                AppSpace.page,
                AppSpace.sm,
              ),
              child: Column(
                children: [
                  FadeSlideIn(
                    child: AnimatedOpacity(
                      duration: AppMotion.of(context, AppMotion.base),
                      // The last state stays in view, faded, while the link is down.
                      opacity: connected ? 1 : 0.55,
                      child: SlideCard(
                        ws: ws,
                        show: show,
                        timer: PresentationTimer(controller: widget.timer),
                        activeScreen: _activeScreen,
                        onScreen: connected && show.running ? _send : null,
                        onNotes: SlideCard.showsPreview(ws, show)
                            ? openPresenterView
                            : () => RemoteDialogs.showNotesDialog(
                                context,
                                ws.slideNotes,
                                ws.currentSlide,
                              ),
                        onPreview: openPresenterView,
                        onGoTo: connected && show.canJump
                            ? () => GoToSlideSheet.show(
                                context,
                                totalSlides: ws.totalSlides,
                                onSend: _send,
                                ws: ws,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Reveal(
                    child: show.running
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: AppSpace.sm),
                            child: InlineAlert(
                              tone: AppTone.danger,
                              icon: Icons.error_outline_rounded,
                              message: context.l10n.presentationNotOpen(
                                PresentationState.nameOf(widget.program),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  FadeSlideIn(
                    index: 1,
                    child: ShowToggleButton(
                      running: show.running,
                      startLabel: context.l10n.actionStart,
                      endLabel: context.l10n.actionEnd,
                      onTap: !connected
                          ? null
                          : () {
                              HapticFeedback.heavyImpact();
                              _send(
                                show.running
                                    ? RemoteCommands.end
                                    : RemoteCommands.start,
                              );
                            },
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Expanded(
                    child: FadeSlideIn(
                      index: 2,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 150),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 112,
                              child: BigSlideButton(
                                next: false,
                                label: context.l10n.actionPrev,
                                onTap: !connected
                                    ? null
                                    : () => _send(RemoteCommands.prev),
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: BigSlideButton(
                                next: true,
                                label: context.l10n.actionNext,
                                onTap: !connected
                                    ? null
                                    : () => _send(RemoteCommands.next),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The show at a glance: the timer, the slide out of how many with a track
/// of the deck, the start of the slide's note, and the black and white
/// screen and go-to-slide keys.
class SlideCard extends StatelessWidget {
  const SlideCard({
    super.key,
    required this.ws,
    required this.show,
    required this.timer,
    required this.activeScreen,
    required this.onNotes,
    this.onScreen,
    this.onGoTo,
    this.onPreview,
  });

  final WebSocketService ws;
  final ShowInfo show;
  final Widget timer;

  /// 'BLACK', 'WHITE' or null.
  final String? activeScreen;
  final VoidCallback onNotes;

  /// Sends BLACK_SCREEN or WHITE_SCREEN; null fades the two keys.
  final ValueChanged<String>? onScreen;

  /// Opens the go-to-slide sheet; null fades the key.
  final VoidCallback? onGoTo;

  /// Called on a tap on the slide's picture.
  final VoidCallback? onPreview;

  /// Width of the slide's picture beside the slide number.
  static const previewWidth = 120.0;

  /// Whether the card shows the slide's picture. Its place stays while the
  /// next slide's picture loads; with none of this deck yet the card looks as
  /// without previews.
  static bool showsPreview(WebSocketService ws, ShowInfo show) =>
      show.running && !show.unreadable && ws.currentSlide > 0 && ws.hasSlideImages;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = ws.currentSlide;
    final total = ws.totalSlides > 0 ? ws.totalSlides.toString() : '?';
    final notes = ws.slideNotes.trim();
    final preview = showsPreview(ws, show);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [p.surfaceRaised, p.surface],
        ),
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.slideshow_rounded,
                color: show.running ? p.primaryText : p.textMuted,
                size: 18,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                context.l10n.slideLabel.toUpperCase(),
                style: AppType.overline.copyWith(color: p.textSecondary),
              ),
              if (show.running) ...[
                const SizedBox(width: AppSpace.xs),
                PulseDot(color: p.success, size: 7),
              ],
              const Spacer(),
              timer,
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  label: show.unreadable
                      ? context.l10n.slideshowOpen
                      : context.l10n.slideCounter(current, total),
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: show.unreadable
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpace.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.slideshowOpen,
                                  style: AppType.headline.copyWith(
                                    color: p.textPrimary,
                                    fontSize: 26,
                                  ),
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text(
                                  show.userWps
                                      ? context.l10n.unreadableShowUserWps
                                      : context.l10n.unreadableShow,
                                  style: AppType.bodySmall.copyWith(
                                    color: p.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _SlideNumber(
                            current: current,
                            total: total,
                            running: show.running,
                          ),
                  ),
                ),
              ),
              if (preview) ...[
                const SizedBox(width: AppSpace.sm),
                SizedBox(
                  width: previewWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: SlideImage(
                      slide: current,
                      image: ws.currentSlideImage,
                      cover: activeScreen,
                      onTap: onPreview,
                      tooltip: context.l10n.presenterViewOpenHint,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!show.unreadable) ...[
            const SizedBox(height: AppSpace.sm),
            _SlideTrack(current: current, total: ws.totalSlides),
          ],
          if (show.running && notes.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            _NotePreview(
              notes: notes,
              onTap: onNotes,
              tooltip: preview ? context.l10n.presenterViewOpenHint : context.l10n.notesOpenHint,
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Divider(height: 1, thickness: 1, color: p.border),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              ScreenKey(
                white: false,
                label: context.l10n.blackScreen,
                active: activeScreen == 'BLACK',
                onTap: onScreen == null
                    ? null
                    : () => onScreen!(RemoteCommands.blackScreen),
              ),
              const SizedBox(width: 6),
              ScreenKey(
                white: true,
                label: context.l10n.whiteScreen,
                active: activeScreen == 'WHITE',
                onTap: onScreen == null
                    ? null
                    : () => onScreen!(RemoteCommands.whiteScreen),
              ),
              const Spacer(),
              _GoToSlideKey(onTap: onGoTo),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideNumber extends StatelessWidget {
  const _SlideNumber({
    required this.current,
    required this.total,
    required this.running,
  });

  final int current;
  final String total;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.base),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: Text.rich(
        key: ValueKey(current),
        TextSpan(
          children: [
            TextSpan(
              text: '$current',
              style: AppType.numeric.copyWith(
                color: running ? p.textPrimary : p.textMuted,
                fontSize: 54,
                height: 1,
                letterSpacing: -2,
              ),
            ),
            TextSpan(
              text: ' /$total',
              style: AppType.title.copyWith(color: p.textMuted, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// The first two lines of the slide's note; a tap shows all of it.
class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.notes, required this.onTap, required this.tooltip});

  final String notes;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      semanticLabel: notes,
      tooltip: tooltip,
      pressedScale: 0.98,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.sm, 10, 10, 10),
        decoration: BoxDecoration(
          color: p.primaryText.withValues(alpha: 0.08),
          borderRadius: radius,
          border: Border.all(color: p.primaryText.withValues(alpha: 0.18)),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notes_rounded, color: p.primaryText, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodySmall.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoToSlideKey extends StatelessWidget {
  const _GoToSlideKey({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      semanticLabel: context.l10n.goToSlide,
      borderRadius: radius,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.16),
          borderRadius: radius,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, color: p.primaryText, size: 18),
              const SizedBox(width: AppSpace.xs),
              Text(
                context.l10n.goToSlide,
                style: AppType.labelSmall.copyWith(
                  color: p.primaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The deck as a row of segments, one per slide, lit up to the current one;
/// a plain bar for long decks.
class _SlideTrack extends StatelessWidget {
  const _SlideTrack({required this.current, required this.total});

  final int current;
  final int total;

  static const _height = 8.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final duration = AppMotion.of(context, AppMotion.base);
    // No LayoutBuilder: the card sits in a SliverFillRemaining, which measures
    // its child's intrinsic height. Up to 40 segments stay over 4 px wide.
    final gap = total > 30 ? 2.0 : 3.0;
    final segmented = total > 0 && total <= 40;
    if (!segmented) {
      final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
      return ClipRRect(
        borderRadius: AppRadius.all(AppRadius.pill),
        child: SizedBox(
          height: _height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: p.surfaceSunken)),
              AnimatedFractionallySizedBox(
                duration: AppMotion.of(context, AppMotion.slow),
                curve: AppMotion.standard,
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [p.primaryText, p.accent]),
                    borderRadius: AppRadius.all(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ExcludeSemantics(
      child: SizedBox(
        height: _height + 4,
        child: Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              if (i > 1) SizedBox(width: gap),
              Expanded(
                child: AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.standard,
                  height: i == current ? _height + 4 : _height,
                  decoration: BoxDecoration(
                    color: i == current
                        ? p.accent
                        : i < current
                        ? p.primaryText
                        : p.surfaceSunken,
                    borderRadius: AppRadius.all(AppRadius.pill),
                    boxShadow: i == current
                        ? AppShadows.glow(p.accent, strength: 0.4)
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
