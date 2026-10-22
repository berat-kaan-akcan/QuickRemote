import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/theme/app_color_theme.dart';

double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('every text color reads at 4.5:1 on the surfaces it sits on, in every palette', () {
    final failures = <String>[];
    for (final theme in AppColorTheme.values) {
      for (final p in {theme.light, theme.dark}) {
        final name = '${theme.name}/${p.isDark ? 'dark' : 'light'}';
        final texts = {
          'textPrimary': p.textPrimary,
          'textSecondary': p.textSecondary,
          'textMuted': p.textMuted,
          'primaryText': p.primaryText,
        };
        final grounds = {'background': p.background, 'surface': p.surface, 'surfaceRaised': p.surfaceRaised};
        texts.forEach((t, tc) {
          grounds.forEach((g, gc) {
            final ratio = _contrast(tc, gc);
            if (ratio < 4.5) failures.add('$name $t on $g: ${ratio.toStringAsFixed(2)}');
          });
        });
      }
    }
    expect(failures, isEmpty);
  });
}
