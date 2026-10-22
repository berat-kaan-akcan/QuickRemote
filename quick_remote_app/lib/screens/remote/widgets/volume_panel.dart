import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/throttler.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import 'media_labels.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class VolumePanel extends StatefulWidget {
  final bool isConnected;

  /// False where the computer tells nothing (a Bluetooth keyboard): only the
  /// mute and step keys, no slider, level or mute state.
  final bool levelKnown;
  final int volume; // 0-100, -1 = bilinmiyor
  final bool muted;
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final VoidCallback onMute;
  final void Function(int) onSetVolume;

  const VolumePanel({
    super.key,
    required this.isConnected,
    this.levelKnown = true,
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
    final isMuted = widget.muted;
    final known = widget.volume >= 0;
    final percent = known
        ? NumberFormat.percentPattern(Localizations.localeOf(context).toLanguageTag()).format(_displayVolume / 100)
        : '–';
    final muteColor = isMuted ? p.danger : p.textPrimary;
    // Unknown: the key toggles mute, whatever the state.
    final muteLabel = !widget.levelKnown
        ? context.l10n.volumeMuteToggle
        : isMuted ? context.l10n.volumeMuted : context.l10n.volumeOn;
    final connected = widget.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MediaSectionHeader(
          icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          label: context.l10n.systemVolume,
          trailing: widget.levelKnown
              ? Text(
                  percent,
                  style: AppType.numeric.copyWith(color: isMuted ? p.textMuted : p.textPrimary, fontSize: 18, letterSpacing: 0),
                )
              : null,
        ),
        const SizedBox(height: AppSpace.sm),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadius.all(AppRadius.lg),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              if (widget.levelKnown) ...[
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: p.primaryBright,
                  inactiveTrackColor: p.surfaceSunken,
                  thumbColor: AppColors.white,
                  overlayColor: p.primaryBright.withValues(alpha: 0.16),
                  valueIndicatorColor: p.primary,
                  valueIndicatorTextStyle: AppType.labelSmall.copyWith(color: p.onPrimary),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 2),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _displayVolume,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_displayVolume.toInt()}',
                  onChanged: connected ? _setLocalVolume : null,
                  onChangeEnd: connected ? (v) => _setLocalVolume(v, sendImmediately: true) : null,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              ],
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: connected
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onMute();
                            }
                          : null,
                      semanticLabel: muteLabel,
                      selected: widget.levelKnown && isMuted,
                      minTarget: 48,
                      borderRadius: AppRadius.all(AppRadius.md),
                      child: AnimatedContainer(
                        duration: AppMotion.of(context, AppMotion.base),
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.all(AppRadius.md),
                          border: Border.all(color: p.border, width: 1.5),
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isMuted || !widget.levelKnown ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: muteColor, size: 19),
                              const SizedBox(width: AppSpace.xs),
                              Flexible(
                                child: Text(
                                  muteLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.label.copyWith(color: muteColor, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _StepButton(
                    icon: Icons.remove_rounded,
                    label: context.l10n.volumeDown,
                    onTap: connected ? _stepDown : null,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _StepButton(
                    icon: Icons.add_rounded,
                    label: context.l10n.volumeUp,
                    onTap: connected ? _stepUp : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      tooltip: label,
      pressedScale: 0.88,
      minTarget: 48,
      borderRadius: AppRadius.all(AppRadius.sm),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.all(AppRadius.sm),
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, color: p.textPrimary, size: 22),
      ),
    );
  }
}
