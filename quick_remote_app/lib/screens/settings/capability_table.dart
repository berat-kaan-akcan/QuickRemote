/// What works where, for Settings → What works where. Written from
/// CLAUDE.md and the PC's code with the PC's laser setting on Auto; keep it
/// in step when a program gains or loses a feature.
library;

enum CapLink { wifi, bluetooth }

enum CapOs { windows, linux }

enum CapProgram {
  powerpoint,
  impress,
  wps,

  /// Linux: the WPS the PC opened (Sunumu WPS ile aç), driven over RPC.
  wpsApp,

  /// Linux: a WPS the user started, driven with its own keys.
  wpsOwn,

  /// A PDF in a viewer or a browser.
  pdf,

  /// PowerPoint for the web and Google Slides in a browser, told by the
  /// window's title.
  powerpointWeb,
  googleSlides,
}

enum CapFeature {
  nextPrev,
  startEnd,
  goTo,
  laser,
  ink,
  eraser,
  blank,
  slideInfo,
  preview,
  slideMedia,
  spotlight,
  volume,
}

enum CapLevel { yes, partial, no }

/// Why a cell is what it is, worded by the screen.
enum CapNote {
  overlay,
  focus,
  fullscreen,
  noJump,
  firstSlide,
  showOnly,
  screenOnly,
  fullscreenOnly,
  playOnly,
  mediaReload,
  noMagnifier,
  wpsArrow,
  highlighterFocus,
  cursor,
  penOnly,
  clearOnly,
  wpsEraser,
  noAnswer,
  keysOnly,
  wpsNoMedia,
  webStart,
  webTitle,
}

class CapCell {
  const CapCell(this.level, [this.note]);

  final CapLevel level;
  final CapNote? note;
}

const _yes = CapCell(CapLevel.yes);
const _no = CapCell(CapLevel.no);

CapCell _y(CapNote note) => CapCell(CapLevel.yes, note);
CapCell _p(CapNote note) => CapCell(CapLevel.partial, note);
CapCell _n(CapNote note) => CapCell(CapLevel.no, note);

class CapabilityTable {
  CapabilityTable._();

  /// The programs offered for [link] and [os], in the order shown.
  static List<CapProgram> programs(CapLink link, CapOs os) =>
      switch ((link, os)) {
        (CapLink.bluetooth, _) => const [
          CapProgram.powerpoint,
          CapProgram.impress,
          CapProgram.wps,
          CapProgram.powerpointWeb,
          CapProgram.googleSlides,
        ],
        (CapLink.wifi, CapOs.windows) => const [
          CapProgram.powerpoint,
          CapProgram.wps,
          CapProgram.powerpointWeb,
          CapProgram.googleSlides,
          CapProgram.pdf,
        ],
        (CapLink.wifi, CapOs.linux) => const [
          CapProgram.impress,
          CapProgram.wpsApp,
          CapProgram.wpsOwn,
          CapProgram.powerpointWeb,
          CapProgram.googleSlides,
          CapProgram.pdf,
        ],
      };

  /// The programs of the compare table: [programs] without the sites in a
  /// browser, whose columns a phone has no room for (they are much as PDF).
  static List<CapProgram> comparePrograms(CapLink link, CapOs os) => [
    for (final program in programs(link, os))
      if (!isWeb(program)) program,
  ];

  /// PowerPoint for the web or Google Slides.
  static bool isWeb(CapProgram program) =>
      program == CapProgram.powerpointWeb || program == CapProgram.googleSlides;

  static CapCell cell(
    CapLink link,
    CapOs os,
    CapProgram program,
    CapFeature feature,
  ) {
    final row = switch (link) {
      CapLink.bluetooth => _bluetooth(os, program),
      CapLink.wifi => _wifi(os, program),
    };
    return row[feature]!;
  }

