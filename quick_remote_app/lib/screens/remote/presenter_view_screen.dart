import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../l10n/app_language.dart';
import '../../services/presentation_timer_controller.dart';
import '../../services/websocket_service.dart';
import '../../widgets/presentation_timer.dart';
import '../../widgets/ui/ui.dart';
import 'widgets/shared_buttons.dart';
import 'widgets/slide_image.dart';

/// The presenter's view of the show: the slide on screen large, the next
/// one small, the slide's notes and the Previous and Next keys. Upright the
/// parts are stacked; on its side the slide is on the left, the rest on the
/// right.
///
/// It opens over the remote screen, which keeps the volume keys, the
/// background session and the timer running. While the link is down the
/// last state stays, faded.
///
/// With a PC that takes the laser as a point (`absLaser`) and a picture on
/// screen, the Laser key turns the picture into a pointing area: the laser
/// is where the finger is (MoveFrame.laserAbs), and the phone draws its dot
/// on the picture at once, so the picture's delay does not show. The picture
/// grows then, and the next slide goes.
class PresenterViewScreen extends StatefulWidget {
  const PresenterViewScreen({
    super.key,
    required this.timer,
    required this.onSend,
  });

  final PresentationTimerController timer;

  /// Sends NEXT or PREV the way the remote does.
  final ValueChanged<String> onSend;

  static Future<void> open(
    BuildContext context, {
    required PresentationTimerController timer,
    required ValueChanged<String> onSend,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PresenterViewScreen(timer: timer, onSend: onSend),
    ),
  );

  @override
  State<PresenterViewScreen> createState() => _PresenterViewScreenState();
}

/// What the screen shows, kept from the last time the link was up.
class _Shown {
  int current = 0;
  int total = 0;
  String notes = '';
  Uint8List? image;
  Uint8List? next;
  bool running = false;

  /// The PC's screen instead of a slide (a full-screen PDF, a show the PC
  /// cannot read): no number, no next slide, no notes.
  bool screen = false;
}

class _PresenterViewScreenState extends State<PresenterViewScreen> {
  final _Shown _shown = _Shown();

  /// The picture is a pointing area (the Laser key).
  bool _laser = false;

  /// The finger is on it: the laser is on at the PC.
  bool _pointing = false;

  /// Where the dot is, fractions of the picture's frame.
  Offset? _dot;

  WebSocketService? _ws;

  void _send(String command) {
    HapticFeedback.mediumImpact();
    widget.onSend(command);
  }

  void _pointAt(Offset local, Size size, {bool start = false}) {
    final ws = _ws;
    if (ws == null || size.isEmpty) return;
    final at = Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
    if (start) {
      HapticFeedback.selectionClick();
      _pointing = true;
      ws.sendCommand(RemoteCommands.modeLaser);
    }
    ws.sendLaserAt(at.dx, at.dy);
    setState(() => _dot = at);
  }

  /// The finger left: the laser goes, as when the touchpad's finger lifts.
  void _endPointing() {
    if (!_pointing) return;
    _pointing = false;
    _ws?.sendCommand(RemoteCommands.laserOff);
    _ws?.sendCommand(RemoteCommands.modeArrow);
    if (mounted) setState(() => _dot = null);
  }

  @override
  void dispose() {
    _endPointing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = _ws = context.watch<WebSocketService>();
    final connected = ws.isConnected;
    if (connected) {
      _shown
        ..current = ws.currentSlide
        ..total = ws.totalSlides
        ..notes = ws.slideNotes.trim()
        ..screen = ws.screenImage != null
        ..image = ws.screenImage ?? ws.currentSlideImage
        ..next = ws.nextSlideImage
        ..running = ws.isPptRunning;
    }
    // A viewer in front turns its pages with Next and Previous too.
    final canSend = connected && (_shown.running || _shown.screen);
    // The PC ignores the laser outside a show unless its overlay draws it.
    final canPoint = connected && (_shown.running || ws.toolsAnywhere);
    final laserKey = ws.absLaserAvailable && _shown.image != null;
    final laser = _laser && laserKey && canPoint;
    if (!laser && _pointing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _endPointing());
    }
    final landscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    final picture = SlideImage(
      slide: _shown.current,
      image: _shown.image,
      radius: AppRadius.md,
      label: _shown.screen ? context.l10n.screenPreviewLabel : null,
    );
    final Widget current = laser
        ? _PointingArea(
            dot: _dot,
            hint: context.l10n.presenterLaserHint,
            onDown: (local, size) => _pointAt(local, size, start: true),
            onMove: (local, size) {
              if (_pointing) _pointAt(local, size);
            },
            onUp: _endPointing,
            child: picture,
          )
        : picture;
    final laserToggle = laserKey
        ? _LaserToggle(
            on: laser,
            onTap: canPoint ? () => setState(() => _laser = !_laser) : null,
          )
        : null;
    final keys = _Keys(
      onPrev: canSend ? () => _send(RemoteCommands.prev) : null,
      onNext: canSend ? () => _send(RemoteCommands.next) : null,
    );
    final notes = _Notes(notes: _shown.notes);
    final nextUp = _NextUp(shown: _shown);

