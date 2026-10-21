import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:quick_remote_pc/services/capture/slide_matcher.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/input/linux/wps_take_over.dart';
import 'package:quick_remote_pc/services/input/linux/x11_windows.dart';

/// A 64 × 36 slide: [paint] gives each pixel's grey.
Uint8List slideJpeg(int Function(int x, int y) paint) {
  final image = img.Image(width: 64, height: 36);
  for (var y = 0; y < 36; y++) {
    for (var x = 0; x < 64; x++) {
      final v = paint(x, y);
      image.setPixelRgb(x, y, v, v, v);
    }
  }
  return img.encodeJpg(image, quality: 95);
}

int leftDark(int x, int y) => x < 32 ? 0 : 255;
int topDark(int x, int y) => y < 18 ? 0 : 255;
int plainGrey(int x, int y) => 128;

/// A 320 × 200 screen showing a 16:9 slide painted by [paint] (in slide
/// pixels 0-63 × 0-35) between grey bars, as a show letterboxes it.
ScreenCapture screenOf(int Function(int x, int y) paint) {
  const width = 320, height = 200, top = 10, slideHeight = 180;
  final pixels = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final inSlide = y >= top && y < top + slideHeight;
      final v = inSlide
          ? paint(x * 64 ~/ width, (y - top) * 36 ~/ slideHeight)
          : 90;
      final i = (y * width + x) * 4;
      pixels[i] = pixels[i + 1] = pixels[i + 2] = v;
    }
  }
  return ScreenCapture(pixels: pixels, width: width, height: height);
}

