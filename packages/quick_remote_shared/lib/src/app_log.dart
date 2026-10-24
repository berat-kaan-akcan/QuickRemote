import 'dart:async';
import 'dart:io';

/// The app's local log: every line goes to the console and, once [init] has
/// a folder, to `quickremote.log` there. Nothing is ever sent anywhere; the
/// user exports the file (PC: Settings, phone: Ayarlar) and attaches it to an
/// issue themselves.
///
/// Lines are cleaned by [redact] before they reach the console or the file,
/// queued in memory and written in batches off the caller's path, so logging
/// never waits for the disk (the 125 Hz input path logs too). The file is
/// rotated at [maxFileBytes]; [keepFiles] files are kept
/// (`quickremote.log`, `quickremote.1.log`, `quickremote.2.log`).
///
/// Both apps route Flutter's `debugPrint` here in `main()`.
class AppLog {
  AppLog._();

  static const maxFileBytes = 1024 * 1024;
  static const keepFiles = 3;
  static const baseName = 'quickremote';

  /// Longer lines are cut (a dumped reply must not fill the file).
  static const maxLineLength = 4000;

  /// Lines waiting for the disk; beyond this the oldest are dropped.
  static const maxPending = 5000;

  static const _flushDelay = Duration(milliseconds: 500);

  static Directory? _dir;
  static bool _enabled = false;
  static void Function(String line) _console = print;
  static List<String> _homes = const [];
  static final List<String> _pending = [];
  static int _dropped = 0;
  static Timer? _timer;
  static Future<void> _writing = Future.value();
  static int? _size;

  /// The folder holding the log files, once [init] found it.
  static Directory? get directory => _dir;

  /// Starts writing to [directory] (created if missing). Lines logged before
  /// it resolves are kept and written first. [console] replaces `print` (the
  /// apps pass Flutter's original `debugPrint`). [homes] are folders whose
  /// path is written as `~` (the user's home; [redact] then hides the rest).
  static Future<void> init(
    FutureOr<Directory> directory, {
    void Function(String line)? console,
    List<String>? homes,
  }) async {
    _enabled = true;
    if (console != null) _console = console;
    _homes = homes ?? _defaultHomes();
    try {
      final dir = await directory;
      await dir.create(recursive: true);
      _dir = dir;
      _size = null;
      _schedule();
    } catch (e) {
      _enabled = false;
      _pending.clear();
      _console('AppLog: no log file: ${redact(e.toString(), homes: _homes)}');
    }
  }

  static List<String> _defaultHomes() {
    final env = Platform.environment;
    return [
      for (final key in const ['HOME', 'USERPROFILE'])
        if ((env[key] ?? '').length > 1) env[key]!,
    ];
  }

  /// Logs [message] (cleaned by [redact]); never throws and never waits.
  static void log(String message) {
    var text = redact(message, homes: _homes);
    if (text.length > maxLineLength) {
      text = '${text.substring(0, maxLineLength)}… (${text.length} chars)';
    }
    try {
      _console(text);
    } catch (_) {}
    if (!_enabled) return;
    final stamp = DateTime.now().toIso8601String();
    for (final line in text.split('\n')) {
      _pending.add('$stamp $line');
    }
    if (_pending.length > maxPending) {
      final extra = _pending.length - maxPending;
      _pending.removeRange(0, extra);
      _dropped += extra;
    }
    _schedule();
  }

  /// Logs an error with its stack; [source] says where it was caught.
  static void error(String source, Object error, [StackTrace? stack]) {
    final trace = stack?.toString().trimRight();
    log('ERROR ($source): $error${trace == null || trace.isEmpty ? '' : '\n$trace'}');
    unawaited(flush());
  }

