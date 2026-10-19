import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/windows/slide_exporter.dart';

void main() {
  test('reads the height the script printed', () {
    expect(SlideExporter.parseHeight('EXPORTED:720'), 720);
    expect(SlideExporter.parseHeight('noise\nEXPORTED:360\n'), 360);
    expect(SlideExporter.parseHeight(''), isNull, reason: 'no show, or WPS');
    expect(SlideExporter.parseHeight('EXPORTED:0'), isNull);
    expect(SlideExporter.parseHeight('EXPORTED:12x'), isNull);
  });

  test('the script exports from PowerPoint only, to a literal path', () {
    final script = SlideExporter.script(
      7,
      1280,
      r"C:\Users\O'Brien\slide-7-1280.jpg",
    );
    expect(script, contains(r"$path = 'C:\Users\O''Brien\slide-7-1280.jpg'"));
    expect(
      script,
      contains(
        r"$presentation.Slides.Item(7).Export($path, 'JPG', 1280, $height)",
      ),
    );
    expect(script, contains(r"$qrPresenter -eq 'powerpoint'"));
    expect(
      script,
      contains(r'[Math]::Round(1280 * $setup.SlideHeight / $setup.SlideWidth)'),
    );
  });
}
