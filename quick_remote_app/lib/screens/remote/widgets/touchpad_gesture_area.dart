import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/draw_tool.dart';
import '../../../../utils/delta_accumulator.dart';

class TouchpadGestureArea extends StatefulWidget {
  final double sensitivity;
  final DrawTool drawTool;
  final void Function(String) onSendCommand;
  final void Function(String, double, double) onSendTouchOrLaser;

  const TouchpadGestureArea({
    super.key,
    required this.sensitivity,
    required this.drawTool,
    required this.onSendCommand,
    required this.onSendTouchOrLaser,
  });

  @override
  State<TouchpadGestureArea> createState() => _TouchpadGestureAreaState();
}

class _TouchpadGestureAreaState extends State<TouchpadGestureArea> {
  DateTime? _lastPointerUpTime;
  Offset? _lastPointerUpPosition;
  bool _isDrawActive = false;
  DrawTool _activeTool = DrawTool.laser;

  static const _sendInterval = Duration(milliseconds: 16);
  // The PC rejects a single step above 500 on either axis.
  final _pending = DeltaAccumulator(maxStep: 500);
  Timer? _sendTimer;

  /// Identifies the current touch, so a delayed LEFT_DOWN from an earlier,
  /// already finished touch is never sent.
  int _gesture = 0;
  bool _leftDownSent = false;

  String get _moveType => _activeTool == DrawTool.laser ? 'LASER' : 'TOUCH';

  @override
  void dispose() {
    _sendTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.localPosition;

    bool isDoubleTap =
        _lastPointerUpTime != null &&
        _lastPointerUpPosition != null &&
        now.difference(_lastPointerUpTime!).inMilliseconds < 400 &&
        (pos - _lastPointerUpPosition!).distance < 80;

    _isDrawActive = true;
    _activeTool = isDoubleTap ? widget.drawTool : DrawTool.laser;
    final gesture = ++_gesture;
    _pending.clear();
    _sendTimer?.cancel();
    _sendTimer = null;
    _leftDownSent = false;

    if (_activeTool == DrawTool.pen) {
      widget.onSendCommand('MODE_PEN');
    } else if (_activeTool == DrawTool.highlighter) {
      widget.onSendCommand('MODE_HIGHLIGHTER');
    } else if (_activeTool == DrawTool.eraser) {
      widget.onSendCommand('MODE_ERASER');
    } else if (_activeTool == DrawTool.laser) {
      widget.onSendCommand('MODE_LASER');
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isDrawActive && gesture == _gesture && mounted && _activeTool != DrawTool.laser) {
        _leftDownSent = true;
        widget.onSendCommand('LEFT_DOWN');
      }
    });
    HapticFeedback.mediumImpact();

    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawActive) return;

    _pending.add(event.delta.dx * widget.sensitivity, event.delta.dy * widget.sensitivity);
    // Send at once when idle, then at most every 16 ms until drained.
    if (_sendTimer == null) _sendNext();
  }

  void _sendNext() {
    final step = mounted ? _pending.take() : null;
    if (step == null) {
      _sendTimer = null;
      return;
    }
    widget.onSendTouchOrLaser(_moveType, step.$1, step.$2);
    _sendTimer = Timer(_sendInterval, _sendNext);
  }

  void _endGesture(Offset position) {
    _lastPointerUpTime = DateTime.now();
    _lastPointerUpPosition = position;

    if (_isDrawActive) {
      // Deliver the rest of the motion before the button goes up.
      _sendTimer?.cancel();
      _sendTimer = null;
      for (var step = _pending.take(); step != null; step = _pending.take()) {
        widget.onSendTouchOrLaser(_moveType, step.$1, step.$2);
      }

      if (_activeTool == DrawTool.laser) {
        widget.onSendCommand('LASER_OFF');
      } else if (_leftDownSent) {
        widget.onSendCommand('LEFT_UP');
      }
      widget.onSendCommand('MODE_ARROW');
    }

    _isDrawActive = false;
    _leftDownSent = false;
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent event) => _endGesture(event.localPosition);

  // A touch taken over by the system (notification shade, incoming call) ends
  // with a cancel instead of an up; without this the PC keeps the button down.
  void _onPointerCancel(PointerCancelEvent event) => _endGesture(event.localPosition);

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth;

    if (_activeTool == DrawTool.pen) {
      borderColor = const Color(0xFF00E676);
      borderWidth = 2.5;
    } else if (_activeTool == DrawTool.highlighter) {
      borderColor = const Color(0xFFFFEA00);
      borderWidth = 2.5;
    } else if (_activeTool == DrawTool.eraser) {
      borderColor = const Color(0xFFFF9800);
      borderWidth = 2.5;
    } else {
      borderColor = const Color(0xFFFF1744); // Laser (Red)
      borderWidth = 2.5;
    }

    final inactiveBorderColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
    final inactiveShadowColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // INACTIVE BACKGROUND
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: inactiveBorderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: inactiveShadowColor,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          
          // ACTIVE BACKGROUND (Animated)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isDrawActive ? 1.0 : 0.0,
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CONTENT
          Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDrawActive && _activeTool == DrawTool.pen) ...[
                Icon(
                  Icons.edit_rounded,
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kalem',
                  style: TextStyle(
                    color: const Color(0xFF00E676).withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_isDrawActive &&
                  _activeTool == DrawTool.highlighter) ...[
                Icon(
                  Icons.border_color_rounded,
                  color: const Color(0xFFFFEA00).withValues(alpha: 0.3),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vurgulayıcı',
                  style: TextStyle(
                    color: const Color(0xFFFFEA00).withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_isDrawActive && _activeTool == DrawTool.eraser) ...[
                Icon(
                  Icons.auto_fix_high_rounded,
                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silgi',
                  style: TextStyle(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_isDrawActive && _activeTool == DrawTool.laser) ...[
                Icon(
                  Icons.highlight_rounded,
                  color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lazer',
                  style: TextStyle(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white.withValues(alpha: 0.08),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tek dokunuş → Lazer',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Çift dokunuş → Seçili Araç',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      ),
    );
  }
}
