import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/pdf_viewers.dart';

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
}
