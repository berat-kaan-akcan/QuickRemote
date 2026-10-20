import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../input/input_service.dart';

/// A screen picture made ready for the phones: the JPEG, and [hash], a
/// summary of a small copy, the same while the screen does not change.
typedef EncodedCapture = ({SlideImage image, int hash});

/// Turns a [ScreenCapture] into a JPEG at most [maxWidth] pixels wide, with
/// the overlay's ink drawn on it, in an isolate of its own (pure Dart, the
/// `image` package: tens of milliseconds for a full HD window).
class CaptureEncoder {
  CaptureEncoder._();

  static const maxWidth = 1280;
  static const quality = 80;

  /// Stroke widths as fractions of the picture's height, as the overlay
  /// draws them on its monitor (laser_overlay.cc), and the highlighter's
  /// opacity.
  static const penWidth = 0.0035;
  static const highlighterWidth = 0.02;
  static const highlighterAlpha = 0.45;

  /// The small copy [EncodedCapture.hash] sums up: fine enough to see a
  /// video move, coarse enough to stay put while nothing does.
  static const hashWidth = 32;
  static const hashHeight = 18;

  static Future<EncodedCapture?> encode(
    ScreenCapture capture, {
    int width = maxWidth,
  }) => Isolate.run(() => encodeNow(capture, width: width));

  /// [encode] in the calling isolate.
  @visibleForTesting
  static EncodedCapture? encodeNow(
    ScreenCapture capture, {
    int width = maxWidth,
  }) {
    if (capture.width <= 0 || capture.height <= 0) return null;
    final needed = capture.stride * (capture.height - 1) + capture.width * 4;
    if (capture.pixels.length < needed) return null;
    final outWidth = math.min(width, capture.width);
    final outHeight = math.max(
      1,
      (capture.height * outWidth / capture.width).round(),
    );
    final rgb = _downscale(capture, outWidth, outHeight);
    for (final stroke in capture.ink) {
      _drawStroke(rgb, outWidth, outHeight, stroke);
    }
    final hash = _hash(rgb, outWidth, outHeight);
    final picture = img.Image.fromBytes(
      width: outWidth,
      height: outHeight,
      bytes: rgb.buffer,
      numChannels: 3,
    );
    final jpeg = img.encodeJpg(
      picture,
      quality: quality,
      chroma: img.JpegChroma.yuv420,
    );
    return (
      image: (jpeg: jpeg, width: outWidth, height: outHeight),
      hash: hash,
    );
  }

  /// RGB, [width] × [height]: each pixel the mean of the source pixels it
  /// covers (BGRX in, the unused byte ignored).
  static Uint8List _downscale(ScreenCapture capture, int width, int height) {
    final src = capture.pixels;
    final out = Uint8List(width * height * 3);
    final xStarts = Int32List(width + 1);
    for (var x = 0; x <= width; x++) {
      xStarts[x] = x * capture.width ~/ width;
    }
    for (var y = 0; y < height; y++) {
      final y0 = y * capture.height ~/ height;
      final y1 = math.max(y0 + 1, (y + 1) * capture.height ~/ height);
      for (var x = 0; x < width; x++) {
        final x0 = xStarts[x];
        final x1 = math.max(x0 + 1, xStarts[x + 1]);
        var b = 0, g = 0, r = 0;
        for (var sy = y0; sy < y1; sy++) {
          var i = sy * capture.stride + x0 * 4;
          for (var sx = x0; sx < x1; sx++, i += 4) {
            b += src[i];
            g += src[i + 1];
            r += src[i + 2];
          }
        }
        final n = (y1 - y0) * (x1 - x0);
        final o = (y * width + x) * 3;
        out[o] = r ~/ n;
        out[o + 1] = g ~/ n;
        out[o + 2] = b ~/ n;
      }
    }
    return out;
  }

  /// Paints [stroke] with round ends, all of it at once: a highlighter that
  /// crosses itself does not get darker there, as on the overlay.
  static void _drawStroke(
    Uint8List rgb,
    int width,
    int height,
    CaptureStroke stroke,
  ) {
    if (stroke.points.isEmpty) return;
    final lineWidth = stroke.highlighter
        ? math.max(4.0, height * highlighterWidth)
        : math.max(1.5, height * penWidth);
    final radius = lineWidth / 2;
    final points = [
      for (final (x, y) in stroke.points) (x * width, y * height),
    ];
    final covered = <int>{};
    for (var i = 0; i < points.length; i++) {
      final a = points[i == 0 ? 0 : i - 1];
      final b = points[i];
      final left = math.max(0, (math.min(a.$1, b.$1) - radius).floor());
      final right = math.min(width - 1, (math.max(a.$1, b.$1) + radius).ceil());
      final top = math.max(0, (math.min(a.$2, b.$2) - radius).floor());
      final bottom = math.min(
        height - 1,
        (math.max(a.$2, b.$2) + radius).ceil(),
      );
      for (var y = top; y <= bottom; y++) {
        for (var x = left; x <= right; x++) {
          if (_distance(x + 0.5, y + 0.5, a, b) <= radius) {
            covered.add(y * width + x);
          }
        }
      }
    }
    final alpha = stroke.highlighter ? highlighterAlpha : 1.0;
    final r = (stroke.rgb >> 16) & 0xFF,
        g = (stroke.rgb >> 8) & 0xFF,
        b = stroke.rgb & 0xFF;
    for (final pixel in covered) {
      final o = pixel * 3;
      rgb[o] = (rgb[o] + (r - rgb[o]) * alpha).round();
      rgb[o + 1] = (rgb[o + 1] + (g - rgb[o + 1]) * alpha).round();
      rgb[o + 2] = (rgb[o + 2] + (b - rgb[o + 2]) * alpha).round();
    }
  }

  static double _distance(
    double x,
    double y,
    (double, double) a,
    (double, double) b,
  ) {
    final (ax, ay) = a;
    final (bx, by) = b;
    final dx = bx - ax, dy = by - ay;
    final length = dx * dx + dy * dy;
    final t = length == 0
        ? 0.0
        : (((x - ax) * dx + (y - ay) * dy) / length).clamp(0.0, 1.0);
    final px = ax + t * dx - x, py = ay + t * dy - y;
    return math.sqrt(px * px + py * py);
  }

  /// FNV-1a of a [hashWidth] × [hashHeight] grey copy, 5 bits a pixel, so
  /// the smallest changes of colour do not count.
  static int _hash(Uint8List rgb, int width, int height) {
    var hash = 0x811C9DC5;
    for (var hy = 0; hy < hashHeight; hy++) {
      final y0 = hy * height ~/ hashHeight;
      final y1 = math.max(y0 + 1, (hy + 1) * height ~/ hashHeight);
      for (var hx = 0; hx < hashWidth; hx++) {
        final x0 = hx * width ~/ hashWidth;
        final x1 = math.max(x0 + 1, (hx + 1) * width ~/ hashWidth);
        var sum = 0, n = 0;
        for (var y = y0; y < math.min(y1, height); y++) {
          for (var x = x0; x < math.min(x1, width); x++) {
            final o = (y * width + x) * 3;
            sum += rgb[o] * 3 + rgb[o + 1] * 6 + rgb[o + 2];
            n += 10;
          }
        }
        hash ^= n == 0 ? 0 : (sum ~/ n) >> 3;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
    }
    return hash;
  }
}
