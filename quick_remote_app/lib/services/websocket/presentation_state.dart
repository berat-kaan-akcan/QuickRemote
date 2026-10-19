import 'dart:collection';
import 'dart:typed_data';

import 'package:quick_remote_shared/quick_remote_shared.dart';

class PresentationState {
  int currentSlide = 0;
  int totalSlides = 0;
  String slideNotes = '';
  bool isPptRunning = true;

  /// Presentation program on the PC ('powerpoint' on Windows, 'impress' on
  /// Linux; 'wps' while WPS runs the show).
  String presenter = 'powerpoint';

  /// The PC's system ('windows' or 'linux'); null from a PC that does not send it.
  String? platform;

  /// Every program the PC controls (older PCs send only [presenter]).
  List<String> presenters = const ['powerpoint'];

  static String nameOf(String presenter) => switch (presenter) {
        'impress' => 'LibreOffice Impress',
        'wps' => 'WPS Office',
        _ => 'PowerPoint',
      };

  /// The name in the remote's header: "WPS" for WPS Office, "Impress" for
  /// LibreOffice Impress.
  static String shortNameOf(String presenter) => switch (presenter) {
        'impress' => 'Impress',
        'wps' => 'WPS',
        _ => 'PowerPoint',
      };

  /// The program running the show, or while none does, every one the PC
  /// controls (the UI joins them: "PowerPoint or WPS Office").
  List<String> get presenterNames =>
      isPptRunning ? [nameOf(presenter)] : presenters.map(nameOf).toList();

  /// The PC's own name (its host name); null from a PC that does not send it.
  /// Kept while the show changes: it is the connection's, not the show's.
  String? pcName;

  void updatePresenters(Map<String, dynamic> authReply) {
    presenter = authReply['presenter'] as String? ?? 'powerpoint';
    final list = authReply['presenters'];
    presenters = list is List && list.isNotEmpty ? list.whereType<String>().toList() : [presenter];
    pcName = cleanName(authReply['name']);
    platform = authReply['platform'] as String?;
    previewsSupported = authReply['previews'] == true;
  }

  // ── Slide pictures (SlideImageFrame) ──

  /// Whether the PC sends slide pictures (`previews` in its auth reply).
  bool previewsSupported = false;

  /// The deck the pictures belong to (SLIDE_STATE's `deck`); null from a PC
  /// that does not send one.
  int? deck;

  /// Pictures kept per size, least recently used first: a few large and
  /// medium ones to go back to, and the slide list's thumbnails.
  static const maxLargeImages = 6;
  static const maxMediumImages = 6;
  static const maxThumbnails = 200;

  final LinkedHashMap<int, Uint8List> _large = LinkedHashMap();
  final LinkedHashMap<int, Uint8List> _medium = LinkedHashMap();
  final LinkedHashMap<int, Uint8List> _thumbnails = LinkedHashMap();

  /// Keeps [frame] when it belongs to the deck on screen; false otherwise.
  bool addImage(SlideImageFrame frame) {
    if (deck != null && frame.deck != deck) return false;
    final (images, max) = switch (frame.kind) {
      SlideImageKind.current => (_large, maxLargeImages),
      SlideImageKind.next => (_medium, maxMediumImages),
      SlideImageKind.thumbnail => (_thumbnails, maxThumbnails),
    };
    images.remove(frame.slide);
    images[frame.slide] = frame.jpeg;
    while (images.length > max) {
      images.remove(images.keys.first);
    }
    return true;
  }

  /// The picture of the slide on screen: the large one, else the medium one
  /// sent as "next" before the slide changed (shown at once on NEXT).
  Uint8List? get currentSlideImage => imageOf(currentSlide);

  Uint8List? get nextSlideImage => currentSlide < 1 || currentSlide >= totalSlides
      ? null
      : _medium[currentSlide + 1] ?? _large[currentSlide + 1] ?? _thumbnails[currentSlide + 1];

