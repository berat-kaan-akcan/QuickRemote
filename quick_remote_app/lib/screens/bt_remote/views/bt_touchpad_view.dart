import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../services/bluetooth/bt_key_mapping.dart';
import '../../../services/presentation_timer_controller.dart';
import '../../../widgets/presentation_timer.dart';
import '../../remote/widgets/shared_buttons.dart';
import '../../remote/widgets/draw_tool_bar.dart';
import '../../remote/widgets/touchpad_surface.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 1: Touchpad View  (WiFi TouchpadView ile aynı tasarım)
// BT'de renk seçici ve slayt picker çalışmaz → kaldırıldı.
// Fare hareketi doğrudan BT HID mouse report olarak gönderilir.
//
// Performans: Pointer move event'leri throttle edilir ve delta biriktirilir.
// Bu sayede BT HID channel flood edilmez ve hareket akıcı olur.
// ═════════════════════════════════════════════════════════════════════════════

class BtTouchpadView extends StatefulWidget {
  final BtHidService bt;
  final Future<void> Function(String) send;
  final bool isConnected;
  final BtTarget target;
  final PresentationTimerController timer;

  const BtTouchpadView({
    super.key,
    required this.bt,
    required this.send,
    required this.isConnected,
    required this.target,
    required this.timer,
  });

  @override
  State<BtTouchpadView> createState() => _BtTouchpadViewState();
}

class _BtTouchpadViewState extends State<BtTouchpadView> with SingleTickerProviderStateMixin {
  DrawTool _drawTool = DrawTool.laser;

  bool _isDrawActive = false;
  DrawTool _activeTool = DrawTool.laser;
  DateTime? _lastPointerUpTime;
  Offset? _lastPointerUpPosition;

  // ── Throttling & delta accumulation ────────────────────────────────────
  static const double _sensitivity = 4.0;
  static const Duration _throttleInterval = Duration(milliseconds: 16);

  double _pendingDx = 0;
  double _pendingDy = 0;
  Timer? _throttleTimer;

  /// Son gönderilen mod — aynı modu tekrar göndermemek için.
  String? _lastSentMode;

  /// The finger's path, drawn on the surface and faded after it lifts.
  final _trail = TouchTrail();
  late final AnimationController _fade = AnimationController(vsync: this)
    ..addListener(() => _trail.setFade(_fade.value));

  /// Impress and PowerPoint for the web have no laser shortcut: the "laser"
  /// is the mouse cursor.
  bool get _cursorLaser => widget.target == BtTarget.impress || widget.target == BtTarget.powerpointWeb;

  /// Tools with a shortcut in the target (see BtKeyMapping). Without the pen
  /// a click advances the slide, so a tool without one cannot stand in.
  Set<DrawTool> get _availableTools => switch (widget.target) {
        BtTarget.powerpoint => DrawTool.values.toSet(),
        BtTarget.impress => const {DrawTool.laser, DrawTool.pen},
        BtTarget.wps => DrawTool.values.toSet(),
        // The sites in a browser have no ink.
        BtTarget.powerpointWeb || BtTarget.googleSlides => const {DrawTool.laser},
      };

  DrawTool get _selectedTool => _availableTools.contains(_drawTool)
      ? _drawTool
      : _availableTools.contains(DrawTool.pen)
      ? DrawTool.pen
      : _availableTools.first;

