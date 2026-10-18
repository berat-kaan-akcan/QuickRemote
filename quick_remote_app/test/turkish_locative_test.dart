import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/turkish_locative.dart';

void main() {
  test('follows the last word of the number as it is read', () {
    const expected = {
      1: 'de', 2: 'de', 3: 'te', 4: 'te', 5: 'te', 6: 'da', 7: 'de', 8: 'de', 9: 'da',
      10: 'da', 12: 'de', 20: 'de', 30: 'da', 40: 'ta', 50: 'de', 60: 'ta', 70: 'te', 80: 'de', 90: 'da',
      100: 'de', 140: 'ta', 1000: 'de', 0: 'da',
    };
    expected.forEach((n, suffix) => expect(turkishLocative(n), suffix, reason: '$n'));
  });
}
