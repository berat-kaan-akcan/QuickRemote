import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../capture/capture_encoder.dart';
import '../input/input_service.dart';

/// The show on screen, as SLIDE_STATE reports it.
typedef ShownSlide = ({int deck, int current, int total});

/// What a screen picture shows: kind, deck and slide of its frame.
typedef _ScreenTarget = ({SlideImageKind kind, int deck, int slide});

/// Sends slide pictures ([SlideImageFrame]) to the phones that turned them
/// on: the current slide and the next one whenever the slide changes, and
/// thumbnails the phones ask for.
///
/// One export runs at a time, the current slide first, then the next one,
/// then thumbnails. A picture of a slide the show already left is not sent,
/// so after a quick run of NEXTs only the last slide is exported. The
/// exporter runs beside the commands (the platform keeps it off their
/// queue); a slow one is given up after [timeout].
///
/// Where the platform can take a picture of the screen ([capture]: the
/// show's window, or a PDF viewer or browser in full screen), that picture
/// goes as the current slide instead, since it shows what the audience
/// sees (the animation step, the ink, a playing video). It is taken
/// [settleDelay] after a slide command (once the slide state that follows
/// it has come, so the picture gets the right number), and every
/// [pollInterval] while the slide stays, sent only when it changed
/// ([EncodedCapture.hash]). Without a slide number (a PDF, a WPS show the
/// PC cannot read) it goes as [SlideImageKind.screen]. The next slide and
/// the thumbnails always come from the export.
class SlidePreviewer {
  SlidePreviewer({
    required this.send,
    required this.exporter,
    this.capture,
    this.timeout = const Duration(seconds: 3),
    this.maxCacheBytes = 30 * 1024 * 1024,
    this.settleDelay = const Duration(milliseconds: 400),
    this.pollInterval = const Duration(seconds: 2),
  });

  /// Sends one binary frame to one phone.
  final void Function(Object client, Uint8List frame) send;
  final Future<SlideImage?> Function(int index, int width) exporter;

  /// The screen's picture, ready to send; null where none can be taken now.
  /// No picture is taken without it.
  final Future<EncodedCapture?> Function()? capture;
  final Duration timeout;
  final int maxCacheBytes;

  /// How long a slide command's transition is given before the picture.
  final Duration settleDelay;

  /// How often the picture is taken again while the slide stays (a video).
  final Duration pollInterval;

  static const currentWidth = 1280;
  static const nextWidth = 640;
  static const thumbnailWidth = 320;

  /// Thumbnail requests kept per phone; older ones are dropped (the phone
  /// asks for the cells on screen, and they changed).
  static const maxQueuedThumbnails = 8;

  final Set<Object> _clients = {};
  ShownSlide? _shown;

  /// The current and next slide each phone was last sent, as (deck, slide).
  final Map<Object, (int, int)> _sentCurrent = {};
  final Map<Object, (int, int)> _sentNext = {};
  final Queue<(Object, int, int)> _thumbnails = Queue(); // client, deck, slide

  /// (deck, slide, width) → picture, least recently used first.
  final LinkedHashMap<(int, int, int), SlideImage> _cache = LinkedHashMap();
  int _cacheBytes = 0;
  bool _busy = false;

  // ── Screen pictures ──

  /// SLIDE_STATE's `front`: a viewer, or a show without a slide number,
  /// gets [SlideImageKind.screen] pictures.
  String? _front;

  /// The screen picture each phone was last sent: what it shows and its
  /// hash. One per phone, so a slide the show comes back to is sent again.
  final Map<Object, (_ScreenTarget, int)> _sentScreen = {};

  /// A slide command waits for the slide state after it; until then a
  /// picture would get the old slide's number.
  bool _awaitingState = false;
  final Stopwatch _sinceCommand = Stopwatch();

  /// Bumped by every slide command and slide change: a picture taken
  /// before one is not sent.
  int _screenGeneration = 0;
  Timer? _settleTimer;
  Timer? _pollTimer;
  bool _capturing = false;
  bool _captureAgain = false;

  bool isEnabled(Object client) => _clients.contains(client);

  void setEnabled(Object client, bool on) {
    if (!on) {
      remove(client);
      return;
    }
    final added = _clients.add(client);
    _pump();
    if (added) _scheduleCapture(Duration.zero);
    _updatePolling();
  }

  void remove(Object client) {
    _clients.remove(client);
    _sentCurrent.remove(client);
    _sentNext.remove(client);
    _sentScreen.remove(client);
    _thumbnails.removeWhere((t) => t.$1 == client);
    _updatePolling();
  }

