import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/throttler.dart';
import 'glass_panel.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

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

  void _stepDown() {
    final currentVol = _displayVolume;
    final clamped = (currentVol - 2).clamp(0, 100).toDouble();
    setState(() => _localVolume = clamped);
    _localVolumeTimeout?.cancel();
    _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
    widget.onVolumeDown();
  }

  void _stepUp() {
    final currentVol = _displayVolume;
    final clamped = (currentVol + 2).clamp(0, 100).toDouble();
    setState(() => _localVolume = clamped);
    _localVolumeTimeout?.cancel();
    _localVolumeTimeout = Timer(const Duration(seconds: 3), _clearLocalVolume);
    widget.onVolumeUp();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.info;
    final isMuted = widget.muted;
    final volStr = widget.volume >= 0 ? '%${_displayVolume.toInt()}' : '–';
    final muteColor = isMuted ? p.danger : accent;

    return GlassPanel(
      accent: accent,
      child: Column(
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: IconBadge(
                  key: ValueKey(isMuted),
                  icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: muteColor,
                  size: 44,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              // Yüzde Metni
              Expanded(
                child: Text(
                  volStr,
                  style: AppType.numeric.copyWith(
                    color: isMuted ? p.textMuted : p.textPrimary,
                    fontSize: 30,
                    decoration: isMuted ? TextDecoration.lineThrough : null,
                    decorationColor: p.textMuted,
                  ),
                ),
              ),
              // Mute butonu
              Pressable(
                onTap: widget.isConnected
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onMute();
                      }
                    : null,
                semanticLabel: isMuted ? context.l10n.volumeMuted : context.l10n.volumeOn,
                selected: isMuted,
                borderRadius: AppRadius.all(AppRadius.pill),
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.base),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md - 2),
                  decoration: BoxDecoration(
                    color: muteColor.withValues(alpha: p.isDark ? 0.16 : 0.10),
                    borderRadius: AppRadius.all(AppRadius.pill),
                    border: Border.all(color: muteColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: muteColor,
                        size: 18,
                        shadows: (!isMuted && _localVolume != null)
                            ? [Shadow(color: accent, blurRadius: 12)]
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMuted ? context.l10n.volumeMuted : context.l10n.volumeOn,
                        style: AppType.labelSmall.copyWith(color: muteColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                color: accent,
                onTap: widget.isConnected ? _stepDown : null,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.18),
                    thumbColor: Colors.white,
                    overlayColor: accent.withValues(alpha: 0.16),
                    valueIndicatorColor: accent,
                    valueIndicatorTextStyle: AppType.labelSmall.copyWith(color: p.onInfo),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 11,
                      elevation: 3,
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
              _StepButton(
                icon: Icons.add_rounded,
                color: accent,
                onTap: widget.isConnected ? _stepUp : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.88,
      borderRadius: AppRadius.all(AppRadius.pill),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: p.isDark ? 0.14 : 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
