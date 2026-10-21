import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/screens/home/widgets/device_lists.dart';
import 'package:quick_remote_app/services/discovery_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';

/// A discovery that has already found [devices] and does not scan.
class _FoundDevices extends DiscoveryService {
  _FoundDevices(this.found);

  final List<DiscoveredDevice> found;

  @override
  List<DiscoveredDevice> get devices => found;

  @override
  bool get isDiscovering => false;

  @override
  Future<void> startScanning() async {}
}

void main() {
  final saved = DiscoveredDevice(name: 'Office PC', ip: '10.0.0.2', port: 8765);
  final other = DiscoveredDevice(name: 'Lab PC', ip: '10.0.0.3', port: 8765);

  Future<List<DiscoveredDevice>> pumpLists(WidgetTester tester) async {
    final tapped = <DiscoveredDevice>[];
    await tester.pumpWidget(
      ChangeNotifierProvider<DiscoveryService>.value(
        value: _FoundDevices([saved, other]),
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeviceLists(
                onDiscoveredTap: tapped.add,
                isSaved: (dev) => dev.ip == saved.ip && dev.port == saved.port,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tapped;
  }

  testWidgets('only the found PCs are listed, a saved one carries the mark', (
    tester,
  ) async {
    final tapped = await pumpLists(tester);

    expect(find.text('Office PC'), findsOneWidget);
    expect(find.text('Lab PC'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Connects with the saved PIN')),
      findsOneWidget,
    );

    await tester.tap(find.text('Office PC'));
    expect(tapped, [saved]);
  });
}
