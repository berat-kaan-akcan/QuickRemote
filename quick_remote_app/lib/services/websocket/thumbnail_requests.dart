import 'dart:async';

/// The slide list's thumbnail requests (SLIDE_THUMB): a few at a time, in
/// the order the list asked, so a long deck stays under the PC's 30
/// commands a second and its export queue stays short. A thumbnail that does
/// not come within [timeout] counts as failed (the program cannot export)
/// and is not asked for again until [reset].
class ThumbnailRequests {
  ThumbnailRequests({
    required this.send,
    this.onFailed,
    this.maxInFlight = 4,
    this.timeout = const Duration(seconds: 4),
  });

  final void Function(int slide) send;
  final void Function()? onFailed;
  final int maxInFlight;
  final Duration timeout;

  final List<int> _waiting = [];
  final Map<int, Timer> _inFlight = {};
  final Set<int> _failed = {};

  bool failed(int slide) => _failed.contains(slide);

  void request(int slide) {
    if (_inFlight.containsKey(slide) ||
        _waiting.contains(slide) ||
        _failed.contains(slide)) {
      return;
    }
    _waiting.add(slide);
    _pump();
  }

  /// The list no longer shows [slide]; asked already, it still comes.
  void cancel(int slide) => _waiting.remove(slide);

  void arrived(int slide) {
    _inFlight.remove(slide)?.cancel();
    _pump();
  }

  void reset() {
    for (final timer in _inFlight.values) {
      timer.cancel();
    }
    _inFlight.clear();
    _waiting.clear();
    _failed.clear();
  }

  void _pump() {
    while (_inFlight.length < maxInFlight && _waiting.isNotEmpty) {
      final slide = _waiting.removeAt(0);
      _inFlight[slide] = Timer(timeout, () {
        _inFlight.remove(slide);
        _failed.add(slide);
        onFailed?.call();
        _pump();
      });
      send(slide);
    }
  }
}
