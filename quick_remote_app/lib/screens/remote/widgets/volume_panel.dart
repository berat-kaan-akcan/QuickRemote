import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/throttler.dart';
import 'glass_panel.dart';

class VolumePanel extends StatefulWidget {
  final bool isConnected;
  final int volume; // 0-100, -1 = bilinmiyor
  final bool muted;
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final VoidCallback onMute;
  final void Function(int) onSetVolume;

  const VolumePanel({
    super.key,
    required this.isConnected,
    required this.volume,
    required this.muted,
    required this.onVolumeUp,
    required this.onVolumeDown,
    required this.onMute,
    required this.onSetVolume,
  });

  @override
  State<VolumePanel> createState() => _VolumePanelState();
}

class _VolumePanelState extends State<VolumePanel> {
  double? _localVolume;
  Timer? _localVolumeTimeout;
  final EventThrottler _volumeThrottler = EventThrottler(
    delay: const Duration(milliseconds: 150),
  );

  double get _displayVolume {
    if (_localVolume != null) return _localVolume!;
    if (widget.volume >= 0) return widget.volume.toDouble();
    return 0.0;
  }

  @override
  void didUpdateWidget(covariant VolumePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_localVolume != null &&
        widget.volume >= 0 &&
        (widget.volume - _localVolume!).abs() < 1) {
      _clearLocalVolume();
    }
  }

  void _setLocalVolume(double value, {bool sendImmediately = false}) {
    final clamped = value.clamp(0, 100).toDouble();
    setState(() => _localVolume = clamped);
    _localVolumeTimeout?.cancel();
    _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
    if (sendImmediately) {
      widget.onSetVolume(clamped.round());
    } else {
      _volumeThrottler.throttle(() => widget.onSetVolume(clamped.round()));
    }
  }

  void _clearLocalVolume() {
    _localVolumeTimeout?.cancel();
    _localVolumeTimeout = null;
    if (mounted && _localVolume != null) {
      setState(() => _localVolume = null);
    }
  }

  @override
  void dispose() {
    _volumeThrottler.cancel();
    _localVolumeTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF38BDF8); // Lighter blue
    final isMuted = widget.muted;
    final volStr = widget.volume >= 0 ? '%${_displayVolume.toInt()}' : '–';

    return GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [
        accent.withValues(alpha: 0.15),
        accent.withValues(alpha: 0.05),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mute butonu
              GestureDetector(
                onTap: widget.isConnected
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onMute();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMuted
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMuted
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: isMuted ? Colors.redAccent : accent,
                        size: 16,
                        shadows: (!isMuted && _localVolume != null)
                            ? [Shadow(color: accent, blurRadius: 12)]
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMuted ? 'Sessiz' : 'Açık',
                        style: TextStyle(
                          color: isMuted ? Colors.redAccent : accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Yüzde Metni
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  volStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: widget.isConnected ? () {
                  final currentVol = _displayVolume;
                  final clamped = (currentVol - 2).clamp(0, 100).toDouble();
                  setState(() => _localVolume = clamped);
                  _localVolumeTimeout?.cancel();
                  _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
                  widget.onVolumeDown();
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_rounded, color: accent, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: accent.withValues(alpha: 0.2),
                    valueIndicatorColor: accent,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 4,
                    ),
                  ),
                  child: Slider(
                    value: _displayVolume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_displayVolume.toInt()}',
                    onChanged: widget.isConnected ? _setLocalVolume : null,
                    onChangeEnd: widget.isConnected
                        ? (v) => _setLocalVolume(v, sendImmediately: true)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.isConnected ? () {
                  final currentVol = _displayVolume;
                  final clamped = (currentVol + 2).clamp(0, 100).toDouble();
                  setState(() => _localVolume = clamped);
                  _localVolumeTimeout?.cancel();
                  _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
                  widget.onVolumeUp();
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: accent, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
