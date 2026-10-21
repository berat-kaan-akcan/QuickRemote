import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../input/input_service.dart';

/// Finds which slide a screen picture shows by comparing small grey copies:
/// a take-over of a WPS show (`WpsTakeOver`) knows the show's window but not
/// its slide number.
class SlideMatcher {
  SlideMatcher._();

  static const width = 32;
  static const height = 18;

  /// The mean difference per pixel (0-255) under which a slide counts as
  /// the one on screen: an animation step half done still matches, another
  /// slide of the same template usually does not.
  static const threshold = 24.0;

  /// A grey [width] × [height] copy of the slide in [capture]: the middle
  /// part with the slide's [aspect] (width / height), where a show letterboxes
  /// it.
  static Uint8List? ofCapture(ScreenCapture capture, double aspect) {
    if (capture.width <= 0 || capture.height <= 0 || aspect <= 0) return null;
    final needed = capture.stride * (capture.height - 1) + capture.width * 4;
    if (capture.pixels.length < needed) return null;
    var w = capture.width.toDouble(), h = capture.height.toDouble();
    if (w / h > aspect) {
      w = h * aspect;
    } else {
      h = w / aspect;
    }
    final left = ((capture.width - w) / 2).round();
    final top = ((capture.height - h) / 2).round();
    return _grey(left, top, math.max(1, w.round()), math.max(1, h.round()), (
      x,
      y,
    ) {
      final i = y * capture.stride + x * 4;
      return _luma(
        capture.pixels[i + 2],
        capture.pixels[i + 1],
        capture.pixels[i],
      );
    });
  }

  /// A grey copy of an exported slide; null when [jpeg] does not decode.
  static Uint8List? ofJpeg(Uint8List jpeg) {
    final image = img.decodeJpg(jpeg);
    if (image == null || image.width == 0 || image.height == 0) return null;
    return _grey(0, 0, image.width, image.height, (x, y) {
      final p = image.getPixel(x, y);
      return _luma(p.r.toInt(), p.g.toInt(), p.b.toInt());
    });
  }

  /// The slide (from 1) of [slides] closest to [screen], or null when none
  /// is close enough. A missing picture never matches; of equal ones the
  /// first wins.
  static int? best(Uint8List screen, List<Uint8List?> slides) {
    int? found;
    var least = threshold;
    for (var i = 0; i < slides.length; i++) {
      final slide = slides[i];
      if (slide == null || slide.length != screen.length) continue;
      var sum = 0;
      for (var p = 0; p < screen.length; p++) {
        sum += (screen[p] - slide[p]).abs();
      }
      final mean = sum / screen.length;
      if (mean < least) {
        least = mean;
        found = i + 1;
      }
    }
    return found;
  }

  static int _luma(int r, int g, int b) => (r * 3 + g * 6 + b) ~/ 10;

  /// The mean grey of each cell of a [width] × [height] grid over the
  /// [w] × [h] area at ([left], [top]).
  static Uint8List _grey(
    int left,
    int top,
    int w,
    int h,
    int Function(int x, int y) luma,
  ) {
    final out = Uint8List(width * height);
    for (var gy = 0; gy < height; gy++) {
      final y0 = top + gy * h ~/ height;
      final y1 = math.max(y0 + 1, top + (gy + 1) * h ~/ height);
      for (var gx = 0; gx < width; gx++) {
        final x0 = left + gx * w ~/ width;
        final x1 = math.max(x0 + 1, left + (gx + 1) * w ~/ width);
        var sum = 0, n = 0;
        for (var y = y0; y < y1; y++) {
          for (var x = x0; x < x1; x++) {
            sum += luma(x, y);
            n++;
          }
        }
        out[gy * width + gx] = sum ~/ n;
      }
    }
    return out;
  }
}
