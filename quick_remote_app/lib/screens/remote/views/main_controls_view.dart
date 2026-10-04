import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../services/websocket_service.dart';
import '../../../services/presentation_timer_controller.dart';
import '../../../widgets/presentation_timer.dart';
import '../widgets/shared_buttons.dart';
import '../utils/remote_dialogs.dart';
import '../utils/slide_picker_sheet.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class MainControlsView extends StatefulWidget {
  final WebSocketService ws;
  final PresentationTimerController timer;

  const MainControlsView({
    super.key,
    required this.ws,
    required this.timer,
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
      if ([RemoteCommands.next, RemoteCommands.prev, RemoteCommands.start, RemoteCommands.end].contains(command) || command.startsWith('START_AT')) {
         setState(() { _activeScreen = null; });
      }
    }
    
    widget.ws.sendCommand(command);
  }

  void _showStartSlideDialog(BuildContext context) {
    SlidePickerSheet.show(
      context,
      totalSlides: widget.ws.totalSlides,
      onSend: _send,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final p = context.palette;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, AppSpace.md),
              child: Column(
                children: [
                  FadeSlideIn(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PresentationTimer(
                        controller: widget.timer,
                        fontSize: 18.0,
                        iconSize: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  FadeSlideIn(
                    index: 1,
                    child: SlideStatusCard(
                      currentSlide: ws.currentSlide,
                      totalSlides: ws.totalSlides,
                      isRunning: ws.isPptRunning,
                      onNotes: ws.isPptRunning && ws.slideNotes.isNotEmpty
                          ? () => RemoteDialogs.showNotesDialog(context, ws.slideNotes)
                          : null,
                    ),
                  ),
                  Reveal(
                    child: ws.isPptRunning
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: AppSpace.sm),
                            child: InlineAlert(
                              tone: AppTone.danger,
                              icon: Icons.error_outline_rounded,
                              message: context.l10n.presentationNotOpen(ws.presenterNames.join(context.l10n.listOr)),
                            ),
                          ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpace.xl),
                  FadeSlideIn(
                    index: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: context.l10n.actionStart,
                            color: p.success,
                            onTap: !ws.isConnected ? null : () {
                              _send(RemoteCommands.start);
                            },
                            onLongPress: !ws.isConnected ? null : () {
                              HapticFeedback.heavyImpact();
                              _showStartSlideDialog(context);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: ActionButton(
                            icon: Icons.stop_rounded,
                            label: context.l10n.actionEnd,
                            color: p.danger,
                            onTap: !ws.isConnected ? null : () => _send(RemoteCommands.end),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  FadeSlideIn(
                    index: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: ScreenToggleButton(
                            label: context.l10n.blackScreen,
                            white: false,
                            isActive: _activeScreen == 'BLACK',
                            onTap: !ws.isConnected ? null : () => _send(RemoteCommands.blackScreen),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: ScreenToggleButton(
                            label: context.l10n.whiteScreen,
                            white: true,
                            isActive: _activeScreen == 'WHITE',
                            onTap: !ws.isConnected ? null : () => _send(RemoteCommands.whiteScreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  FadeSlideIn(
                    index: 4,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SlideButton(
                            icon: Icons.arrow_back_rounded,
                            label: context.l10n.actionPrev,
                            onTap: !ws.isConnected ? null : () => _send(RemoteCommands.prev),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          flex: 3,
                          child: SlideButton(
                            icon: Icons.arrow_forward_rounded,
                            label: context.l10n.actionNext,
                            isPrimary: true,
                            onTap: !ws.isConnected ? null : () => _send(RemoteCommands.next),
                          ),
                        ),
                      ],
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

/// The slide the show is on, out of how many, with a track of the deck and
/// the notes button.
class SlideStatusCard extends StatelessWidget {
  const SlideStatusCard({
    super.key,
    required this.currentSlide,
    required this.totalSlides,
    required this.isRunning,
    this.onNotes,
  });

  final int currentSlide;
  final int totalSlides;
  final bool isRunning;

  /// Shows the notes button when set.
  final VoidCallback? onNotes;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // 0: a show the PC sees but cannot read (a WPS it did not open).
    final unreadable = isRunning && currentSlide == 0 && totalSlides == 0;
    final total = totalSlides > 0 ? totalSlides.toString() : '?';

    return AppCard(
      elevated: true,
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.md, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.slideshow_rounded,
                  color: isRunning ? p.primaryText : p.textMuted,
                  size: 18,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  context.l10n.slideLabel,
                  style: AppType.overline.copyWith(color: p.textSecondary),
                ),
                if (isRunning) ...[
                  const SizedBox(width: AppSpace.xs),
                  PulseDot(color: p.success, size: 7),
                ],
                const Spacer(),
                if (onNotes != null)
                  AppButton(
                    label: context.l10n.notes,
                    icon: Icons.notes_rounded,
                    variant: AppButtonVariant.tonal,
                    expand: false,
                    height: 40,
                    onPressed: onNotes,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          Semantics(
            label: unreadable
                ? context.l10n.slideshowOpen
                : context.l10n.slideCounter(currentSlide, total),
            liveRegion: true,
            child: ExcludeSemantics(
              child: unreadable
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      child: Text(
                        context.l10n.slideshowOpen,
                        style: AppType.headline.copyWith(color: p.textPrimary),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.base),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text.rich(
                        key: ValueKey(currentSlide),
                        TextSpan(children: [
                          TextSpan(
                            text: '$currentSlide',
                            style: AppType.numeric.copyWith(color: p.textPrimary, fontSize: 60, letterSpacing: -2),
                          ),
                          TextSpan(
                            text: '  /  $total',
                            style: AppType.title.copyWith(color: p.textMuted, fontSize: 22),
                          ),
                        ]),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          _SlideTrack(current: currentSlide, total: totalSlides),
        ],
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
    {
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
                      boxShadow: i == current ? AppShadows.glow(p.accent, strength: 0.4) : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }
}
