import 'dart:typed_data';

import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
  Uint8List good({
    SlideImageKind kind = SlideImageKind.current,
    int slide = 1,
  }) =>
      SlideImageFrame(
        kind: kind,
        slide: slide,
        deck: 1,
        width: 10,
        height: 10,
        jpeg: jpeg,
      ).encode();

  test('every truncation of a good frame decodes to null or the full frame', () {
    final bytes = good();
    for (var n = 0; n < bytes.length; n++) {
      final f = SlideImageFrame.decode(bytes.sublist(0, n));
      if (n < SlideImageFrame.headerLength + 2) {
        expect(f, isNull, reason: 'length $n');
      } else {
        // Header intact and SOI present: a cut JPEG is the JPEG decoder's
        // business, the framing is still valid.
        expect(f, isNotNull, reason: 'length $n');
        expect(f!.jpeg.length, n - SlideImageFrame.headerLength);
      }
    }
  });

  test('the smallest valid frame is the header plus the two SOI bytes', () {
    final min = good().sublist(0, SlideImageFrame.headerLength + 2);
    expect(SlideImageFrame.decode(min)!.jpeg, [0xFF, 0xD8]);
    expect(SlideImageFrame.decode(min.sublist(0, 13)), isNull);
  });

  test('accepts a plain List<int> and an offset view', () {
    final bytes = good();
    expect(SlideImageFrame.decode(bytes.toList()), isNotNull);
    final padded = Uint8List(bytes.length + 5)..setRange(5, bytes.length + 5, bytes);
    final view = Uint8List.sublistView(padded, 5);
    final f = SlideImageFrame.decode(view)!;
    expect(f.jpeg, jpeg);
    expect(f.slide, 1);
  });

  test('kind 3 may have slide 0, the others may not', () {
    expect(SlideImageFrame.decode(good(kind: SlideImageKind.screen, slide: 0)),
        isNotNull);
    for (final kind in [
      SlideImageKind.current,
      SlideImageKind.next,
      SlideImageKind.thumbnail,
    ]) {
      expect(SlideImageFrame.decode(good(kind: kind, slide: 0)), isNull);
    }
  });

  test('extremes round-trip: slide 65535, deck 0xFFFFFFFF, 65535x65535', () {
    final f = SlideImageFrame.decode(SlideImageFrame(
      kind: SlideImageKind.thumbnail,
      slide: 0xFFFF,
      deck: 0xFFFFFFFF,
      width: 0xFFFF,
      height: 0xFFFF,
      jpeg: jpeg,
    ).encode())!;
    expect([f.slide, f.deck, f.width, f.height],
        [0xFFFF, 0xFFFFFFFF, 0xFFFF, 0xFFFF]);
  });

  test('a zero height alone is refused', () {
    final b = good()..[10] = 0..[11] = 0;
    expect(SlideImageFrame.decode(b), isNull);
  });

  test('a text-looking or move-sized binary frame never decodes', () {
    expect(SlideImageFrame.decode('{"cmd":"NEXT"}'.codeUnits), isNull);
    expect(SlideImageFrame.decode(Uint8List(9)), isNull);
    expect(SlideImageFrame.decode(Uint8List(200)), isNull);
    expect(SlideImageFrame.decode(List.filled(200, 0x51)), isNull);
  });

  test('deckId stays within 32 bits for long and non-ASCII keys', () {
    for (final key in ['x' * 10000, 'Sunum-çğıöşü.pptx|12|1', '\u{1F600}']) {
      final id = SlideImageFrame.deckId(key);
      expect(id, inInclusiveRange(0, 0xFFFFFFFF));
    }
    expect(SlideImageFrame.deckId('a'), isNot(SlideImageFrame.deckId('b')));
  });
}
