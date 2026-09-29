import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../services/bluetooth/bt_key_mapping.dart';
import '../../remote/widgets/shared_buttons.dart';
import '../../remote/widgets/draw_tool_bar.dart';
import '../../../models/draw_tool.dart';

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

  bool get _impress => widget.target == BtTarget.impress;

  /// Impress has no keyboard shortcuts for highlighter/eraser (see BtKeyMapping),
  /// and without the pen a click advances the slide, so only laser and pen remain.
  Set<DrawTool> get _availableTools =>
      _impress ? const {DrawTool.laser, DrawTool.pen} : DrawTool.values.toSet();

  DrawTool get _selectedTool => _availableTools.contains(_drawTool) ? _drawTool : DrawTool.pen;

  /// In Impress the "laser" is just the mouse cursor.
  String get _laserLabel => _impress ? 'İmleç' : 'Lazer';

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          // Top bar: Başlat / Bitir
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: !widget.isConnected ? null : () => widget.send('START'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Color(0xFF4CAF50), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Başlat',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // BT mode indicator (timer yerine)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_rounded, color: Color(0xFF64B5F6), size: 14),
                    SizedBox(width: 4),
                    Text('BT', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: !widget.isConnected ? null : () => widget.send('END'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_rounded, color: Color(0xFFFF5252), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Bitir',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Touchpad area
          Expanded(child: _buildTouchpad(context)),
          const SizedBox(height: 16),
          // Draw tool selector — WiFi touchpad ile aynı tasarım
          _buildToolBar(),
          const SizedBox(height: 16),
          // Slide buttons at bottom
          Row(
            children: [
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Geri',
                  onTap: !widget.isConnected ? null : () => widget.send('PREV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'İleri',
                  isPrimary: true,
                  onTap: !widget.isConnected ? null : () => widget.send('NEXT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpad(BuildContext context) {
    Color borderColor;
    double borderWidth = 2;

    if (_isDrawActive && _activeTool == DrawTool.pen) {
      borderColor = const Color(0xFF00E676);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == DrawTool.highlighter) {
      borderColor = const Color(0xFFFFEA00);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == DrawTool.eraser) {
      borderColor = const Color(0xFFFF9800);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == DrawTool.laser) {
      borderColor = const Color(0xFFFF1744);
      borderWidth = 2.5;
    } else {
      borderColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: _isDrawActive
                  ? borderColor.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDrawActive && _activeTool == DrawTool.pen) ...[
                Icon(Icons.edit_rounded,
                    color: const Color(0xFF00E676).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Kalem',
                    style: TextStyle(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else if (_isDrawActive && _activeTool == DrawTool.highlighter) ...[
                Icon(Icons.border_color_rounded,
                    color: const Color(0xFFFFEA00).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Vurgulayıcı',
                    style: TextStyle(
                        color: const Color(0xFFFFEA00).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else if (_isDrawActive && _activeTool == DrawTool.eraser) ...[
                Icon(Icons.auto_fix_high_rounded,
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Silgi',
                    style: TextStyle(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else if (_isDrawActive && _activeTool == DrawTool.laser) ...[
                Icon(Icons.highlight_rounded,
                    color: const Color(0xFFFF1744).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text(_laserLabel,
                    style: TextStyle(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else ...[
                Icon(Icons.touch_app_rounded,
                    color: Colors.white.withValues(alpha: 0.08), size: 48),
                const SizedBox(height: 12),
                Text('Tek dokunuş → $_laserLabel',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Çift dokunuş → Seçili Araç',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DrawToolBar(
          activeTool: _selectedTool,
          tools: _availableTools,
          laserLabel: _laserLabel,
          onToolSelected: (tool) => setState(() => _drawTool = tool),
          onClear: () {
            HapticFeedback.mediumImpact();
            widget.send('ERASE_ALL');
          },
        ),
        const SizedBox(height: 6),
        _buildTargetSelector(),
      ],
    );
  }

  /// Over Bluetooth the phone only sends keyboard shortcuts, which differ per
  /// presentation program, so the user picks the target.
  Widget _buildTargetSelector() {
    return Row(
      children: [
        Text(
          'Hedef:',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SegmentedButton<BtTarget>(
            segments: const [
              ButtonSegment(value: BtTarget.powerpoint, label: Text('PowerPoint')),
              ButtonSegment(value: BtTarget.impress, label: Text('LibreOffice Impress')),
            ],
            selected: {widget.target},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              HapticFeedback.selectionClick();
              widget.onTargetChanged(s.first);
            },
            style: SegmentedButton.styleFrom(
              foregroundColor: Colors.white54,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.5),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
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
    if (_pendingDx != 0 || _pendingDy != 0) {
      final dx = _pendingDx.round().clamp(-127, 127);
      final dy = _pendingDy.round().clamp(-127, 127);
      _pendingDx = 0;
      _pendingDy = 0;
      if (dx != 0 || dy != 0) {
        final int buttons = _isLeftButtonHeld ? 1 : 0;
        widget.bt.sendMouseMove(dx, dy, buttons: buttons);
      }
    }

    if (_isDrawActive) {
      if (_activeTool == DrawTool.laser) {
        widget.send('LASER_CURSOR');
      } else {
        // Release the held mouse button via HID
        if (_isLeftButtonHeld) {
          widget.bt.sendMouseUp();
          _isLeftButtonHeld = false;
        }
      }
      widget.send('MODE_ARROW');
      _lastSentMode = 'MODE_ARROW';
    }

    _isDrawActive = false;
    setState(() {});
  }

  /// Returns the mode command string for a given tool.
  static String _modeCommandFor(DrawTool tool) {
    switch (tool) {
      case DrawTool.pen:
        return 'MODE_PEN';
      case DrawTool.highlighter:
        return 'MODE_HIGHLIGHTER';
      case DrawTool.eraser:
        return 'MODE_ERASER';
      case DrawTool.laser:
        return 'MODE_LASER';
    }
  }
}
