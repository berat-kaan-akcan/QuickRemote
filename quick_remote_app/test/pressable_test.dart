import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:quick_remote_app/widgets/ui/pressable.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a stretched key keeps the width its parent gives it', (tester) async {
    // Previous/Next sit in an Expanded; an Align around them once shrank the
    // keys to their label and the text spilled out (2026-10-24, S23 FE).
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Pressable(
                  onTap: () {},
                  child: Container(key: const Key('key'), color: Colors.blue, child: const Text('Previous')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('key'))), const Size(300, 120));
  });

  testWidgets('a small key gets a 48 px touch area and stays its own size', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Pressable(
          onTap: () => taps++,
          child: const SizedBox(key: Key('dot'), width: 20, height: 20),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('dot'))), const Size(20, 20));
    expect(tester.getSize(find.byType(Pressable)), const Size(48, 48));

    // A tap 20 px from the centre misses the dot but hits the touch area.
    final centre = tester.getCenter(find.byKey(const Key('dot')));
    await tester.tapAt(centre + const Offset(20, 0));
    expect(taps, 1);
  });

  testWidgets('minTarget 0 leaves the size to the child', (tester) async {
    await tester.pumpWidget(
      _app(
        Pressable(
          onTap: () {},
          minTarget: 0,
          child: const SizedBox(width: 20, height: 20),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Pressable)), const Size(20, 20));
  });
}
