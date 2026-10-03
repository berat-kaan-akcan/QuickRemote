/// Keys that start and end a presentation in a program QuickRemote cannot
/// drive otherwise, as Windows virtual-key codes (Linux maps them with
/// Evdev.fromVk).
class ViewerKeys {
  final List<int> start;

  /// Pressed on END only when [start] toggled a mode on in the same window
  /// (null: END keeps its Esc, which leaves the mode).
  final List<int>? end;

  const ViewerKeys(this.start, {this.end});
}

/// PDF viewers and browsers. Their F5 does not start a presentation: browsers
/// reload the page (and lose the PDF's place), LibreOffice Draw opens its
/// navigator. Next and previous need nothing: PageDown/PageUp turn the pages.
class PdfViewers {
  PdfViewers._();

  static const _ctrl = 0x11, _alt = 0x12, _shift = 0x10, _f11 = 0x7A, _l = 0x4C, _p = 0x50;

  /// Firefox's PDF viewer: presentation mode (Esc leaves it).
  static const firefox = ViewerKeys([_ctrl, _alt, _p]);

  /// Chromium browsers have no presentation mode: full screen, left with F11.
  static const fullScreen = ViewerKeys([_f11], end: [_f11]);

  /// Adobe Acrobat / Reader: full screen mode (Esc leaves it).
  static const acrobat = ViewerKeys([_ctrl, _l]);

  /// Okular: presentation mode (Esc leaves it).
  static const okular = ViewerKeys([_ctrl, _shift, _p]);

  /// WPS PDF: its F5 does nothing, F11 is full screen (Esc leaves it).
  /// Verified on WPS 11.1 (Linux), whose window class is "pdf".
  static const wpsPdf = ViewerKeys([_f11]);

  static const _chromium = ['chrome', 'msedge', 'brave', 'vivaldi', 'opera'];

  /// The keys for [program]: an executable file name (Windows, "firefox.exe")
  /// or a WM_CLASS name (Linux, "firefox", "google-chrome"). Null when F5
  /// does the job or the program is unknown.
  static ViewerKeys? forProgram(String program) {
    final name = program.toLowerCase();
    if (name.startsWith('firefox') || name == 'navigator') return firefox;
    if (_chromium.any(name.contains)) return fullScreen;
    if (name.startsWith('acrobat') || name.startsWith('acrord')) return acrobat;
    if (name.startsWith('okular')) return okular;
    if (name == 'pdf' || name.startsWith('wpspdf')) return wpsPdf;
    return null;
  }
}