  static void _schedule() {
    if (_dir == null || _pending.isEmpty || _timer != null) return;
    _timer = Timer(_flushDelay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  /// Writes what is queued now; the returned future completes when it is on
  /// disk.
  static Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    final dir = _dir;
    if (dir == null || _pending.isEmpty) return _writing;
    final lines = List<String>.of(_pending);
    _pending.clear();
    if (_dropped > 0) {
      lines.insert(0,
          '${DateTime.now().toIso8601String()} AppLog: $_dropped lines dropped');
      _dropped = 0;
    }
    final chunk = '${lines.join('\n')}\n';
    return _writing =
        _writing.then((_) => _write(dir, chunk)).catchError((Object e) {
      try {
        _console(
            'AppLog: write failed: ${redact(e.toString(), homes: _homes)}');
      } catch (_) {}
    });
  }

  static Future<void> _write(Directory dir, String chunk) async {
    final current = File(_path(dir, 0));
    _size ??= await current.exists() ? await current.length() : 0;
    final bytes = chunk.length; // close enough: rotation needs no exact count
    if (_size! > 0 && _size! + bytes > maxFileBytes) {
      await _rotate(dir);
      _size = 0;
    }
    await current.writeAsString(chunk, mode: FileMode.append);
    _size = _size! + bytes;
  }

  static Future<void> _rotate(Directory dir) async {
    final oldest = File(_path(dir, keepFiles - 1));
    if (await oldest.exists()) await oldest.delete();
    for (var i = keepFiles - 2; i >= 0; i--) {
      final file = File(_path(dir, i));
      if (await file.exists()) await file.rename(_path(dir, i + 1));
    }
  }

  static String _path(Directory dir, int index) =>
      '${dir.path}${Platform.pathSeparator}$baseName${index == 0 ? '' : '.$index'}.log';

  /// The log files that exist, oldest first.
  static List<File> files() {
    final dir = _dir;
    if (dir == null) return const [];
    return [
      for (var i = keepFiles - 1; i >= 0; i--) File(_path(dir, i)),
    ].where((f) => f.existsSync()).toList();
  }

  /// Every log file after a [flush], oldest first, as one text.
  static Future<String> collect() async {
    await flush();
    final buffer = StringBuffer();
    for (final file in files()) {
      try {
        buffer.write(await file.readAsString());
      } catch (_) {
        // A half-written UTF-8 sequence after a crash: keep the rest.
        buffer.write(String.fromCharCodes(await file.readAsBytes()));
      }
    }
    return buffer.toString();
  }

  /// Forgets the folder and the queue (tests).
  static Future<void> reset() async {
    _timer?.cancel();
    _timer = null;
    await _writing;
    _pending.clear();
    _dropped = 0;
    _dir = null;
    _enabled = false;
    _size = null;
    _console = print;
    _homes = const [];
  }

  /// The project on GitHub, where "Report a problem" opens a new issue.
  static const repository = 'https://github.com/berat-kaan-akcan/QuickRemote';

  /// A new GitHub issue with [title] and [body] filled in. The user attaches
  /// the exported log themselves; nothing is uploaded by the app.
  static Uri issueUrl({required String title, required String body}) => Uri.parse(
        '$repository/issues/new?title=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent(body)}',
      );

  // ---------------------------------------------------------------------
  // Redaction

  /// Folders shown as they are: system places that say what is broken and
  /// hold nothing of the user's.
  static const _systemDirs = [
    '/dev/',
    '/usr/',
    '/proc/',
    '/sys/',
    '/etc/',
    '/bin/',
    '/sbin/',
    '/lib/',
    '/lib64/',
    '/opt/',
    '/var/lib/',
    '/var/log/',
  ];

  static const _pathChars = r'''[^\s'"`<>|,;()\[\]{}]''';

  static final _pairing = RegExp(r'quickremote://\S*', caseSensitive: false);
  static final _fileUri = RegExp(r'''file:/[^\s'"<>]*''', caseSensitive: false);
  static final _quotedPath = RegExp(
    r'''(['"])((?:~[\\/]|/|[A-Za-z]:[\\/]|\\\\)[^'"\n]*)\1''',
  );
  // A space belongs to the path when the next word goes on with a separator.
  static final _windowsPath = RegExp(
    r'(?<![A-Za-z0-9])(?:[A-Za-z]:[\\/]|\\\\)(?:' +
        _pathChars +
        r'|\s(?=' +
        _pathChars +
        r'*[\\/]))*',
  );
  static final _unixPath = RegExp(
    r'(?<![\w:/.~\\-])(?:~|/' +
        _pathChars +
        r'+)(?:/(?:' +
        _pathChars +
        r'|\s(?=' +
        _pathChars +
        r'*/))*)+',
  );
  static const _secretKeys =
      r'pin|auth|notes?|title|artist|album|deckKey|path|file|filename|fingerprint|cert_fingerprint\w*';
  // "key": "value" / 'key': 'value' / "key": 123 (JSON, Python).
  static final _quotedValue = RegExp(
    // An unclosed string (a cut excerpt in a FormatException) runs to the
    // end of the line.
    '''(["']?)\\b($_secretKeys)\\1(\\s*[:=]\\s*)(?:"(?:[^"\\\\\\n]|\\\\.)*"?|'(?:[^'\\\\\\n]|\\\\.)*'?|[0-9]+)''',
    caseSensitive: false,
  );
  // key: value in a Dart Map's toString, up to the next ", key:" or "}".
  static final _bareValue = RegExp(
    '\\b($_secretKeys)(: )(?!<)[^\\n]*?(?=, \\w+: |\\}|\$)',
    caseSensitive: false,
  );
  static final _hexFingerprint =
      RegExp(r'(?<![0-9A-Fa-f])[0-9A-Fa-f]{40,}(?![0-9A-Fa-f])');
  static final _colonFingerprint = RegExp(
      r'(?<![0-9A-Fa-f:])(?:[0-9A-Fa-f]{2}:){15,}[0-9A-Fa-f]{2}(?![0-9A-Fa-f:])');
  static final _base64Fingerprint =
      RegExp(r'(?<![A-Za-z0-9_-])(?=[A-Za-z_-]*\d)[A-Za-z0-9_-]{43}(?![A-Za-z0-9_-])');
  static final _securityCode = RegExp(
      r'(?<![0-9A-Fa-f-])[0-9A-Fa-f]{4}(?:-[0-9A-Fa-f]{4}){3}(?![0-9A-Fa-f-])');
  static final _pin = RegExp(r'(?<![\w.:-])\d{6}(?![\w.:-])');

  /// [text] without anything private: PINs (any lone 6-digit number),
  /// pairing QR contents, certificate fingerprints and security codes, notes
  /// and media titles, and file paths (home folders, decks, `file:` URLs).
  /// IP addresses, ports and device names stay: they are what a bug report
  /// needs.
  static String redact(String text, {List<String> homes = const []}) {
    var out = text;
    for (final home in homes) {
      if (home.length > 1) out = out.replaceAll(home, '~');
    }
    out = out.replaceAll(_pairing, 'quickremote://<redacted>');
    out = out.replaceAll(_fileUri, 'file:<path>');
    out = out.replaceAllMapped(
        _quotedPath, (m) => _isSystem(m[2]!) ? m[0]! : '${m[1]}<path>${m[1]}');
    out = out.replaceAll(_windowsPath, '<path>');
    out = out.replaceAllMapped(
        _unixPath, (m) => _isSystem(m[0]!) ? m[0]! : '<path>');
    out = out.replaceAllMapped(
        _quotedValue, (m) => '${m[1]}${m[2]}${m[1]}${m[3]}<redacted>');
    out = out.replaceAllMapped(_bareValue, (m) => '${m[1]}${m[2]}<redacted>');
    out = out.replaceAll(_colonFingerprint, '<fingerprint>');
    out = out.replaceAll(_hexFingerprint, '<fingerprint>');
    out = out.replaceAll(_base64Fingerprint, '<fingerprint>');
    out = out.replaceAll(_securityCode, '<code>');
    out = out.replaceAll(_pin, '<pin>');
    return out;
  }

  static bool _isSystem(String path) => _systemDirs.any(path.startsWith);
}
