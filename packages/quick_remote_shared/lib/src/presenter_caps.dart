/// What kind of window is in front on the PC: SLIDE_STATE's `front`.
abstract class FrontWindow {
  /// A slideshow of a program the PC drives (PowerPoint, Impress, WPS).
  static const show = 'show';

  /// That program's editor (or LibreOffice Draw with a PDF, which START
  /// turns into a presentation).
  static const editor = 'editor';

  /// A PDF viewer (Okular, Acrobat, SumatraPDF, WPS PDF, ...).
  static const pdf = 'pdf';

  /// A web browser (Firefox, Chrome, Edge, ...), whose PDF viewer has no
  /// slides either.
  static const browser = 'browser';

  /// Any other window.
  static const other = 'other';

  static const values = {show, editor, pdf, browser, other};

  /// A viewer in front: only page turns and full screen, no slide to jump to.
  static bool isViewer(String? front) => front == pdf || front == browser;
}

/// The tools that work on the PC right now: SLIDE_STATE's `caps`. Next,
/// previous, start and end always work and are not listed.
abstract class RemoteCaps {
  static const laser = 'laser';
  static const pen = 'pen';
  static const highlighter = 'highlighter';
  static const eraser = 'eraser';
  static const eraseAll = 'eraseAll';

  /// Black and white screen.
  static const blank = 'blank';

  /// Play and pause the slide's media.
  static const media = 'media';

  /// Rewind the slide's media.
  static const rewind = 'rewind';

  /// Jump to a slide (START_AT).
  static const goto = 'goto';
  static const notes = 'notes';

  /// Pen and highlighter colors.
  static const colors = 'colors';

  /// Slide pictures (SLIDE_PREVIEW).
  static const previews = 'previews';

  /// QuickRemote's overlay: MODE_SPOTLIGHT, MODE_ZOOM, UNDO_INK.
  static const spotlight = 'spotlight';
  static const zoom = 'zoom';
  static const undo = 'undo';

  static const values = {
    laser,
    pen,
    highlighter,
    eraser,
    eraseAll,
    blank,
    media,
    rewind,
    goto,
    notes,
    colors,
    previews,
    spotlight,
    zoom,
    undo,
  };
}

/// SLIDE_STATE's `front` and `caps`, worked out on the PC (the rules differ
/// per program and platform, and all of them are there). A phone shows the
/// tools missing from [caps] faded; a SLIDE_STATE without `caps` (an older
/// PC) leaves the phone as it was before them.
class PresenterCaps {
  const PresenterCaps({this.front, this.caps = const {}});

  /// A [FrontWindow] value; null when unknown (a native Wayland window).
  final String? front;
  final Set<String> caps;

  bool has(String cap) => caps.contains(cap);

  /// These caps and [more].
  PresenterCaps plus(Iterable<String> more) =>
      PresenterCaps(front: front, caps: {...caps, ...more});

  /// The fields for a SLIDE_STATE message; `front` only when known.
  Map<String, Object> toJson() => {
        if (front != null) 'front': front!,
        'caps': (caps.toList()..sort()),
      };

  /// From a SLIDE_STATE message; null without `caps` (an older PC). Values
  /// this version does not know are left out, so a newer PC can add some.
  static PresenterCaps? fromJson(Map<String, dynamic> message) {
    final caps = message['caps'];
    if (caps is! List) return null;
    final front = message['front'];
    return PresenterCaps(
      front:
          front is String && FrontWindow.values.contains(front) ? front : null,
      caps: {
        for (final cap in caps)
          if (cap is String && RemoteCaps.values.contains(cap)) cap
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PresenterCaps &&
      other.front == front &&
      other.caps.length == caps.length &&
      other.caps.containsAll(caps);

  @override
  int get hashCode => Object.hash(front, Object.hashAllUnordered(caps));

  @override
  String toString() => 'PresenterCaps($front, $caps)';
}
