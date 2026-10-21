import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../capture/slide_matcher.dart';
import '../input_service.dart';
import '../../linux/system_executable.dart';
import 'x11_windows.dart';

/// A request to the WPS bridge.
typedef WpsRequest =
    Future<Map<String, dynamic>> Function(
      String cmd,
      Map<String, Object?> args,
      Duration timeout,
    );

/// Moves the presentations of a WPS Presentation the user started into the
/// WPS the bridge drives (WPS_TAKE_OVER), which pywpsrpc cannot attach to:
/// reads its files from `/proc/<pid>/fd`, closes it as its close button
/// would (WPS asks to save what changed), opens them in the bridge's WPS and,
/// when a show ran, starts the show again at the slide that was on screen
/// (its picture matched against the slides', else the first).
class WpsTakeOver {
  WpsTakeOver({
    required this.clientWindows,
    required this.title,
    required this.close,
    required this.capture,
    required this.request,
    required this.exportPath,
    this.reopen = openInWps,
    this.proc = '/proc',
    this.closeTimeout = const Duration(seconds: 60),
    this.poll = const Duration(milliseconds: 250),
  });

  final List<X11Window> Function() clientWindows;
  final String? Function(int window) title;
  final bool Function(int window) close;
  final ScreenCapture? Function(int window) capture;
  final WpsRequest request;

  /// A fresh file for a slide picture (`SlideFiles.path`).
  final Future<String> Function(int index, int width) exportPath;

  /// Opens files in a WPS as the user would (`wpp FILE...`).
  final void Function(List<String> files) reopen;
  final String proc;

  /// How long WPS may take to close: its save question waits for the user.
  final Duration closeTimeout;
  final Duration poll;

  static const extensions = {
    '.pptx',
    '.ppt',
    '.ppsx',
    '.pps',
    '.pptm',
    '.dps',
    '.dpt',
    '.odp',
  };

  /// Slide pictures for the match: small, and at most this many slides.
  static const matchWidth = 64;
  static const matchSlides = 200;

  bool _running = false;

  /// WPS windows not of the bridge's WPS ([bridgePid]).
  static List<X11Window> userWindows(List<X11Window> windows, int? bridgePid) =>
      [
        for (final w in windows)
          if (w.hasClass('wpp') && w.pid != null && w.pid != bridgePid) w,
      ];

  /// Null when done, else why not.
  Future<RemoteError?> run({int? bridgePid}) async {
    if (_running) return null;
    _running = true;
    try {
      return await _run(bridgePid);
    } finally {
      _running = false;
    }
  }

  Future<RemoteError?> _run(int? bridgePid) async {
    final windows = userWindows(clientWindows(), bridgePid);
    if (windows.isEmpty) return RemoteError.wpsTakeOverNoWps;
    final pid =
        (windows.where((w) => w.fullscreen).firstOrNull ?? windows.first).pid!;
    final own = windows.where((w) => w.pid == pid).toList();
    final files = presentationFiles(pid, proc: proc);
    if (files.isEmpty) return RemoteError.wpsTakeOverNoFile;
    // The show's file first, then the editor's active tab.
    final titles = [
      for (final w in own.where((w) => w.fullscreen)) title(w.id),
      for (final w in own.where((w) => !w.fullscreen)) title(w.id),
    ].nonNulls.toList();
    final ordered = activeLast(files, titles);
    final show = own.where((w) => w.fullscreen).firstOrNull;
    final screen = show == null ? null : capture(show.id);
    debugPrint(
      'WPS take-over: pid $pid, ${files.length} file(s), show ${show != null}',
    );

    // A question of WPS's own (save the changes?) waits for the user: a close
    // sent to it answers "don't save". So with one open nothing is closed.
    if (!own.any((w) => w.dialog)) {
      if (show != null) {
        // Closing the show first ends it; the editor then closes as usual.
        close(show.id);
        await _until(() => !_hasWindow(show.id), const Duration(seconds: 3));
      }
      for (final w in userWindows(clientWindows(), bridgePid)) {
        if (w.pid == pid && !w.dialog) close(w.id);
      }
    }
    if (!await _until(() => !_alive(pid), closeTimeout)) {
      return RemoteError.wpsTakeOverNotClosed;
    }

    Map<String, dynamic>? opened;
    final failed = <String>[];
    for (final file in ordered) {
      final reply = await request('open', {
        'path': file,
      }, const Duration(seconds: 40));
      if (reply['ok'] != true) {
        debugPrint('WPS take-over: opening a file failed: ${reply['error']}');
        failed.add(file);
      } else if (file == ordered.last) {
        opened = reply;
      }
    }
    // The user's WPS is closed by now: what the bridge could not open goes
    // back to a WPS of the user's own rather than nowhere.
    if (failed.isNotEmpty) reopen(failed);
    if (opened == null) return RemoteError.wpsTakeOverFailed;
    if (show == null) return null;

    final total = opened['total'];
    final slide = screen != null && total is int && total > 0
        ? await _slideOf(screen, total)
        : null;
    debugPrint('WPS take-over: the show goes on at slide ${slide ?? 1}');
    final started = await request('startAt', {
      'slide': slide ?? 1,
    }, const Duration(seconds: 10));
    return started['ok'] == true ? null : RemoteError.slideshowStartFailed;
  }

