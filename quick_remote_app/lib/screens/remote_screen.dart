import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

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
  bool _laserActive = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 300;

    if (isCompact) {
      return _WatchLayout(ws: ws);
    }

    if (_touchpadMode) {
      return _buildTouchpadView(ws);
    }

    return _buildMainView(ws);
  }

  // ─── Ekran 1: Ana Kontroller ───
  Widget _buildMainView(WebSocketService ws) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, ws),
              const SizedBox(height: 24),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _ClockWidget(),
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

                    // Touchpad / Laser button
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        icon: Icons.touch_app_rounded,
                        label: 'Touchpad / Lazer',
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
            _laserActive = false;
          });
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
                          _laserActive = false;
                        });
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
                  const Spacer(),
                  // Laser toggle
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      setState(() => _laserActive = !_laserActive);
                      ws.sendCommand('LASER_CURSOR');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _laserActive
                            ? const Color(0xFFFF1744)
                            : const Color(0xFFFF1744).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _laserActive
                              ? const Color(0xFFFF1744)
                              : const Color(0xFFFF1744).withValues(alpha: 0.4),
                        ),
                        boxShadow: _laserActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _laserActive ? Colors.white : const Color(0xFFFF1744),
                              boxShadow: _laserActive
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFFF1744)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lazer',
                            style: TextStyle(
                              color: _laserActive ? Colors.white : const Color(0xFFFF1744),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Touchpad area
              Expanded(
                child: _Touchpad(
                  sensitivity: _sensitivity,
                  onMove: (dx, dy) {
                    ws.sendRaw({
                      'type': 'TOUCH',
                      'dx': double.parse(dx.toStringAsFixed(1)),
                      'dy': double.parse(dy.toStringAsFixed(1)),
                    });
                  },
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ws.sendCommand('LEFT_CLICK');
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Sensitivity slider
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
          onPressed: () {
            ws.disconnect();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _send(WebSocketService ws, String command) {
    HapticFeedback.mediumImpact();
    ws.sendCommand(command);
  }
}

// ─── Touchpad Widget ───
class _Touchpad extends StatefulWidget {
  final double sensitivity;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onTap;

  const _Touchpad({
    required this.sensitivity,
    required this.onMove,
    required this.onTap,
  });

  @override
  State<_Touchpad> createState() => _TouchpadState();
}

class _TouchpadState extends State<_Touchpad> {
  Offset? _lastPosition;
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        _lastPosition = d.localPosition;
        _moved = false;
      },
      onPanUpdate: (d) {
        if (_lastPosition != null) {
          final delta = d.localPosition - _lastPosition!;
          final dx = delta.dx * widget.sensitivity * 0.5;
          final dy = delta.dy * widget.sensitivity * 0.5;
          if (dx.abs() > 0.3 || dy.abs() > 0.3) {
            widget.onMove(dx, dy);
            _moved = true;
          }
          _lastPosition = d.localPosition;
        }
      },
      onPanEnd: (_) => _lastPosition = null,
      onTap: () {
        if (!_moved) widget.onTap();
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: Colors.white.withValues(alpha: 0.07),
                size: 56,
              ),
              const SizedBox(height: 6),
              Text(
                'Kaydır → fare  •  Dokun → tıkla',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.08),
                  fontSize: 12,
                ),
              ),
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
  const _WatchLayout({required this.ws});

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

    return Scaffold(
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
    );
  }
}
