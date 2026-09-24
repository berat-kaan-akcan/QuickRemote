import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/websocket_service.dart';
import '../../../widgets/presentation_timer.dart';
import '../widgets/shared_buttons.dart';
import '../../../utils/throttler.dart';
import '../utils/slide_picker_sheet.dart';

enum DrawTool { laser, pen, highlighter, eraser }

class TouchpadView extends StatefulWidget {
  final WebSocketService ws;
  final GlobalKey presentationTimerKey;

  const TouchpadView({
    super.key,
    required this.ws,
    required this.presentationTimerKey,
  });

  @override
  State<TouchpadView> createState() => _TouchpadViewState();
}

class _TouchpadViewState extends State<TouchpadView> {
  final double _sensitivity = 8.0;
  DrawTool _drawTool = DrawTool.laser;

  void _send(String command) {
    HapticFeedback.mediumImpact();
    widget.ws.sendCommand(command);
  }

  void _showStartSlideDialog(BuildContext context) {
    SlidePickerSheet.show(
      context,
      totalSlides: widget.ws.totalSlides,
      onSend: _send,
    );
  }

  void _showColorPicker(BuildContext context, DrawTool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = [
          {
            'name': 'Kırmızı',
            'color': const Color(0xFFFF1744),
            'cmd': 'SET_PEN_COLOR:255',
          },
          {
            'name': 'Mavi',
            'color': const Color(0xFF2979FF),
            'cmd': 'SET_PEN_COLOR:16711680',
          },
          {
            'name': 'Yeşil',
            'color': const Color(0xFF00E676),
            'cmd': 'SET_PEN_COLOR:65280',
          },
          {
            'name': 'Sarı',
            'color': const Color(0xFFFFEA00),
            'cmd': 'SET_PEN_COLOR:65535',
          },
          {
            'name': 'Beyaz',
            'color': const Color(0xFFFFFFFF),
            'cmd': 'SET_PEN_COLOR:16777215',
          },
          {
            'name': 'Mor',
            'color': const Color(0xFFD500F9),
            'cmd': 'SET_PEN_COLOR:8388736',
          },
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool == DrawTool.pen
                            ? Icons.edit
                            : Icons.border_color_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tool == DrawTool.pen ? 'Kalem' : 'Vurgulayıcı'} Rengi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: colors.map((c) {
                      final color = c['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _send(c['cmd'] as String);
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c['name'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: !widget.ws.isConnected
                      ? null
                      : () {
                          HapticFeedback.heavyImpact();
                          _send('START');
                        },
                  onLongPress: !widget.ws.isConnected
                      ? null
                      : () {
                          HapticFeedback.heavyImpact();
                          _showStartSlideDialog(context);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Başlat',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PresentationTimer(key: widget.presentationTimerKey),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: !widget.ws.isConnected ? null : () => _send('END'),
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
                        Icon(
                          Icons.stop_rounded,
                          color: Color(0xFFFF5252),
                          size: 18,
                        ),
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
          Expanded(
            child: _Touchpad(
              ws: widget.ws,
              sensitivity: _sensitivity,
              drawTool: _drawTool,
            ),
          ),
          const SizedBox(height: 16),
          // Draw tool selector
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Lazer',
                  child: Tooltip(
                    message: 'Lazer aracını seç',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _drawTool = DrawTool.laser);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _drawTool == DrawTool.laser
                              ? const Color(0xFFFF1744).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == DrawTool.laser
                                ? const Color(
                                    0xFFFF1744,
                                  ).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.highlight_rounded,
                              size: 14,
                              color: _drawTool == DrawTool.laser
                                  ? const Color(0xFFFF1744)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Lazer',
                                  style: TextStyle(
                                    color: _drawTool == DrawTool.laser
                                        ? const Color(0xFFFF1744)
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
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Kalem',
                  child: Tooltip(
                    message: 'Kalem aracını seç',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_drawTool == DrawTool.pen) {
                          _showColorPicker(context, DrawTool.pen);
                        } else {
                          setState(() => _drawTool = DrawTool.pen);
                        }
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showColorPicker(context, DrawTool.pen);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _drawTool == DrawTool.pen
                              ? const Color(0xFF00E676).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == DrawTool.pen
                                ? const Color(
                                    0xFF00E676,
                                  ).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: _drawTool == DrawTool.pen
                                  ? const Color(0xFF00E676)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Kalem',
                                  style: TextStyle(
                                    color: _drawTool == DrawTool.pen
                                        ? const Color(0xFF00E676)
                                        : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: _drawTool == DrawTool.pen
                                  ? const Color(0xFF00E676)
                                  : Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Vurgula',
                  child: Tooltip(
                    message: 'Vurgulayıcı aracını seç',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_drawTool == DrawTool.highlighter) {
                          _showColorPicker(
                            context,
                            DrawTool.highlighter,
                          );
                        } else {
                          setState(() => _drawTool = DrawTool.highlighter);
                        }
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showColorPicker(context, DrawTool.highlighter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _drawTool == DrawTool.highlighter
                              ? const Color(0xFFFFEA00).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == DrawTool.highlighter
                                ? const Color(
                                    0xFFFFEA00,
                                  ).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.border_color_rounded,
                              size: 14,
                              color: _drawTool == DrawTool.highlighter
                                  ? const Color(0xFFFFEA00)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Vurgula',
                                  style: TextStyle(
                                    color: _drawTool == DrawTool.highlighter
                                        ? const Color(0xFFFFEA00)
                                        : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: _drawTool == DrawTool.highlighter
                                  ? const Color(0xFFFFEA00)
                                  : Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Silgi',
                  child: Tooltip(
                    message: 'Silgi aracını seç',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _drawTool = DrawTool.eraser);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _drawTool == DrawTool.eraser
                              ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == DrawTool.eraser
                                ? const Color(
                                    0xFFFF9800,
                                  ).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              size: 14,
                              color: _drawTool == DrawTool.eraser
                                  ? const Color(0xFFFF9800)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Silgi',
                                  style: TextStyle(
                                    color: _drawTool == DrawTool.eraser
                                        ? const Color(0xFFFF9800)
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
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Temizle',
                  child: Tooltip(
                    message: 'Tüm çizimleri temizle',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _send('ERASE_ALL');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 2,
                        ),
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
          ),
          const SizedBox(height: 16),
          // Slide buttons at bottom
          Row(
            children: [
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Geri',
                  onTap: !widget.ws.isConnected ? null : () => _send('PREV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlideButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'İleri',
                  isPrimary: true,
                  onTap: !widget.ws.isConnected ? null : () => _send('NEXT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Touchpad Widget ───
class _Touchpad extends StatefulWidget {
  final WebSocketService ws;
  final double sensitivity;
  final DrawTool drawTool;

  const _Touchpad({
    required this.ws,
    required this.sensitivity,
    required this.drawTool,
  });

  @override
  State<_Touchpad> createState() => _TouchpadState();
}

class _TouchpadState extends State<_Touchpad> {
  DateTime? _lastPointerUpTime;
  Offset? _lastPointerUpPosition;
  bool _isDrawActive = false;
  DrawTool _activeTool = DrawTool.laser;

  final _throttler = EventThrottler(delay: const Duration(milliseconds: 16));
  double _pendingDx = 0;
  double _pendingDy = 0;

  @override
  void dispose() {
    _throttler.cancel();
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

    if (_activeTool == DrawTool.pen) {
      widget.ws.sendCommand('MODE_PEN');
    } else if (_activeTool == DrawTool.highlighter) {
      widget.ws.sendCommand('MODE_HIGHLIGHTER');
    } else if (_activeTool == DrawTool.eraser) {
      widget.ws.sendCommand('MODE_ERASER');
    } else if (_activeTool == DrawTool.laser) {
      widget.ws.sendCommand('MODE_LASER');
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isDrawActive && mounted) {
        if (_activeTool != DrawTool.laser) {
          widget.ws.sendCommand('LEFT_DOWN');
        }
      }
    });
    HapticFeedback.mediumImpact();

    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawActive) return;

    _pendingDx += event.delta.dx * widget.sensitivity;
    _pendingDy += event.delta.dy * widget.sensitivity;

    _throttler.throttle(() {
      if (!mounted) return;
      if (_pendingDx == 0 && _pendingDy == 0) return;

      widget.ws.sendTouchOrLaser(
        (_activeTool == DrawTool.laser)
            ? 'LASER'
            : 'TOUCH',
        _pendingDx,
        _pendingDy,
      );

      _pendingDx = 0;
      _pendingDy = 0;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    final now = DateTime.now();
    _lastPointerUpTime = now;
    _lastPointerUpPosition = event.localPosition;

    if (_isDrawActive) {
      if (_activeTool == DrawTool.laser) {
        widget.ws.sendCommand('LASER_OFF');
      } else {
        widget.ws.sendCommand('LEFT_UP');
      }
      widget.ws.sendCommand('MODE_ARROW');
    }

    _isDrawActive = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      borderColor = Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2);
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
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
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
      ),
    );
  }
}
