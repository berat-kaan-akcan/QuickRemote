import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/remote/utils/show_info.dart';
import 'package:quick_remote_app/screens/remote/views/main_controls_view.dart';
import 'package:quick_remote_app/screens/remote/widgets/slide_image.dart';
import 'package:quick_remote_app/services/websocket/presentation_state.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

SlideImageFrame frame(SlideImageKind kind, int slide, {int deck = 7}) =>
    SlideImageFrame(
      kind: kind,
      slide: slide,
      deck: deck,
      width: 640,
      height: 360,
      jpeg: Uint8List.fromList([0xFF, 0xD8, kind.index, slide]),
    );

/// Records the settings it would send instead of sending them.
class _Ws extends WebSocketService {
  final List<String> sent = [];

  @override
  void sendDirect(String command) => sent.add(command);
}

Map<String, dynamic> slideState(int current, {int total = 10, int? deck = 7}) =>
    {
      'type': 'SLIDE_STATE',
      'current': current,
      'total': total,
      'notes': '',
      'deck': ?deck,
    };

SlideImageFrame screenFrame([int marker = 1]) => SlideImageFrame(
  kind: SlideImageKind.screen,
  slide: 0,
  deck: 0,
  width: 1280,
  height: 720,
  jpeg: Uint8List.fromList([0xFF, 0xD8, 0xEE, marker]),
);

