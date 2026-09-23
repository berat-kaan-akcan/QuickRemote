import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/bluetooth/bt_hid_service.dart';
import '../../remote/widgets/shared_buttons.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 1: Touchpad View  (WiFi TouchpadView ile aynı tasarım)
// BT'de renk seçici ve slayt picker çalışmaz → kaldırıldı.
// Fare hareketi doğrudan BT HID mouse report olarak gönderilir.
// ═════════════════════════════════════════════════════════════════════════════

enum BtDrawTool { laser, pen, highlighter, eraser, screen }

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
  String _screenCommand = 'BLACK_SCREEN';
  bool _isDrawActive = false;
  BtDrawTool _activeTool = BtDrawTool.laser;
  DateTime? _lastPointerUpTime;
  Offset? _lastPointerUpPosition;

  static const double _sensitivity = 2.5;

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
    } else if (_isDrawActive && _activeTool == BtDrawTool.screen) {
      borderColor = Colors.grey;
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
        // Ekran tool
        Expanded(
          child: Semantics(
            button: true,
            label: 'Ekran',
            child: Tooltip(
              message: 'Ekran Aracı',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (_drawTool == BtDrawTool.screen) {
                    // Toggle screen command
                    setState(() {
                      _screenCommand = _screenCommand == 'BLACK_SCREEN'
                          ? 'WHITE_SCREEN'
                          : 'BLACK_SCREEN';
                    });
                    widget.send(_screenCommand);
                  } else {
                    setState(() => _drawTool = BtDrawTool.screen);
                    widget.send(_screenCommand);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  decoration: BoxDecoration(
                    color: _drawTool == BtDrawTool.screen
                        ? (_screenCommand == 'BLACK_SCREEN'
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.2))
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _drawTool == BtDrawTool.screen
                          ? (_screenCommand == 'BLACK_SCREEN'
                                ? Colors.grey.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.5))
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _screenCommand == 'BLACK_SCREEN'
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 14,
                        color: _drawTool == BtDrawTool.screen
                            ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey : Colors.white)
                            : Colors.white38,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _screenCommand == 'BLACK_SCREEN' ? 'Siyah' : 'Beyaz',
                            style: TextStyle(
                              color: _drawTool == BtDrawTool.screen
                                  ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey : Colors.white)
                                  : Colors.white38,
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

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.localPosition;

    bool isDoubleTap = _lastPointerUpTime != null &&
        _lastPointerUpPosition != null &&
        now.difference(_lastPointerUpTime!).inMilliseconds < 400 &&
        (pos - _lastPointerUpPosition!).distance < 80;

    _isDrawActive = true;
    _activeTool = isDoubleTap ? _drawTool : BtDrawTool.laser;

    // Send mode command via BT HID
    if (_activeTool == BtDrawTool.pen) {
      widget.send('MODE_PEN');
    } else if (_activeTool == BtDrawTool.highlighter) {
      widget.send('MODE_HIGHLIGHTER');
    } else if (_activeTool == BtDrawTool.eraser) {
      widget.send('MODE_ERASER');
    } else if (_activeTool == BtDrawTool.laser) {
      widget.send('MODE_LASER');
    }

    // For pen/highlighter/eraser, simulate LEFT_DOWN after mode switch
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isDrawActive && mounted) {
        if (_activeTool != BtDrawTool.laser && _activeTool != BtDrawTool.screen) {
          widget.send('LEFT_DOWN');
        }
      }
    });
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawActive) return;

    final dx = (event.delta.dx * _sensitivity).round().clamp(-127, 127);
    final dy = (event.delta.dy * _sensitivity).round().clamp(-127, 127);
    if (dx != 0 || dy != 0) {
      widget.bt.sendMouseMove(dx, dy);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _lastPointerUpTime = DateTime.now();
    _lastPointerUpPosition = event.localPosition;

    if (_isDrawActive) {
      if (_activeTool == BtDrawTool.laser || _activeTool == BtDrawTool.screen) {
        widget.send('LASER_CURSOR');
      } else {
        widget.send('LEFT_UP');
      }
      widget.send('MODE_ARROW');
    }

    _isDrawActive = false;
    setState(() {});
  }
}
