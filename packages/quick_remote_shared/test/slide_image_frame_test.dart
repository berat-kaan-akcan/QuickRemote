import 'dart:typed_data';

import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  final jpeg =
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 0xFF, 0xD9]);

  SlideImageFrame frame({SlideImageKind kind = SlideImageKind.next}) =>
      SlideImageFrame(
        kind: kind,
        slide: 7,
        deck: 0xDEADBEEF,
        width: 640,
        height: 360,
        jpeg: jpeg,
      );

  test('decodes what it encodes', () {
    for (final kind in SlideImageKind.values) {
      final decoded = SlideImageFrame.decode(frame(kind: kind).encode())!;
      expect(decoded.kind, kind);
      expect(decoded.slide, 7);
      expect(decoded.deck, 0xDEADBEEF);
      expect(decoded.width, 640);
      expect(decoded.height, 360);
      expect(decoded.jpeg, jpeg);
    }
  });

  test('the header is little-endian, magic first', () {
    final bytes = frame().encode();
    expect(bytes.length, SlideImageFrame.headerLength + jpeg.length);
    expect(bytes.sublist(0, 12),
        [0x51, 1, 7, 0, 0xEF, 0xBE, 0xAD, 0xDE, 0x80, 2, 0x68, 1]);
  });

  test('rejects short and broken frames', () {
    final good = frame().encode();
    expect(SlideImageFrame.decode(good.sublist(0, 12)), isNull,
        reason: 'no JPEG');
    expect(SlideImageFrame.decode(Uint8List(9)), isNull,
        reason: 'a move frame');
    expect(SlideImageFrame.decode([]), isNull);

    Uint8List patched(int index, int value) =>
        Uint8List.fromList(good)..[index] = value;
    expect(SlideImageFrame.decode(patched(0, 0x52)), isNull, reason: 'magic');
    expect(SlideImageFrame.decode(patched(1, 4)), isNull, reason: 'kind');
    expect(SlideImageFrame.decode(patched(1, 0xFF)), isNull, reason: 'kind');
    expect(SlideImageFrame.decode(patched(2, 0)), isNull, reason: 'slide 0');
    expect(SlideImageFrame.decode(patched(8, 0)..[9] = 0), isNull,
        reason: 'width 0');
    expect(SlideImageFrame.decode(patched(12, 0)), isNull,
        reason: 'not a JPEG');
  });

  test('a screen picture has no slide and no deck', () {
    final bytes = SlideImageFrame(
      kind: SlideImageKind.screen,
      slide: 0,
      deck: 0,
      width: 1280,
      height: 720,
      jpeg: jpeg,
    ).encode();
    expect(bytes[1], 3, reason: 'kind 3 on the wire');
    final decoded = SlideImageFrame.decode(bytes)!;
    expect(decoded.kind, SlideImageKind.screen);
    expect(decoded.slide, 0);
    expect(decoded.deck, 0);
  });

  test('phones from before screen pictures drop them', () {
    // Their decode: `kind >= SlideImageKind.values.length` (3 kinds then)
    // is null, before anything else is read.
    const oldKinds = 3;
    final screen = frame(kind: SlideImageKind.screen).encode();
    expect(screen[1] >= oldKinds, isTrue);
    for (final kind in SlideImageKind.values.take(oldKinds)) {
      expect(frame(kind: kind).encode()[1] < oldKinds, isTrue);
    }
  });

  test('deckId is a stable 32-bit hash', () {
    expect(SlideImageFrame.deckId(''), 0x811C9DC5);
    expect(SlideImageFrame.deckId('a'), 0xE40C292C);
    expect(SlideImageFrame.deckId('C:/talk.pptx|12|1'),
        isNot(SlideImageFrame.deckId('C:/talk.pptx|12|2')));
  });
}
