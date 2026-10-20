import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/remote/presenter_view_screen.dart';
import 'package:quick_remote_app/screens/remote/widgets/shared_buttons.dart';
import 'package:quick_remote_app/screens/remote/widgets/slide_image.dart';
import 'package:quick_remote_app/services/presentation_timer_controller.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A show on slide [current] of 10 with pictures, connected or not.
class _Ws extends WebSocketService {
  _Ws({int current = 3}) {
    handleMessage({'type': 'auth', 'status': 'ok', 'previews': true});
    show(current);
  }

  bool connected = true;

  @override
  bool get isConnected => connected;

  @override
  void sendDirect(String command) {}

  void show(int current) {
    handleMessage({
      'type': 'SLIDE_STATE',
      'current': current,
      'total': 10,
      'notes': 'Say hello at slide $current',
      'deck': 1,
    });
    for (final kind in [SlideImageKind.current, SlideImageKind.next]) {
      handleImage(
        SlideImageFrame(
          kind: kind,
          slide: kind == SlideImageKind.current ? current : current + 1,
          deck: 1,
          width: 640,
          height: 360,
          jpeg: Uint8List.fromList([0xFF, 0xD8, kind.index, current]),
        ),
      );
    }
  }

  void drop() {
    connected = false;
    notifyListeners();
  }
}

void main() {
  late List<String> sent;
  late PresentationTimerController timer;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent = [];
    timer = PresentationTimerController();
  });
  tearDown(() => timer.dispose());

  Future<void> pumpView(WidgetTester tester, _Ws ws, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider<WebSocketService>.value(value: ws),
        ],
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
          home: PresenterViewScreen(timer: timer, onSend: sent.add),
        ),
      ),
    );
    await tester.pump();
  }

  Rect rectOf(WidgetTester tester, int slide) => tester.getRect(
    find.byWidgetPredicate((w) => w is SlideImage && w.slide == slide),
  );

  testWidgets(
    'upright: the slide on top, the next one, the notes and the keys below',
    (tester) async {
      await pumpView(tester, _Ws(), const Size(400, 860));
      expect(tester.takeException(), isNull);
      expect(find.text('NEXT UP'), findsOneWidget);
      expect(find.text('Say hello at slide 3'), findsOneWidget);
      final current = rectOf(tester, 3);
      final next = rectOf(tester, 4);
      expect(current.width, greaterThan(next.width * 2));
      expect(next.top, greaterThan(current.bottom));
      expect(
        tester.getRect(find.byType(BigSlideButton).first).top,
        greaterThan(next.bottom),
      );
    },
  );

  testWidgets('on its side: the slide on the left, the rest on the right', (
    tester,
  ) async {
    await pumpView(tester, _Ws(), const Size(900, 420));
    expect(tester.takeException(), isNull);
    final current = rectOf(tester, 3);
    final next = rectOf(tester, 4);
    expect(next.left, greaterThan(current.right));
    expect(
      tester.getRect(find.byType(BigSlideButton).last).left,
      greaterThan(current.right),
    );
  });

  testWidgets('the keys send PREV and NEXT', (tester) async {
    await pumpView(tester, _Ws(), const Size(400, 860));
    await tester.tap(find.bySemanticsLabel('Next'));
    await tester.tap(find.bySemanticsLabel('Previous'));
    expect(sent, [RemoteCommands.next, RemoteCommands.prev]);
  });

  testWidgets('the last slide has no next picture', (tester) async {
    await pumpView(tester, _Ws(current: 10), const Size(400, 860));
    expect(find.text('Last slide'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is SlideImage && w.slide == 11),
      findsNothing,
    );
  });

  testWidgets('a lost link keeps the last state, faded, and the keys off', (
    tester,
  ) async {
    final ws = _Ws();
    await pumpView(tester, ws, const Size(400, 860));
    ws.drop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Say hello at slide 3'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is AnimatedOpacity && w.opacity == 0.55),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Next'));
    expect(sent, isEmpty);
  });

  testWidgets('a full-screen PDF: the PC\'s screen and the keys, no slide parts', (tester) async {
    final ws = _Ws()
      ..handleMessage({'type': 'STATUS', 'state': 'POWERPOINT_NOT_RUNNING', 'front': FrontWindow.pdf, 'caps': <String>[]})
      ..handleMessage({'type': 'SLIDE_STATE', 'data': null, 'front': FrontWindow.pdf, 'caps': <String>[]})
      ..handleImage(
        SlideImageFrame(
          kind: SlideImageKind.screen,
          slide: 0,
          deck: 0,
          width: 1280,
          height: 720,
          jpeg: Uint8List.fromList([0xFF, 0xD8, 3, 0]),
        ),
      );
    await pumpView(tester, ws, const Size(400, 860));
    expect(tester.takeException(), isNull);
    expect(find.text("The PC's screen"), findsOneWidget);
    expect(find.text('NEXT UP'), findsNothing);
    expect(find.text('No slideshow is running.'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Next'));
    expect(sent, [RemoteCommands.next], reason: 'the viewer turns its page');
  });
}