void main() {
  late Directory tmp;
  late String proc;
  late List<(String, Map<String, Object?>)> requests;
  late List<int> closed;
  late List<X11Window> windows;
  late Map<String, Map<String, dynamic>> replies;
  late List<Uint8List> slides;
  late bool exitsOnClose;
  late List<String> reopened;
  ScreenCapture? screen;

  const editor = X11Window(1, ['wpp', 'wpp'], pid: 100);
  const show = X11Window(2, ['wpp', 'wpp'], pid: 100, fullscreen: true);
  const bridgeEditor = X11Window(3, ['wpp', 'wpp'], pid: 200);

  /// A presentation file and process 100 holding [names] open.
  List<String> holdOpen(List<String> names) {
    final fd = Directory('$proc/100/fd')..createSync(recursive: true);
    final paths = <String>[];
    for (var i = 0; i < names.length; i++) {
      final path = '${tmp.path}/docs/${names[i]}';
      File(path).createSync(recursive: true);
      Link('${fd.path}/${i + 3}').createSync(path);
      paths.add(path);
    }
    return paths;
  }

  WpsTakeOver takeOver() => WpsTakeOver(
    clientWindows: () => windows,
    title: (id) => switch (id) {
      1 => 'b.pptx - WPS Presentation',
      _ => null,
    },
    close: (id) {
      closed.add(id);
      windows = windows.where((w) => w.id != id).toList();
      if (exitsOnClose && !windows.any((w) => w.pid == 100)) {
        Directory('$proc/100').deleteSync(recursive: true);
      }
      return true;
    },
    capture: (id) => id == show.id ? screen : null,
    request: (cmd, args, timeout) async {
      requests.add((cmd, args));
      if (cmd == 'export') {
        final index = args['index']! as int;
        File(args['path']! as String).writeAsBytesSync(slides[index - 1]);
        return {'ok': true, 'height': 36};
      }
      return replies[cmd] ?? {'ok': true};
    },
    exportPath: (index, width) async => '${tmp.path}/slide-$index-$width.jpg',
    reopen: reopened.addAll,
    proc: proc,
    closeTimeout: const Duration(milliseconds: 100),
    poll: const Duration(milliseconds: 5),
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('takeover');
    proc = '${tmp.path}/proc';
    requests = [];
    closed = [];
    windows = [];
    replies = {
      'open': {'ok': true, 'pid': 200, 'total': 3},
    };
    slides = [slideJpeg(leftDark), slideJpeg(topDark), slideJpeg(plainGrey)];
    exitsOnClose = true;
    reopened = [];
    screen = null;
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  List<String> commands() => [for (final r in requests) r.$1];

  test(
    'opens the editor\'s files in the bridge, the titled one last',
    () async {
      final [a, b] = holdOpen(['a.pptx', 'b.pptx']);
      windows = [editor, bridgeEditor];
      expect(await takeOver().run(bridgePid: 200), isNull);
      expect(closed, [editor.id]);
      expect([for (final r in requests) (r.$1, r.$2['path'])], [('open', a), ('open', b)]);
    },
  );

  test('a running show goes on at the slide on screen', () async {
    holdOpen(['b.pptx']);
    windows = [editor, show];
    screen = screenOf(topDark);
    expect(await takeOver().run(), isNull);
    expect(closed.first, show.id);
    expect(commands(), ['open', 'export', 'export', 'export', 'startAt']);
    expect(requests.last.$2, {'slide': 2});
  });

  test('a show whose slide matches none starts at the first', () async {
    holdOpen(['b.pptx']);
    windows = [editor, show];
    screen = screenOf((x, y) => x < 32 ? 255 : 0);
    expect(await takeOver().run(), isNull);
    expect(commands().last, 'startAt');
    expect(requests.last.$2, {'slide': 1});
  });

  test('a WPS that does not close (its save question) is left alone', () async {
    holdOpen(['b.pptx']);
    windows = [editor];
    exitsOnClose = false;
    expect(await takeOver().run(), RemoteError.wpsTakeOverNotClosed);
    expect(requests, isEmpty);
  });

  test('a question of WPS already open is never closed: it waits for the user', () async {
    holdOpen(['b.pptx']);
    const question = X11Window(9, ['wpp', 'wpp'], pid: 100, dialog: true);
    windows = [editor, question];
    expect(await takeOver().run(), RemoteError.wpsTakeOverNotClosed);
    expect(closed, isEmpty);
    expect(requests, isEmpty);
  });

  test('nothing to take over: no WPS of the user, no saved file', () async {
    windows = [bridgeEditor];
    expect(await takeOver().run(bridgePid: 200), RemoteError.wpsTakeOverNoWps);
    windows = [editor];
    Directory('$proc/100/fd').createSync(recursive: true);
    expect(await takeOver().run(), RemoteError.wpsTakeOverNoFile);
    expect(closed, isEmpty);
  });

  test('what the bridge cannot open goes back to a WPS of the user', () async {
    final [b] = holdOpen(['b.pptx']);
    windows = [editor];
    replies['open'] = {'ok': false, 'error': 'WPS_START_FAILED'};
    expect(await takeOver().run(), RemoteError.wpsTakeOverFailed);
    expect(reopened, [b]);
  });

  group('presentationFiles', () {
    test('presentations only, lock files lead to their file', () {
      final fd = Directory('$proc/7/fd')..createSync(recursive: true);
      final deck = File('${tmp.path}/talk.pptx')..createSync();
      File('${tmp.path}/old.odp').createSync();
      Link('${fd.path}/3').createSync('${tmp.path}/.~old.odp');
      Link('${fd.path}/4').createSync(deck.path);
      Link('${fd.path}/5').createSync('${tmp.path}/notes.txt');
      Link('${fd.path}/6').createSync('${tmp.path}/~\$talk.pptx');
      Link('${fd.path}/10').createSync(deck.path);
      expect(WpsTakeOver.presentationFiles(7, proc: proc), [
        '${tmp.path}/old.odp',
        deck.path,
      ]);
      expect(WpsTakeOver.presentationFiles(8, proc: proc), isEmpty);
    });

    test('the file a title names goes last, with or without its extension', () {
      const files = ['/d/a.pptx', '/d/ab.pptx', '/d/c.dps'];
      expect(WpsTakeOver.activeLast(files, ['ab.pptx - WPS']), [
        '/d/a.pptx',
        '/d/c.dps',
        '/d/ab.pptx',
      ]);
      expect(WpsTakeOver.activeLast(files, ['', 'c - WPS']), [
        '/d/a.pptx',
        '/d/ab.pptx',
        '/d/c.dps',
      ]);
      expect(WpsTakeOver.activeLast(files, ['WPS']), files);
    });
  });

  test('SlideMatcher crops the letterboxed slide before comparing', () {
    final grey = SlideMatcher.ofCapture(screenOf(leftDark), 16 / 9)!;
    final candidates = [for (final jpeg in slides) SlideMatcher.ofJpeg(jpeg)];
    expect(SlideMatcher.best(grey, candidates), 1);
    expect(SlideMatcher.best(grey, [null, candidates[1]]), isNull);
  });
}
