import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/input/slide_files.dart';
import 'package:quick_remote_pc/services/input/linux/evdev_keys.dart';
import 'package:quick_remote_pc/services/input/linux/linux_input_service.dart';
import 'package:quick_remote_pc/services/input/linux/script_bridge.dart';
import 'package:quick_remote_pc/services/input/linux/x11_windows.dart';

/// Answers each command with [replies] (default: no show runs).
class FakeBridge extends ScriptBridge {
  FakeBridge([Map<String, Map<String, dynamic>>? replies])
      : replies = replies ?? {},
        super('FakeBridge', 'fake.py');

  final Map<String, Map<String, dynamic>> replies;
  final List<(String, Map<String, Object?>)> requests = [];

  /// Commands sent without waiting for a reply.
  final List<String> sent = [];
  final List<Duration> timeouts = [];

  List<String> get commands => [for (final r in requests) r.$1];

  @override
  Future<String?> interpreter() async => null;

  @override
  Future<Map<String, dynamic>> request(
    String cmd, [
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 6),
  ]) async {
    requests.add((cmd, args));
    timeouts.add(timeout);
    return replies[cmd] ?? {'ok': false, 'error': 'NOT_RUNNING'};
  }

  @override
  void send(String cmd, Map<String, Object?> args) => sent.add(cmd);
}

const _ok = {'ok': true};

/// An Impress bridge whose `export` writes [jpeg] where it is asked to.
class ExportingBridge extends FakeBridge {
  ExportingBridge(super.replies, {this.jpeg = const [0xFF, 0xD8, 0xFF, 0xD9]});

  final List<int> jpeg;

  @override
  Future<Map<String, dynamic>> request(
    String cmd, [
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 6),
  ]) async {
    if (cmd == 'export') File(args['path']! as String).writeAsBytesSync(jpeg);
    return super.request(cmd, args, timeout);
  }
}

