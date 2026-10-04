import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../models/draw_tool.dart';
import '../../../utils/delta_accumulator.dart';
import 'touchpad_surface.dart';

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
      widget.onSendCommand(RemoteCommands.modePen);
    } else if (_activeTool == DrawTool.highlighter) {
      widget.onSendCommand(RemoteCommands.modeHighlighter);
    } else if (_activeTool == DrawTool.eraser) {
      widget.onSendCommand(RemoteCommands.modeEraser);
    } else if (_activeTool == DrawTool.laser) {
      widget.onSendCommand(RemoteCommands.modeLaser);
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isDrawActive && gesture == _gesture && mounted && _activeTool != DrawTool.laser) {
        _leftDownSent = true;
        widget.onSendCommand(RemoteCommands.leftDown);
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
        widget.onSendCommand(RemoteCommands.laserOff);
      } else if (_leftDownSent) {
        widget.onSendCommand(RemoteCommands.leftUp);
      }
      widget.onSendCommand(RemoteCommands.modeArrow);
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
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: TouchpadSurface(isDrawActive: _isDrawActive, activeTool: _activeTool),
    );
  }
}
