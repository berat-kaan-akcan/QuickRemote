import 'package:flutter_test/flutter_test.dart';
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
}

const _ok = {'ok': true};

void main() {
  late FakeBridge impress;
  late FakeBridge wps;
  late List<List<int>> keys;
  late List<String> errors;
  X11Window? active;
  List<X11Window> windows = const [];

  LinuxInputService service() {
    final s = LinuxInputService.withDependencies(
      impress: impress,
      wps: wps,
      activeWindow: () => active,
      clientWindows: () => windows,
      keys: keys.add,
    );
    s.onCommandError = errors.add;
    return s;
  }

  setUp(() {
    impress = FakeBridge();
    wps = FakeBridge();
    keys = [];
    errors = [];
    active = null;
    windows = const [];
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

    test('fall back to PageDown when no show answers', () async {
      service().slideNext();
      await pumpEventQueue();
      expect(keys, [
        [Evdev.keyPageDown]
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

  group('tools', () {
    test('a WPS out of the bridge\'s reach has no eraser', () async {
      active = userWps;
      windows = const [wpsShow];
      service().modeEraser();
      await pumpEventQueue();
      expect(keys, isEmpty);
      expect(errors.single, contains('QuickRemote\'tan açılan'));
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
}
