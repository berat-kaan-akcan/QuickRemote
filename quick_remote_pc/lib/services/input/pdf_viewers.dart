import 'package:quick_remote_shared/quick_remote_shared.dart' show FrontWindow, WebPresenters;

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

  /// A slide number typed and Enter jump there, once [start] has put the
  /// show on screen (Google Slides).
  final bool typesSlideNumber;

  const ViewerKeys(this.start, {this.end, this.next, this.prev, this.typesSlideNumber = false});
}

/// PDF viewers, browsers and the presentation sites in a browser tab. Their
/// F5 does not start a presentation: browsers reload the page (and lose the
/// PDF's place), LibreOffice Draw opens its navigator. Next and previous are
/// PageDown/PageUp, except in browsers and WPS PDF.
class PdfViewers {
  PdfViewers._();

  static const _ctrl = 0x11, _alt = 0x12, _shift = 0x10, _f5 = 0x74, _f11 = 0x7A, _l = 0x4C, _p = 0x50;
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

  /// PowerPoint for the web: Ctrl+F5 starts the show from the first slide
  /// (F5 is the browser's reload), Esc ends it (Microsoft's list of its
  /// keys). A slide number and Enter, B and W do nothing in its show (a test
  /// published in 2025), so the overlay covers the screen. Not tried here.
  static const powerpointWeb = ViewerKeys([_ctrl, _f5], next: [_right], prev: [_left]);

  /// Google Slides: Ctrl+F5 presents from the slide selected, Esc stops, a
  /// number and Enter jump to that slide (Google's list of its keys). Not
  /// tried here.
  static const googleSlides = ViewerKeys([_ctrl, _f5], next: [_right], prev: [_left], typesSlideNumber: true);

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
  /// A browser window whose title names a presentation site is that site
  /// ([webPresenterOf]).
  static String windowsProgram(String executable, String title) {
    final exe = executable.toLowerCase();
    if (exe == 'wps.exe' && RegExp(r'\.pdf\b', caseSensitive: false).hasMatch(title)) return 'wpspdf';
    if (kindOf(exe) == FrontWindow.browser) return webPresenterOf(title) ?? exe;
    return exe;
  }

  /// The names [forProgram] and [kindOf] get for a Linux window of the
  /// WM_CLASS names [wmClass] titled [title]: the presentation site first
  /// when it is a browser showing one.
  static List<String> linuxPrograms(List<String> wmClass, String? title) {
    final browser = wmClass.any((c) => kindOf(c) == FrontWindow.browser);
    final web = browser && title != null ? webPresenterOf(title) : null;
    return [?web, ...wmClass];
  }

  /// The [WebPresenters] value [program] (as [windowsProgram] and
  /// [linuxPrograms] name it) is, or null.
  static String? presenterOf(String program) {
    final name = program.toLowerCase();
    for (final site in WebPresenters.values) {
      if (name == site.toLowerCase()) return site;
    }
    return null;
  }

  /// The sites' own names, which end their page titles, in the languages
  /// their pages come in (only English and Turkish checked).
  static const _siteNames = {
    'powerpoint': WebPresenters.powerpointWeb,
    'microsoft powerpoint': WebPresenters.powerpointWeb,
    'powerpoint online': WebPresenters.powerpointWeb,
    'microsoft powerpoint online': WebPresenters.powerpointWeb,
    'powerpoint for the web': WebPresenters.powerpointWeb,
    'google slides': WebPresenters.googleSlides,
    'google slaytlar': WebPresenters.googleSlides,
    'google pr\u00e4sentationen': WebPresenters.googleSlides,
    'presentaciones de google': WebPresenters.googleSlides,
    'apresenta\u00e7\u00f5es google': WebPresenters.googleSlides,
    'presentazioni google': WebPresenters.googleSlides,
  };

  /// Edge adds "and 2 more pages" to the title of a window with more tabs
  /// (in Turkish too, measured on Edge 156).
  static final _morePages = RegExp('\\s+(and \\d+ more pages?|ve di\u011fer \\d+ sayfa)\$');

  /// Edge writes "Microsoft\u200B Edge".
  static final _invisible = RegExp('[\u200B-\u200D\u2060\uFEFF]');

  /// The presentation site ([WebPresenters]) a browser window titled
  /// [title] shows, or null. The sites end their page titles with their
  /// name ("Deck - Google Slides"; PowerPoint's not seen yet, assumed
  /// "Deck.pptx - PowerPoint"), and the browser adds its own: "- Google
  /// Chrome", "\u2014 Mozilla Firefox", "- Profile - Microsoft Edge" (measured,
  /// Chrome 156 and Edge 156). So the name must be the last part of the page
  /// title and never its first: "PowerPoint - Wikipedia" or a search for
  /// "powerpoint" is no deck. A wrong match costs a reload (Ctrl+F5).
  static String? webPresenterOf(String title) {
    final parts = title
        .replaceAll(_invisible, '')
        .split(RegExp(r'\s+[-\u2013\u2014|]\s+'))
        .map((p) => p.trim().toLowerCase().replaceFirst(_morePages, ''))
        .toList();
    final browser = _isBrowserName(parts.last);
    // The page title's last part: without the browser's name, and in Edge
    // also without the profile's (one, a name of any kind, or none).
    final candidates = !browser
        ? [parts.length - 1]
        : parts.last.contains('edge')
            ? [parts.length - 2, parts.length - 3]
            : [parts.length - 2];
    for (final i in candidates) {
      if (i < 1) continue;
      final site = _siteNames[parts[i]];
      if (site != null) return site;
    }
    return null;
  }

  static bool _isBrowserName(String part) {
    final words = _words(part);
    return _isFirefox(part, words) || _isChromium(words);
  }

  /// SLIDE_STATE's `front` for [program] (named as for [forProgram]):
  /// [FrontWindow.browser], [FrontWindow.pdf], or null for anything else.
  static String? kindOf(String program) {
    final name = program.toLowerCase();
    final words = _words(name);
    if (_isFirefox(name, words) || _isChromium(words) || presenterOf(name) != null) return FrontWindow.browser;
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
    switch (presenterOf(name)) {
      case WebPresenters.powerpointWeb:
        return powerpointWeb;
      case WebPresenters.googleSlides:
        return googleSlides;
    }
    if (_isFirefox(name, words)) return firefox;
    if (_isChromium(words)) return fullScreen;
    if (name.startsWith('acrobat') || name.startsWith('acrord')) return acrobat;
    if (words.contains('okular')) return okular;
    if (name == 'pdf' || name.startsWith('wpspdf')) return wpsPdf;
    return null;
  }
}
