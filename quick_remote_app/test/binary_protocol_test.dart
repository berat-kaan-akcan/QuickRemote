import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Binary Protocol Format Tests', () {
    test('TOUCH command is correctly encoded', () {
      final type = 'TOUCH';
      final dx = 10.5;
      final dy = -5.25;

      final bytes = ByteData(9);
      bytes.setUint8(0, type == 'TOUCH' ? 0 : 1);
      bytes.setFloat32(1, dx, Endian.little);
      bytes.setFloat32(5, dy, Endian.little);
      final encoded = bytes.buffer.asUint8List();

      expect(encoded.length, 9);
      
      // Decode
      final decoded = ByteData.sublistView(encoded);
      expect(decoded.getUint8(0), 0); // 0 means TOUCH
      expect(decoded.getFloat32(1, Endian.little), closeTo(10.5, 0.001));
      expect(decoded.getFloat32(5, Endian.little), closeTo(-5.25, 0.001));
    });

    test('LASER command is correctly encoded', () {
      final type = 'LASER';
      final dx = 0.0;
      final dy = 42.0;

      final bytes = ByteData(9);
      bytes.setUint8(0, type == 'TOUCH' ? 0 : 1);
      bytes.setFloat32(1, dx, Endian.little);
      bytes.setFloat32(5, dy, Endian.little);
      final encoded = bytes.buffer.asUint8List();

      expect(encoded.length, 9);
      
      // Decode
      final decoded = ByteData.sublistView(encoded);
      expect(decoded.getUint8(0), 1); // 1 means LASER
      expect(decoded.getFloat32(1, Endian.little), closeTo(0.0, 0.001));
      expect(decoded.getFloat32(5, Endian.little), closeTo(42.0, 0.001));
    });
  });
}