  /// The best picture of slide [slide] there is.
  Uint8List? imageOf(int slide) => _large[slide] ?? _medium[slide] ?? _thumbnails[slide];

  /// A thumbnail for the slide list (a larger picture does as well).
  Uint8List? thumbnail(int slide) => _thumbnails[slide] ?? _medium[slide] ?? _large[slide];

  bool get hasSlideImages => _large.isNotEmpty || _medium.isNotEmpty || _thumbnails.isNotEmpty;

  void clearImages() {
    _large.clear();
    _medium.clear();
    _thumbnails.clear();
  }

  /// Makes the PC's name safe to show, as the PC does with a phone's
  /// (`ConnectedClient.sanitizeName`): no control or bidi override
  /// characters, single spaces, at most [maxNameLength] characters. Null if
  /// nothing is left.
  static String? cleanName(Object? raw) {
    if (raw is! String) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    final runes = cleaned.runes;
    if (runes.length <= maxNameLength) return cleaned;
    return '${String.fromCharCodes(runes.take(maxNameLength - 1)).trimRight()}…';
  }

  static const maxNameLength = 40;

  bool hasMedia = false;
  String? mediaTitle;
  String? mediaArtist;
  String? mediaThumbnailBase64;
  int positionMs = 0;
  int durationMs = 0;
  bool isPlaying = false;
  int systemVolume = -1; // 0-100; -1 = bilinmiyor
  bool systemMuted = false;

  void reset() {
    currentSlide = 0;
    totalSlides = 0;
    slideNotes = '';
    isPptRunning = false;
    pptHasMedia = false;
    pptIsMediaPlaying = false;
    // Without a connection there is no "now playing" to show.
    hasMedia = false;
    mediaTitle = null;
    mediaArtist = null;
    mediaThumbnailBase64 = null;
    positionMs = 0;
    durationMs = 0;
    isPlaying = false;
    systemVolume = -1;
    systemMuted = false;
    deck = null;
    clearImages();
  }

  bool pptHasMedia = false;
  bool pptIsMediaPlaying = false;

  void updateFromSlideState(Map<String, dynamic> message) {
    isPptRunning = true;
    final running = message['presenter'];
    if (running is String) presenter = running;
    final newSlide = message['current'] as int? ?? 0;
    if (newSlide != currentSlide) {
      pptIsMediaPlaying = false;
    }
    currentSlide = newSlide;
    totalSlides = message['total'] as int? ?? 0;
    final newDeck = message['deck'] as int?;
    if (newDeck != deck) {
      // Another presentation (or one saved since): the pictures are stale.
      deck = newDeck;
      clearImages();
    }
    slideNotes = message['notes'] as String? ?? '';
    pptHasMedia = message['hasMedia'] as bool? ?? false;
    
    if (message['isMediaPlaying'] != null) {
      pptIsMediaPlaying = message['isMediaPlaying'] as bool;
    }
  }

  void updateFromSmtcState(Map<String, dynamic> message) {
    hasMedia = message['hasMedia'] as bool? ?? false;
    mediaTitle = message['title'] as String?;
    mediaArtist = message['artist'] as String?;
    // The PC sends the cover only when it changed; no key means "keep it".
    if (message.containsKey('thumbnail')) {
      mediaThumbnailBase64 = message['thumbnail'] as String?;
    }
    positionMs = (message['positionMs'] as num?)?.toInt() ?? 0;
    durationMs = (message['durationMs'] as num?)?.toInt() ?? 0;
    isPlaying = message['isPlaying'] as bool? ?? false;
  }

  void updateFromStatus(Map<String, dynamic> message) {
    final state = message['state'] as String?;
    if (state == 'POWERPOINT_NOT_RUNNING') {
      isPptRunning = false;
    } else if (state == 'VOLUME_CHANGED') {
      final vol = message['volume'];
      final mut = message['muted'];
      if (vol != null) systemVolume = (vol as num).toInt();
      if (mut != null) systemMuted = mut as bool;
    }
  }
}
