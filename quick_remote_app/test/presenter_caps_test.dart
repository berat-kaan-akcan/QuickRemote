import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/models/draw_tool.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/remote/utils/show_info.dart';
import 'package:quick_remote_app/screens/remote/views/main_controls_view.dart';
import 'package:quick_remote_app/screens/remote/views/touchpad_view.dart';
import 'package:quick_remote_app/screens/remote/widgets/draw_tool_bar.dart';
import 'package:quick_remote_app/screens/remote/widgets/shared_buttons.dart';
import 'package:quick_remote_app/services/presentation_timer_controller.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A connected PC whose messages the test hands in; commands are recorded.
class _Ws extends WebSocketService {
  _Ws() {
    handleMessage({
      'type': 'auth',
      'status': 'ok',
      'presenter': 'impress',
      'presenters': ['impress', 'wps'],
    });
  }

  final List<String> sent = [];

  @override
  bool get isConnected => true;

  @override
  void sendCommand(String command) => sent.add(command);

  @override
  void sendDirect(String command) {}

  /// No show runs; [front] is in front (null: an older PC, no caps).
  void noShow({String? front}) {
    final caps = {'front': ?front, if (front != null) 'caps': <String>[]};
    handleMessage({
      'type': 'STATUS',
      'state': 'POWERPOINT_NOT_RUNNING',
      ...caps,
    });
    handleMessage({'type': 'SLIDE_STATE', 'data': null});
  }

  /// A show on slide 3 of 10; [caps] null: an older PC.
  void show({Set<String>? caps}) => handleMessage({
    'type': 'SLIDE_STATE',
    'current': 3,
    'total': 10,
    'notes': 'Hello',
    if (caps != null) 'front': FrontWindow.show,
    if (caps != null) 'caps': caps.toList(),
  });
}

Widget _app(Widget child, WebSocketService ws) => MultiProvider(
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
    home: Scaffold(body: child),
  ),
);