  /// In Impress the "laser" is just the mouse cursor.
  String get _laserLabel => _cursorLaser ? context.l10n.toolCursor : context.l10n.toolLaser;
  IconData? get _laserIcon => _cursorLaser ? Icons.north_west_rounded : null;
  Color? get _laserColor => _cursorLaser ? context.palette.info : null;

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _fade.dispose();
    _trail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.isConnected;
    final p = context.palette;
    final note = switch (widget.target) {
      BtTarget.impress => context.l10n.btImpressToolsNote,
      BtTarget.wps => context.l10n.btWpsToolsNote,
      BtTarget.powerpointWeb => context.l10n.btPowerpointWebToolsNote,
      BtTarget.googleSlides => context.l10n.btGoogleSlidesToolsNote,
      BtTarget.powerpoint => null,
    };
    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xxs, AppSpace.page, AppSpace.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StartEndPair(
                    height: 46,
                    iconsOnly: true,
                    onStart: !connected ? null : () => widget.send(RemoteCommands.start),
                    onEnd: !connected ? null : () => widget.send(RemoteCommands.end),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                PresentationTimer(controller: widget.timer, tall: true),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: TouchpadSurface(
                  isDrawActive: _isDrawActive,
                  activeTool: _activeTool,
                  selectedTool: _selectedTool,
                  laserLabel: _laserLabel,
                  laserIcon: _laserIcon,
                  laserColor: _laserColor,
                  trail: _trail,
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: AppSpace.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: p.textMuted, size: 17),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(child: Text(note, style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpace.sm),
            DrawToolBar(
              activeTool: _selectedTool,
              tools: _availableTools,
              laserLabel: _laserLabel,
              laserIcon: _laserIcon,
              laserColor: _laserColor,
              onToolSelected: (tool) => setState(() => _drawTool = tool),
              onClear: () {
                HapticFeedback.mediumImpact();
                widget.send(RemoteCommands.eraseAll);
              },
            ),
            const SizedBox(height: AppSpace.sm),
            SlideNavRow(
              prevLabel: context.l10n.actionPrev,
              nextLabel: context.l10n.actionNext,
              onPrev: !connected ? null : () => widget.send(RemoteCommands.prev),
              onNext: !connected ? null : () => widget.send(RemoteCommands.next),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pointer handling ─────────────────────────────────────────────────────

  /// Whether the HID left mouse button is currently held down (for drawing).
  bool _isLeftButtonHeld = false;

  /// Identifies the current touch, so a delayed button press from an earlier,
  /// already finished touch is never sent.
  int _gesture = 0;

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.localPosition;

    bool isDoubleTap = _lastPointerUpTime != null &&
        _lastPointerUpPosition != null &&
        now.difference(_lastPointerUpTime!).inMilliseconds < 400 &&
        (pos - _lastPointerUpPosition!).distance < 80;

    _isDrawActive = true;
    _activeTool = isDoubleTap ? _selectedTool : DrawTool.laser;
    _fade.stop();
    _trail.start(pos, _activeTool, null);
    final gesture = ++_gesture;

    // Reset pending deltas
    _pendingDx = 0;
    _pendingDy = 0;
    _isLeftButtonHeld = false;

    // Send mode command via BT HID — only if different from last sent mode
    final modeCmd = _modeCommandFor(_activeTool);
    if (modeCmd != _lastSentMode) {
      widget.send(modeCmd);
      _lastSentMode = modeCmd;
    }

    // For pen/highlighter/eraser: hold left mouse button down via HID
    // (WiFi'daki LEFT_DOWN davranışı — buton basılı kalır)
    if (_activeTool != DrawTool.laser) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isDrawActive && gesture == _gesture && mounted) {
          _isLeftButtonHeld = true;
          widget.bt.sendMouseDown(button: 1);
        }
      });
    }

    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawActive) return;
    _trail.add(event.localPosition);

    // Accumulate deltas
    _pendingDx += event.delta.dx * _sensitivity;
    _pendingDy += event.delta.dy * _sensitivity;

    // Schedule a throttled flush if not already scheduled and not in-flight
    _throttleTimer ??= Timer(_throttleInterval, _flushPendingMove);
  }

  void _flushPendingMove() {
    _throttleTimer = null;

    if (!_isDrawActive || !mounted) return;

    final int dx = _pendingDx.round().clamp(-127, 127);
    final int dy = _pendingDy.round().clamp(-127, 127);
    
    // Subtract the portion we are sending now
    _pendingDx -= dx;
    _pendingDy -= dy;

    if (dx == 0 && dy == 0) {
      // Re-schedule if there are fractional pending deltas that didn't round to 1
      if (_pendingDx.abs() > 0.5 || _pendingDy.abs() > 0.5) {
        _throttleTimer ??= Timer(_throttleInterval, _flushPendingMove);
      }
      return;
    }

    // During drawing (pen/highlighter/eraser), keep left button held in every
    // HID report so the OS doesn't release it between moves.
    final int buttons = _isLeftButtonHeld ? 1 : 0;

    // Fire and forget for lowest latency
    widget.bt.sendMouseMove(dx, dy, buttons: buttons);

    // If there is still leftover delta (because we clamped at 127), schedule another flush
    if (_pendingDx.abs() >= 1 || _pendingDy.abs() >= 1) {
      _throttleTimer ??= Timer(_throttleInterval, _flushPendingMove);
    }
  }

  void _onPointerUp(PointerUpEvent event) => _endGesture(event.localPosition);

  // A touch taken over by the system (notification shade, incoming call) ends
  // with a cancel instead of an up; without this the PC keeps the button down.
  void _onPointerCancel(PointerCancelEvent event) => _endGesture(event.localPosition);

  void _endGesture(Offset position) {
    _lastPointerUpTime = DateTime.now();
    _lastPointerUpPosition = position;

    // Flush any remaining deltas immediately
    _throttleTimer?.cancel();
    _throttleTimer = null;
    // A HID report carries at most ±127 per axis: send the rest in steps
    // instead of dropping it, or the stroke would end short of the finger.
    var restX = _pendingDx.round();
    var restY = _pendingDy.round();
    _pendingDx = 0;
    _pendingDy = 0;
    final int buttons = _isLeftButtonHeld ? 1 : 0;
    while (restX != 0 || restY != 0) {
      final dx = restX.clamp(-127, 127);
      final dy = restY.clamp(-127, 127);
      widget.bt.sendMouseMove(dx, dy, buttons: buttons);
      restX -= dx;
      restY -= dy;
    }

    if (_isDrawActive) {
      if (_activeTool == DrawTool.laser) {
        widget.send(RemoteCommands.laserOff);
      } else {
        // Release the held mouse button via HID
        if (_isLeftButtonHeld) {
          widget.bt.sendMouseUp();
          _isLeftButtonHeld = false;
        }
      }
      widget.send(RemoteCommands.modeArrow);
      _lastSentMode = RemoteCommands.modeArrow;
    }

    _isDrawActive = false;
    _trail.end();
    _fade.duration = AppMotion.of(context, const Duration(seconds: 1));
    _fade.forward(from: 0);
    setState(() {});
  }

  /// Returns the mode command string for a given tool.
  static String _modeCommandFor(DrawTool tool) {
    switch (tool) {
      case DrawTool.pen:
        return RemoteCommands.modePen;
      case DrawTool.highlighter:
        return RemoteCommands.modeHighlighter;
      case DrawTool.eraser:
        return RemoteCommands.modeEraser;
      case DrawTool.laser:
        return RemoteCommands.modeLaser;
    }
  }
}
