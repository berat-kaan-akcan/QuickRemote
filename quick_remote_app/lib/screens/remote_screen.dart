import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/presentation_timer.dart';

final GlobalKey _presentationTimerKeyMain = GlobalKey();
final GlobalKey _presentationTimerKeyTouchpad = GlobalKey();

enum _DrawTool { laser, pen, eraser }

/// Main remote control screen for presentation control.
/// Has two views: main controls and touchpad mode.
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  bool _touchpadMode = false;
  double _sensitivity = 8.0;
  _DrawTool _drawTool = _DrawTool.laser;
  late WebSocketService _wsRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wsRef = context.read<WebSocketService>();
      _wsRef.addListener(_onConnectionChanged);
    });
  }

  void _onConnectionChanged() {
    if (!mounted) return;
    if (!_wsRef.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı koptu! Lütfen tekrar bağlanın.'),
          backgroundColor: Color(0xFFFF5252),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(); // Go back to Home Screen
    }
  }

  @override
  void dispose() {
    _wsRef.removeListener(_onConnectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 300;

    if (isCompact) {
      return _WatchLayout(
        ws: ws,
        onExit: () {
          ws.removeListener(_onConnectionChanged);
          ws.disconnect();
          if (mounted) Navigator.of(context).pop();
        },
      );
    }

    if (_touchpadMode) {
      return _buildTouchpadView(ws);
    }

    return _buildMainView(ws);
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bağlantıyı Kes', style: TextStyle(color: Colors.white)),
        content: const Text('Bağlantıyı kesip çıkmak istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Ekran 1: Ana Kontroller ───
  Widget _buildMainView(WebSocketService ws) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog();
        if (shouldPop) {
          ws.removeListener(_onConnectionChanged);
          ws.disconnect();
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, ws),
              const SizedBox(height: 24),
              PresentationTimer(key: _presentationTimerKeyMain),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Start/End
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'Başlat',
                            color: const Color(0xFF4CAF50),
                            onTap: () => _send(ws, 'START'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.stop_rounded,
                            label: 'Bitir',
                            color: const Color(0xFFFF5252),
                            onTap: () => _send(ws, 'END'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Slide navigation
                    Row(
                      children: [
                        Expanded(
                          child: _SlideButton(
                            icon: Icons.arrow_back_rounded,
                            label: 'Geri',
                            onTap: () => _send(ws, 'PREV'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SlideButton(
                            icon: Icons.arrow_forward_rounded,
                            label: 'İleri',
                            isPrimary: true,
                            onTap: () => _send(ws, 'NEXT'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Touchpad button
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        icon: Icons.touch_app_rounded,
                        label: 'Touchpad',
                        color: const Color(0xFF6C63FF),
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          setState(() => _touchpadMode = true);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Lock
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        icon: Icons.lock_rounded,
                        label: 'PC Kilitle',
                        color: const Color(0xFFFF9800),
                        onTap: () => _send(ws, 'LOCK'),
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
    );
  }

  // ─── Ekran 2: Touchpad Modu ───
  Widget _buildTouchpadView(WebSocketService ws) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _touchpadMode = false;
          });
          ws.sendCommand('MODE_ARROW');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top bar with back button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _touchpadMode = false;
                        });
                        ws.sendCommand('MODE_ARROW');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Text(
                    'Touchpad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ],
                ),

              const SizedBox(height: 16),
              
              // Sensitivity slider (moved to top)
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white30, size: 16),
                  Expanded(
                    child: Slider(
                      value: _sensitivity,
                      min: 2,
                      max: 20,
                      activeColor: const Color(0xFF6C63FF),
                      inactiveColor: Colors.white10,
                      onChanged: (v) => setState(() => _sensitivity = v),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      _sensitivity.toInt().toString(),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              PresentationTimer(key: _presentationTimerKeyTouchpad),
              const SizedBox(height: 12),

              // Touchpad area
              Expanded(
                child: _Touchpad(
                  ws: ws,
                  sensitivity: _sensitivity,
                  drawTool: _drawTool,
                ),
              ),

              const SizedBox(height: 16),

              // Draw tool selector (for double-tap mode)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.touch_app, color: Colors.white24, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'Araç:',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _drawTool = _DrawTool.laser);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _drawTool == _DrawTool.laser
                              ? const Color(0xFFFF1744).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == _DrawTool.laser
                                ? const Color(0xFFFF1744).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.highlight, size: 14,
                                color: _drawTool == _DrawTool.laser
                                    ? const Color(0xFFFF1744)
                                    : Colors.white38),
                            const SizedBox(width: 4),
                            Text('Lazer',
                                style: TextStyle(
                                  color: _drawTool == _DrawTool.laser
                                      ? const Color(0xFFFF1744)
                                      : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _drawTool = _DrawTool.pen);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _drawTool == _DrawTool.pen
                              ? const Color(0xFF00E676).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == _DrawTool.pen
                                ? const Color(0xFF00E676).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 14,
                                color: _drawTool == _DrawTool.pen
                                    ? const Color(0xFF00E676)
                                    : Colors.white38),
                            const SizedBox(width: 4),
                            Text('Kalem',
                                style: TextStyle(
                                  color: _drawTool == _DrawTool.pen
                                      ? const Color(0xFF00E676)
                                      : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _drawTool = _DrawTool.eraser);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _drawTool == _DrawTool.eraser
                              ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == _DrawTool.eraser
                                ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high, size: 14,
                                color: _drawTool == _DrawTool.eraser
                                    ? const Color(0xFFFF9800)
                                    : Colors.white38),
                            const SizedBox(width: 4),
                            Text('Silgi',
                                style: TextStyle(
                                  color: _drawTool == _DrawTool.eraser
                                      ? const Color(0xFFFF9800)
                                      : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Slide buttons at bottom
              Row(
                children: [
                  Expanded(
                    child: _SlideButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Geri',
                      onTap: () => _send(ws, 'PREV'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SlideButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'İleri',
                      isPrimary: true,
                      onTap: () => _send(ws, 'NEXT'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context, WebSocketService ws) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.touch_app, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QuickRemote',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                ws.serverAddress,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ws.isConnected
                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                : const Color(0xFFFF5252).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ws.isConnected
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                  : const Color(0xFFFF5252).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: ws.isConnected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                ws.isConnected ? 'Bağlı' : 'Kopuk',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ws.isConnected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54, size: 22),
          onPressed: () async {
            final shouldPop = await _showExitDialog();
            if (shouldPop) {
              ws.removeListener(_onConnectionChanged);
              ws.disconnect();
              if (mounted) Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  void _send(WebSocketService ws, String command) {
    HapticFeedback.mediumImpact();
    if ((command == 'NEXT' || command == 'PREV') && context.read<SettingsProvider>().clearInkOnNext) {
      ws.sendCommand('CLEAR_INK');
    }
    ws.sendCommand(command);
  }
}

// ─── Touchpad Widget ───
class _Touchpad extends StatefulWidget {
  final WebSocketService ws;
  final double sensitivity;
  final _DrawTool drawTool;

  const _Touchpad({
    required this.ws,
    required this.sensitivity,
    required this.drawTool,
  });

  @override
  State<_Touchpad> createState() => _TouchpadState();
}

class _TouchpadState extends State<_Touchpad> {
  // Double-tap detection
  DateTime? _lastPointerUpTime;
  Offset? _lastPointerUpPosition;

  // Active mode tracking
  bool _isDrawActive = false;

  // Tap vs drag detection
  DateTime? _pointerStartTime;
  double _totalDragDistance = 0;

  Timer? _tapClickTimer;

  @override
  void dispose() {
    _tapClickTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.localPosition;

    _tapClickTimer?.cancel();

    bool isDoubleTap = _lastPointerUpTime != null &&
        _lastPointerUpPosition != null &&
        now.difference(_lastPointerUpTime!).inMilliseconds < 350 &&
        (pos - _lastPointerUpPosition!).distance < 60;

    if (isDoubleTap || widget.drawTool == _DrawTool.laser) {
      // Double tap detected (or laser is selected, which is immediate)
      _isDrawActive = true;

      if (widget.drawTool == _DrawTool.pen) {
        widget.ws.sendCommand('MODE_PEN');
      } else if (widget.drawTool == _DrawTool.eraser) {
        widget.ws.sendCommand('MODE_ERASER');
      } else if (widget.drawTool == _DrawTool.laser) {
        widget.ws.sendCommand('MODE_LASER');
      }
      
      Future.delayed(const Duration(milliseconds: 80), () {
        if (_isDrawActive && mounted) {
          if (widget.drawTool != _DrawTool.laser) {
            widget.ws.sendCommand('LEFT_DOWN');
          }
        }
      });
      HapticFeedback.mediumImpact();
    } else {
      _isDrawActive = false;
    }

    _pointerStartTime = now;
    _totalDragDistance = 0;
    _lastPointerUpTime = null;
    _lastPointerUpPosition = null;

    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    _totalDragDistance += event.delta.distance;

    final dx = event.delta.dx * widget.sensitivity;
    final dy = event.delta.dy * widget.sensitivity;

    widget.ws.sendRaw({
      'type': (_isDrawActive && widget.drawTool == _DrawTool.laser) ? 'LASER' : 'TOUCH',
      'dx': dx,
      'dy': dy,
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    final now = DateTime.now();
    _lastPointerUpTime = now;
    _lastPointerUpPosition = event.localPosition;

    final duration = _pointerStartTime != null
        ? now.difference(_pointerStartTime!).inMilliseconds
        : 999;

    if (!_isDrawActive && _totalDragDistance < 10 && duration < 300) {
      _tapClickTimer?.cancel();
      _tapClickTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) {
          widget.ws.sendCommand('LEFT_CLICK');
          HapticFeedback.selectionClick();
        }
      });
    }

    if (_isDrawActive) {
      if (widget.drawTool == _DrawTool.laser) {
        widget.ws.sendCommand('LASER_OFF');
      } else {
        widget.ws.sendCommand('LEFT_UP');
      }
      widget.ws.sendCommand('MODE_ARROW');
    }

    _isDrawActive = false;
    _totalDragDistance = 0;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth = 2;

    if (_isDrawActive && widget.drawTool == _DrawTool.pen) {
      borderColor = const Color(0xFF00E676);
      borderWidth = 2.5;
    } else if (_isDrawActive && widget.drawTool == _DrawTool.eraser) {
      borderColor = const Color(0xFFFF9800);
      borderWidth = 2.5;
    } else if (_isDrawActive && widget.drawTool == _DrawTool.laser) {
      borderColor = const Color(0xFFFF1744);
      borderWidth = 2.5;
    } else {
      borderColor = const Color(0xFF6C63FF).withValues(alpha: 0.2);
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: _isDrawActive
                  ? borderColor.withValues(alpha: 0.15)
                  : const Color(0xFF6C63FF).withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDrawActive && widget.drawTool == _DrawTool.pen) ...[
                Icon(Icons.edit,
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                    size: 48),
                const SizedBox(height: 8),
                Text('Kalem',
                    style: TextStyle(
                      color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ] else if (_isDrawActive && widget.drawTool == _DrawTool.eraser) ...[
                Icon(Icons.auto_fix_high,
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                    size: 48),
                const SizedBox(height: 8),
                Text('Silgi',
                    style: TextStyle(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ] else if (_isDrawActive && widget.drawTool == _DrawTool.laser) ...[
                Icon(Icons.highlight,
                    color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                    size: 48),
                const SizedBox(height: 8),
                Text('Lazer',
                    style: TextStyle(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ] else ...[
                Icon(Icons.touch_app_rounded,
                    color: Colors.white.withValues(alpha: 0.08), size: 48),
                const SizedBox(height: 12),
                if (widget.drawTool == _DrawTool.laser) ...[
                  Text('Sürükleyin → Lazer',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                ] else ...[
                  Text('Tek dokunuş → Fare',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 4),
                  Text('Çift dokunuş → Seçili Araç',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slide Button ───
class _SlideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _SlideButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 140,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                  )
                : null,
            color: isPrimary ? null : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: isPrimary
                ? null
                : Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ───
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Clock Widget ───
class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, color: Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 8),
          Text(
            '$h:$m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WearOS Layout ───
class _WatchLayout extends StatefulWidget {
  final WebSocketService ws;
  final VoidCallback onExit;
  const _WatchLayout({super.key, required this.ws, required this.onExit});

  @override
  State<_WatchLayout> createState() => _WatchLayoutState();
}

class _WatchLayoutState extends State<_WatchLayout> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Çıkış', style: TextStyle(color: Colors.white)),
            content: const Text('Bağlantı kesilsin mi?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Evet', style: TextStyle(color: Color(0xFFFF5252))),
              ),
            ],
          ),
        ) ?? false;
        if (shouldPop) {
          widget.onExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top bar: Time + Connection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: widget.ws.isConnected
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$h:$m',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Next button (huge)
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  widget.ws.sendCommand('NEXT');
                },
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 40),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Prev + Lock buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.ws.sendCommand('PREV');
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.ws.sendCommand('LOCK');
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Color(0xFFFF9800), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
