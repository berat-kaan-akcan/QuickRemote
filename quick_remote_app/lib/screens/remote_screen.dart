import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/websocket_service.dart';
import '../widgets/presentation_timer.dart';
import '../utils/throttler.dart';
import 'settings_screen.dart';
import 'analytics_report_screen.dart';
import '../providers/settings_provider.dart';


enum _DrawTool { laser, pen, highlighter, eraser, screen }

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
  String _screenCommand = 'BLACK_SCREEN';
  final GlobalKey _presentationTimerKeyMain = GlobalKey();
  final GlobalKey _presentationTimerKeyTouchpad = GlobalKey();
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
    
    // Check for auto-completed analytics (presentation ended naturally)
    if (_wsRef.completedAnalytics != null) {
      final analytics = _wsRef.completedAnalytics!;
      _wsRef.clearCompletedAnalytics();
      
      // Save to history
      final settings = context.read<SettingsProvider>();
      settings.savePresentationAnalytics(analytics);
      
      // Show report
      AnalyticsReportScreen.showAsBottomSheet(context, analytics);
    }

    // Check for command errors
    if (_wsRef.lastCommandError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_wsRef.lastCommandError!),
          backgroundColor: const Color(0xFFFF5252),
          duration: const Duration(seconds: 3),
        ),
      );
      _wsRef.clearCommandError();
    }

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
    final int currentIndex = _touchpadMode ? 1 : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_touchpadMode) {
          setState(() {
            _touchpadMode = false;
          });
          if (!ws.isConnected && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bağlantı koptu, komut gönderilemedi.', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFFFF9800),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ws.sendCommand('MODE_ARROW');
          }
          return;
        }
        final shouldPop = await _showExitDialog();
        if (shouldPop) {
          ws.removeListener(_onConnectionChanged);
          ws.disconnect();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        resizeToAvoidBottomInset: false,
        body: ws.connectionState == AppConnectionState.failed
            ? _buildFailedView(ws)
            : (_touchpadMode ? _buildTouchpadView(ws) : _buildMainView(ws)),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF0F172A),
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Colors.white38,
            currentIndex: currentIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _touchpadMode = index == 1;
              });
              if (!_touchpadMode) {
                ws.sendCommand('MODE_ARROW');
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.gamepad_rounded), label: 'Kontroller'),
              BottomNavigationBarItem(icon: Icon(Icons.touch_app_rounded), label: 'Touchpad'),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
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

  Widget _buildFailedView(WebSocketService ws) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Bağlantı Kurulamadı',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sunucuya ulaşılamıyor. Lütfen PC uygulamasının açık olduğundan emin olun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ws.manualReconnect(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yeniden Bağlan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ws.removeListener(_onConnectionChanged);
              ws.disconnect();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(BuildContext context, String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notes_rounded, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text('Konuşmacı Notları', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  // ─── Ekran 1: Ana Kontroller ───
  Widget _buildMainView(WebSocketService ws) {
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, ws),
              const SizedBox(height: 24),
              PresentationTimer(
                key: _presentationTimerKeyMain,
                fontSize: 16.0,
                iconSize: 20.0,
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.slideshow_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Slayt: ${ws.isPptRunning && ws.totalSlides > 0 ? ws.currentSlide : 0} / ${ws.isPptRunning && ws.totalSlides > 0 ? ws.totalSlides : 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (ws.isPptRunning && ws.slideNotes.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _showNotesDialog(context, ws.slideNotes),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notes_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                              const SizedBox(width: 4),
                              Text('Notlar', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!ws.isPptRunning) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Sunum Açık Değil, PowerPoint\'i başlatın',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                            onTap: !ws.isConnected ? null : () {
                              HapticFeedback.heavyImpact();
                              ws.startTracking();
                              _send(ws, 'START');
                            },
                            onLongPress: !ws.isConnected ? null : () {
                              HapticFeedback.heavyImpact();
                              ws.startTracking();
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
                            onTap: !ws.isConnected ? null : () {
                              _send(ws, 'END');
                              _finishAndShowAnalytics(context, ws);
                            },
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
                            onTap: !ws.isConnected ? null : () => _send(ws, 'PREV'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SlideButton(
                            icon: Icons.arrow_forward_rounded,
                            label: 'İleri',
                            isPrimary: true,
                            onTap: !ws.isConnected ? null : () => _send(ws, 'NEXT'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Black / White Screen
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.dark_mode_rounded,
                            label: 'Siyah Ekran',
                            color: Colors.grey,
                            onTap: !ws.isConnected ? null : () {
                              HapticFeedback.lightImpact();
                              _send(ws, 'BLACK_SCREEN');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.light_mode_rounded,
                            label: 'Beyaz Ekran',
                            color: Colors.white70,
                            onTap: !ws.isConnected ? null : () {
                              HapticFeedback.lightImpact();
                              _send(ws, 'WHITE_SCREEN');
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Lock
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        icon: Icons.lock_rounded,
                        label: 'PC Kilitle',
                        color: const Color(0xFFFF9800),
                        onTap: !ws.isConnected ? null : () => _send(ws, 'LOCK'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ─── Ekran 2: Touchpad Modu ───
  Widget _buildTouchpadView(WebSocketService ws) {
    return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top bar with back button
                Row(
                  children: [

                  const Text(
                    'Touchpad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 22),
                    tooltip: 'Ayarlar',
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
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, color: Colors.white60, size: 16),
                        Expanded(
                          child: Slider(
                            value: _sensitivity,
                            min: 2,
                            max: 20,
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Colors.white10,
                            onChanged: (v) => setState(() => _sensitivity = v),
                          ),
                        ),
                        Text(
                          '${_sensitivity.toInt()}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F38),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.slideshow_rounded, color: Theme.of(context).colorScheme.primary, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${ws.isPptRunning && ws.totalSlides > 0 ? ws.currentSlide : 0} / ${ws.isPptRunning && ws.totalSlides > 0 ? ws.totalSlides : 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: !ws.isConnected ? null : () {
                        HapticFeedback.heavyImpact();
                        _send(ws, 'START');
                      },
                      onLongPress: !ws.isConnected ? null : () {
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Color(0xFF4CAF50), size: 18),
                            const SizedBox(width: 4),
                            const Text('Başlat', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down_rounded, color: const Color(0xFF4CAF50).withValues(alpha: 0.7), size: 16),
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
                      onTap: !ws.isConnected ? null : () => _send(ws, 'END'),
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
              // Draw tool selector (for double-tap mode)
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
                            setState(() => _drawTool = _DrawTool.laser);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.highlight_rounded, size: 14,
                                    color: _drawTool == _DrawTool.laser
                                        ? const Color(0xFFFF1744)
                                        : Colors.white38),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Lazer',
                                        style: TextStyle(
                                          color: _drawTool == _DrawTool.laser
                                              ? const Color(0xFFFF1744)
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        )),
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
                            if (_drawTool == _DrawTool.pen) {
                              _showColorPicker(context, ws, _DrawTool.pen);
                            } else {
                              setState(() => _drawTool = _DrawTool.pen);
                            }
                          },
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showColorPicker(context, ws, _DrawTool.pen);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 14,
                                    color: _drawTool == _DrawTool.pen
                                        ? const Color(0xFF00E676)
                                        : Colors.white38),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Kalem',
                                        style: TextStyle(
                                          color: _drawTool == _DrawTool.pen
                                              ? const Color(0xFF00E676)
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down_rounded, size: 16, 
                                    color: _drawTool == _DrawTool.pen ? const Color(0xFF00E676) : Colors.white54),
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
                            if (_drawTool == _DrawTool.highlighter) {
                              _showColorPicker(context, ws, _DrawTool.highlighter);
                            } else {
                              setState(() => _drawTool = _DrawTool.highlighter);
                            }
                          },
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showColorPicker(context, ws, _DrawTool.highlighter);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.border_color_rounded, size: 14,
                                    color: _drawTool == _DrawTool.highlighter
                                        ? const Color(0xFFFFEA00)
                                        : Colors.white38),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Vurgula',
                                        style: TextStyle(
                                          color: _drawTool == _DrawTool.highlighter
                                              ? const Color(0xFFFFEA00)
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down_rounded, size: 16, 
                                    color: _drawTool == _DrawTool.highlighter ? const Color(0xFFFFEA00) : Colors.white54),
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
                            setState(() => _drawTool = _DrawTool.eraser);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_fix_high_rounded, size: 14,
                                    color: _drawTool == _DrawTool.eraser
                                        ? const Color(0xFFFF9800)
                                        : Colors.white38),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Silgi',
                                        style: TextStyle(
                                          color: _drawTool == _DrawTool.eraser
                                              ? const Color(0xFFFF9800)
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        )),
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
                      label: 'Ekran',
                      child: Tooltip(
                        message: 'Ekran Aracı',
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (_drawTool == _DrawTool.screen) {
                              _showScreenColorPicker(context, ws);
                            } else {
                              setState(() => _drawTool = _DrawTool.screen);
                              _send(ws, _screenCommand);
                            }
                          },
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showScreenColorPicker(context, ws);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                            decoration: BoxDecoration(
                              color: _drawTool == _DrawTool.screen
                                  ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2))
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _drawTool == _DrawTool.screen
                                    ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5))
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _screenCommand == 'BLACK_SCREEN' ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  size: 14, 
                                  color: _drawTool == _DrawTool.screen
                                      ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey : Colors.white)
                                      : Colors.white38
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(_screenCommand == 'BLACK_SCREEN' ? 'Siyah' : 'Beyaz',
                                        style: TextStyle(
                                          color: _drawTool == _DrawTool.screen
                                              ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey : Colors.white)
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down_rounded, size: 16, 
                                    color: _drawTool == _DrawTool.screen 
                                        ? (_screenCommand == 'BLACK_SCREEN' ? Colors.grey : Colors.white) 
                                        : Colors.white54),
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
                    child: _SlideButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Geri',
                      onTap: !ws.isConnected ? null : () => _send(ws, 'PREV'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SlideButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'İleri',
                      isPrimary: true,
                      onTap: !ws.isConnected ? null : () => _send(ws, 'NEXT'),
                    ),
                  ),
                ],
              ),
            ],
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
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Sunuma Başla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: ws.totalSlides > 0 ? 'Slayt (1-${ws.totalSlides})' : 'Slayt Numarası (Örn: 5)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              helperText: ws.totalSlides > 0 ? 'Maksimum ${ws.totalSlides} slayt girebilirsiniz.' : 'Boş bırakırsanız baştan başlar.',
              helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (value) {
              final slideNumber = value.trim();
              if (slideNumber.isNotEmpty) {
                final parsed = int.tryParse(slideNumber);
                final maxSlide = ws.totalSlides > 0 ? ws.totalSlides : 9999;
                if (parsed == null || parsed <= 0 || parsed > maxSlide) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Geçerli bir slayt numarası girin (1-$maxSlide)')),
                  );
                  return;
                }
                _send(ws, 'START_AT:$parsed');
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
                  final parsed = int.tryParse(slideNumber);
                  final maxSlide = ws.totalSlides > 0 ? ws.totalSlides : 9999;
                  if (parsed == null || parsed <= 0 || parsed > maxSlide) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Geçerli bir slayt numarası girin (1-$maxSlide)')),
                    );
                    return;
                  }
                  _send(ws, 'START_AT:$parsed');
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
                color: const Color(0xFF1E293B).withValues(alpha: 0.75),
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
                        tool == _DrawTool.pen ? Icons.edit : Icons.border_color_rounded,
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

  void _showScreenColorPicker(BuildContext context, WebSocketService ws) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final options = [
          {'name': 'Siyah', 'color': Colors.black, 'cmd': 'BLACK_SCREEN', 'icon': Icons.dark_mode_rounded},
          {'name': 'Beyaz', 'color': Colors.white, 'cmd': 'WHITE_SCREEN', 'icon': Icons.light_mode_rounded},
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.75),
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
                        Icons.desktop_windows_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ekran Rengi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Options
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: options.map((opt) {
                      final color = opt['color'] as Color;
                      final icon = opt['icon'] as IconData;
                      final name = opt['name'] as String;
                      final cmd = opt['cmd'] as String;
                      final isSelected = _screenCommand == cmd;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _screenCommand = cmd;
                            _drawTool = _DrawTool.screen;
                          });
                          _send(ws, cmd);
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2979FF) : Colors.white.withValues(alpha: 0.5),
                                  width: isSelected ? 3.5 : 2,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    const BoxShadow(
                                      color: Color(0xFF2979FF),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: cmd == 'BLACK_SCREEN' ? Colors.white : Colors.black, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF2979FF) : Colors.white,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Color(0xFF00BCD4)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
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
        if (!ws.isConnected && ws.connectionState != AppConnectionState.failed)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
            onPressed: () {
              ws.manualReconnect();
            },
            tooltip: 'Yeniden Bağlan',
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
              if (ws.connectionState == AppConnectionState.reconnecting || ws.connectionState == AppConnectionState.connecting)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 5),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5252)),
                  ),
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: ws.isConnected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                ws.isConnected ? 'Bağlı' : (ws.connectionState == AppConnectionState.reconnecting || ws.connectionState == AppConnectionState.connecting ? 'Bağlanıyor...' : 'Kopuk'),
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
          icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 22),
          tooltip: 'Ayarlar',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
          tooltip: 'Kapat',
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

  /// Stop tracking, save analytics, and show report.
  void _finishAndShowAnalytics(BuildContext context, WebSocketService ws) {
    final analytics = ws.stopTracking();
    if (analytics == null || analytics.slideRecords.isEmpty) return;

    // Save to history
    final settings = context.read<SettingsProvider>();
    settings.savePresentationAnalytics(analytics);

    // Show report as bottom sheet
    AnalyticsReportScreen.showAsBottomSheet(context, analytics);
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

  // Throttling
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
        if (_activeTool != _DrawTool.laser && _activeTool != _DrawTool.screen) {
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
        (_activeTool == _DrawTool.laser || _activeTool == _DrawTool.screen) ? 'LASER' : 'TOUCH',
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
      if (_activeTool == _DrawTool.laser || _activeTool == _DrawTool.screen) {
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
    } else if (_isDrawActive && _activeTool == _DrawTool.screen) {
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
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: _isDrawActive
                  ? borderColor.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
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
                Icon(Icons.edit_rounded,
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
                Icon(Icons.border_color_rounded,
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
                Icon(Icons.auto_fix_high_rounded,
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
                Icon(Icons.highlight_rounded,
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
  final VoidCallback? onTap;

  const _SlideButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 140,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Theme.of(context).colorScheme.primary, Color(0xFF00BCD4)],
                  )
                : null,
            color: isPrimary ? null : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: isPrimary
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: Material(
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
              if (onLongPress != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.arrow_drop_down_rounded, color: color.withValues(alpha: 0.7), size: 16),
              ],
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }
}
