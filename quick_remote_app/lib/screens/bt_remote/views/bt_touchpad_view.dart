import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/bluetooth/bt_hid_service.dart';
import '../../remote/widgets/shared_buttons.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 1: Touchpad View  (WiFi TouchpadView ile aynı tasarım)
// BT'de renk seçici ve slayt picker çalışmaz → kaldırıldı.
// Fare hareketi doğrudan BT HID mouse report olarak gönderilir.
//
// Performans: Pointer move event'leri throttle edilir ve delta biriktirilir.
// Bu sayede BT HID channel flood edilmez ve hareket akıcı olur.
// ═════════════════════════════════════════════════════════════════════════════

enum BtDrawTool { laser, pen, highlighter, eraser }

class BtTouchpadView extends StatefulWidget {
  final BtHidService bt;
  final Future<void> Function(String) send;
  final bool isConnected;

  const BtTouchpadView({
    super.key,
    required this.bt,
    required this.send,
    required this.isConnected,
  });

  @override
  State<BtTouchpadView> createState() => _BtTouchpadViewState();
}

class _BtTouchpadViewState extends State<BtTouchpadView> {
  BtDrawTool _drawTool = BtDrawTool.laser;

  bool _isDrawActive = false;
  BtDrawTool _activeTool = BtDrawTool.laser;
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

    if (_isDrawActive && _activeTool == BtDrawTool.pen) {
      borderColor = const Color(0xFF00E676);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == BtDrawTool.highlighter) {
      borderColor = const Color(0xFFFFEA00);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == BtDrawTool.eraser) {
      borderColor = const Color(0xFFFF9800);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == BtDrawTool.laser) {
      borderColor = const Color(0xFFFF1744);
      borderWidth = 2.5;
    } else {
      borderColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
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
              if (_isDrawActive && _activeTool == BtDrawTool.pen) ...[
                Icon(Icons.edit_rounded,
                    color: const Color(0xFF00E676).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Kalem',
                    style: TextStyle(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else if (_isDrawActive && _activeTool == BtDrawTool.highlighter) ...[
                Icon(Icons.border_color_rounded,
                    color: const Color(0xFFFFEA00).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Vurgulayıcı',
                    style: TextStyle(
                        color: const Color(0xFFFFEA00).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else if (_isDrawActive && _activeTool == BtDrawTool.eraser) ...[
                Icon(Icons.auto_fix_high_rounded,
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Silgi',
                    style: TextStyle(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else if (_isDrawActive && _activeTool == BtDrawTool.laser) ...[
                Icon(Icons.highlight_rounded,
                    color: const Color(0xFFFF1744).withValues(alpha: 0.3), size: 48),
                const SizedBox(height: 8),
                Text('Lazer',
                    style: TextStyle(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ] else ...[
                Icon(Icons.touch_app_rounded,
                    color: Colors.white.withValues(alpha: 0.08), size: 48),
                const SizedBox(height: 12),
                Text('Tek dokunuş → Lazer',
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
    return Row(
      children: [
        _buildToolButton(
          tool: BtDrawTool.laser,
          icon: Icons.highlight_rounded,
          label: 'Lazer',
          activeColor: const Color(0xFFFF1744),
        ),
        const SizedBox(width: 4),
        _buildToolButton(
          tool: BtDrawTool.pen,
          icon: Icons.edit_rounded,
          label: 'Kalem',
          activeColor: const Color(0xFF00E676),
        ),
        const SizedBox(width: 4),
        _buildToolButton(
          tool: BtDrawTool.highlighter,
          icon: Icons.border_color_rounded,
          label: 'Vurgula',
          activeColor: const Color(0xFFFFEA00),
        ),
        const SizedBox(width: 4),
        _buildToolButton(
          tool: BtDrawTool.eraser,
          icon: Icons.auto_fix_high_rounded,
          label: 'Silgi',
          activeColor: const Color(0xFFFF9800),
        ),
        const SizedBox(width: 4),
        // Temizle (Tüm çizimleri sil) button
        Expanded(
          child: Semantics(
            button: true,
            label: 'Temizle',
            child: Tooltip(
              message: 'Tüm çizimleri temizle',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.send('ERASE_ALL');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cleaning_services_rounded,
                        size: 14,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Temizle',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required BtDrawTool tool,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isActive = _drawTool == tool;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: '$label aracını seç',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _drawTool = tool);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: isActive ? activeColor : Colors.white38),
                  const SizedBox(width: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isActive ? activeColor : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pointer handling ─────────────────────────────────────────────────────

  /// Whether the HID left mouse button is currently held down (for drawing).
  bool _isLeftButtonHeld = false;

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.localPosition;

    bool isDoubleTap = _lastPointerUpTime != null &&
        _lastPointerUpPosition != null &&
        now.difference(_lastPointerUpTime!).inMilliseconds < 400 &&
        (pos - _lastPointerUpPosition!).distance < 80;

    _isDrawActive = true;
    _activeTool = isDoubleTap ? _drawTool : BtDrawTool.laser;

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
    if (_activeTool != BtDrawTool.laser) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isDrawActive && mounted) {
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

  void _onPointerUp(PointerUpEvent event) {
    _lastPointerUpTime = DateTime.now();
    _lastPointerUpPosition = event.localPosition;

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
      if (_activeTool == BtDrawTool.laser) {
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
  static String _modeCommandFor(BtDrawTool tool) {
    switch (tool) {
      case BtDrawTool.pen:
        return 'MODE_PEN';
      case BtDrawTool.highlighter:
        return 'MODE_HIGHLIGHTER';
      case BtDrawTool.eraser:
        return 'MODE_ERASER';
      case BtDrawTool.laser:
        return 'MODE_LASER';
    }
  }
}
