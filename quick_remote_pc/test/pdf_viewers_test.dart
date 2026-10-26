import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/pdf_viewers.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart' show WebPresenters;

void main() {
  test('finds viewers by Windows executable and Linux WM_CLASS', () {
    expect(PdfViewers.forProgram('firefox.exe'), PdfViewers.firefox);
    expect(PdfViewers.forProgram('Navigator'), PdfViewers.firefox); // Firefox's X11 instance name
    expect(PdfViewers.forProgram('msedge.exe'), PdfViewers.fullScreen);
    expect(PdfViewers.forProgram('google-chrome'), PdfViewers.fullScreen);
    expect(PdfViewers.forProgram('brave-browser'), PdfViewers.fullScreen);
    expect(PdfViewers.forProgram('AcroRd32.exe'), PdfViewers.acrobat);
    expect(PdfViewers.forProgram('Acrobat.exe'), PdfViewers.acrobat);
    expect(PdfViewers.forProgram('okular'), PdfViewers.okular);
    expect(PdfViewers.forProgram('pdf'), PdfViewers.wpsPdf); // WPS PDF's WM_CLASS
    expect(PdfViewers.forProgram('wpspdf.exe'), PdfViewers.wpsPdf);
    expect(PdfViewers.forProgram('foxitpdfreader.exe'), isNull);
  });

  test('knows browsers and viewers by their Wayland app_ids and other builds', () {
    for (final program in ['org.mozilla.firefox', 'firefox-esr', 'librewolf', 'zen.exe', 'firefox_firefox']) {
      expect(PdfViewers.forProgram(program), PdfViewers.firefox, reason: program);
    }
    for (final program in [
      'chromium',
      'Chromium-browser',
      'org.chromium.Chromium',
      'com.google.Chrome',
      'microsoft-edge',
      'com.microsoft.Edge',
      'com.brave.Browser',
      'vivaldi-stable',
      'opera.exe',
    ]) {
      expect(PdfViewers.forProgram(program), PdfViewers.fullScreen, reason: program);
      expect(PdfViewers.kindOf(program), 'browser', reason: program);
    }
    expect(PdfViewers.forProgram('org.kde.okular'), PdfViewers.okular);
    for (final viewer in ['org.gnome.Evince', 'org.gnome.Papers', 'org.pwmt.zathura']) {
      expect(PdfViewers.kindOf(viewer), 'pdf', reason: viewer);
      expect(PdfViewers.forProgram(viewer), isNull, reason: viewer);
    }
    // Not a browser for containing one's letters.
    for (final other in ['msedgewebview2.exe', 'searchhost.exe', 'org.kde.konsole', 'code']) {
      expect(PdfViewers.kindOf(other), isNull, reason: other);
    }
  });

  test('a WPS window on Windows whose title names a PDF is WPS PDF', () {
    expect(PdfViewers.windowsProgram('wps.exe', 'rapor.PDF - WPS Office'), 'wpspdf');
    expect(PdfViewers.forProgram(PdfViewers.windowsProgram('wps.exe', 'rapor.pdf - WPS Office')), PdfViewers.wpsPdf);
    expect(PdfViewers.windowsProgram('wps.exe', 'sunum.pptx - WPS Office'), 'wps.exe');
    expect(PdfViewers.windowsProgram('wps.exe', 'pdfler.pptx'), 'wps.exe');
    expect(PdfViewers.windowsProgram('Chrome.exe', 'a.pdf'), 'chrome.exe');
  });

  test('leaves programs whose F5 starts a show alone', () {
    for (final program in ['powerpnt.exe', 'wpp', 'soffice.bin', 'SumatraPDF.exe', 'evince']) {
      expect(PdfViewers.forProgram(program), isNull, reason: program);
    }
  });

  test('tells PDF viewers from browsers for SLIDE_STATE\'s front', () {
    for (final browser in ['firefox.exe', 'Navigator', 'msedge.exe', 'google-chrome']) {
      expect(PdfViewers.kindOf(browser), 'browser', reason: browser);
    }
    for (final viewer in ['okular', 'pdf', 'AcroRd32.exe', 'SumatraPDF.exe', 'evince', 'foxitpdfreader.exe']) {
      expect(PdfViewers.kindOf(viewer), 'pdf', reason: viewer);
    }
    for (final other in ['powerpnt.exe', 'wpp', 'konsole', 'code.exe']) {
      expect(PdfViewers.kindOf(other), isNull, reason: other);
    }
  });

  test('only full screen is toggled off again by END', () {
    expect(PdfViewers.fullScreen.end, isNotNull);
    expect(PdfViewers.firefox.end, isNull);
  });

  test('browsers and WPS PDF turn pages with the arrows, the others with PageDown/PageUp', () {
    const right = 0x27, left = 0x25;
    for (final viewer in [PdfViewers.fullScreen, PdfViewers.firefox, PdfViewers.wpsPdf]) {
      expect(viewer.next, [right]);
      expect(viewer.prev, [left]);
    }
    for (final viewer in [PdfViewers.acrobat, PdfViewers.okular]) {
      expect(viewer.next, isNull);
      expect(viewer.prev, isNull);
    }
  });

  group('presentation sites in a browser tab', () {
    final zwsp = String.fromCharCode(0x200B);
    final emDash = String.fromCharCode(0x2014);

    test('are told by the last part of the page title, before the browser\'s name', () {
      final titles = {
        // Measured: Chrome 156, Edge 156 (Turkish profile and tab count).
        'Ders 3 - Google Slaytlar - Google Chrome': WebPresenters.googleSlides,
        'Ders 3 - Google Slaytlar ve diğer 1 sayfa - Kişisel - Microsoft$zwsp Edge': WebPresenters.googleSlides,
        'Deck - Google Slides and 2 more pages - Work - Microsoft$zwsp Edge': WebPresenters.googleSlides,
        'Deck - Google Slides $emDash Mozilla Firefox': WebPresenters.googleSlides,
        'Sunu1.pptx - PowerPoint - Google Chrome': WebPresenters.powerpointWeb,
        'Sunu1 - Microsoft PowerPoint Online - Microsoft$zwsp Edge': WebPresenters.powerpointWeb,
        'Sunu1.pptx - PowerPoint - Kişisel - Microsoft$zwsp Edge': WebPresenters.powerpointWeb,
        // A Linux WM title without the browser's name.
        'Deck - Google Slides': WebPresenters.googleSlides,
      };
      titles.forEach((title, site) => expect(PdfViewers.webPresenterOf(title), site, reason: title));
    });

    test('are not pages about them', () {
      for (final title in [
        'PowerPoint - Wikipedia - Google Chrome',
        'Microsoft PowerPoint - Vikipedi - Kişisel - Microsoft$zwsp Edge',
        'powerpoint - Google\'da Ara - Google Chrome',
        'Google Slides - Google Chrome',
        'PowerPoint',
        'How to present in PowerPoint - Blog - Google Chrome',
        'Sunu1.pptx - Google Chrome',
        '',
      ]) {
        expect(PdfViewers.webPresenterOf(title), isNull, reason: title);
      }
    });

    test('only in browser windows', () {
      expect(PdfViewers.windowsProgram('msedge.exe', 'Sunu1.pptx - PowerPoint - Kişisel - Microsoft$zwsp Edge'),
          WebPresenters.powerpointWeb);
      expect(PdfViewers.windowsProgram('chrome.exe', 'Deck - Google Slides - Google Chrome'), WebPresenters.googleSlides);
      // PowerPoint's own editor is titled so too.
      expect(PdfViewers.windowsProgram('POWERPNT.EXE', 'Sunu1 - PowerPoint'), 'powerpnt.exe');
      expect(PdfViewers.linuxPrograms(['Navigator', 'firefox'], 'Deck - Google Slides $emDash Mozilla Firefox'),
          [WebPresenters.googleSlides, 'Navigator', 'firefox']);
      expect(PdfViewers.linuxPrograms(['konsole'], 'Deck - Google Slides'), ['konsole']);
      expect(PdfViewers.linuxPrograms(['google-chrome'], null), ['google-chrome']);
    });

    test('count as browsers and get their show keys', () {
      const ctrl = 0x11, f5 = 0x74, esc = 0x1B;
      for (final site in WebPresenters.values) {
        expect(PdfViewers.kindOf(site), 'browser', reason: site);
        expect(PdfViewers.presenterOf(site), site);
        final keys = PdfViewers.forProgram(site)!;
        // Ctrl+F5: F5 alone reloads the page. END keeps its Esc.
        expect(keys.start, [ctrl, f5], reason: site);
        expect(keys.end, isNull, reason: site);
        expect(keys.start, isNot(contains(esc)));
        expect(keys.next, [0x27]);
        expect(keys.prev, [0x25]);
      }
      expect(PdfViewers.googleSlides.typesSlideNumber, isTrue);
      expect(PdfViewers.powerpointWeb.typesSlideNumber, isFalse);
      expect(PdfViewers.presenterOf('chrome.exe'), isNull);
    });
  });
}
