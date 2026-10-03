import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _messageKeys(String path) {
  final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('every message is translated in every language', () {
    final tr = _messageKeys('lib/l10n/app_tr.arb');
    final en = _messageKeys('lib/l10n/app_en.arb');
    expect(en.difference(tr), isEmpty, reason: 'only in app_en.arb');
    expect(tr.difference(en), isEmpty, reason: 'only in app_tr.arb');
  });

  test('no Turkish text is hard-coded outside the ARB files', () {
    // A string literal holding a Turkish letter; comments are skipped.
    final turkish = RegExp(r"""(['"])[^'"\n]*[çğıöşüÇĞİÖŞÜ][^'"\n]*\1""");
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(Platform.pathSeparator, '/');
      if (!path.endsWith('.dart') || path.startsWith('lib/l10n/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].trimLeft();
        if (code.startsWith('//')) continue;
        if (turkish.hasMatch(code)) found.add('$path:${i + 1}: $code');
      }
    }
    expect(found, isEmpty, reason: 'move these to lib/l10n/app_tr.arb and app_en.arb');
  });
}
