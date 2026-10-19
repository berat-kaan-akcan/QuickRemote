import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/server/slide_previewer.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

void main() {
  late List<(Object, SlideImageFrame)> sent;
  late List<(int, int)> exports;
  late SlidePreviewer previewer;
  SlideImage? Function(int, int) exporter = (_, _) => null;

  SlideImage picture(int index, int width, {int size = 100}) => (
    jpeg: Uint8List(size)..setAll(0, [0xFF, 0xD8, index]),
    width: width,
    height: width ~/ 2,
  );

  SlidePreviewer create({
    int maxCacheBytes = 30 * 1024 * 1024,
    Duration timeout = const Duration(seconds: 3),
  }) => SlidePreviewer(
    send: (client, frame) => sent.add((client, SlideImageFrame.decode(frame)!)),
    exporter: (index, width) async {
      exports.add((index, width));
      return exporter(index, width);
    },
    maxCacheBytes: maxCacheBytes,
    timeout: timeout,
  );

  setUp(() {
    sent = [];
    exports = [];
    exporter = picture;
    previewer = create();
  });

  Future<void> idle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('a second phone gets the pictures from the cache', () async {
    previewer.show((deck: 1, current: 1, total: 3));
    previewer.setEnabled('a', true);
    await idle();
    previewer.setEnabled('b', true);
    await idle();
    expect(sent.map((s) => (s.$1, s.$2.kind, s.$2.slide)), [
      ('a', SlideImageKind.current, 1),
      ('a', SlideImageKind.next, 2),
      ('b', SlideImageKind.current, 1),
      ('b', SlideImageKind.next, 2),
    ]);
    expect(exports, [(1, 1280), (2, 640)]);
  });

  test('the last slide has no next picture', () async {
    previewer.show((deck: 1, current: 3, total: 3));
    previewer.setEnabled('a', true);
    await idle();
    expect(sent.map((s) => s.$2.kind), [SlideImageKind.current]);
  });

  test('another deck empties the cache', () async {
    previewer.show((deck: 1, current: 1, total: 1));
    previewer.setEnabled('a', true);
    await idle();
    expect(previewer.cacheBytes, 100);
    previewer.show((deck: 2, current: 1, total: 1));
    await idle();
    expect(exports, [(1, 1280), (1, 1280)]);
    expect(sent.last.$2.deck, 2);
    expect(previewer.cacheBytes, 100);
  });

  test(
    'the cache keeps to its size, dropping the least recently used',
    () async {
      previewer = create(maxCacheBytes: 250);
      previewer.setEnabled('a', true);
      previewer.show((deck: 1, current: 1, total: 3));
      for (final slide in [1, 2, 3]) {
        previewer.requestThumbnail('a', slide);
      }
      await idle();
      expect(previewer.cacheBytes, lessThanOrEqualTo(250));
      exports.clear();
      // The current and next pictures and thumbnail 1 went first.
      previewer.requestThumbnail('a', 2);
      previewer.requestThumbnail('a', 3);
      await idle();
      expect(exports, isEmpty);
    },
  );

  test(
    'a failed or slow export sends nothing and is not retried in a loop',
    () async {
      final never = Completer<SlideImage?>();
      previewer = SlidePreviewer(
        send: (client, frame) =>
            sent.add((client, SlideImageFrame.decode(frame)!)),
        exporter: (index, width) {
          exports.add((index, width));
          return width == 1280 ? never.future : Future.error('COM failed');
        },
        timeout: const Duration(milliseconds: 30),
      );
      previewer.show((deck: 1, current: 1, total: 2));
      previewer.setEnabled('a', true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(sent, isEmpty);
      expect(exports, [(1, 1280), (2, 640)]);
    },
  );

  test('a phone that left gets nothing', () async {
    previewer.show((deck: 1, current: 1, total: 3));
    previewer.setEnabled('a', true);
    previewer.requestThumbnail('a', 3);
    previewer.remove('a');
    await idle();
    expect(sent, isEmpty);
  });
}
