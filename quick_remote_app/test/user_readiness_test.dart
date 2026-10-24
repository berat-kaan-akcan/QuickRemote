import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/scan/scan_screen.dart';
import 'package:quick_remote_app/screens/settings/settings_screen.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_color_theme.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, {ThemeData? theme, Locale locale = const Locale('en'), double scale = 1}) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark,
    locale: locale,
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
    home: home,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('camera refused', () {
    for (final code in [MobileScannerErrorCode.permissionDenied, MobileScannerErrorCode.genericError]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$code at text scale $scale: a message, a way back, no overflow', (tester) async {
          tester.view.physicalSize = const Size(540, 960);
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          var opened = false;
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(_app(
            Scaffold(body: ScanErrorView(error: code, onOpenSettings: () => opened = true)),
            scale: scale,
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Go back'), findsOneWidget);
          if (code == MobileScannerErrorCode.permissionDenied) {
            expect(find.text('Camera access needed'), findsOneWidget);
            await tester.ensureVisible(find.text('Open settings'));
            await tester.tap(find.text('Open settings'));
            expect(opened, isTrue);
          } else {
            expect(find.text('Camera unavailable'), findsOneWidget);
            expect(find.text('Open settings'), findsNothing);
          }
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });
      }
    }
  });

  group('settings: about, privacy, licenses', () {
    Future<void> pump(WidgetTester tester, {ThemeData? theme, double scale = 1, Locale? locale}) async {
      tester.view.physicalSize = const Size(540, 960);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => WebSocketService()),
        ],
        child: _app(const SettingsScreen(), theme: theme, scale: scale, locale: locale ?? const Locale('en')),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the version, the privacy note and the license page', (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.text('Privacy'));
      await tester.pumpAndSettle();
      expect(find.text('Version'), findsOneWidget);
      await tester.tap(find.text('Privacy'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no account, no analytics'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Open-source licenses'));
      await tester.tap(find.text('Open-source licenses'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('the privacy dialog fits a 270 dp wide phone at text scale 2.0', (tester) async {
      await pump(tester, scale: 2.0);
      await tester.scrollUntilVisible(find.text('Privacy'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Close'), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      for (final colorTheme in AppColorTheme.values) {
        testWidgets('${colorTheme.name} at text scale $scale has no overflow and passes the guidelines', (tester) async {
          final handle = tester.ensureSemantics();
          await pump(tester, theme: AppTheme.of(colorTheme.dark), scale: scale);
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  });
}
