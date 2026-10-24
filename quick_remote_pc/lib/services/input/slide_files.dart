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

  /// Folders already made private and swept in this run.
  static final Set<String> _prepared = {};

  /// Creates the folder, owner-only where the system has modes (the slides
  /// of a private talk must not be readable by other users of the computer
  /// while a picture waits there), and removes pictures a crashed run left.
  static Future<void> _prepare(Directory dir) async {
    await dir.create(recursive: true);
    if (!_prepared.add(dir.path)) return;
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['700', dir.path]);
      } catch (e) {
        debugPrint('Slide folder not made private: $e');
      }
    }
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File && RegExp(r'^slide-\d+-\d+\.jpg$').hasMatch(p.basename(entity.path))) {
          await discard(entity.path);
        }
      }
    } catch (_) {}
  }

  /// A fresh path for slide [index] at [width] pixels; an old file there is
  /// removed first.
  static Future<String> path(int index, int width) async {
    final dir = directoryOverride ??
        (_dir ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'slide-previews')));
    await _prepare(dir);
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
