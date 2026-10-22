import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/app_language.dart';
import 'package:quick_remote_app/services/background_session.dart';
import 'package:quick_remote_app/widgets/notification_denied_host.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: supportedAppLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const Scaffold(body: NotificationDeniedHost(child: SizedBox())),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a refusal is explained once, with a key to the settings', (tester) async {
    var opened = 0;
    BackgroundSession.openSettings = () async => ++opened > 0;
    await tester.pumpWidget(_app());

    await tester.runAsync(() => BackgroundSession.handleNotificationResult(false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Notifications are off'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    expect(opened, 1);
  });

  testWidgets('it is not said again, and a grant says nothing', (tester) async {
    await tester.pumpWidget(_app());
    await tester.runAsync(() => BackgroundSession.handleNotificationResult(true));
    await tester.pump();
    expect(find.textContaining('Notifications are off'), findsNothing);

    await tester.runAsync(() => BackgroundSession.handleNotificationResult(false));
    await tester.pump();
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => BackgroundSession.handleNotificationResult(false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Notifications are off'), findsNothing);
  });
}
