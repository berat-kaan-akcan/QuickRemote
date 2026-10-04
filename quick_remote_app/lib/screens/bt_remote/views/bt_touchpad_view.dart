import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../services/bluetooth/bt_key_mapping.dart';
import '../../remote/widgets/shared_buttons.dart';
import '../../remote/widgets/draw_tool_bar.dart';
import '../../remote/widgets/touchpad_surface.dart';
import '../widgets/bt_target_selector.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

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
  final ValueChanged<BtTarget> onTargetChanged;

  const BtTouchpadView({
    super.key,
    required this.bt,
    required this.send,
    required this.isConnected,
    required this.target,
    required this.onTargetChanged,
  });

  @override
  State<BtTouchpadView> createState() => _BtTouchpadViewState();
}

class _BtTouchpadViewState extends State<BtTouchpadView> {
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

  /// Impress and WPS have no laser shortcut: the "laser" is the mouse cursor.
  bool get _cursorLaser => widget.target != BtTarget.powerpoint;

  /// Tools with a shortcut in the target (see BtKeyMapping). Without the pen
  /// a click advances the slide, so a tool without one cannot stand in.
  Set<DrawTool> get _availableTools => switch (widget.target) {
        BtTarget.powerpoint => DrawTool.values.toSet(),
        BtTarget.impress => const {DrawTool.laser, DrawTool.pen},
        BtTarget.wps => const {DrawTool.laser, DrawTool.pen, DrawTool.highlighter},
      };

  DrawTool get _selectedTool => _availableTools.contains(_drawTool) ? _drawTool : DrawTool.pen;

  /// In Impress and WPS the "laser" is just the mouse cursor.
  String get _laserLabel => _cursorLaser ? context.l10n.toolCursor : context.l10n.toolLaser;

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.isConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PillButton(
                  icon: Icons.play_arrow_rounded,
                  label: context.l10n.actionStart,
                  color: AppColors.success,
                  onTap: !connected ? null : () => widget.send(RemoteCommands.start),
                ),
              ),
              const SizedBox(width: 8),
              // Where the Wi-Fi remote shows the timer
              const _BtBadge(),
              const SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  icon: Icons.stop_rounded,
                  label: context.l10n.actionEnd,
                  color: AppColors.danger,
                  onTap: !connected ? null : () => widget.send(RemoteCommands.end),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: TouchpadSurface(
                isDrawActive: _isDrawActive,
                activeTool: _activeTool,
                laserLabel: _laserLabel,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DrawToolBar(
            activeTool: _selectedTool,
            tools: _availableTools,
            laserLabel: _laserLabel,
            onToolSelected: (tool) => setState(() => _drawTool = tool),
            onClear: () {
              HapticFeedback.mediumImpact();
              widget.send(RemoteCommands.eraseAll);
            },
          ),
          const SizedBox(height: 6),
          BtTargetSelector(target: widget.target, onChanged: widget.onTargetChanged),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_back_rounded,
                  label: context.l10n.actionPrev,
                  onTap: !connected ? null : () => widget.send(RemoteCommands.prev),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_forward_rounded,
                  label: context.l10n.actionNext,
                  isPrimary: true,
                  onTap: !connected ? null : () => widget.send(RemoteCommands.next),
                ),
              ),
            ],
          ),
        ],
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

class _BtBadge extends StatelessWidget {
  const _BtBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bluetooth.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bluetooth.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_rounded, color: AppColors.bluetoothLight, size: 14),
          SizedBox(width: 4),
          Text('BT', style: TextStyle(color: AppColors.bluetoothLight, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
