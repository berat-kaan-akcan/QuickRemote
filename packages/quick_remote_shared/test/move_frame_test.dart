import 'dart:typed_data';

import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  test('decodes what it encodes', () {
    for (final (type, x, y) in [
      (MoveFrame.touch, -12.5, 300.0),
      (MoveFrame.laser, 500.0, -500.0),
      (MoveFrame.laserAbs, 0.25, 0.75),
    ]) {
      final bytes = MoveFrame(type, x, y).encode();
      expect(bytes, hasLength(9));
      final frame = MoveFrame.decode(bytes)!;
      expect(frame.type, type);
      expect(frame.x, x);
      expect(frame.y, y);
    }
  });

  test('is the 9-byte layout older apps send', () {
    final bytes = ByteData(9)
      ..setUint8(0, 1)
      ..setFloat32(1, 3, Endian.little)
      ..setFloat32(5, -4, Endian.little);
    final frame = MoveFrame.decode(bytes.buffer.asUint8List())!;
    expect((frame.type, frame.x, frame.y), (MoveFrame.laser, 3.0, -4.0));
    expect(frame.isAbsolute, isFalse);
  });

  test('drops broken frames', () {
    Uint8List raw(int type, double x, double y) => (ByteData(9)
          ..setUint8(0, type)
          ..setFloat32(1, x, Endian.little)
          ..setFloat32(5, y, Endian.little))
        .buffer
        .asUint8List();
    expect(MoveFrame.decode(Uint8List(8)), isNull);
    expect(MoveFrame.decode(Uint8List(10)), isNull);
    expect(MoveFrame.decode(raw(3, 0, 0)), isNull);
    expect(MoveFrame.decode(raw(0, 501, 0)), isNull);
    expect(MoveFrame.decode(raw(1, double.nan, 0)), isNull);
    expect(MoveFrame.decode(raw(2, 1.5, 0.5)), isNull);
    expect(MoveFrame.decode(raw(2, 0.5, -0.1)), isNull);
    expect(MoveFrame.decode(raw(2, 1, 0))!.isAbsolute, isTrue);
  });
}
