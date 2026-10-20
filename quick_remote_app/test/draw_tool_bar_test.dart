import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/models/draw_tool.dart';
import 'package:quick_remote_app/screens/remote/widgets/draw_tool_bar.dart';
import 'package:quick_remote_app/theme/app_theme.dart';

Widget _app(Widget bar) => MaterialApp(
  theme: AppTheme.dark,
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: bar),
);

void main() {
  testWidgets('holding Clear takes back the last stroke, a tap clears', (
    tester,
  ) async {
    var cleared = 0;
    var undone = 0;
    await tester.pumpWidget(
      _app(
        DrawToolBar(
          activeTool: DrawTool.laser,
          onToolSelected: (_) {},
          onClear: () => cleared++,
          onUndo: () => undone++,
        ),
      ),
    );
    await tester.longPress(find.text('Clear'));
    await tester.pump(const Duration(seconds: 1));
    expect((cleared, undone), (0, 1));
    await tester.tap(find.text('Clear'));
    await tester.pump(const Duration(seconds: 1));
    expect((cleared, undone), (1, 1));
  });

  testWidgets('a PC with the overlay: the selected laser opens its choice', (
    tester,
  ) async {
    final asked = <DrawTool>[];
    Widget bar({required bool options}) => _app(
      DrawToolBar(
        activeTool: DrawTool.laser,
        onToolSelected: (_) {},
        onClear: () {},
        onColorPickerRequested: asked.add,
        laserHasOptions: options,
      ),
    );
    await tester.pumpWidget(bar(options: false));
    await tester.tap(find.text('Laser'));
    await tester.pump(const Duration(seconds: 1));
    expect(asked, isEmpty);

    await tester.pumpWidget(bar(options: true));
    await tester.tap(find.text('Laser'));
    await tester.pump(const Duration(seconds: 1));
    expect(asked, [DrawTool.laser]);
  });
}