/// No show; [front] in front (what the PC sends then).
Map<String, dynamic> noShow(String front) => {
  'type': 'SLIDE_STATE',
  'data': null,
  'front': front,
  'caps': <String>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PresentationState', () {
    PresentationState state() =>
        PresentationState()..updateFromSlideState(slideState(3));

    test('keeps pictures of its deck and drops others', () {
      final s = state();
      expect(s.addImage(frame(SlideImageKind.current, 3)), isTrue);
      expect(s.addImage(frame(SlideImageKind.current, 4, deck: 8)), isFalse);
      expect(s.currentSlideImage, [0xFF, 0xD8, 0, 3]);
      expect(s.imageOf(4), isNull);
    });

    test('the next picture shows at once after NEXT', () {
      final s = state()..addImage(frame(SlideImageKind.next, 4));
      expect(s.nextSlideImage, [0xFF, 0xD8, 1, 4]);
      s.updateFromSlideState(slideState(4));
      expect(s.currentSlideImage, [
        0xFF,
        0xD8,
        1,
        4,
      ], reason: 'until the large one comes');
      s.addImage(frame(SlideImageKind.current, 4));
      expect(s.currentSlideImage, [0xFF, 0xD8, 0, 4]);
    });

    test('the last slide has no next picture', () {
      final s = state()..addImage(frame(SlideImageKind.thumbnail, 11));
      s.updateFromSlideState(slideState(10));
      expect(s.nextSlideImage, isNull);
    });

    test('another deck empties the cache', () {
      final s = state()
        ..addImage(frame(SlideImageKind.current, 3))
        ..addImage(frame(SlideImageKind.thumbnail, 5));
      s.updateFromSlideState(slideState(3));
      expect(s.hasSlideImages, isTrue, reason: 'same deck');
      s.updateFromSlideState(slideState(3, deck: 9));
      expect(s.hasSlideImages, isFalse);
      expect(s.thumbnail(5), isNull);
    });

    test('keeps a bounded number of pictures', () {
      final s = state();
      for (var slide = 1; slide <= 20; slide++) {
        s.addImage(frame(SlideImageKind.current, slide));
      }
      expect(s.imageOf(14), isNull);
      expect(s.imageOf(15), isNotNull);
    });

    test('the screen picture shows while a viewer is in front', () {
      final s = PresentationState()..updateCaps(noShow(FrontWindow.pdf));
      expect(s.addImage(screenFrame()), isTrue);
      expect(s.screenImage, [0xFF, 0xD8, 0xEE, 1]);
      expect(s.hasSlideImages, isFalse, reason: 'no slide picture');
      s.updateCaps(noShow(FrontWindow.browser));
      expect(s.screenImage, isNotNull);
      s.updateCaps(noShow(FrontWindow.other));
      expect(s.screenImage, isNull);
      s.updateCaps(noShow(FrontWindow.pdf));
      expect(s.screenImage, isNull, reason: 'the old picture is of something else');
    });

    test('and while a show the PC cannot read runs, not in a readable one', () {
      final s = PresentationState()
        ..updateFromSlideState({...slideState(0, total: 0), 'front': FrontWindow.show, 'caps': <String>[]})
        ..addImage(screenFrame());
      expect(s.screenImage, isNotNull);
      s.updateFromSlideState({...slideState(3), 'front': FrontWindow.show, 'caps': <String>[]});
      expect(s.screenImage, isNull);
    });

    test('the end of the show forgets the pictures', () {
      final s = state()..addImage(frame(SlideImageKind.current, 3));
      s.reset();
      expect(s.hasSlideImages, isFalse);
      expect(s.deck, isNull);
    });
  });

  group('the setting', () {
    test('is on by default and stored', () async {
      final provider = SettingsProvider();
      await Future<void>.delayed(Duration.zero);
      expect(provider.slidePreview, isTrue);
      await provider.setSlidePreview(false);
      final reloaded = SettingsProvider();
      await Future<void>.delayed(Duration.zero);
      expect(reloaded.slidePreview, isFalse);
    });

    test('goes to a PC with previews after every connect', () {
      final ws = _Ws()
        ..handleMessage({'type': 'auth', 'status': 'ok', 'previews': true});
      ws.sendSettings();
      expect(ws.sent, [
        RemoteCommands.keepInk(false),
        RemoteCommands.slidePreview(true),
      ]);
      expect(ws.previewsAvailable, isTrue);
    });

    test('is not sent to an older PC', () {
      final ws = _Ws()..handleMessage({'type': 'auth', 'status': 'ok'});
      ws.sendSettings();
      ws.setSlidePreview(false);
      expect(ws.sent, [RemoteCommands.keepInk(false)]);
      expect(ws.previewsAvailable, isFalse);
    });

    test('a change is sent, and off hides the pictures', () {
      final ws = _Ws()
        ..handleMessage({'type': 'auth', 'status': 'ok', 'previews': true})
        ..handleMessage(slideState(3))
        ..handleImage(frame(SlideImageKind.current, 3));
      expect(ws.currentSlideImage, isNotNull);
      ws.setSlidePreview(false);
      expect(ws.sent, [RemoteCommands.slidePreview(false)]);
      expect(ws.currentSlideImage, isNull);
      expect(ws.hasSlideImages, isFalse);
    });
  });

  group('screen picture', () {
    _Ws viewer() => _Ws()
      ..handleMessage({'type': 'auth', 'status': 'ok', 'previews': true})
      ..handleMessage({'type': 'STATUS', 'state': 'POWERPOINT_NOT_RUNNING', 'front': FrontWindow.pdf, 'caps': <String>[]})
      ..handleMessage(noShow(FrontWindow.pdf))
      ..handleImage(screenFrame());

    test('comes through the service, only with previews on', () {
      final ws = viewer();
      expect(ws.screenImage, isNotNull);
      ws.setSlidePreview(false);
      expect(ws.screenImage, isNull);
    });

    test('stays across the empty slide state that repeats "no show"', () {
      final ws = viewer()..handleMessage(noShow(FrontWindow.pdf));
      expect(ws.screenImage, [0xFF, 0xD8, 0xEE, 1]);
    });

    test('a newer one replaces it', () {
      final ws = viewer()..handleImage(screenFrame(2));
      expect(ws.screenImage, [0xFF, 0xD8, 0xEE, 2]);
    });
  });

  group('SlideCard', () {
    Future<void> pumpCard(
      WidgetTester tester,
      WebSocketService ws, {
      String? activeScreen,
      VoidCallback? onPreview,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
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
              child: SlideCard(
                ws: ws,
                show: ShowInfo.of(ws),
                timer: const SizedBox(),
                activeScreen: activeScreen,
                onNotes: () {},
                onPreview: onPreview,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    WebSocketService withShow({bool picture = true}) {
      final ws = _Ws()
        ..handleMessage({'type': 'auth', 'status': 'ok', 'previews': true})
        ..handleMessage(slideState(3));
      if (picture) ws.handleImage(frame(SlideImageKind.current, 3));
      return ws;
    }

    double coverOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(SlideImage),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('shows the slide\'s picture beside its number', (tester) async {
      await pumpCard(tester, withShow());
      expect(find.byType(SlideImage), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel('Preview of slide 3'), findsOneWidget);
      expect(coverOpacity(tester), 0);
    });

    testWidgets('looks as before without pictures', (tester) async {
      await pumpCard(tester, withShow(picture: false));
      expect(find.byType(SlideImage), findsNothing);
    });

    testWidgets('a tap on the picture opens the presenter view', (tester) async {
      var opened = 0;
      await pumpCard(tester, withShow(), onPreview: () => opened++);
      await tester.tap(find.byType(SlideImage));
      expect(opened, 1);
      expect(SlideCard.showsPreview(withShow(), ShowInfo.of(withShow())), isTrue);
      final noPicture = withShow(picture: false);
      expect(SlideCard.showsPreview(noPicture, ShowInfo.of(noPicture)), isFalse);
    });

    testWidgets('a full-screen PDF shows the PC\'s screen', (tester) async {
      final ws = _Ws()
        ..handleMessage({'type': 'auth', 'status': 'ok', 'previews': true})
        ..handleMessage(noShow(FrontWindow.pdf));
      await pumpCard(tester, ws);
      expect(find.byType(SlideImage), findsNothing, reason: 'no picture yet');
      ws.handleImage(screenFrame());
      await pumpCard(tester, ws);
      expect(find.byType(SlideImage), findsOneWidget);
      expect(find.bySemanticsLabel("The PC's screen"), findsOneWidget);
    });

    testWidgets('a black screen covers the picture', (tester) async {
      await pumpCard(tester, withShow(), activeScreen: 'BLACK');
      expect(coverOpacity(tester), 1);
    });
  });
}
