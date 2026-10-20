import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/server/slide_previewer.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

/// Screen pictures (SlidePreviewer.capture): when they are taken, which
/// frame they go as, and when they are not sent.
void main() {
  const settle = Duration(milliseconds: 40);
  const poll = Duration(milliseconds: 150);

  late List<(Object, SlideImageFrame)> sent;
  late int captures;
  late int hash;

  /// What the next capture answers; null: no picture.
  late bool screenAvailable;

  /// When set, a capture waits for it.
  Completer<void>? gate;
  late SlidePreviewer previewer;

  /// A JPEG whose third byte tells pictures apart: 0xEE for screen pictures,
  /// the slide number for exported ones.
  Uint8List jpeg(int marker) => Uint8List.fromList([0xFF, 0xD8, marker, 0, 0]);

  Future<SlideImage?> export(int index, int width) async =>
      (jpeg: jpeg(index), width: width, height: width ~/ 2);

  setUp(() {
    sent = [];
    captures = 0;
    hash = 1;
    screenAvailable = true;
    gate = null;
    previewer = SlidePreviewer(
      send: (client, frame) =>
          sent.add((client, SlideImageFrame.decode(frame)!)),
      exporter: export,
      capture: () async {
        captures++;
        if (gate != null) await gate!.future;
        if (!screenAvailable) return null;
        return (image: (jpeg: jpeg(0xEE), width: 1280, height: 720), hash: hash);
      },
      settleDelay: settle,
      pollInterval: poll,
    );
  });

  tearDown(() => previewer.reset());

  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  List<(SlideImageKind, int, int)> frames() => [
    for (final (_, f) in sent) (f.kind, f.slide, f.jpeg[2]),
  ];

  group('a viewer in front', () {
    test('a full-screen PDF goes as a screen picture, slide 0', () async {
      previewer.show(null, front: FrontWindow.pdf);
      previewer.setEnabled('a', true);
      await wait(20);
      expect(sent, hasLength(1));
      final frame = sent.single.$2;
      expect(frame.kind, SlideImageKind.screen);
      expect(frame.slide, 0);
      expect(frame.deck, 0);
      expect(frame.jpeg[2], 0xEE);
    });

    test('a page turn takes it again after the settle delay', () async {
      previewer.show(null, front: FrontWindow.browser);
      previewer.setEnabled('a', true);
      await wait(20);
      hash = 2;
      previewer.slideMoved();
      await wait(10);
      expect(captures, 1, reason: 'the transition is still running');
      await wait(60);
      expect(captures, 2);
      expect(frames(), [
        (SlideImageKind.screen, 0, 0xEE),
        (SlideImageKind.screen, 0, 0xEE),
      ]);
    });

    test(
      'nothing is taken for the desktop, an editor or another window',
      () async {
        for (final front in [null, FrontWindow.other, FrontWindow.editor]) {
          previewer.show(null, front: front);
          previewer.setEnabled('a', true);
          previewer.slideMoved();
          await wait(60);
        }
        expect(captures, 0);
        expect(sent, isEmpty);
      },
    );

    test('no phone with previews on, no picture', () async {
      previewer.show(null, front: FrontWindow.pdf);
      previewer.slideMoved();
      await wait(200);
      expect(captures, 0);
    });

    test(
      'a platform without a picture (not full screen) sends nothing',
      () async {
        screenAvailable = false;
        previewer.show(null, front: FrontWindow.pdf);
        previewer.setEnabled('a', true);
        await wait(20);
        expect(captures, 1);
        expect(sent, isEmpty);
      },
    );

    test('a viewer that comes back is sent again', () async {
      previewer.show(null, front: FrontWindow.pdf);
      previewer.setEnabled('a', true);
      await wait(20);
      previewer.show(null, front: FrontWindow.other);
      previewer.show(null, front: FrontWindow.pdf);
      await wait(70);
      expect(frames(), hasLength(2), reason: 'the phone dropped it meanwhile');
    });
  });

  group('polling', () {
    test('an unchanged screen is not sent again; a changed one is', () async {
      previewer.show(null, front: FrontWindow.pdf);
      previewer.setEnabled('a', true);
      await wait(20);
      await wait(170);
      expect(captures, greaterThanOrEqualTo(2));
      expect(sent, hasLength(1));
      hash = 2; // a video moved
      await wait(160);
      expect(sent, hasLength(2));
    });

    test('stops when no phone wants pictures', () async {
      previewer.show(null, front: FrontWindow.pdf);
      previewer.setEnabled('a', true);
      await wait(20);
      previewer.setEnabled('a', false);
      final before = captures;
      await wait(320);
      expect(captures, before);
    });
  });

  group('in a show', () {
    test('the picture goes as the current slide', () async {
      previewer.show((deck: 9, current: 2, total: 5), front: FrontWindow.show);
      previewer.setEnabled('a', true);
      await wait(30);
      expect(
        frames(),
        containsAll([
          (SlideImageKind.current, 2, 0xEE),
          (SlideImageKind.next, 3, 3),
        ]),
      );
      expect(
        sent.where((s) => s.$2.kind == SlideImageKind.current).last.$2.jpeg[2],
        0xEE,
        reason: 'the screen picture comes after the export and replaces it',
      );
      expect(
        sent.firstWhere((s) => s.$2.kind == SlideImageKind.current).$2.deck,
        9,
      );
    });

    test(
      'after NEXT it waits for the slide state, so the number is right',
      () async {
        previewer.show((
          deck: 9,
          current: 1,
          total: 5,
        ), front: FrontWindow.show);
        previewer.setEnabled('a', true);
        await wait(30);
        final before = captures;
        hash = 2;
        previewer.slideMoved();
        await wait(80);
        expect(
          captures,
          before,
          reason: 'no state yet: the old number would go with the new slide',
        );
        sent.clear();
        previewer.show((
          deck: 9,
          current: 2,
          total: 5,
        ), front: FrontWindow.show);
        await wait(20);
        expect(frames().where((f) => f.$1 == SlideImageKind.current).toList(), [
          (SlideImageKind.current, 2, 2), // the export, at once
          (SlideImageKind.current, 2, 0xEE), // the screen, which replaces it
        ]);
      },
    );

    test(
      'a state read already on its way when NEXT went does not count',
      () async {
        previewer.show((
          deck: 9,
          current: 1,
          total: 5,
        ), front: FrontWindow.show);
        previewer.setEnabled('a', true);
        await wait(30);
        final before = captures;
        previewer.slideMoved();
        previewer.show((
          deck: 9,
          current: 1,
          total: 5,
        ), front: FrontWindow.show);
        await wait(80);
        expect(captures, before);
      },
    );

    test('a picture taken while the slide moved is dropped', () async {
      previewer.show((deck: 9, current: 1, total: 5), front: FrontWindow.show);
      gate = Completer();
      previewer.setEnabled('a', true);
      await wait(10);
      expect(captures, 1);
      previewer.slideMoved();
      gate!.complete();
      gate = null;
      await wait(10);
      expect(frames().where((f) => f.$3 == 0xEE), isEmpty);
    });

    test('an animation step (same slide) is taken again', () async {
      previewer.show((deck: 9, current: 1, total: 5), front: FrontWindow.show);
      previewer.setEnabled('a', true);
      await wait(30);
      sent.clear();
      hash = 2;
      previewer.slideMoved();
      await wait(35);
      previewer.show((deck: 9, current: 1, total: 5), front: FrontWindow.show);
      await wait(30);
      expect(frames(), [(SlideImageKind.current, 1, 0xEE)]);
    });

    test(
      'a show without a slide number (a WPS the PC cannot read) sends the screen',
      () async {
        previewer.show((
          deck: 9,
          current: 0,
          total: 0,
        ), front: FrontWindow.show);
        previewer.setEnabled('a', true);
        await wait(20);
        expect(frames(), [(SlideImageKind.screen, 0, 0xEE)]);
      },
    );

    test('a slide changed on the PC is taken after the settle delay', () async {
      previewer.show((deck: 9, current: 1, total: 5), front: FrontWindow.show);
      previewer.setEnabled('a', true);
      await wait(30);
      final before = captures;
      previewer.show((deck: 9, current: 3, total: 5), front: FrontWindow.show);
      await wait(10);
      expect(captures, before);
      await wait(50);
      expect(captures, before + 1);
      expect(frames().last, (SlideImageKind.current, 3, 0xEE));
    });
  });
}
