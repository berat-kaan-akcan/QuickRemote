import 'dart:typed_data';

/// A pointer frame the phone sends many times a second, as one binary
/// WebSocket frame of exactly 9 bytes, little-endian:
///
/// `uint8 type`, `float32 x`, `float32 y`.
///
/// For [touch] and [laser], x and y are a movement in pixels, at most
/// [maxDelta] either way (larger movements are split). For [laserAbs], they
/// are the laser's place on the show, fractions (0..1) of its width and
/// height; only a PC whose `auth` reply carries `absLaser` takes it (older
/// ones drop an unknown type).
class MoveFrame {
  const MoveFrame(this.type, this.x, this.y);

  static const touch = 0;
  static const laser = 1;
  static const laserAbs = 2;

  static const length = 9;
  static const maxDelta = 500.0;

  final int type;
  final double x;
  final double y;

  bool get isAbsolute => type == laserAbs;

  Uint8List encode() {
    final bytes = ByteData(length)
      ..setUint8(0, type)
      ..setFloat32(1, x, Endian.little)
      ..setFloat32(5, y, Endian.little);
    return bytes.buffer.asUint8List();
  }

  /// Null for a frame of another length, an unknown type, a number that is
  /// not finite, or one out of range.
  static MoveFrame? decode(List<int> data) {
    if (data.length != length) return null;
    final bytes = ByteData.sublistView(data is Uint8List ? data : Uint8List.fromList(data));
    final type = bytes.getUint8(0);
    final x = bytes.getFloat32(1, Endian.little);
    final y = bytes.getFloat32(5, Endian.little);
    if (!x.isFinite || !y.isFinite) return null;
    switch (type) {
      case touch || laser:
        if (x.abs() > maxDelta || y.abs() > maxDelta) return null;
      case laserAbs:
        if (x < 0 || x > 1 || y < 0 || y > 1) return null;
      default:
        return null;
    }
    return MoveFrame(type, x, y);
  }
}
