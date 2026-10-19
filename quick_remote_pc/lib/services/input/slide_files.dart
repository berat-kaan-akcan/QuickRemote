import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'input_service.dart';

/// Where the presentation programs write the slide pictures the phones get:
/// a folder of its own under the app support directory, each file deleted
/// once read.
class SlideFiles {
  SlideFiles._();

  @visibleForTesting
  static Directory? directoryOverride;

  static Directory? _dir;

  /// A fresh path for slide [index] at [width] pixels; an old file there is
  /// removed first.
  static Future<String> path(int index, int width) async {
    final dir = directoryOverride ??
        (_dir ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'slide-previews')));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'slide-$index-$width.jpg'));
    await discard(file.path);
    return file.path;
  }

  /// Reads and deletes the picture at [path]; null when it is missing or
  /// not a JPEG.
  static Future<SlideImage?> read(String path, int width, int height) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final jpeg = await file.readAsBytes();
      await discard(path);
      if (jpeg.length < 2 || jpeg[0] != 0xFF || jpeg[1] != 0xD8) return null;
      return (jpeg: jpeg, width: width, height: height);
    } catch (e) {
      debugPrint('Slide picture $path unreadable: $e');
      return null;
    }
  }

  static Future<void> discard(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
