import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../input/input_service.dart';

/// The show on screen, as SLIDE_STATE reports it.
typedef ShownSlide = ({int deck, int current, int total});

/// Sends slide pictures ([SlideImageFrame]) to the phones that turned them
/// on: the current slide and the next one whenever the slide changes, and
/// thumbnails the phones ask for.
///
/// One export runs at a time, the current slide first, then the next one,
/// then thumbnails. A picture of a slide the show already left is not sent,
/// so after a quick run of NEXTs only the last slide is exported. The
/// exporter runs beside the commands (the platform keeps it off their
/// queue); a slow one is given up after [timeout].
class SlidePreviewer {
  SlidePreviewer({
    required this.send,
    required this.exporter,
    this.timeout = const Duration(seconds: 3),
    this.maxCacheBytes = 30 * 1024 * 1024,
  });

  /// Sends one binary frame to one phone.
  final void Function(Object client, Uint8List frame) send;
  final Future<SlideImage?> Function(int index, int width) exporter;
  final Duration timeout;
  final int maxCacheBytes;

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

  bool isEnabled(Object client) => _clients.contains(client);

  void setEnabled(Object client, bool on) {
    if (!on) {
      remove(client);
      return;
    }
    _clients.add(client);
    _pump();
  }

  void remove(Object client) {
    _clients.remove(client);
    _sentCurrent.remove(client);
    _sentNext.remove(client);
    _thumbnails.removeWhere((t) => t.$1 == client);
  }

  /// The show moved to [shown], or ended (null).
  void show(ShownSlide? shown) {
    if (shown != null && shown.current < 1) {
      shown = null; // a show with an unknown slide
    }
    if (shown != null && _shown != null && shown.deck != _shown!.deck) {
      _clearCache();
    }
    _shown = shown;
    if (shown == null) {
      _thumbnails.clear();
      return;
    }
    _thumbnails.removeWhere((t) => t.$2 != shown!.deck);
    _pump();
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
    _thumbnails.clear();
    _shown = null;
    _clearCache();
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
