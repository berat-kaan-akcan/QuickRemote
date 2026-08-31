import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/settings_provider.dart';

class PresentationTimer extends StatefulWidget {
  const PresentationTimer({super.key});

  @override
  State<PresentationTimer> createState() => _PresentationTimerState();
}

class _PresentationTimerState extends State<PresentationTimer> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _targetSeconds = 0; // 0 means just count up
  bool _isRunning = false;
  bool _isDurationSelected = false;
  DateTime? _startTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (!_isDurationSelected) {
        // If not started yet, ask for duration first
        _showDurationPicker();
      } else {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    HapticFeedback.lightImpact();
    setState(() => _isRunning = true);
    
    // Set or resume start time
    _startTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
    
    // Run timer more frequently (e.g., 500ms) so it instantly updates when coming from background
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _startTime == null) return;
      
      final now = DateTime.now();
      final newElapsed = now.difference(_startTime!).inSeconds;
      
      if (newElapsed != _elapsedSeconds) {
        setState(() {
          _elapsedSeconds = newElapsed;
        });
        
        if (_targetSeconds > 0) {
          int remaining = _targetSeconds - _elapsedSeconds;
          final shouldWarn = context.read<SettingsProvider>().earlyWarningHaptic;
          
          if ((remaining == 60 || remaining == 30) && shouldWarn) {
            // Erken Uyarı: Çift güçlü titreşim (Bzz-Bzz)
            Vibration.vibrate(pattern: [0, 300, 100, 300]);
          } else if (remaining == 0) {
            // Süre Doldu: 3'lü güçlü titreşim
            Vibration.vibrate(pattern: [0, 500, 150, 500, 150, 800]); 
          }
        }
      }
    });
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
      _targetSeconds = 0;
      _isDurationSelected = false;
      _startTime = null;
    });
  }

  void _showDurationPicker() {
    HapticFeedback.mediumImpact();
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sunum Süresi Belirle',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _DurationChip(label: 'Serbest', minutes: 0, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '5 dk', minutes: 5, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '10 dk', minutes: 10, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '15 dk', minutes: 15, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '20 dk', minutes: 20, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '30 dk', minutes: 30, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '45 dk', minutes: 45, onTap: (m) => _setDuration(ctx, m)),
                  _DurationChip(label: '60 dk', minutes: 60, onTap: (m) => _setDuration(ctx, m)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Özel süre girin (dk)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                      onSubmitted: (val) {
                        final m = int.tryParse(val);
                        if (m != null && m > 0) {
                          _setDuration(ctx, m);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Lütfen geçerli bir süre (tam sayı, saniye) girin.')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final m = int.tryParse(customController.text);
                      if (m != null && m > 0) {
                        _setDuration(ctx, m);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Lütfen geçerli bir süre (tam sayı, saniye) girin.')),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ayarla', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Sayaç üzerine basılı tutarak sıfırlayabilirsiniz.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _setDuration(BuildContext ctx, int minutes) {
    Navigator.of(ctx).pop();
    setState(() {
      _targetSeconds = minutes * 60;
      _elapsedSeconds = 0;
      _isDurationSelected = true;
      _startTime = null;
    });
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    bool isOvertime = _targetSeconds > 0 && _elapsedSeconds > _targetSeconds;
    int displaySeconds = _targetSeconds > 0
        ? (_targetSeconds - _elapsedSeconds).abs()
        : _elapsedSeconds;

    String timeStr = _formatTime(displaySeconds);
    if (isOvertime) {
      timeStr = '+$timeStr';
    }

    Color textColor = isOvertime ? const Color(0xFFFF5252) : Colors.white;
    Color bgColor = isOvertime
        ? const Color(0xFFFF5252).withValues(alpha: 0.15)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
    Color borderColor = isOvertime
        ? const Color(0xFFFF5252).withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: _toggleTimer,
      onLongPress: () {
        if (_isRunning || _elapsedSeconds > 0 || _isDurationSelected) {
          _resetTimer();
        } else {
          _showDurationPicker();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: textColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (_isRunning || _elapsedSeconds > 0 || _isDurationSelected) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _resetTimer,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: textColor,
                    size: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final int minutes;
  final Function(int) onTap;

  const _DurationChip({required this.label, required this.minutes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF262C4A),
      side: BorderSide.none,
      onPressed: () => onTap(minutes),
    );
  }
}