  /// The show moved to [shown], or ended (null); [front] is SLIDE_STATE's
  /// `front`. Called with every slide state read.
  void show(ShownSlide? shown, {String? front}) {
    if (shown != null && shown.current < 1) {
      shown = null; // a show with an unknown slide
    }
    if (shown != null && _shown != null && shown.deck != _shown!.deck) {
      _clearCache();
    }
    final before = _screenTarget;
    _shown = shown;
    _front = front;
    _screenStateArrived(before);
    if (shown == null) {
      _thumbnails.clear();
      return;
    }
    _thumbnails.removeWhere((t) => t.$2 != shown!.deck);
    _pump();
  }

  /// A slide command (NEXT, PREV, START, START_AT) went to the PC: the
  /// screen is taken again once its transition had time and the slide
  /// state after it came.
  void slideMoved() {
    if (capture == null) return;
    _screenGeneration++;
    _awaitingState = _shown != null;
    _sinceCommand
      ..reset()
      ..start();
    _scheduleCapture(settleDelay);
  }

  void requestThumbnail(Object client, int slide) {
    final shown = _shown;
    if (!_clients.contains(client) || shown == null || slide > shown.total) {
      return;
    }
    final mine = _thumbnails.where((t) => t.$1 == client).toList();
    if (mine.length >= maxQueuedThumbnails) _thumbnails.remove(mine.first);
    _thumbnails.add((client, shown.deck, slide));
    _pump();
  }

  void reset() {
    _clients.clear();
    _sentCurrent.clear();
    _sentNext.clear();
    _sentScreen.clear();
    _thumbnails.clear();
    _shown = null;
    _front = null;
    _awaitingState = false;
    _settleTimer?.cancel();
    _settleTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _screenGeneration++;
    _clearCache();
  }

  /// What a screen picture taken now shows: the show's current slide, the
  /// screen where no slide is known (a viewer in front, or a show the PC
  /// cannot read), or nothing.
  _ScreenTarget? get _screenTarget {
    final shown = _shown;
    if (shown != null) return (kind: SlideImageKind.current, deck: shown.deck, slide: shown.current);
    if (FrontWindow.isViewer(_front) || _front == FrontWindow.show) {
      return (kind: SlideImageKind.screen, deck: 0, slide: 0);
    }
    return null;
  }

  void _screenStateArrived(_ScreenTarget? before) {
    if (capture == null) return;
    final target = _screenTarget;
    if (target == null) {
      // Nothing to show: whatever comes later is sent again.
      _sentScreen.clear();
    } else if (_awaitingState && _sinceCommand.elapsed >= _stateAfterCommand) {
      // (A state read that was on its way when the command went says
      // nothing of it: the server reads one again 500 ms after the command.)
      _awaitingState = false;
      final left = settleDelay - _sinceCommand.elapsed;
      _scheduleCapture(left.isNegative ? Duration.zero : left);
    } else if (target != before) {
      // The slide changed on the PC, or a viewer came to the front.
      _screenGeneration++;
      _scheduleCapture(settleDelay);
    }
    _updatePolling();
  }

  /// How soon after a slide command a slide state can tell its outcome.
  Duration get _stateAfterCommand => settleDelay * 3 ~/ 4;

  bool get _screenWanted => capture != null && _clients.isNotEmpty && _screenTarget != null;

  void _scheduleCapture(Duration delay) {
    if (!_screenWanted) return;
    _settleTimer?.cancel();
    _settleTimer = Timer(delay, () {
      _settleTimer = null;
      _captureScreen();
    });
  }

  void _updatePolling() {
    if (!_screenWanted) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(pollInterval, (_) {
      // No slide state came after the command: take the slide it reports.
      if (_awaitingState && _sinceCommand.elapsed > pollInterval) _awaitingState = false;
      // A picture is on its way after a command or a change.
      if (_settleTimer == null) _captureScreen();
    });
  }

  Future<void> _captureScreen() async {
    final take = capture;
    final target = _screenTarget;
    if (take == null || target == null || _clients.isEmpty || _awaitingState) return;
    if (_capturing) {
      _captureAgain = true;
      return;
    }
    _capturing = true;
    final generation = _screenGeneration;
    try {
      // (then: a future typed without null would refuse onTimeout's null.)
      final result = await take().then<EncodedCapture?>((v) => v).timeout(timeout, onTimeout: () => null);
      if (result == null || result.image.jpeg.isEmpty) return;
      // The slide moved meanwhile: the picture may show either slide.
      if (generation != _screenGeneration || _awaitingState || _screenTarget != target) return;
      for (final client in _clients) {
        if (_sentScreen[client] == (target, result.hash)) continue;
        _sentScreen[client] = (target, result.hash);
        _sendFrame(client, target.kind, target.deck, target.slide, result.image);
      }
    } catch (e) {
      debugPrint('SlidePreviewer: screen picture failed: $e');
    } finally {
      _capturing = false;
      if (_captureAgain) {
        _captureAgain = false;
        _scheduleCapture(Duration.zero);
      }
    }
  }

