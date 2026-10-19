import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/screens/remote/utils/go_to_slide_sheet.dart';
import 'package:quick_remote_app/screens/remote/widgets/slide_image.dart';
import 'package:quick_remote_app/services/websocket/thumbnail_requests.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:quick_remote_app/widgets/ui/ui.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

SlideImageFrame thumbnail(int slide) => SlideImageFrame(
  kind: SlideImageKind.thumbnail,
  slide: slide,
  deck: 1,
  width: 320,
  height: 180,
  jpeg: Uint8List.fromList([0xFF, 0xD8, slide]),
);

/// A running show of [total] slides on slide 2; what it would send is kept.
class _Ws extends WebSocketService {
  _Ws({int total = 20, bool pictures = true}) {
    handleMessage({'type': 'auth', 'status': 'ok', 'previews': true});
    handleMessage({
      'type': 'SLIDE_STATE',
      'current': 2,
      'total': total,
      'notes': '',
      'deck': 1,
    });
    if (pictures) {
      handleImage(
        SlideImageFrame(
          kind: SlideImageKind.current,
          slide: 2,
          deck: 1,
          width: 1280,
          height: 720,
          jpeg: Uint8List.fromList([0xFF, 0xD8, 0]),
        ),
      );
    }
  }

  final List<String> sent = [];

  @override
  void sendDirect(String command) => sent.add(command);

  List<int> get asked => sent
      .where((c) => c.startsWith('SLIDE_THUMB:'))
      .map((c) => int.parse(c.split(':')[1]))
      .toList();
}

void main() {
  group('ThumbnailRequests', () {
    test('asks four at a time, in order, and the next when one arrives', () {
      final sent = <int>[];
      final requests = ThumbnailRequests(send: sent.add);
      for (var slide = 1; slide <= 6; slide++) {
        requests.request(slide);
      }
      requests.request(2); // already asked
      expect(sent, [1, 2, 3, 4]);
      requests.cancel(5); // scrolled away
      requests.arrived(1);
      expect(sent, [1, 2, 3, 4, 6]);
      requests.reset();
    });

    test('one that does not come counts as failed, once', () async {
      final sent = <int>[];
      var failures = 0;
      final requests = ThumbnailRequests(
        send: sent.add,
        onFailed: () => failures++,
        timeout: const Duration(milliseconds: 20),
      );
      requests.request(1);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(requests.failed(1), isTrue);
      expect(failures, 1);
      requests.request(1);
      expect(sent, [1], reason: 'not asked again');
      requests.reset();
      expect(requests.failed(1), isFalse);
    });
  });

  group('the grid', () {
    late List<String> picked;

    setUp(() => picked = []);

    Future<void> open(WidgetTester tester, _Ws ws) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => GoToSlideSheet.show(
                  context,
                  totalSlides: ws.totalSlides,
                  onSend: picked.add,
                  ws: ws,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    /// Waits for the sheet to go: its cells take back what they did not get.
    Future<void> closed(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byType(GridView), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    }

    /// Lets the unanswered requests time out, so no timer outlives the test.
    Future<void> finish(WidgetTester tester) async {
      Navigator.of(tester.element(find.byType(GridView))).pop();
      await closed(tester);
    }

    testWidgets('asks for the visible thumbnails, a few at a time', (
      tester,
    ) async {
      final ws = _Ws();
      await open(tester, ws);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      // Slide 2 has a picture already.
      expect(ws.asked, [1, 3, 4, 5]);
      expect(find.byType(Skeleton), findsWidgets);

      ws.handleImage(thumbnail(3));
      await tester.pump();
      expect(ws.asked, [1, 3, 4, 5, 6]);
      expect(
        find.byWidgetPredicate(
          (w) => w is SlideImage && w.slide == 3 && w.image != null,
        ),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('a tap jumps to that slide', (tester) async {
      final ws = _Ws();
      await open(tester, ws);
      await tester.tap(
        find.byWidgetPredicate((w) => w is SlideImage && w.slide == 2),
      );
      expect(picked, [RemoteCommands.startAt(2)]);
      await closed(tester);
    });

    testWidgets('a thumbnail that does not come leaves the empty frame', (
      tester,
    ) async {
      final ws = _Ws(total: 3);
      await open(tester, ws);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(Skeleton), findsNothing);
      expect(find.byType(SlideImage), findsNWidgets(3));
      await finish(tester);
    });

    testWidgets('without pictures the number keyboard stays', (tester) async {
      await open(tester, _Ws(pictures: false));
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
