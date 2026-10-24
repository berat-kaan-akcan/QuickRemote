import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/remote/views/main_controls_view.dart';
import 'package:quick_remote_app/screens/remote/views/media_control_view.dart';
import 'package:quick_remote_app/screens/remote/views/touchpad_view.dart';
import 'package:quick_remote_app/services/presentation_timer_controller.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_color_theme.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ws extends WebSocketService {
  _Ws({required bool show}) {
    handleMessage({'type': 'auth', 'status': 'ok', 'platform': 'windows', 'presenter': 'powerpoint', 'overlay': true});
    if (show) {
      handleMessage({'type': 'SLIDE_STATE', 'current': 3, 'total': 10, 'notes': 'Say hello', 'deck': 1});
    }
  }

  @override
  bool get isConnected => true;

  @override
  void sendDirect(String command) {}
}

void main() {
  final sizes = <String, (Size, double)>{
    'phone': (const Size(360, 780), 1.0),
    'phone text 2.0': (const Size(360, 780), 2.0),
    'small phone text 2.0': (const Size(320, 568), 2.0),
    'landscape': (const Size(780, 360), 1.0),
    'tablet': (const Size(800, 1280), 1.0),
  };
  final views = <String, Widget Function(WebSocketService, PresentationTimerController)>{
    'controls': (ws, t) => MainControlsView(ws: ws, timer: t, program: 'powerpoint'),
    'touchpad': (ws, t) => TouchpadView(ws: ws, timer: t, inks: {}, onInk: (_, _) {}),
    'media': (ws, t) => MediaControlView(ws: ws),
  };

  for (final show in [false, true]) {
    for (final lang in ['tr', 'en']) {
      for (final v in views.entries) {
        for (final s in sizes.entries) {
          testWidgets('${v.key} ($lang, show: $show) at ${s.key}: no overflow, 48 dp targets, labels', (tester) async {
            SharedPreferences.setMockInitialValues({});
            tester.view.physicalSize = s.value.$1;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final handle = tester.ensureSemantics();
            final timer = PresentationTimerController();
            addTearDown(timer.dispose);
            final ws = _Ws(show: show);
            await tester.pumpWidget(MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => SettingsProvider()),
                ChangeNotifierProvider<WebSocketService>.value(value: ws),
              ],
              child: MaterialApp(
                theme: AppTheme.of(AppColorTheme.cobalt.dark),
                locale: Locale(lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s.value.$2)),
                  child: child!,
                ),
                home: Scaffold(body: SafeArea(child: v.value(ws, timer))),
              ),
            ));
            await tester.pump(const Duration(seconds: 1));
            final problems = <String>[];
            Object? ex;
            while ((ex = tester.takeException()) != null) {
              problems.add('OVERFLOW/EXC: ${(ex is FlutterError ? ex.toStringDeep() : ex.toString()).split('\n').where((l) => l.contains('.dart:') || l.contains('overflowed')).join(' / ')}');
            }
            for (final g in [androidTapTargetGuideline, labeledTapTargetGuideline]) {
              final r = await g.evaluate(tester);
              if (!r.passed) problems.add('${g.description}: ${r.reason!.replaceAll(RegExp(r'\s+'), ' ')}');
            }
            handle.dispose();
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 3));
            if (problems.isNotEmpty) {
              // ignore: avoid_print
              print('SWEEP ${v.key} $lang show=$show ${s.key}\n  ${problems.join('\n  ')}');
            }
            expect(problems, isEmpty);
          });
        }
      }
    }
  }
}