  void _clearCache() {
    _cache.clear();
    _cacheBytes = 0;
  }

  Future<void> _pump() async {
    if (_busy) return;
    _busy = true;
    try {
      while (true) {
        final job = _nextJob();
        if (job == null) break;
        await job();
      }
    } catch (e) {
      debugPrint('SlidePreviewer: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> Function()? _nextJob() {
    final shown = _shown;
    if (shown != null) {
      final current = _slideJob(
        shown,
        SlideImageKind.current,
        shown.current,
        _sentCurrent,
      );
      if (current != null) return current;
      if (shown.current < shown.total) {
        final next = _slideJob(
          shown,
          SlideImageKind.next,
          shown.current + 1,
          _sentNext,
        );
        if (next != null) return next;
      }
    }
    if (_thumbnails.isEmpty) return null;
    final (client, deck, slide) = _thumbnails.removeFirst();
    return () async {
      final image = await _image(deck, slide, thumbnailWidth);
      if (image == null || _shown?.deck != deck || !_clients.contains(client)) {
        return;
      }
      _sendFrame(client, SlideImageKind.thumbnail, deck, slide, image);
    };
  }

  /// Sends slide [slide] as [kind] to the phones in [sent] that do not have
  /// it yet; null when all do.
  Future<void> Function()? _slideJob(
    ShownSlide shown,
    SlideImageKind kind,
    int slide,
    Map<Object, (int, int)> sent,
  ) {
    final key = (shown.deck, slide);
    if (kind == SlideImageKind.current) {
      // A screen picture of this slide was sent already: it is the better one.
      final screen = (kind: kind, deck: shown.deck, slide: slide);
      for (final client in _clients) {
        if (_sentScreen[client]?.$1 == screen) sent[client] = key;
      }
    }
    final targets = _clients.where((c) => sent[c] != key).toList();
    if (targets.isEmpty) return null;
    return () async {
      final width = kind == SlideImageKind.current ? currentWidth : nextWidth;
      final image = await _image(shown.deck, slide, width);
      final now = _shown;
      // The show moved on meanwhile: the next round exports where it is.
      if (now == null || now.deck != shown.deck || now.current != shown.current) {
        return;
      }
      for (final client in targets) {
        if (!_clients.contains(client)) continue;
        // Marked even without a picture, so a slide that cannot be exported
        // is tried once per visit, not in a loop.
        sent[client] = key;
        // A screen picture that came meanwhile stays.
        if (kind == SlideImageKind.current &&
            _sentScreen[client]?.$1 == (kind: kind, deck: shown.deck, slide: slide)) {
          continue;
        }
        if (image != null) _sendFrame(client, kind, shown.deck, slide, image);
      }
    };
  }

  void _sendFrame(
    Object client,
    SlideImageKind kind,
    int deck,
    int slide,
    SlideImage image,
  ) {
    send(
      client,
      SlideImageFrame(
        kind: kind,
        slide: slide,
        deck: deck,
        width: image.width,
        height: image.height,
        jpeg: image.jpeg,
      ).encode(),
    );
  }

  Future<SlideImage?> _image(int deck, int slide, int width) async {
    final key = (deck, slide, width);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // most recently used again
      return cached;
    }
    SlideImage? image;
    try {
      image = await exporter(
        slide,
        width,
      ).timeout(timeout, onTimeout: () => null);
    } catch (e) {
      debugPrint('SlidePreviewer: export of slide $slide failed: $e');
    }
    if (image == null ||
        image.jpeg.isEmpty ||
        image.jpeg.length > maxCacheBytes) {
      return null;
    }
    // A picture of a deck that was closed meanwhile is not kept.
    if (_shown?.deck == deck) {
      _cache[key] = image;
      _cacheBytes += image.jpeg.length;
      while (_cacheBytes > maxCacheBytes) {
        final oldest = _cache.keys.first;
        _cacheBytes -= _cache.remove(oldest)!.jpeg.length;
      }
    }
    return image;
  }

  @visibleForTesting
  int get cacheBytes => _cacheBytes;
}
