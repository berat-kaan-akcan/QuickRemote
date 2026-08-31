import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/websocket_service.dart';
import '../widgets/presentation_timer.dart';
import 'settings_screen.dart';

final GlobalKey _presentationTimerKeyMain = GlobalKey();
final GlobalKey _presentationTimerKeyTouchpad = GlobalKey();

enum _DrawTool { laser, pen, highlighter, eraser }

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
  bool _wasConnected = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wsRef = context.read<WebSocketService>();
      _wasConnected = _wsRef.isConnected;
      _wsRef.addListener(_onConnectionChanged);
    });
  }

  void _onConnectionChanged() {
    if (!mounted) return;
    
    if (_wasConnected && !_wsRef.isConnected) {
      _wasConnected = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı koptu, otomatik bağlanılıyor...'),
          backgroundColor: Color(0xFFFF9800),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (!_wasConnected && _wsRef.isConnected) {
      _wasConnected = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeniden bağlanıldı!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _wsRef.removeListener(_onConnectionChanged);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();

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

  void _showNotesDialog(BuildContext context, String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notes_rounded, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text('Konuşmacı Notları', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            notes,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
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
        resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, ws),
              const SizedBox(height: 24),
              PresentationTimer(key: _presentationTimerKeyMain),

              if (ws.totalSlides > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.slideshow_rounded, color: Color(0xFF6C63FF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Slayt: ${ws.currentSlide} / ${ws.totalSlides}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ws.slideNotes.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showNotesDialog(context, ws.slideNotes),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.notes_rounded, color: Color(0xFF6C63FF), size: 16),
                                SizedBox(width: 4),
                                Text('Notlar', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

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
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _send(ws, 'START');
                            },
                            onLongPress: () {
                              HapticFeedback.heavyImpact();
                              _showStartSlideDialog(context, ws);
                            },
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
                  Text(
                    ws.totalSlides > 0 ? 'Touchpad (Slayt: ${ws.currentSlide}/${ws.totalSlides})' : 'Touchpad',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white54, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
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
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        _send(ws, 'START');
                      },
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        _showStartSlideDialog(context, ws);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Color(0xFF4CAF50), size: 18),
                            SizedBox(width: 4),
                            Text('Başlat', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PresentationTimer(key: _presentationTimerKeyTouchpad),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _send(ws, 'END'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop_rounded, color: Color(0xFFFF5252), size: 18),
                            SizedBox(width: 4),
                            Text('Bitir', style: TextStyle(color: Color(0xFFFF5252), fontSize: 12, fontWeight: FontWeight.w600)),
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
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showColorPicker(context, ws, _DrawTool.pen);
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
                        setState(() => _drawTool = _DrawTool.highlighter);
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showColorPicker(context, ws, _DrawTool.highlighter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _drawTool == _DrawTool.highlighter
                              ? const Color(0xFFFFEA00).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _drawTool == _DrawTool.highlighter
                                ? const Color(0xFFFFEA00).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.border_color, size: 14,
                                color: _drawTool == _DrawTool.highlighter
                                    ? const Color(0xFFFFEA00)
                                    : Colors.white38),
                            const SizedBox(width: 4),
                            Text('Vurgulayıcı',
                                style: TextStyle(
                                  color: _drawTool == _DrawTool.highlighter
                                      ? const Color(0xFFFFEA00)
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

  void _showStartSlideDialog(BuildContext context, WebSocketService ws) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Sunuma Başla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Slayt Numarası (Örn: 5)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              helperText: 'Boş bırakırsanız baştan başlar.',
              helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (value) {
              final slideNumber = value.trim();
              if (slideNumber.isNotEmpty) {
                _send(ws, 'START_AT:$slideNumber');
              } else {
                _send(ws, 'START');
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              onPressed: () {
                final slideNumber = controller.text.trim();
                if (slideNumber.isNotEmpty) {
                  _send(ws, 'START_AT:$slideNumber');
                } else {
                  _send(ws, 'START');
                }
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Başlat', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, WebSocketService ws, _DrawTool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = [
          {'name': 'Kırmızı', 'color': const Color(0xFFFF1744), 'cmd': 'SET_PEN_COLOR:255'},
          {'name': 'Mavi', 'color': const Color(0xFF2979FF), 'cmd': 'SET_PEN_COLOR:16711680'},
          {'name': 'Yeşil', 'color': const Color(0xFF00E676), 'cmd': 'SET_PEN_COLOR:65280'},
          {'name': 'Sarı', 'color': const Color(0xFFFFEA00), 'cmd': 'SET_PEN_COLOR:65535'},
          {'name': 'Beyaz', 'color': const Color(0xFFFFFFFF), 'cmd': 'SET_PEN_COLOR:16777215'},
          {'name': 'Mor', 'color': const Color(0xFFD500F9), 'cmd': 'SET_PEN_COLOR:8388736'},
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                  // Drag Handle
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool == _DrawTool.pen ? Icons.edit : Icons.border_color,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tool == _DrawTool.pen ? 'Kalem' : 'Vurgulayıcı'} Rengi',
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
                  
                  // Color Grid
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: colors.map((c) {
                      final color = c['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _send(ws, c['cmd'] as String);
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
                  
                  // Cancel Button
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
          icon: const Icon(Icons.settings, color: Colors.white54, size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54, size: 22),
          onPressed: () async {
            final shouldPop = await _showExitDialog();
            if (shouldPop) {
              ws.removeListener(_onConnectionChanged);
              ws.disconnect();
              if (context.mounted) Navigator.of(context).pop();
            }
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
  _DrawTool _activeTool = _DrawTool.laser;

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.localPosition;

    bool isDoubleTap = _lastPointerUpTime != null &&
        _lastPointerUpPosition != null &&
        now.difference(_lastPointerUpTime!).inMilliseconds < 350 &&
        (pos - _lastPointerUpPosition!).distance < 60;

    _isDrawActive = true;
    _activeTool = isDoubleTap ? widget.drawTool : _DrawTool.laser;

    if (_activeTool == _DrawTool.pen) {
      widget.ws.sendCommand('MODE_PEN');
    } else if (_activeTool == _DrawTool.highlighter) {
      widget.ws.sendCommand('MODE_HIGHLIGHTER');
    } else if (_activeTool == _DrawTool.eraser) {
      widget.ws.sendCommand('MODE_ERASER');
    } else if (_activeTool == _DrawTool.laser) {
      widget.ws.sendCommand('MODE_LASER');
    }
    
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_isDrawActive && mounted) {
        if (_activeTool != _DrawTool.laser) {
          widget.ws.sendCommand('LEFT_DOWN');
        }
      }
    });
    HapticFeedback.mediumImpact();

    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawActive) return;

    final dx = event.delta.dx * widget.sensitivity;
    final dy = event.delta.dy * widget.sensitivity;

    widget.ws.sendRaw({
      'type': _activeTool == _DrawTool.laser ? 'LASER' : 'TOUCH',
      'dx': dx,
      'dy': dy,
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    final now = DateTime.now();
    _lastPointerUpTime = now;
    _lastPointerUpPosition = event.localPosition;

    if (_isDrawActive) {
      if (_activeTool == _DrawTool.laser) {
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

    if (_isDrawActive && _activeTool == _DrawTool.pen) {
      borderColor = const Color(0xFF00E676);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == _DrawTool.highlighter) {
      borderColor = const Color(0xFFFFEA00);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == _DrawTool.eraser) {
      borderColor = const Color(0xFFFF9800);
      borderWidth = 2.5;
    } else if (_isDrawActive && _activeTool == _DrawTool.laser) {
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
              if (_isDrawActive && _activeTool == _DrawTool.pen) ...[
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
              ] else if (_isDrawActive && _activeTool == _DrawTool.highlighter) ...[
                Icon(Icons.border_color,
                    color: const Color(0xFFFFEA00).withValues(alpha: 0.3),
                    size: 48),
                const SizedBox(height: 8),
                Text('Vurgulayıcı',
                    style: TextStyle(
                      color: const Color(0xFFFFEA00).withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ] else if (_isDrawActive && _activeTool == _DrawTool.eraser) ...[
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
              ] else if (_isDrawActive && _activeTool == _DrawTool.laser) ...[
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
                Text('Tek dokunuş → Lazer',
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
  final VoidCallback? onLongPress;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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