  bool _hasWindow(int id) => clientWindows().any((w) => w.id == id);

  bool _alive(int pid) => Directory('$proc/$pid').existsSync();

  Future<bool> _until(bool Function() done, Duration timeout) async {
    final end = DateTime.now().add(timeout);
    while (!done()) {
      if (DateTime.now().isAfter(end)) return false;
      await Future<void>.delayed(poll);
    }
    return true;
  }

  /// The slide [screen] shows, from small pictures of every slide of the
  /// presentation just opened; null when none matches.
  Future<int?> _slideOf(ScreenCapture screen, int total) async {
    final jpegs = <Uint8List?>[];
    double? aspect;
    for (var i = 1; i <= total && i <= matchSlides; i++) {
      final path = await exportPath(i, matchWidth);
      final reply = await request('export', {
        'index': i,
        'width': matchWidth,
        'path': path,
      }, const Duration(seconds: 5));
      final height = reply['height'];
      Uint8List? jpeg;
      try {
        final file = File(path);
        if (reply['ok'] == true &&
            height is int &&
            height > 0 &&
            file.existsSync()) {
          jpeg = file.readAsBytesSync();
          aspect ??= matchWidth / height;
        }
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        debugPrint('WPS take-over: slide picture $i unreadable: $e');
      }
      jpegs.add(jpeg);
    }
    final slideAspect = aspect;
    if (slideAspect == null) return null;
    return Isolate.run(() {
      final grey = SlideMatcher.ofCapture(screen, slideAspect);
      if (grey == null) return null;
      return SlideMatcher.best(grey, [
        for (final jpeg in jpegs)
          jpeg == null ? null : SlideMatcher.ofJpeg(jpeg),
      ]);
    });
  }

  static Future<void> openInWps(List<String> files) async {
    try {
      await Process.start(systemExecutable('wpp'), files, mode: ProcessStartMode.detached);
    } catch (e) {
      debugPrint('WPS take-over: cannot start wpp: $e');
    }
  }

  /// The presentations process [pid] holds open, in the order of its file
  /// descriptors. WPS keeps the file open; when only its lock file
  /// (`.~name.pptx`, beside it) is, the file is found from that.
  static List<String> presentationFiles(int pid, {String proc = '/proc'}) {
    final found = <String>[];
    void add(String path) {
      if (!found.contains(path) && File(path).existsSync()) found.add(path);
    }

    try {
      final fds = Directory('$proc/$pid/fd').listSync()
        ..sort(
          (a, b) => (int.tryParse(p.basename(a.path)) ?? 0).compareTo(
            int.tryParse(p.basename(b.path)) ?? 0,
          ),
        );
      for (final fd in fds) {
        String target;
        try {
          target = Link(fd.path).targetSync();
        } catch (_) {
          continue;
        }
        if (!target.startsWith('/') || target.endsWith(' (deleted)')) continue;
        if (!extensions.contains(p.extension(target).toLowerCase())) continue;
        final name = p.basename(target);
        if (name.startsWith('.~')) {
          add(p.join(p.dirname(target), name.substring(2)));
        } else if (!name.startsWith('~\$')) {
          add(target);
        }
      }
    } catch (e) {
      debugPrint('WPS take-over: cannot read the open files of $pid: $e');
    }
    return found;
  }

  /// [files] with the one a window title names (the longest name that
  /// fits, with or without its extension, first title first) moved to the
  /// end: the file opened last is the active one.
  static List<String> activeLast(List<String> files, List<String> titles) {
    int fit(String title, String file) {
      final name = p.basename(file);
      if (title.contains(name)) return name.length;
      final stem = p.basenameWithoutExtension(file);
      return stem.isNotEmpty && title.contains(stem) ? stem.length : 0;
    }

    for (final title in titles) {
      String? named;
      var longest = 0;
      for (final file in files) {
        final length = fit(title, file);
        if (length > longest) {
          longest = length;
          named = file;
        }
      }
      if (named != null) return [...files.where((f) => f != named), named];
    }
    return files;
  }
}
