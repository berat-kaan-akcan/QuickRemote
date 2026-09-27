import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../input_simulator.dart';

class StateBroadcaster {
  bool _isPolling = false;
  Timer? _volumeStateTimer;
  Map<String, dynamic>? _lastSlideState;
  int _pptNotRunningSkipCount = 0;
  int _lastBroadcastVolume = -1;
  bool _lastBroadcastMuted = false;

  final void Function(Map<String, dynamic> message) onBroadcast;
  final bool Function() hasClients;

  StateBroadcaster({required this.onBroadcast, required this.hasClients});

  void startSlideStatePoller() {
    if (_isPolling) return;
    _isPolling = true;
    _pptNotRunningSkipCount = 0;
    _pollLoop();
  }

  Future<void> _pollLoop() async {
    while (_isPolling) {
      await fetchAndBroadcastSmtcState();
      await broadcastVolumeState();
      
      if (_pptNotRunningSkipCount > 0) {
        _pptNotRunningSkipCount--;
      } else {
        await fetchAndBroadcastSlideState();
      }

      if (!_isPolling) break;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void stop() {
    _isPolling = false;
    _volumeStateTimer?.cancel();
    _volumeStateTimer = null;
    _lastSlideState = null;
  }

  void scheduleVolumeStateBroadcast() {
    _volumeStateTimer?.cancel();
    _volumeStateTimer = Timer(
      const Duration(milliseconds: 350),
      broadcastVolumeState,
    );
  }

  Future<void> fetchAndBroadcastSmtcState() async {
    if (!hasClients()) return;
    
    final smtcState = await InputSimulator.getSmtcState();
    if (smtcState != null) {
      onBroadcast({
        'type': 'SMTC_STATE',
        'hasMedia': smtcState['hasMedia'] ?? false,
        'title': smtcState['title'],
        'artist': smtcState['artist'],
        'positionMs': smtcState['positionMs'] ?? 0,
        'durationMs': smtcState['durationMs'] ?? 0,
        'isPlaying': smtcState['isPlaying'] ?? false,
        'thumbnail': smtcState['thumbnail'],
      });
    }
  }

  Future<void> fetchAndBroadcastSlideState() async {
    if (!hasClients()) return;

    final state = await InputSimulator.getSlideState();
    if (state != null) {
      if (state['error'] == 'POWERPOINT_NOT_RUNNING') {
        _pptNotRunningSkipCount = 3;
        if (_lastSlideState == null || _lastSlideState!['error'] != 'POWERPOINT_NOT_RUNNING') {
          _lastSlideState = state;
          onBroadcast({
            'type': 'STATUS',
            'state': 'POWERPOINT_NOT_RUNNING',
          });
          onBroadcast({
            'type': 'SLIDE_STATE',
            'data': null,
          });
        }
        return;
      }

      _pptNotRunningSkipCount = 0;

      final current = state['current'];
      final total = state['total'];
      final notes = state['notes'];

      if (_lastSlideState == null ||
          _lastSlideState!['current'] != current ||
          _lastSlideState!['total'] != total ||
          _lastSlideState!['notes'] != notes ||
          _lastSlideState!['hasMedia'] != state['hasMedia'] ||
          _lastSlideState!['isMediaPlaying'] != state['isMediaPlaying'] ||
          _lastSlideState!['error'] != null) {
        
        _lastSlideState = state;
        
        onBroadcast({
          'type': 'SLIDE_STATE',
          'current': current,
          'total': total,
          'notes': notes,
          'hasMedia': state['hasMedia'] ?? false,
          'isMediaPlaying': state['isMediaPlaying'] ?? false,
        });
      }
    }
  }

  void triggerSlideStateUpdate([Duration delay = Duration.zero]) {
    if (delay == Duration.zero) {
      fetchAndBroadcastSmtcState();
      fetchAndBroadcastSlideState();
    } else {
      Future.delayed(delay, () {
        fetchAndBroadcastSmtcState();
        fetchAndBroadcastSlideState();
      });
    }
  }

  Future<void> broadcastVolumeState({bool force = false}) async {
    if (!hasClients()) return;
    final script = '''
try {
\${InputSimulator.getAudioControlPSScript()}
    \$lv = [AudioControl.Audio]::GetVolume()
    \$mu = [AudioControl.Audio]::GetMute()
    Write-Output "{`"volume`":\$([int](\$lv * 100)),`"muted`":\$(if(\$mu){`"true`"}else{`"false`"})}"
} catch {
    Write-Output "ERROR"
}
''';
    try {
      final output = await InputSimulator.runPowerShellScript(script, isPolling: true);
      if (output.startsWith('{')) {
        final data = jsonDecode(output) as Map<String, dynamic>;
        final volume = (data['volume'] as num?)?.toInt() ?? -1;
        final muted = data['muted'] as bool? ?? false;
        if (force || volume != _lastBroadcastVolume || muted != _lastBroadcastMuted) {
          _lastBroadcastVolume = volume;
          _lastBroadcastMuted = muted;
          onBroadcast({
            'type': 'STATUS',
            'state': 'VOLUME_CHANGED',
            'volume': volume,
            'muted': muted,
          });
        }
      }
    } catch (e) {
      debugPrint('broadcastVolumeState error: \$e');
    }
  }

  int get lastBroadcastVolume => _lastBroadcastVolume;
  bool get lastBroadcastMuted => _lastBroadcastMuted;
  Map<String, dynamic>? get lastSlideState => _lastSlideState;
}
