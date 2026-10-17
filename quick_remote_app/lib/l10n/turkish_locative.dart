/// The ending of the Turkish locative after the number [n] as it is read
/// ("7'de", "3'te", "6'da", "40'ta"): the `suffix` select key of messages
/// such as slideMediaOnSlide. Other languages ignore it.
String turkishLocative(int n) {
  n = n.abs();
  if (n == 0) return 'da';
  // The last word read decides: the units, else the tens, else the hundreds
  // and thousands ("yüz", "bin"), else the millions.
  const units = {1: 'de', 2: 'de', 3: 'te', 4: 'te', 5: 'te', 6: 'da', 7: 'de', 8: 'de', 9: 'da'};
  const tens = {1: 'da', 2: 'de', 3: 'da', 4: 'ta', 5: 'de', 6: 'ta', 7: 'te', 8: 'de', 9: 'da'};
  if (n % 10 != 0) return units[n % 10]!;
  if (n % 100 != 0) return tens[n ~/ 10 % 10]!;
  if (n % 1000000 != 0) return 'de';
  return 'da';
}
