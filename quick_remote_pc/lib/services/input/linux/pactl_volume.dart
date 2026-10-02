import 'dart:io';
import 'package:flutter/foundation.dart';
import '../input_service.dart';

/// System volume through `pactl` (PulseAudio and PipeWire-Pulse).
class PactlVolume {
  static const _sink = '@DEFAULT_SINK@';
  // Same step as Windows media keys.
  static const step = 2;

  /// pactl localizes its output ("Mute: no" → "Sessiz: hayır"), so force C.
  static const _env = {'LC_ALL': 'C'};

  Future<ProcessResult?> _pactl(List<String> args) async {
    try {
      return await Process.run('pactl', args, environment: _env);
    } catch (e) {
      debugPrint('pactl not available: $e');
      return null;
    }
  }

  Future<VolumeState?> getState() async {
    final vol = await _pactl(['get-sink-volume', _sink]);
    final mute = await _pactl(['get-sink-mute', _sink]);
    if (vol == null || mute == null || vol.exitCode != 0 || mute.exitCode != 0) return null;
    final volume = parseVolume(vol.stdout as String);
    final muted = parseMute(mute.stdout as String);
    if (volume == null || muted == null) return null;
    return (volume: volume, muted: muted);
  }

  Future<void> _changes = Future.value();

  /// Changes run one after another: two quick presses read the level in turn
  /// instead of both reading the old one and counting as a single step.
  Future<void> change(int delta) => _changes = _changes.then((_) async {
        final current = await getState();
        if (current == null) return;
        await setLevel(current.volume + delta);
      });

  Future<void> setLevel(int level) async {
    await _pactl(['set-sink-volume', _sink, '${level.clamp(0, 100)}%']);
  }

  Future<void> toggleMute() async {
    await _pactl(['set-sink-mute', _sink, 'toggle']);
  }

  /// "Volume: front-left: 32768 /  50% / -18.06 dB, ..." → 50
  @visibleForTesting
  static int? parseVolume(String output) {
    final match = RegExp(r'(\d+)%').firstMatch(output);
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// "Mute: yes" → true
  @visibleForTesting
  static bool? parseMute(String output) {
    final match = RegExp(r'Mute:\s*(yes|no)').firstMatch(output);
    return match == null ? null : match.group(1) == 'yes';
  }
}