void main() {
  late PresentationTimerController timer;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    timer = PresentationTimerController();
  });
  tearDown(() => timer.dispose());

  group('ShowInfo', () {
    test('an older PC: the guesses of before', () {
      final ws = _Ws()..show();
      final show = ShowInfo.of(ws);
      expect(show.caps, isNull);
      expect(show.tools, DrawTool.values.toSet());
      expect([
        show.eraseAll,
        show.blank,
        show.media,
        show.rewind,
        show.canJump,
        show.notes,
        show.previews,
      ], everyElement(isTrue));
      expect([show.spotlight, show.zoom, show.undo], everyElement(isFalse));

      ws.noShow();
      final none = ShowInfo.of(ws);
      expect(none.tools, isEmpty);
      expect(none.viewer, isFalse);
      expect(none.canJump, isTrue);
    });

    test('a PC with caps says which tools work', () {
      final ws = _Ws()
        ..show(
          caps: {
            RemoteCaps.laser,
            RemoteCaps.pen,
            RemoteCaps.goto,
            RemoteCaps.spotlight,
          },
        );
      final show = ShowInfo.of(ws);
      expect(show.front, FrontWindow.show);
      expect(show.tools, {DrawTool.laser, DrawTool.pen});
      expect([
        show.eraseAll,
        show.blank,
        show.media,
        show.rewind,
        show.colorsAvailable,
        show.notes,
        show.previews,
        show.zoom,
      ], everyElement(isFalse));
      expect([show.canJump, show.spotlight], everyElement(isTrue));
    });

    test(
      'a PDF in front, told by the "no show" status, stays after the empty slide state',
      () {
        final ws = _Ws()..noShow(front: FrontWindow.pdf);
        expect(ws.frontWindow, FrontWindow.pdf);
        final show = ShowInfo.of(ws);
        expect(show.viewer, isTrue);
        expect(show.canJump, isFalse);
        expect(show.tools, isEmpty);
      },
    );
  });

  group('the controls', () {
    Future<void> pumpControls(WidgetTester tester, _Ws ws) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          // The remote screen rebuilds the view when the PC's state changes.
          ListenableBuilder(
            listenable: ws,
            builder: (_, _) => MainControlsView(ws: ws, timer: timer, program: 'impress'),
          ),
          ws,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('a PDF in front: page turns and full screen, no go-to-slide', (
      tester,
    ) async {
      final ws = _Ws()..noShow(front: FrontWindow.pdf);
      await pumpControls(tester, ws);
      expect(
        find.text('PDF open · page turns and full screen only'),
        findsOneWidget,
      );
      expect(find.textContaining('No Presentation Open'), findsNothing);
      expect(find.text('Go to slide'), findsNothing);
      await tester.tap(find.text('Full screen'));
      expect(ws.sent, [RemoteCommands.start]);
    });

    testWidgets('a browser in front says so', (tester) async {
      final ws = _Ws()..noShow(front: FrontWindow.browser);
      await pumpControls(tester, ws);
      expect(
        find.text('Browser in front · page turns and full screen only'),
        findsOneWidget,
      );
      expect(find.text('Full screen'), findsOneWidget);
    });

    testWidgets('a WPS the user started can be taken over', (tester) async {
      final ws = _Ws()
        ..handleMessage({
          'type': 'STATUS',
          'state': 'POWERPOINT_NOT_RUNNING',
          'front': FrontWindow.editor,
          'caps': [RemoteCaps.takeOver],
        })
        ..handleMessage({'type': 'SLIDE_STATE', 'data': null});
      await pumpControls(tester, ws);
      expect(find.textContaining('No Presentation Open'), findsNothing);
      await tester.tap(find.text('Take over'));
      expect(ws.sent, [RemoteCommands.wpsTakeOver]);
      // In a show it stays under the card; without the cap it goes.
      ws.show(caps: {RemoteCaps.takeOver, RemoteCaps.laser});
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Take over'), findsOneWidget);
      ws.show(caps: {RemoteCaps.laser});
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Take over'), findsNothing);
    });

    testWidgets('an older PC without a show: as before', (tester) async {
      final ws = _Ws()..noShow();
      await pumpControls(tester, ws);
      expect(find.textContaining('No Presentation Open'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Go to slide'), findsOneWidget);
    });

    testWidgets('black and white fade when the PC cannot blank the screen', (
      tester,
    ) async {
      final ws = _Ws()..show(caps: {RemoteCaps.laser, RemoteCaps.notes});
      await pumpControls(tester, ws);
      final keys = tester.widgetList<ScreenKey>(find.byType(ScreenKey));
      expect(keys.map((k) => k.onTap), everyElement(isNull));
      // The note shows; without the notes cap it would not.
      expect(find.text('Hello'), findsOneWidget);

      ws.show(caps: {RemoteCaps.blank});
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widgetList<ScreenKey>(find.byType(ScreenKey))
            .map((k) => k.onTap),
        everyElement(isNotNull),
      );
      expect(find.text('Hello'), findsNothing);
    });
  });

  group('the touchpad', () {
    testWidgets('tools the PC lacks are faded, Clear too', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ws = _Ws()..show(caps: {RemoteCaps.laser, RemoteCaps.pen});
      await tester.pumpWidget(
        _app(
          TouchpadView(ws: ws, timer: timer, inks: const {}, onInk: (_, _) {}),
          ws,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final bar = tester.widget<DrawToolBar>(find.byType(DrawToolBar));
      expect(bar.enabled, isTrue);
      expect(bar.available, {DrawTool.laser, DrawTool.pen});
      expect(bar.clearEnabled, isFalse);
    });

    testWidgets('a faded tool and a faded Clear ignore taps', (tester) async {
      final picked = <DrawTool>[];
      var cleared = 0;
      await tester.pumpWidget(
        _app(
          DrawToolBar(
            activeTool: DrawTool.laser,
            onToolSelected: picked.add,
            onClear: () => cleared++,
            available: const {DrawTool.laser, DrawTool.pen},
            clearEnabled: false,
          ),
          _Ws(),
        ),
      );
      await tester.tap(find.text('Highlight'));
      await tester.tap(find.text('Eraser'));
      await tester.tap(find.text('Clear'));
      await tester.tap(find.text('Pen'));
      await tester.pump(const Duration(seconds: 1));
      expect(picked, [DrawTool.pen]);
      expect(cleared, 0);
    });
  });
}
