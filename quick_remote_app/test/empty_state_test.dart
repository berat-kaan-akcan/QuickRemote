import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/screens/home/widgets/device_lists.dart';
import 'package:quick_remote_app/services/discovery_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';

class _Nothing extends DiscoveryService {
  @override
  List<DiscoveredDevice> get devices => const [];
  @override
  bool get isDiscovering => false;
  @override
  Future<void> startScanning() async {}
}

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final height in [220.0, 320.0, 420.0]) {
      testWidgets('nothing found: fits $height px at text scale $scale and offers the PC download', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          ChangeNotifierProvider<DiscoveryService>.value(
            value: _Nothing(),
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
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SizedBox(height: height, child: DeviceLists(onDiscoveredTap: (_) {}, isSaved: (_) => false)),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('Get QuickRemote PC'), findsOneWidget);
        expect(find.text('Scan Again'), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  }
}