void main() {
  late FakeBridge impress;
  late FakeBridge wps;
  late List<List<int>> keys;
  late List<(RemoteError, String?)> errors;
  X11Window? active;
  List<X11Window> windows = const [];

  /// The windows captureScreen took a picture of.
  late List<int> captured;

  LinuxInputService service() {
    final s = LinuxInputService.withDependencies(
      impress: impress,
      wps: wps,
      activeWindow: () => active,
      clientWindows: () => windows,
      keys: keys.add,
      windowArea: (id) => id == 7 ? (x: 1920, y: 0, width: 1920, height: 1080) : null,
      captureWindow: (id) {
        captured.add(id);
        return ScreenCapture(pixels: Uint8List(16), width: 2, height: 2);
      },
    );
    s.onCommandError = (error, [info]) => errors.add((error, info));
    return s;
  }

  setUp(() {
    impress = FakeBridge();
    wps = FakeBridge();
    keys = [];
    errors = [];
    active = null;
    windows = const [];
    captured = [];
  });

  const userWps = X11Window(1, ['wpp', 'wpp'], pid: 100);
  const bridgeWps = X11Window(2, ['wpp', 'wpp'], pid: 200);
  const wpsShow = X11Window(3, ['wpp', 'wpp'], pid: 100, fullscreen: true);

  group('slides', () {
    test('go to the WPS the bridge opened when Impress has no show', () async {
      wps.replies['next'] = _ok;
      service().slideNext();
      await pumpEventQueue();
      expect(wps.requests.single.$2, containsPair('clearInk', true));
      expect(keys, isEmpty);
    });

    test('Impress comes first', () async {
      impress.replies['next'] = _ok;
      service().slideNext();
      await pumpEventQueue();
      expect(wps.requests, isEmpty);
    });

    test('a phone that keeps the ink: no clearInk for the bridge', () async {
      impress.replies['next'] = _ok;
      impress.replies['startAt'] = _ok;
      final s = service();
      s.slideNext(keepInk: true);
      await s.slideStartAt(3, keepInk: true);
      s.slidePrev();
      await pumpEventQueue();
      expect(impress.requests.map((r) => r.$2['clearInk']), [false, false, true]);
    });

    test('fall back to PageDown when no show answers', () async {
      service().slideNext();
      await pumpEventQueue();
      expect(keys, [
        [Evdev.keyPageDown]
      ]);
    });

    test('a viewer whose PageDown scrolls by a screen gets its arrows', () async {
      active = const X11Window(7, ['wpspdf', 'pdf']);
      final s = service();
      s.slideNext();
      await pumpEventQueue();
      s.slidePrev();
      await pumpEventQueue();
      active = const X11Window(8, ['okular']);
      s.slideNext();
      await pumpEventQueue();
      expect(keys, [
        [106], // Right
        [105], // Left
        [Evdev.keyPageDown],
      ]);
    });
  });

  group('start', () {
    test('a focused WPS the bridge does not control gets F5', () async {
      active = userWps;
      wps.replies['start'] = _ok; // the bridge's own WPS, elsewhere
      await service().slideStart();
      expect(wps.commands, isNot(contains('start')));
      expect(keys, [
        [Evdev.keyF5]
      ]);
    });

    test('the bridge starts the show of its own focused WPS', () async {
      wps.replies['state'] = {'ok': true, 'state': 'NOT_RUNNING', 'pid': 200};
      wps.replies['start'] = _ok;
      final s = service();
      await s.getSlideState(); // learns the bridge's pid
      active = bridgeWps;
      await s.slideStart();
      expect(wps.commands, contains('start'));
      expect(keys, isEmpty);
    });
  });

  group('slide pictures', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('slide-previews');
      SlideFiles.directoryOverride = dir;
    });
    tearDown(() {
      SlideFiles.directoryOverride = null;
      dir.deleteSync(recursive: true);
    });

    const impressShow = {'ok': true, 'state': 'RUNNING', 'current': 2, 'total': 5, 'deckKey': 'file:///talk.odp|1'};

    test('Impress exports the slide of its show', () async {
      impress = ExportingBridge({
        'state': impressShow,
        'export': {'ok': true, 'height': 360},
      });
      final s = service();
      expect(await s.getSlideState(), containsPair('deckKey', 'file:///talk.odp|1'));
      final image = await s.exportSlide(3, 640);
      expect(image, isNotNull);
      expect((image!.width, image.height), (640, 360));
      expect(image.jpeg.take(2), [0xFF, 0xD8]);
      final (_, args) = impress.requests.last;
      expect(args, containsPair('index', 3));
      expect(args, containsPair('width', 640));
      expect(args['path'] as String, startsWith(dir.path));
      expect(dir.listSync(), isEmpty, reason: 'the file is deleted once read');
    });

    test('a failed export leaves no file and no picture', () async {
      impress = ExportingBridge({
        'state': impressShow,
        'export': {'ok': false, 'error': 'BUSY'},
      });
      final s = service();
      await s.getSlideState();
      expect(await s.exportSlide(1, 320), isNull);
      expect(dir.listSync(), isEmpty);
    });

    test('the WPS the bridge opened exports the slide of its show', () async {
      wps = ExportingBridge({
        'state': {'ok': true, 'state': 'RUNNING', 'current': 3, 'total': 9, 'pid': 200},
        'export': {'ok': true, 'height': 180},
      });
      final s = service();
      await s.getSlideState();
      final image = await s.exportSlide(4, 320);
      expect((image?.width, image?.height), (320, 180));
      expect(impress.commands, isNot(contains('export')));
    });

    test('nothing is exported from a WPS the user started, or without a show', () async {
      windows = const [wpsShow];
      final s = service();
      expect(await s.getSlideState(), containsPair('current', 0));
      expect(await s.exportSlide(1, 320), isNull);
      windows = const [];
      await s.getSlideState();
      expect(await s.exportSlide(1, 320), isNull);
      expect(impress.commands, isNot(contains('export')));
      expect(wps.commands, isNot(contains('export')));
    });
  });

  group('slide state', () {
    test('a WPS show the bridge cannot read runs on an unknown slide', () async {
      windows = const [wpsShow];
      final state = await service().getSlideState();
      expect(state, containsPair('presenter', 'wps'));
      expect(state, containsPair('current', 0));
    });

    test('names the program reporting the show', () async {
      wps.replies['state'] = {'ok': true, 'state': 'RUNNING', 'current': 3, 'total': 9, 'pid': 200};
      final state = await service().getSlideState();
      expect(state, containsPair('presenter', 'wps'));
      expect(state, containsPair('current', 3));
    });

    test('without any show', () async {
      expect(await service().getSlideState(), {'error': 'POWERPOINT_NOT_RUNNING'});
    });
  });

  group('errors', () {
    test('Impress\'s error when WPS is absent', () async {
      impress.replies['penColor'] = {'ok': false, 'error': 'NO_PYTHON'};
      wps.replies['penColor'] = {'ok': false, 'error': 'NO_RPC'};
      await service().setPenColor(0xFF);
      expect(errors.single, (RemoteError.impressNoUno, null));
    });

    test('an unknown bridge error travels as info', () async {
      wps.replies['penColor'] = {'ok': false, 'error': 'BOOM'};
      await service().setPenColor(0xFF);
      expect(errors.single, (RemoteError.commandFailed, 'BOOM'));
    });
  });

  group('tools', () {
    test('a WPS out of the bridge\'s reach gets its eraser key', () async {
      active = userWps;
      windows = const [wpsShow];
      service().modeEraser();
      await pumpEventQueue();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyE],
      ]);
      expect(errors, isEmpty);
    });

    test('a focused WPS takes the pen and erase-all keys', () async {
      active = userWps;
      final s = service();
      s.modePen();
      await pumpEventQueue();
      await s.eraseAllInk();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyP],
        [Evdev.keyE],
      ]);
    });

    test('a focused WPS show gets its laser pen, which the next mode puts away', () async {
      active = wpsShow;
      windows = const [wpsShow];
      final s = service();
      await s.modeLaser();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyA],
        [Evdev.keyLeftCtrl, Evdev.keyR],
      ]);
      // Neither the bridge's pointer types nor LASER_OFF's no key would.
      keys.clear();
      s.laserOff();
      await pumpEventQueue();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyA]
      ]);
      keys.clear();
      s.modePen();
      await pumpEventQueue();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyP]
      ]);
    });

    test('an unfocused WPS gets the bridge\'s arrow for a laser, the editor no keys', () async {
      wps.replies['laserOn'] = _ok;
      final s = service();
      await s.modeLaser();
      expect(wps.commands, ['laserOn']);
      expect(keys, isEmpty);

      // Ctrl+R in the editor aligns text right: only the arrow, as before.
      wps.replies.remove('laserOn');
      active = userWps;
      await s.modeLaser();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyA]
      ]);
    });

    test('the highlighter is Ctrl+I, then the bridge colors it', () async {
      wps.replies['state'] = {'ok': true, 'state': 'RUNNING', 'current': 1, 'total': 2, 'pid': 200};
      wps.replies['pointerColor'] = _ok;
      final s = service();
      await s.getSlideState();
      await s.setHighlighterColor(0x00FFFF);
      active = bridgeWps;
      await s.modeHighlighter();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyI]
      ]);
      expect(wps.commands.last, 'pointerColor');
      expect(wps.requests.last.$2, {'bgr': 0x00FFFF});
    });

    test('Impress\'s see-through highlighter draws strokes, not ink', () async {
      impress.replies['highlighter'] = {'ok': true, 'strokes': true};
      final s = service();
      s.modeHighlighter();
      // The button waits for the mode: it either draws ink or starts a stroke.
      s.leftDown();
      expect(impress.sent, isEmpty);
      await pumpEventQueue();
      expect(s.handlesDrawPointer, isTrue);
      s.drawPointerMoved(0.5, 0.5);
      s.leftUp();
      await pumpEventQueue();
      expect(impress.sent, ['strokeBegin', 'pointer', 'strokeEnd']);

      s.modeArrow();
      expect(s.handlesDrawPointer, isFalse);
    });

    test('the highlighter stays ink where Impress cannot draw strokes', () async {
      impress.replies['highlighter'] = _ok;
      final s = service();
      await s.modeHighlighter();
      expect(s.handlesDrawPointer, isFalse);
    });

    test('pen colors go to Impress as RGB and to WPS as BGR', () async {
      await service().setPenColor(0x0000FF); // red
      expect(impress.commands, ['penColor']);
      expect(impress.requests.single.$2, {'rgb': 0xFF0000});
      expect(wps.commands, ['penColor']);
      expect(wps.requests.single.$2, {'bgr': 0x0000FF});
    });
  });

  group('PDF viewers', () {
    const firefox = X11Window(4, ['Navigator', 'firefox']);
    const chrome = X11Window(5, ['google-chrome', 'Google-chrome']);

    test('START opens Firefox\'s presentation mode instead of reloading', () async {
      active = firefox;
      await service().slideStart();
      expect(keys, [
        [Evdev.keyLeftCtrl, Evdev.keyLeftAlt, Evdev.keyP]
      ]);
      expect(impress.requests, isEmpty);
    });

    test('END leaves the full screen START entered in a browser', () async {
      active = chrome;
      final s = service();
      await s.slideStart();
      await s.slideEnd();
      expect(keys, [
        [Evdev.fromVk(0x7A)],
        [Evdev.fromVk(0x7A)],
      ]);
    });

    test('END elsewhere is the usual Esc', () async {
      active = chrome;
      final s = service();
      await s.slideStart();
      active = null;
      await s.slideEnd();
      expect(keys.last, [Evdev.keyEsc]);
    });

    test('START gives Impress time to open a PDF as a presentation', () async {
      impress.replies['start'] = _ok;
      await service().slideStart();
      expect(impress.timeouts.single, greaterThan(const Duration(seconds: 60)));
      expect(keys, isEmpty);
    });
  });

  group('laser overlay area', () {
    test('the Impress show\'s window, as its bridge tells it', () async {
      impress = FakeBridge({
        'state': {'ok': true, 'state': 'RUNNING', 'current': 1, 'total': 3, 'window': [1920, 0, 1920, 1080]},
      });
      final s = service();
      final state = await s.getSlideState();
      expect(await s.laserArea(), (x: 1920, y: 0, width: 1920, height: 1080));
      // Not sent on to the phones.
      expect(state, isNot(contains('window')));
    });

    test('else the focused X11 window (a PDF viewer)', () async {
      active = const X11Window(7, ['okular']);
      final s = service();
      await s.getSlideState();
      expect(await s.laserArea(), (x: 1920, y: 0, width: 1920, height: 1080));
    });

    test('unknown under a native Wayland window', () async {
      final s = service();
      await s.getSlideState();
      expect(await s.laserArea(), isNull);
    });
  });

  group('capabilities', () {
    Future<PresenterCaps> capsAfterState(LinuxInputService s) async {
      await s.getSlideState();
      return s.capabilities();
    }

    test('an Impress show has every tool', () async {
      impress.replies['state'] = {'ok': true, 'state': 'RUNNING', 'current': 1, 'total': 4};
      active = const X11Window(5, ['libreoffice', 'libreoffice-impress']);
      final caps = await capsAfterState(service());
      expect(caps.front, FrontWindow.show);
      expect(caps.caps, containsAll([RemoteCaps.laser, RemoteCaps.goto, RemoteCaps.media, RemoteCaps.previews]));
    });

    test('the bridge\'s WPS lacks the highlighter while it has no focus', () async {
      wps.replies['state'] = {'ok': true, 'state': 'RUNNING', 'current': 3, 'total': 9, 'pid': 200};
      active = const X11Window(7, ['okular']);
      final s = service();
      var caps = await capsAfterState(s);
      expect(caps.front, FrontWindow.pdf);
      expect(caps.has(RemoteCaps.highlighter), isFalse);
      expect(caps.has(RemoteCaps.pen), isTrue);
      expect(caps.has(RemoteCaps.media), isFalse); // WPS's Player does nothing
      active = const X11Window(2, ['wpp', 'wpp'], pid: 200, fullscreen: true);
      caps = await capsAfterState(s);
      expect(caps.front, FrontWindow.show);
      expect(caps.has(RemoteCaps.highlighter), isTrue);
    });

    test('a WPS the user started: its keys only, no slide to jump to', () async {
      windows = const [wpsShow];
      active = wpsShow;
      final caps = await capsAfterState(service());
      expect(caps.front, FrontWindow.show);
      expect(caps.caps, containsAll([RemoteCaps.laser, RemoteCaps.pen, RemoteCaps.blank]));
      expect(caps.caps, isNot(anyOf(contains(RemoteCaps.goto), contains(RemoteCaps.notes), contains(RemoteCaps.previews))));
    });

    test('a PDF viewer or a browser: page turns only', () async {
      active = const X11Window(7, ['okular']);
      final s = service();
      expect(await capsAfterState(s), const PresenterCaps(front: FrontWindow.pdf));
      active = const X11Window(8, ['Navigator', 'firefox']);
      expect(await capsAfterState(s), const PresenterCaps(front: FrontWindow.browser));
    });

    test('an editor jumps to a slide, a WPS the bridge does not control does not', () async {
      final s = service();
      active = const X11Window(5, ['libreoffice', 'libreoffice-draw']);
      expect(await capsAfterState(s), const PresenterCaps(front: FrontWindow.editor, caps: {RemoteCaps.goto}));
      active = userWps;
      expect(await capsAfterState(s), const PresenterCaps(front: FrontWindow.editor));
    });

    test('a WPS the user started can be taken over once the bridge answers', () async {
      windows = const [userWps, bridgeWps];
      active = const X11Window(9, ['konsole']);
      wps.replies['state'] = {'ok': true, 'state': 'NOT_RUNNING', 'pid': 200};
      final s = service();
      expect((await capsAfterState(s)).has(RemoteCaps.takeOver), isTrue);
      // Only the bridge's own WPS: nothing to take over.
      windows = const [bridgeWps];
      expect((await capsAfterState(s)).has(RemoteCaps.takeOver), isFalse);
      // Without pywpsrpc the bridge could not open the files.
      windows = const [userWps];
      wps.replies['state'] = {'ok': false, 'error': 'NO_RPC'};
      expect((await capsAfterState(s)).has(RemoteCaps.takeOver), isFalse);
    });

    test('any other window, and an unknown one (native Wayland)', () async {
      final s = service();
      active = const X11Window(9, ['konsole']);
      expect(await capsAfterState(s), const PresenterCaps(front: FrontWindow.other));
      active = null;
      expect(await capsAfterState(s), const PresenterCaps());
    });
  });

  group('screen picture', () {
    const impressEditor = X11Window(10, ['libreoffice', 'libreoffice-impress']);
    const impressShow = X11Window(11, ['libreoffice', 'libreoffice-impress'], fullscreen: true);
    const okular = X11Window(12, ['okular'], fullscreen: true);
    const firefoxWindowed = X11Window(13, ['Navigator', 'firefox']);
    const firefoxFull = X11Window(14, ['Navigator', 'firefox'], fullscreen: true);
    const konsoleFull = X11Window(15, ['konsole'], fullscreen: true);

    Future<int?> capturedAfterState(LinuxInputService s) async {
      captured.clear();
      await s.getSlideState();
      final picture = await s.captureScreen();
      expect(picture == null, captured.isEmpty);
      return captured.isEmpty ? null : captured.single;
    }

    test('an Impress show: its full-screen window, not the editor', () async {
      impress.replies['state'] = {'ok': true, 'state': 'RUNNING', 'current': 1, 'total': 4};
      windows = const [impressEditor, impressShow];
      active = konsoleFull; // another window in front does not matter
      expect(await capturedAfterState(service()), 11);
    });

    test('an Impress show: the window its state names, when known', () async {
      impress.replies['state'] = {
        'ok': true,
        'state': 'RUNNING',
        'current': 1,
        'total': 4,
        'window': [1920, 0, 1920, 1080],
      };
      windows = const [impressShow, X11Window(7, ['libreoffice', 'libreoffice-impress'])];
      expect(await capturedAfterState(service()), 7);
    });

    test('an Impress show out of X11 reach (native Wayland): none', () async {
      impress.replies['state'] = {'ok': true, 'state': 'RUNNING', 'current': 1, 'total': 4};
      windows = const [];
      active = okular;
      expect(await capturedAfterState(service()), isNull, reason: 'never the PDF beside the show');
    });

    test('a WPS show, the bridge\'s or the user\'s', () async {
      windows = const [userWps, wpsShow];
      expect(await capturedAfterState(service()), 3);
    });

    test('a PDF viewer or browser only in full screen', () async {
      final s = service();
      active = okular;
      expect(await capturedAfterState(s), 12);
      active = firefoxFull;
      expect(await capturedAfterState(s), 14);
      active = firefoxWindowed;
      expect(await capturedAfterState(s), isNull, reason: 'its other tabs, the desktop around it');
    });

    test('never another window, full screen or not', () async {
      final s = service();
      active = konsoleFull;
      expect(await capturedAfterState(s), isNull);
      active = const X11Window(16, ['libreoffice', 'libreoffice-impress'], fullscreen: true);
      expect(await capturedAfterState(s), isNull, reason: 'an editor without a show');
      active = null;
      expect(await capturedAfterState(s), isNull);
    });
  });
}
