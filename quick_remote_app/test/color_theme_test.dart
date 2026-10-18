import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/theme/app_color_theme.dart';
import 'package:quick_remote_app/theme/app_palette.dart';
import 'package:quick_remote_app/widgets/brand/brand_mark.dart';

void main() {
  final palettes = {
    for (final theme in AppColorTheme.values) ...{theme.light, theme.dark},
  };

  test('The laser and the status colors are the same in every theme', () {
    for (final p in palettes) {
      final base = p.isDark ? AppPalette.dark : AppPalette.light;
      expect(
        [p.toolLaser, p.accent, p.success, p.warning, p.danger, p.info],
        [
          base.toolLaser,
          base.accent,
          base.success,
          base.warning,
          base.danger,
          base.info,
        ],
      );
    }
  });

  test('Text on a primary fill reads at 4.5:1 in every theme', () {
    double contrast(Color a, Color b) {
      final (la, lb) = (a.computeLuminance(), b.computeLuminance());
      return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
    }

    for (final theme in AppColorTheme.values) {
      for (final p in {theme.light, theme.dark}) {
        // Primary fills run from primaryBright to primary (and primaryDeep).
        for (final fill in [p.primary, p.primaryBright, p.primaryDeep]) {
          expect(
            contrast(p.onPrimary, fill),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.name}: onPrimary on $fill',
          );
        }
      }
    }
  });

  test('Only Cobalt follows the mode; Sunset is light, the rest dark', () {
    for (final theme in AppColorTheme.values) {
      expect(theme.followsMode, theme == AppColorTheme.cobalt);
      if (theme.followsMode) continue;
      expect(theme.light, same(theme.dark));
      expect(
        theme.fixedMode,
        theme == AppColorTheme.sunset ? ThemeMode.light : ThemeMode.dark,
      );
    }
    expect(AppColorTheme.cobalt.paletteFor(Brightness.light), AppPalette.light);
    expect(AppColorTheme.cobalt.paletteFor(Brightness.dark), AppPalette.dark);
  });

  testWidgets('The in-app logo takes the theme, Cobalt keeps the brand', (
    tester,
  ) async {
    Future<BrandColors> colorsIn(AppPalette palette) async {
      late BrandColors colors;
      await tester.pumpWidget(
        Theme(
          data: ThemeData(extensions: [palette]),
          child: Builder(
            builder: (context) {
              colors = BrandColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return colors;
    }

    expect(await colorsIn(AppPalette.dark), same(BrandColors.dark));
    expect(await colorsIn(AppPalette.light), same(BrandColors.light));
    final mint = await colorsIn(AppPalette.mint);
    expect(mint.next.first, AppPalette.mint.primaryBright);
    expect(mint.nextChevron, AppPalette.mint.onPrimary);
  });
}