    final Widget body = landscape
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: laser ? 4 : 3, child: Center(child: current)),
              const SizedBox(width: AppSpace.md),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_shown.screen)
                      const Spacer()
                    else ...[
                      if (!laser) ...[
                        nextUp,
                        const SizedBox(height: AppSpace.sm),
                      ],
                      Expanded(child: notes),
                    ],
                    const SizedBox(height: AppSpace.sm),
                    SizedBox(height: 88, child: keys),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              current,
              const SizedBox(height: AppSpace.sm),
              if (_shown.screen)
                const Spacer()
              else ...[
                if (!laser) ...[
                  nextUp,
                  const SizedBox(height: AppSpace.sm),
                ],
                Expanded(child: notes),
              ],
              const SizedBox(height: AppSpace.sm),
              SizedBox(height: 120, child: keys),
            ],
          );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.xs,
            AppSpace.page,
            AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(shown: _shown, timer: widget.timer, laser: laserToggle),
              Reveal(
                child: connected && !_shown.running && !_shown.screen
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: InlineAlert(
                          tone: AppTone.danger,
                          icon: Icons.error_outline_rounded,
                          message: context.l10n.errorSlideshowNotRunning,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: AppMotion.of(context, AppMotion.base),
                  opacity: connected ? 1 : 0.55,
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.shown, required this.timer, this.laser});

  final _Shown shown;
  final PresentationTimerController timer;

  /// The Laser key, when the picture can point.
  final Widget? laser;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = shown.total > 0 ? '${shown.total}' : '?';
    if (shown.screen) {
      return SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  context.l10n.screenPreviewLabel,
                  style: AppType.title.copyWith(color: p.textPrimary, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ?laser,
            PresentationTimer(controller: timer),
          ],
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
          ),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Semantics(
              header: true,
              label:
                  '${context.l10n.presenterViewTitle}, ${context.l10n.slideCounter(shown.current, total)}',
              liveRegion: true,
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${shown.current}',
                        style: AppType.numeric.copyWith(
                          color: p.textPrimary,
                          fontSize: 26,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: ' / $total',
                        style: AppType.title.copyWith(
                          color: p.textMuted,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ?laser,
          PresentationTimer(controller: timer),
        ],
      ),
    );
  }
}

/// The Laser key of the top bar: on, the picture points.
class _LaserToggle extends StatelessWidget {
  const _LaserToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpace.xs),
      child: Pressable(
        onTap: onTap,
        selected: on,
        semanticLabel: context.l10n.toolLaser,
        tooltip: context.l10n.presenterLaserHint,
        borderRadius: AppRadius.all(AppRadius.pill),
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: on ? p.accent : p.surface,
            shape: BoxShape.circle,
            border: Border.all(color: on ? p.accent : p.border),
          ),
          child: Icon(
            Icons.highlight_rounded,
            size: 22,
            color: on ? readableOn(p.accent) : p.accentText,
          ),
        ),
      ),
    );
  }
}

/// The slide picture as a pointing area: the finger's place, as fractions
/// of the picture's 16:9 frame, which matches the show's 16:9 screen (a
/// slide of another shape is fitted into both the same way). The dot shows
/// where the laser is.
class _PointingArea extends StatelessWidget {
  const _PointingArea({
    required this.dot,
    required this.hint,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.child,
  });

  final Offset? dot;
  final String hint;
  final void Function(Offset local, Size size) onDown;
  final void Function(Offset local, Size size) onMove;
  final VoidCallback onUp;
  final Widget child;

  static const _dotSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: hint,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final at = dot;
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => onDown(e.localPosition, size),
              onPointerMove: (e) => onMove(e.localPosition, size),
              onPointerUp: (_) => onUp(),
              onPointerCancel: (_) => onUp(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  IgnorePointer(
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.all(AppRadius.md),
                        border: Border.all(color: p.accent, width: 2),
                      ),
                    ),
                  ),
                  if (at != null)
                    Positioned(
                      key: const ValueKey('laserDot'),
                      left: at.dx * size.width - _dotSize / 2,
                      top: at.dy * size.height - _dotSize / 2,
                      width: _dotSize,
                      height: _dotSize,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accent,
                            boxShadow: [
                              BoxShadow(
                                color: p.accent.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The next slide's picture and number, or "Last slide".
class _NextUp extends StatelessWidget {
  const _NextUp({required this.shown});

  final _Shown shown;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = shown.total > 0 && shown.current >= shown.total;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: last
              ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      borderRadius: AppRadius.all(AppRadius.sm),
                      border: Border.all(color: p.border),
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: p.textMuted,
                      size: 22,
                    ),
                  ),
                )
              : SlideImage(slide: shown.current + 1, image: shown.next),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.presenterNextUp.toUpperCase(),
                style: AppType.overline.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                last ? context.l10n.presenterLastSlide : '${shown.current + 1}',
                style: last
                    ? AppType.bodySmall.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w600,
                      )
                    : AppType.numeric.copyWith(
                        color: p.textPrimary,
                        fontSize: 22,
                        height: 1,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The slide's notes, scrolling when long.
class _Notes extends StatelessWidget {
  const _Notes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes_rounded, color: p.primaryText, size: 18),
                const SizedBox(width: AppSpace.xs),
                Text(
                  context.l10n.notesTitle.toUpperCase(),
                  style: AppType.overline.copyWith(color: p.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              notes.isEmpty ? context.l10n.notesEmpty : notes,
              style: AppType.body.copyWith(
                color: notes.isEmpty ? p.textMuted : p.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({required this.onPrev, required this.onNext});

  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 112,
          child: BigSlideButton(
            next: false,
            label: context.l10n.actionPrev,
            onTap: onPrev,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: BigSlideButton(
            next: true,
            label: context.l10n.actionNext,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}