  static Map<CapFeature, CapCell> _wifi(CapOs os, CapProgram program) {
    final spotlight = os == CapOs.windows
        ? _yes
        : _p(CapNote.noMagnifier);
    return switch (program) {
      CapProgram.powerpoint || CapProgram.wps when os == CapOs.windows => {
        CapFeature.nextPrev: _yes,
        CapFeature.startEnd: _yes,
        CapFeature.goTo: _yes,
        CapFeature.laser: _yes,
        CapFeature.ink: _yes,
        CapFeature.eraser: _yes,
        CapFeature.blank: _yes,
        CapFeature.slideInfo: _yes,
        CapFeature.preview: program == CapProgram.wps
            ? _p(CapNote.screenOnly)
            : _yes,
        CapFeature.slideMedia: program == CapProgram.wps
            ? _p(CapNote.playOnly)
            : _yes,
        CapFeature.spotlight: spotlight,
        CapFeature.volume: _yes,
      },
      CapProgram.impress => {
        CapFeature.nextPrev: _yes,
        CapFeature.startEnd: _yes,
        CapFeature.goTo: _yes,
        CapFeature.laser: _y(CapNote.overlay),
        CapFeature.ink: _y(CapNote.overlay),
        CapFeature.eraser: _y(CapNote.overlay),
        CapFeature.blank: _yes,
        CapFeature.slideInfo: _yes,
        CapFeature.preview: _yes,
        CapFeature.slideMedia: _p(CapNote.mediaReload),
        CapFeature.spotlight: spotlight,
        CapFeature.volume: _yes,
      },
      CapProgram.wpsApp => {
        CapFeature.nextPrev: _yes,
        CapFeature.startEnd: _yes,
        CapFeature.goTo: _yes,
        CapFeature.laser: _p(CapNote.wpsArrow),
        CapFeature.ink: _p(CapNote.highlighterFocus),
        CapFeature.eraser: _yes,
        CapFeature.blank: _yes,
        CapFeature.slideInfo: _yes,
        CapFeature.preview: _yes,
        CapFeature.slideMedia: _n(CapNote.wpsNoMedia),
        CapFeature.spotlight: spotlight,
        CapFeature.volume: _yes,
      },
      CapProgram.wpsOwn => {
        CapFeature.nextPrev: _p(CapNote.focus),
        CapFeature.startEnd: _p(CapNote.focus),
        CapFeature.goTo: _n(CapNote.firstSlide),
        CapFeature.laser: _p(CapNote.focus),
        CapFeature.ink: _p(CapNote.focus),
        CapFeature.eraser: _p(CapNote.focus),
        CapFeature.blank: _p(CapNote.focus),
        CapFeature.slideInfo: _n(CapNote.showOnly),
        CapFeature.preview: _p(CapNote.screenOnly),
        CapFeature.slideMedia: _n(CapNote.wpsNoMedia),
        CapFeature.spotlight: spotlight,
        CapFeature.volume: _yes,
      },
      CapProgram.powerpointWeb || CapProgram.googleSlides => {
        CapFeature.nextPrev: _yes,
        // Linux reads the title of X11 windows only.
        CapFeature.startEnd: os == CapOs.linux
            ? _p(CapNote.webTitle)
            : _y(CapNote.webStart),
        // Google Slides takes a typed number, PowerPoint has no such key.
        CapFeature.goTo: program == CapProgram.googleSlides
            ? _yes
            : _n(CapNote.noJump),
        CapFeature.laser: _y(CapNote.overlay),
        CapFeature.ink: _y(CapNote.overlay),
        CapFeature.eraser: _y(CapNote.overlay),
        CapFeature.blank: _y(CapNote.overlay),
        CapFeature.slideInfo: _no,
        CapFeature.preview: _p(CapNote.fullscreenOnly),
        CapFeature.slideMedia: _no,
        CapFeature.spotlight: spotlight,
        CapFeature.volume: _yes,
      },
      _ => {
        CapFeature.nextPrev: _yes,
        CapFeature.startEnd: _y(CapNote.fullscreen),
        CapFeature.goTo: _n(CapNote.noJump),
        CapFeature.laser: _y(CapNote.overlay),
        CapFeature.ink: _y(CapNote.overlay),
        CapFeature.eraser: _y(CapNote.overlay),
        CapFeature.blank: _y(CapNote.overlay),
        CapFeature.slideInfo: _no,
        CapFeature.preview: _p(CapNote.fullscreenOnly),
        CapFeature.slideMedia: _no,
        CapFeature.spotlight: spotlight,
        CapFeature.volume: _yes,
      },
    };
  }

