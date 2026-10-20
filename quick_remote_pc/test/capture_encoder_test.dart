import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:quick_remote_pc/services/capture/capture_encoder.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';

void main() {
  /// A [width] × [height] capture in one BGRX colour, rows padded to [stride].
  ScreenCapture solid(int width, int height, int rgb, {int? stride}) {
    final rowBytes = stride ?? width * 4;
    final pixels = Uint8List(rowBytes * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * rowBytes + x * 4;
        pixels[i] = rgb & 0xFF;
        pixels[i + 1] = (rgb >> 8) & 0xFF;
        pixels[i + 2] = (rgb >> 16) & 0xFF;
      }
    }
    return ScreenCapture(
      pixels: pixels,
      width: width,
      height: height,
      stride: rowBytes,
    );
  }

  img.Image decode(EncodedCapture encoded) =>
      img.decodeJpg(encoded.image.jpeg)!;

  void expectColor(img.Pixel pixel, int r, int g, int b) {
    expect(pixel.r.toInt(), closeTo(r, 12));
    expect(pixel.g.toInt(), closeTo(g, 12));
    expect(pixel.b.toInt(), closeTo(b, 12));
  }

  test('scales to 1280 px wide, keeping the shape, as a JPEG', () {
    final encoded = CaptureEncoder.encodeNow(solid(1920, 1080, 0x3366CC))!;
    expect(encoded.image.width, 1280);
    expect(encoded.image.height, 720);
    expect(encoded.image.jpeg.sublist(0, 2), [0xFF, 0xD8]);
    final picture = decode(encoded);
    expect(picture.width, 1280);
    expectColor(picture.getPixel(640, 360), 0x33, 0x66, 0xCC);
  });

  test('a small window stays its size; padded rows are read right', () {
    final encoded = CaptureEncoder.encodeNow(
      solid(64, 36, 0xFF0000, stride: 64 * 4 + 16),
    )!;
    expect((encoded.image.width, encoded.image.height), (64, 36));
    expectColor(decode(encoded).getPixel(32, 18), 255, 0, 0);
  });

  test('each pixel is the mean of the ones it covers', () {
    // Left half black, right half white, scaled to two pixels.
    final capture = solid(4, 2, 0x000000);
    for (var y = 0; y < 2; y++) {
      for (var x = 2; x < 4; x++) {
        capture.pixels.fillRange(y * 16 + x * 4, y * 16 + x * 4 + 3, 255);
      }
    }
    final picture = decode(CaptureEncoder.encodeNow(capture, width: 2)!);
    expect(picture.getPixel(0, 0).r.toInt(), lessThan(40));
    expect(picture.getPixel(1, 0).r.toInt(), greaterThan(215));
  });

  test('a broken capture gives nothing', () {
    expect(
      CaptureEncoder.encodeNow(
        ScreenCapture(pixels: Uint8List(10), width: 64, height: 36),
      ),
      isNull,
    );
    expect(
      CaptureEncoder.encodeNow(
        ScreenCapture(pixels: Uint8List(0), width: 0, height: 0),
      ),
      isNull,
    );
  });

  group('hash', () {
    test(
      'the same screen, the same hash; a tiny colour change does not count',
      () {
        final a = CaptureEncoder.encodeNow(solid(320, 180, 0x808080))!;
        final b = CaptureEncoder.encodeNow(solid(320, 180, 0x808080))!;
        final c = CaptureEncoder.encodeNow(solid(320, 180, 0x818181))!;
        expect(a.hash, b.hash);
        expect(a.hash, c.hash);
      },
    );

    test('a part of the screen that changed does', () {
      final still = solid(320, 180, 0x808080);
      final moved = solid(320, 180, 0x808080);
      // A 40 × 40 square turns white (a video frame).
      for (var y = 70; y < 110; y++) {
        moved.pixels.fillRange(y * 1280 + 140 * 4, y * 1280 + 180 * 4, 255);
      }
      expect(
        CaptureEncoder.encodeNow(moved)!.hash,
        isNot(CaptureEncoder.encodeNow(still)!.hash),
      );
    });
  });

  group('ink', () {
    test('a pen stroke is drawn in its colour, opaque', () {
      final capture = solid(640, 360, 0xFFFFFF).withInk([
        (highlighter: false, rgb: 0xFF0000, points: [(0.1, 0.5), (0.9, 0.5)]),
      ]);
      final encoded = CaptureEncoder.encodeNow(capture)!;
      final picture = decode(encoded);
      // A thin line: the JPEG blurs it a little, it stays plainly red.
      final line = picture.getPixel(320, 180);
      expect(line.r - line.g, greaterThan(100));
      expect(line.r - line.b, greaterThan(100));
      expectColor(picture.getPixel(320, 60), 255, 255, 255);
      expect(
        encoded.hash,
        isNot(CaptureEncoder.encodeNow(solid(640, 360, 0xFFFFFF))!.hash),
        reason: 'new ink is sent',
      );
    });

    test(
      'a highlighter shows the slide through, once where it crosses itself',
      () {
        final capture = solid(640, 360, 0xFFFFFF).withInk([
          (
            highlighter: true,
            rgb: 0x0000FF,
            points: [(0.2, 0.5), (0.8, 0.5), (0.5, 0.2), (0.5, 0.8)],
          ),
        ]);
        final picture = decode(CaptureEncoder.encodeNow(capture)!);
        // White under 45 % blue.
        expectColor(picture.getPixel(200, 180), 140, 140, 255);
        expectColor(picture.getPixel(320, 180), 140, 140, 255);
      },
    );

    test('a tap is a dot', () {
      final capture = solid(640, 360, 0xFFFFFF).withInk([
        (highlighter: false, rgb: 0x000000, points: [(0.5, 0.5)]),
      ]);
      expect(
        decode(CaptureEncoder.encodeNow(capture)!).getPixel(320, 180).r.toInt(),
        lessThan(60),
      );
    });
  });

  test('encode runs in an isolate of its own', () async {
    final encoded = await CaptureEncoder.encode(solid(128, 72, 0x00FF00));
    expect(encoded!.image.width, 128);
  });
}
