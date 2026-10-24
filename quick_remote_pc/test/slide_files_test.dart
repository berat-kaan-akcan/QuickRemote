import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/slide_files.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('slide_files_test');
    SlideFiles.directoryOverride = Directory('${dir.path}/slide-previews');
  });
  tearDown(() {
    SlideFiles.directoryOverride = null;
    dir.deleteSync(recursive: true);
  });

  test('the folder is private and old pictures of a crashed run are swept once', () async {
    final folder = Directory('${dir.path}/slide-previews')..createSync();
    File('${folder.path}/slide-3-1280.jpg').writeAsBytesSync([0xFF, 0xD8]);
    File('${folder.path}/other.txt').writeAsStringSync('keep');

    final path = await SlideFiles.path(1, 640);
    expect(path, '${folder.path}${Platform.pathSeparator}slide-1-640.jpg');
    expect(File('${folder.path}/slide-3-1280.jpg').existsSync(), isFalse);
    expect(File('${folder.path}/other.txt').existsSync(), isTrue);
    if (!Platform.isWindows) {
      expect(folder.statSync().mode & 0x1FF, 0x1C0, reason: 'rwx------');
    }

    // Later calls leave a picture that is waiting to be read.
    File('${folder.path}/slide-2-640.jpg').writeAsBytesSync([0xFF, 0xD8]);
    await SlideFiles.path(1, 640);
    expect(File('${folder.path}/slide-2-640.jpg').existsSync(), isTrue);
  });
}
