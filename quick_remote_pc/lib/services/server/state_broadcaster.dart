import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../input_simulator.dart';
import 'slide_previewer.dart';

class StateBroadcaster {
  bool _isPolling = false;
  /// Bumped on every start/stop so a loop still sleeping from a previous
  /// run exits instead of running next to the new one.
  int _generation = 0;
  Timer? _volumeStateTimer;
  Map<String, dynamic>? _lastSlideState;
  int _pptNotRunningSkipCount = 0;
  /// The last SMTC_STATE sent, without its cover, and the cover sent last
  /// ([_noThumbnail] until one was sent).
  String? _lastSmtcKey;
  Object? _lastThumbnail = _noThumbnail;
  static const _noThumbnail = Object();
  int _lastBroadcastVolume = -1;
  bool _lastBroadcastMuted = false;

  final void Function(Map<String, dynamic> message) onBroadcast;
  final bool Function() hasClients;

  /// Every slide state read: the show on screen, or null without one.
  final void Function(ShownSlide? shown)? onShow;

  StateBroadcaster({required this.onBroadcast, required this.hasClients, this.onShow});

  /// The deck id of a slide state: from the platform's `deckKey` (the file's
  /// path and when it was last saved) and the slide count.
  static int deckOf(Map<String, dynamic> state) =>
      SlideImageFrame.deckId('${state['deckKey'] ?? ''}|${state['total']}');

  void startSlideStatePoller() {
    if (_isPolling) return;
    _isPolling = true;
    _pptNotRunningSkipCount = 0;
    _pollLoop(++_generation);
  }

  Future<void> _pollLoop(int generation) async {
    bool current() => _isPolling && generation == _generation;
    while (current()) {
      // One failed poll must not end state updates for the rest of the session.
      await _guard('state poll', () async {
        await fetchAndBroadcastSmtcState();
        await broadcastVolumeState();

        if (_pptNotRunningSkipCount > 0) {
          _pptNotRunningSkipCount--;
        } else {
          await fetchAndBroadcastSlideState();
        }
      });

      if (!current()) break;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Future<void> _guard(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('StateBroadcaster: $what failed: $e');
    }
  }

  void stop() {
    _isPolling = false;
    _generation++;
    _volumeStateTimer?.cancel();
    _volumeStateTimer = null;
    _lastSlideState = null;
    resendSmtcInFull();
  }

  void scheduleVolumeStateBroadcast() {
    _volumeStateTimer?.cancel();
    _volumeStateTimer = Timer(
      const Duration(milliseconds: 350),
      () => _guard('volume broadcast', broadcastVolumeState),
    );
  }

  Future<void> fetchAndBroadcastSmtcState() async {
    if (!hasClients()) return;
    
    final smtcState = await InputSimulator.getSmtcState();
    if (smtcState == null) return;
    final message = <String, dynamic>{
      'type': 'SMTC_STATE',
      'hasMedia': smtcState['hasMedia'] ?? false,
      'title': smtcState['title'],
      'artist': smtcState['artist'],
      'positionMs': smtcState['positionMs'] ?? 0,
      'durationMs': smtcState['durationMs'] ?? 0,
      'isPlaying': smtcState['isPlaying'] ?? false,
    };
    // The cover is a base64 image of up to hundreds of KB, polled every 2 s:
    // send it only when it changed, and skip a state that did not change.
    final thumbnail = smtcState['thumbnail'] as String?;
    final key = jsonEncode(message);
    final thumbnailChanged = thumbnail != _lastThumbnail;
    if (!thumbnailChanged && key == _lastSmtcKey) return;
    _lastSmtcKey = key;
    if (thumbnailChanged) {
      _lastThumbnail = thumbnail;
      message['thumbnail'] = thumbnail;
    }
    onBroadcast(message);
  }

  /// The next SMTC_STATE goes out in full, cover included: a client that just
  /// connected has none of it.
  void resendSmtcInFull() {
    _lastSmtcKey = null;
    _lastThumbnail = _noThumbnail;
  }

  /// The next slide state goes out even if unchanged: a client that just
  /// connected during a show otherwise saw it as running with no slide
  /// number until the slide changed.
  void resendSlideState() {
    _lastSlideState = null;
  }

  Future<void> fetchAndBroadcastSlideState() async {
    if (!hasClients()) return;

    final state = await InputSimulator.getSlideState();
    if (state != null) {
      if (state['error'] == 'POWERPOINT_NOT_RUNNING') {
        _pptNotRunningSkipCount = 3;
        onShow?.call(null);
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
      final deck = deckOf(state);
      onShow?.call(
        current is int && total is int ? (deck: deck, current: current, total: total) : null,
      );

      if (_lastSlideState == null ||
          _lastSlideState!['current'] != current ||
          _lastSlideState!['total'] != total ||
          _lastSlideState!['notes'] != notes ||
          _lastSlideState!['hasMedia'] != state['hasMedia'] ||
          _lastSlideState!['isMediaPlaying'] != state['isMediaPlaying'] ||
          _lastSlideState!['presenter'] != state['presenter'] ||
          _lastSlideState!['deckKey'] != state['deckKey'] ||
          _lastSlideState!['error'] != null) {
        
        _lastSlideState = state;
        
        onBroadcast({
          'type': 'SLIDE_STATE',
          'current': current,
          'total': total,
          'notes': notes,
          'hasMedia': state['hasMedia'] ?? false,
          'isMediaPlaying': state['isMediaPlaying'] ?? false,
          if (state['presenter'] != null) 'presenter': state['presenter'],
          'deck': deck,
        });
      }
    }
  }

  void triggerSlideStateUpdate([Duration delay = Duration.zero]) {
    void update() {
      _guard('media state update', fetchAndBroadcastSmtcState);
      _guard('slide state update', fetchAndBroadcastSlideState);
    }

    if (delay == Duration.zero) {
      update();
    } else {
      Future.delayed(delay, update);
    }
  }

  Future<void> broadcastVolumeState({bool force = false}) async {
    if (!hasClients()) return;
    final state = await InputSimulator.getVolumeState();
    if (state == null) return;
    if (force || state.volume != _lastBroadcastVolume || state.muted != _lastBroadcastMuted) {
      _lastBroadcastVolume = state.volume;
      _lastBroadcastMuted = state.muted;
      onBroadcast({
        'type': 'STATUS',
        'state': 'VOLUME_CHANGED',
        'volume': state.volume,
        'muted': state.muted,
      });
    }
  }

  int get lastBroadcastVolume => _lastBroadcastVolume;
  bool get lastBroadcastMuted => _lastBroadcastMuted;
  Map<String, dynamic>? get lastSlideState => _lastSlideState;
}
