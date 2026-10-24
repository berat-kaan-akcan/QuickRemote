import 'package:quick_remote_shared/quick_remote_shared.dart' show FrontWindow;

/// Keys that start and end a presentation in a program QuickRemote cannot
/// drive otherwise, as Windows virtual-key codes (Linux maps them with
/// Evdev.fromVk).
class ViewerKeys {
  final List<int> start;

  /// Pressed on END only when [start] toggled a mode on in the same window
  /// (null: END keeps its Esc, which leaves the mode).
  final List<int>? end;

  /// Pressed on NEXT and PREV instead of PageDown and PageUp (null: those).
  final List<int>? next;
  final List<int>? prev;

  const ViewerKeys(this.start, {this.end, this.next, this.prev});
}

/// PDF viewers and browsers. Their F5 does not start a presentation: browsers
/// reload the page (and lose the PDF's place), LibreOffice Draw opens its
/// navigator. Next and previous are PageDown/PageUp, except in browsers and
/// WPS PDF.
class PdfViewers {
  PdfViewers._();

  static const _ctrl = 0x11, _alt = 0x12, _shift = 0x10, _f11 = 0x7A, _l = 0x4C, _p = 0x50;
  static const _left = 0x25, _right = 0x27;

  /// Firefox's PDF viewer: presentation mode (Esc leaves it). Out of it,
  /// PageDown scrolls by a screen and stops between pages, the arrows jump
  /// to the next page's top (measured on Firefox 157, Windows).
  static const firefox = ViewerKeys([_ctrl, _alt, _p], next: [_right], prev: [_left]);

  /// Chromium browsers have no presentation mode: full screen, left with F11.
  /// PageDown scrolls by a screen (Chrome's first presses did nothing at
  /// all), the arrows turn whole pages, also in full screen (measured on
  /// Edge and Chrome 154, Windows).
  static const fullScreen = ViewerKeys([_f11], end: [_f11], next: [_right], prev: [_left]);

  /// Adobe Acrobat / Reader: full screen mode (Esc leaves it).
  static const acrobat = ViewerKeys([_ctrl, _l]);

  /// Okular: presentation mode (Esc leaves it).
  static const okular = ViewerKeys([_ctrl, _shift, _p]);

  /// WPS PDF: its F5 does nothing, F11 is full screen (Esc leaves it).
  /// PageDown scrolls by a screen, the arrows jump to the next page's top,
  /// also in full screen. Verified on WPS 11.1 (Linux), whose window class
  /// is "pdf". WPS 12 on Windows opens PDFs in a tab of its wps.exe window,
  /// told apart by the window's title ([windowsProgram]; not tried there).
  static const wpsPdf = ViewerKeys([_f11], next: [_right], prev: [_left]);

  /// Firefox and its forks (pdf.js, the same keys). Matched as a word of
  /// the program's name, so "org.mozilla.firefox" (Flatpak's Wayland app_id)
  /// and "firefox-esr" count.
  static const _firefoxes = ['firefox', 'librewolf', 'waterfox', 'floorp', 'zen'];

  /// Chromium browsers: Windows executables ("msedge.exe"), X11 WM_CLASS
  /// ("google-chrome", "microsoft-edge", "brave-browser") and Wayland
  /// app_ids ("com.google.Chrome", "org.chromium.Chromium").
  static const _chromium = ['chrome', 'chromium', 'msedge', 'edge', 'brave', 'vivaldi', 'opera', 'thorium', 'arc'];

  /// PDF viewers whose F5 starts their presentation (SumatraPDF) or that
  /// have no keys of their own here, so [forProgram] does not know them.
  static const _otherPdfViewers = [
    'sumatrapdf',
    'evince',
    'papers',
    'atril',
    'xreader',
    'zathura',
    'qpdfview',
  ];

  /// The words of a program name: lower case, split at dots, dashes,
  /// underscores and spaces ("org.kde.okular" → org, kde, okular).
  static List<String> _words(String program) =>
      program.toLowerCase().split(RegExp(r'[.\-_ ]')).where((w) => w.isNotEmpty).toList();

  static bool _isFirefox(String name, List<String> words) =>
      name == 'navigator' || words.any((w) => w.startsWith('firefox') || _firefoxes.contains(w));

  static bool _isChromium(List<String> words) => words.any(_chromium.contains);

  /// The name [forProgram] and [kindOf] get for a Windows window of
  /// [executable] ("wps.exe") titled [title]. WPS 12 opens PDFs in a tab of
  /// its wps.exe window, beside its presentations and documents, so a WPS
  /// window whose title names a PDF counts as WPS PDF ("wpspdf"), whose
  /// PageDown scrolls by a screen and whose F5 does not start anything.
  /// Not tried on WPS 12: its title format is assumed to carry the file name.
  static String windowsProgram(String executable, String title) {
    final exe = executable.toLowerCase();
    if (exe == 'wps.exe' && RegExp(r'\.pdf\b', caseSensitive: false).hasMatch(title)) return 'wpspdf';
    return exe;
  }

  /// SLIDE_STATE's `front` for [program] (named as for [forProgram]):
  /// [FrontWindow.browser], [FrontWindow.pdf], or null for anything else.
  static String? kindOf(String program) {
    final name = program.toLowerCase();
    final words = _words(name);
    if (_isFirefox(name, words) || _isChromium(words)) return FrontWindow.browser;
    if (forProgram(name) != null || name.startsWith('foxit') || words.any(_otherPdfViewers.contains)) {
      return FrontWindow.pdf;
    }
    return null;
  }

  /// The keys for [program]: an executable file name (Windows, "firefox.exe"),
  /// a WM_CLASS name (Linux X11, "firefox", "google-chrome") or a Wayland
  /// app_id as KWin reports it ("org.mozilla.firefox", "org.kde.okular").
  /// Null when F5 does the job or the program is unknown.
  static ViewerKeys? forProgram(String program) {
    final name = program.toLowerCase();
    final words = _words(name);
    if (_isFirefox(name, words)) return firefox;
    if (_isChromium(words)) return fullScreen;
    if (name.startsWith('acrobat') || name.startsWith('acrord')) return acrobat;
    if (words.contains('okular')) return okular;
    if (name == 'pdf' || name.startsWith('wpspdf')) return wpsPdf;
    return null;
  }
}
