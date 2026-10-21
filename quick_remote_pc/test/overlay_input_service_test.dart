import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/input/overlay_input_service.dart';
import 'package:quick_remote_pc/services/overlay/laser_overlay.dart';

import 'fakes.dart';

void main() {
  late FakeInputService inner;
  late FakeLaserOverlay overlay;
  late OverlayInputService service;

  setUp(() {
    LaserOverlaySettings.mode = LaserOverlayMode.auto;
    inner = FakeInputService();
    overlay = FakeLaserOverlay();
    service = OverlayInputService(inner, overlay);
  });

  tearDown(() {
    LaserOverlaySettings.mode = LaserOverlayMode.auto;
  });

  Future<void> showBy(String? presenter, {int slide = 1}) async {
    inner.slideState = presenter == null
        ? {'error': 'POWERPOINT_NOT_RUNNING'}
        : {'current': slide, 'total': 9, 'presenter': presenter, 'deckKey': 'deck'};
    await service.getSlideState();
  }

  /// A stroke as the server sends it: the position, the button, motion, up.
  void stroke(double x, double y, {double dx = 0.1}) {
    service.drawPointerMoved(x, y);
    service.leftDown();
    service.drawPointerMoved(x + dx, y);
    service.leftUp();
  }

  group('laser', () {
    test('in Impress the overlay draws it, the cursor stays still', () async {
      await showBy('impress');
      await service.modeLaser();
      expect(service.handlesLaserPointer, isTrue);
      service.laserPointerMoved(0.5, 0.5);
      service.laserOff();
      expect(overlay.calls, ['place', 'show', 'move', 'hide']);
      expect(inner.calls, isNot(contains('modeLaser')));
      expect(service.handlesLaserPointer, isFalse);
    });

    test('PowerPoint and WPS keep their own', () async {
      for (final program in ['powerpoint', 'wps']) {
        await showBy(program);
        await service.modeLaser();
        service.laserPointerMoved(0.5, 0.5);
        service.laserOff();
      }
      expect(overlay.calls, isEmpty);
      expect(inner.calls.where((c) => c == 'modeLaser'), hasLength(2));
      expect(inner.calls.where((c) => c == 'laserPointerMoved'), hasLength(2));
    });

    test('without a slideshow it presses nothing', () async {
      await showBy(null);
      await service.modeLaser();
      service.laserOff();
      service.modeArrow();
      expect(overlay.calls, ['place', 'show', 'hide']);
      expect(inner.calls, isEmpty);
      expect(service.toolsAnywhere, isTrue);
    });

    test('always: the overlay in PowerPoint too', () async {
      LaserOverlaySettings.mode = LaserOverlayMode.always;
      await showBy('powerpoint');
      await service.modeLaser();
      expect(overlay.calls, ['place', 'show']);
      expect(inner.calls, isNot(contains('modeLaser')));
    });

    test('never: the program\'s laser, only during a show', () async {
      LaserOverlaySettings.mode = LaserOverlayMode.never;
      await showBy('impress');
      await service.modeLaser();
      expect(overlay.calls, isEmpty);
      expect(inner.calls, contains('modeLaser'));
      expect(service.toolsAnywhere, isFalse);
    });

    test('a PC that cannot show the overlay keeps the program\'s laser', () async {
      overlay.supported = false;
      await showBy('impress');
      await service.modeLaser();
      expect(overlay.calls, isEmpty);
      expect(inner.calls, contains('modeLaser'));
      expect(service.toolsAnywhere, isFalse);
    });

    test('the overlay opens on the show\'s monitor', () async {
      inner.area = (x: 1920, y: 0, width: 1920, height: 1080);
      await showBy('impress');
      await service.modeLaser();
      expect(overlay.placedOn, (x: 1920, y: 0, width: 1920, height: 1080));
    });

    group('the overlay fails to start', () {
      setUp(() => overlay.starts = false);

      test('in a show: the program\'s laser', () async {
        await showBy('impress');
        await service.modeLaser();
        expect(service.handlesLaserPointer, isFalse);
        expect(inner.calls, contains('modeLaser'));
      });

      test('without a show: reported, nothing pressed', () async {
        final errors = <RemoteError>[];
        service.onCommandError = (error, [_]) => errors.add(error);
        await showBy(null);
        await service.modeLaser();
        expect(errors, [RemoteError.slideshowNotRunning]);
        expect(inner.calls, isEmpty);
      });
    });
  });

  group('ink', () {
    test('the pen draws on the overlay, no click reaches the PC', () async {
      await showBy('impress');
      await service.modePen();
      expect(service.handlesDrawPointer, isTrue);
      stroke(0.2, 0.2);
      service.modeArrow();
      expect(overlay.calls, ['place', 'inkBegin:pen:ff0000', 'inkTo', 'inkEnd']);
      expect(inner.calls, isNot(anyOf(contains('leftDown'), contains('modePen'))));
      expect(service.strokes, hasLength(1));
      expect(service.handlesDrawPointer, isFalse);
    });

    test('the colors the phone picked, from BGR', () async {
      await showBy(null);
      await service.setPenColor(0xFF0000); // blue
      await service.setHighlighterColor(0x00FF00); // green
      await service.modePen();
      stroke(0.2, 0.2);
      await service.modeHighlighter();
      stroke(0.3, 0.3);
      expect(overlay.calls, containsAllInOrder(['inkBegin:pen:0000ff', 'inkBegin:highlighter:00ff00']));
      // Not to Impress, which would report no show.
      expect(inner.calls, isNot(contains('setPenColor:16711680')));
    });

    test('the eraser takes away the strokes it touches', () async {
      await showBy(null);
      await service.modePen();
      stroke(0.2, 0.2);
      stroke(0.2, 0.8);
      await service.modeEraser();
      overlay.calls.clear();
      service.drawPointerMoved(0.25, 0.2);
      service.leftDown();
      service.leftUp();
      expect(service.strokes, hasLength(1));
      expect(service.strokes.single.points.first, (0.2, 0.8));
      // Cleared and the other stroke drawn again.
      expect(overlay.calls, ['inkClear', 'inkBegin:pen:ff0000', 'inkTo', 'inkEnd']);
    });

    test('ERASE_ALL clears the overlay, not the program', () async {
      await showBy('impress');
      await service.modePen();
      stroke(0.2, 0.2);
      service.eraseAllInk();
      expect(service.strokes, isEmpty);
      expect(overlay.calls.last, 'inkClear');
      expect(inner.calls, isNot(contains('eraseAllInk')));
    });

    test('the last phone leaving takes the ink, the dot and the cover away', () async {
      await showBy(null);
      await service.modePen();
      stroke(0.2, 0.2);
      await service.whiteScreen();
      await service.modeLaser();
      overlay.calls.clear();
      service.phonesGone();
      expect(service.strokes, isEmpty);
      expect(overlay.calls, containsAll(['hide', 'inkClear', 'blank:off']));
      expect(inner.calls, contains('phonesGone'));
    });

    test('in PowerPoint the program\'s pen, as before', () async {
      await showBy('powerpoint');
      await service.modePen();
      service.leftDown();
      service.eraseAllInk();
      expect(inner.calls, containsAllInOrder(['modePen', 'leftDown', 'eraseAllInk']));
      expect(overlay.calls, isEmpty);
    });

    test('a new slide drops the ink', () async {
      await showBy('impress', slide: 1);
      await service.modePen();
      stroke(0.2, 0.2);
      service.slideNext();
      expect(service.strokes, isEmpty);
      expect(overlay.calls.last, 'inkClear');
      expect(inner.calls, contains('slideNext'));
    });

    test('a PDF\'s page: NEXT drops the ink there too', () async {
      await showBy(null);
      await service.modePen();
      stroke(0.2, 0.2);
      service.slideNext();
      expect(service.strokes, isEmpty);
    });

    test('kept ink comes back with its slide', () async {
      await showBy('impress', slide: 1);
      await service.modePen();
      stroke(0.2, 0.2);
      service.modeArrow();
      service.slideNext(keepInk: true);
      expect(inner.inkChoices, ['slideNext:keep']);
      await showBy('impress', slide: 2);
      expect(service.strokes, isEmpty);
      service.slidePrev(keepInk: true);
      overlay.calls.clear();
      await showBy('impress', slide: 1);
      expect(service.strokes, hasLength(1));
      expect(overlay.calls, ['inkClear', 'inkBegin:pen:ff0000', 'inkTo', 'inkEnd']);
    });

    test('the show\'s own black screen puts the ink away until it ends', () async {
      await showBy('impress');
      await service.modePen();
      stroke(0.2, 0.2);
      overlay.calls.clear();
      inner.slideState = {'current': 1, 'total': 9, 'presenter': 'impress', 'deckKey': 'deck', 'isBlackScreen': true};
      await service.getSlideState();
      expect(overlay.calls, ['inkClear']);
      expect(service.strokes, hasLength(1));
      await showBy('impress');
      expect(overlay.calls, ['inkClear', 'inkClear', 'inkBegin:pen:ff0000', 'inkTo', 'inkEnd']);
    });

    test('a phone that clears loses the ink another phone kept', () async {
      await showBy('impress', slide: 1);
      await service.modePen();
      stroke(0.2, 0.2);
      service.modeArrow();
      service.slideNext(keepInk: true);
      await showBy('impress', slide: 2);
      service.slidePrev(); // a phone that clears
      await showBy('impress', slide: 1);
      expect(service.strokes, isEmpty);
      expect(inner.inkChoices, ['slideNext:keep', 'slidePrev:clear']);
    });

    test('a slide changed on the PC drops the ink when the state shows it', () async {
      await showBy('impress', slide: 1);
      await service.modePen();
      stroke(0.2, 0.2);
      await showBy('impress', slide: 2); // the presenter pressed a key
      expect(service.strokes, isEmpty);
    });

    test('the end of the show drops everything kept', () async {
      await showBy('impress', slide: 1);
      await service.modePen();
      stroke(0.2, 0.2);
      service.slideNext(keepInk: true);
      await service.slideEnd();
      await showBy('impress', slide: 1);
      expect(service.strokes, isEmpty);
    });

    test('drawing on keeps the monitor, so the ink stays', () async {
      await showBy(null);
      await service.modePen();
      stroke(0.2, 0.2);
      await service.modePen();
      await service.modeLaser();
      expect(overlay.calls.where((c) => c == 'place'), hasLength(1));
      expect(overlay.calls.where((c) => c == 'keep'), hasLength(2));
    });
  });

  group('spotlight', () {
    test('the overlay draws it, in PowerPoint too', () async {
      await showBy('powerpoint');
      await service.modeSpotlight();
      expect(service.handlesLaserPointer, isTrue);
      service.laserPointerMoved(0.5, 0.5);
      service.laserOff();
      expect(overlay.calls, ['place', 'spotlight:on', 'move', 'spotlight:off']);
      expect(inner.calls, isEmpty);
    });

    test('never: none, the program reports it', () async {
      LaserOverlaySettings.mode = LaserOverlayMode.never;
      await showBy('impress');
      await service.modeSpotlight();
      expect(overlay.calls, isEmpty);
      expect(inner.calls, ['modeSpotlight']);
    });
  });

  group('magnifier', () {
    test('where the overlay has one it follows the laser', () async {
      overlay.supportsZoom = true;
      await showBy('powerpoint');
      await service.modeZoom();
      service.laserPointerMoved(0.5, 0.5);
      service.modeArrow();
      expect(overlay.calls, ['place', 'zoom:on', 'move', 'zoom:off']);
      expect(service.zoomAvailable, isTrue);
    });

    test('where it has none the program reports it', () async {
      await showBy(null);
      await service.modeZoom();
      expect(overlay.calls, isEmpty);
      expect(inner.calls, ['modeZoom']);
      expect(service.zoomAvailable, isFalse);
    });
  });

  group('black and white screen', () {
    test('outside a show the overlay covers the screen, and a second press uncovers it', () async {
      await showBy(null);
      await service.blackScreen();
      await service.blackScreen();
      await service.whiteScreen();
      expect(overlay.calls, ['place', 'blank:000000', 'blank:off', 'place', 'blank:ffffff']);
      expect(inner.calls, isEmpty);
    });

    test('a slide command uncovers it', () async {
      await showBy(null);
      await service.blackScreen();
      service.slideNext();
      expect(overlay.calls.last, 'blank:off');
    });

    test('in a show the program\'s own', () async {
      await showBy('impress');
      await service.blackScreen();
      expect(inner.calls, ['blackScreen']);
      expect(overlay.calls, isEmpty);
    });
  });

  test('UNDO_INK takes back the last stroke', () async {
    await showBy(null);
    await service.modePen();
    stroke(0.2, 0.2);
    stroke(0.2, 0.8);
    overlay.calls.clear();
    service.undoInk();
    expect(service.strokes, hasLength(1));
    expect(service.strokes.single.points.first, (0.2, 0.2));
    expect(overlay.calls, ['inkClear', 'inkBegin:pen:ff0000', 'inkTo', 'inkEnd']);
  });

  test('other commands go to the platform service', () async {
    service.slideStart();
    service.volumeUp();
    expect(inner.calls, ['slideStart', 'volumeUp']);
  });

  group('capabilities', () {
    test('outside a show the overlay adds the laser, the ink and its black screen', () async {
      inner.caps = const PresenterCaps(front: FrontWindow.pdf);
      await showBy(null);
      final caps = await service.capabilities();
      expect(caps.front, FrontWindow.pdf);
      expect(caps.caps, containsAll([RemoteCaps.laser, RemoteCaps.pen, RemoteCaps.undo, RemoteCaps.blank, RemoteCaps.spotlight]));
      expect(caps.has(RemoteCaps.zoom), isFalse);
    });

    test('in PowerPoint (auto) only the spotlight and the magnifier are its own', () async {
      overlay.supportsZoom = true;
      inner.caps = const PresenterCaps(front: FrontWindow.show, caps: {RemoteCaps.laser, RemoteCaps.blank});
      await showBy('powerpoint');
      final caps = await service.capabilities();
      expect(caps.caps, {RemoteCaps.laser, RemoteCaps.blank, RemoteCaps.spotlight, RemoteCaps.zoom});
    });

    test('never, or without an overlay: the program\'s caps alone', () async {
      inner.caps = const PresenterCaps(front: FrontWindow.other);
      LaserOverlaySettings.mode = LaserOverlayMode.never;
      await showBy(null);
      expect(await service.capabilities(), inner.caps);
      LaserOverlaySettings.mode = LaserOverlayMode.auto;
      overlay.supported = false;
      expect(await service.capabilities(), inner.caps);
    });
  });

  group('screen picture', () {
    ScreenCapture picture() => ScreenCapture(pixels: Uint8List(16), width: 2, height: 2);

    test('passes the program\'s picture through, with the ink on it', () async {
      await showBy('impress');
      inner.screen = picture();
      expect((await service.captureScreen())!.ink, isEmpty);
      await service.modePen();
      stroke(0.2, 0.3);
      final ink = (await service.captureScreen())!.ink;
      expect(ink, hasLength(1));
      expect(ink.single.highlighter, isFalse);
      expect(ink.single.rgb, 0xFF0000);
      expect(ink.single.points, [(0.2, 0.3), (0.30000000000000004, 0.3)]);
    });

    test('none while the show\'s black or white screen is on', () async {
      inner.screen = picture();
      inner.slideState = {'current': 1, 'total': 9, 'presenter': 'impress', 'deckKey': 'd', 'isBlackScreen': true};
      await service.getSlideState();
      expect(await service.captureScreen(), isNull);
      expect(inner.captures, 0);
    });

    test('none while the overlay covers the screen (outside a show)', () async {
      await showBy(null);
      inner.screen = picture();
      await service.blackScreen();
      expect(await service.captureScreen(), isNull);
      await service.blackScreen(); // off again
      expect(await service.captureScreen(), isNotNull);
    });
  });
}