  /// Whether the cell was written from the code but not yet tried on a
  /// real device, as the site's "What we tried" section and
  /// docs/raporlar/YAPILMAYANLAR.md say.
  /// Remove an entry once it has been tried.
  static bool untried(
    CapLink link,
    CapOs os,
    CapProgram program,
    CapFeature feature,
  ) =>
      // The sites in a browser: written from their lists of keys only.
      (isWeb(program) && cell(link, os, program, feature).level != CapLevel.no) ||
      _untried.contains((link, os, program, feature));

  static const _untried = {
    // Windows: the program's own eraser, the media of a slide and the
    // volume and now-playing panel have not been tried; the slide picture
    // of PowerPoint only on the PC's side, not on the phone.
    (CapLink.wifi, CapOs.windows, CapProgram.powerpoint, CapFeature.eraser),
    (CapLink.wifi, CapOs.windows, CapProgram.powerpoint, CapFeature.preview),
    (CapLink.wifi, CapOs.windows, CapProgram.powerpoint, CapFeature.slideMedia),
    (CapLink.wifi, CapOs.windows, CapProgram.powerpoint, CapFeature.volume),
    (CapLink.wifi, CapOs.windows, CapProgram.wps, CapFeature.eraser),
    (CapLink.wifi, CapOs.windows, CapProgram.wps, CapFeature.slideMedia),
    (CapLink.wifi, CapOs.windows, CapProgram.wps, CapFeature.volume),
    // Windows PDF: the overlay's laser, pen and spotlight were tried in
    // full-screen Chrome, its eraser was not.
    (CapLink.wifi, CapOs.windows, CapProgram.pdf, CapFeature.eraser),
    (CapLink.wifi, CapOs.windows, CapProgram.pdf, CapFeature.volume),
    // Linux: no video played in WPS 11.1, so its media keys were never seen
    // working; the arrow of an unfocused WPS was not tried.
    (CapLink.wifi, CapOs.linux, CapProgram.wpsApp, CapFeature.laser),
  };

  /// Over Bluetooth the phone is the computer's keyboard and mouse: the
  /// program's own shortcuts, no answer from the computer.
  static Map<CapFeature, CapCell> _bluetooth(CapOs os, CapProgram program) {
    final impress = program == CapProgram.impress;
    // In a browser: PowerPoint has no key for the laser, ink or a blank
    // screen, Google Slides has its laser (L) and B/W but no ink.
    if (isWeb(program)) {
      final slides = program == CapProgram.googleSlides;
      return {
        CapFeature.nextPrev: _yes,
        CapFeature.startEnd: _y(CapNote.webStart),
        CapFeature.goTo: _n(CapNote.noAnswer),
        CapFeature.laser: slides ? _yes : _p(CapNote.cursor),
        CapFeature.ink: _no,
        CapFeature.eraser: _no,
        CapFeature.blank: slides ? _yes : _no,
        CapFeature.slideInfo: _n(CapNote.noAnswer),
        CapFeature.preview: _n(CapNote.noAnswer),
        CapFeature.slideMedia: _n(CapNote.noAnswer),
        CapFeature.spotlight: _no,
        CapFeature.volume: _p(CapNote.keysOnly),
      };
    }
    return {
      CapFeature.nextPrev: _yes,
      CapFeature.startEnd: _yes,
      CapFeature.goTo: _n(CapNote.noAnswer),
      CapFeature.laser: impress ? _p(CapNote.cursor) : _yes,
      CapFeature.ink: impress ? _p(CapNote.penOnly) : _yes,
      CapFeature.eraser: impress
          ? _p(CapNote.clearOnly)
          : program == CapProgram.wps && os == CapOs.windows
          ? _p(CapNote.wpsEraser)
          : _yes,
      CapFeature.blank: _yes,
      CapFeature.slideInfo: _n(CapNote.noAnswer),
      CapFeature.preview: _n(CapNote.noAnswer),
      CapFeature.slideMedia: _n(CapNote.noAnswer),
      CapFeature.spotlight: _no,
      CapFeature.volume: _p(CapNote.keysOnly),
    };
  }
}
