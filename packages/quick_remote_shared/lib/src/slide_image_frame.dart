import 'dart:typed_data';

/// Which picture a [SlideImageFrame] carries.
enum SlideImageKind {
  /// The slide on screen (1280 px wide).
  current,

  /// The slide after it (640 px).
  next,

  /// A slide of the slide list (320 px), asked for with SLIDE_THUMB.
  thumbnail,

  /// A picture of the screen (1280 px) where no slide is known: a PDF viewer
  /// or browser in full screen, or a show the PC cannot read. Its slide and
  /// deck are 0. Phones from before it have three kinds and drop it.
  screen,
}

/// A slide picture the PC sends to a phone that turned previews on
/// (`SLIDE_PREVIEW:1`), as one binary WebSocket frame, little-endian:
///
/// `uint8 magic (0x51)`, `uint8 kind`, `uint16 slide`, `uint32 deck`,
/// `uint16 width`, `uint16 height`, then the JPEG bytes.
///
/// [slide] counts from 1 (0 for [SlideImageKind.screen]). [deck] is the
/// presentation's id from SLIDE_STATE: a picture of another deck is stale.
class SlideImageFrame {
  const SlideImageFrame({
    required this.kind,
    required this.slide,
    required this.deck,
    required this.width,
    required this.height,
    required this.jpeg,
  });

  static const magic = 0x51;
  static const headerLength = 12;

  final SlideImageKind kind;
  final int slide;
  final int deck;
  final int width;
  final int height;
  final Uint8List jpeg;

  Uint8List encode() {
    final bytes = Uint8List(headerLength + jpeg.length);
    ByteData.sublistView(bytes)
      ..setUint8(0, magic)
      ..setUint8(1, kind.index)
      ..setUint16(2, slide, Endian.little)
      ..setUint32(4, deck, Endian.little)
      ..setUint16(8, width, Endian.little)
      ..setUint16(10, height, Endian.little);
    bytes.setRange(headerLength, bytes.length, jpeg);
    return bytes;
  }

  /// Null for anything that is not a whole frame: short, another magic or
  /// kind (a kind this version does not know, too), no slide (but for a
  /// screen picture), no size, or no JPEG after the header.
  static SlideImageFrame? decode(List<int> data) {
    if (data.length < headerLength + 2) return null;
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    final header = ByteData.sublistView(bytes, 0, headerLength);
    if (header.getUint8(0) != magic) return null;
    final kindIndex = header.getUint8(1);
    if (kindIndex >= SlideImageKind.values.length) return null;
    final kind = SlideImageKind.values[kindIndex];
    final slide = header.getUint16(2, Endian.little);
    final width = header.getUint16(8, Endian.little);
    final height = header.getUint16(10, Endian.little);
    if (slide == 0 && kind != SlideImageKind.screen) return null;
    if (width == 0 || height == 0) return null;
    // Every JPEG starts with the SOI marker.
    if (bytes[headerLength] != 0xFF || bytes[headerLength + 1] != 0xD8)
      return null;
    return SlideImageFrame(
      kind: kind,
      slide: slide,
      deck: header.getUint32(4, Endian.little),
      width: width,
      height: height,
      jpeg: Uint8List.sublistView(bytes, headerLength),
    );
  }

  /// The deck id SLIDE_STATE carries: 32-bit FNV-1a of [key] (the file's
  /// path, its slide count and when it was last changed).
  static int deckId(String key) {
    var hash = 0x811C9DC5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
