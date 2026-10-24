import 'dart:io';

import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  group('AppLog.redact', () {
    String r(String s, {List<String> homes = const []}) =>
        AppLog.redact(s, homes: homes);

    test('hides PINs', () {
      expect(
          r('Client auth 482913 from 192.168.1.5'), isNot(contains('482913')));
      expect(
          r('{"auth":"482913","name":"Pixel 8"}'), isNot(contains('482913')));
      expect(r("{auth: 482913, name: Pixel 8}"), isNot(contains('482913')));
      expect(r('PIN replaced: 004211'), isNot(contains('004211')));
    });

    test('hides pairing QR contents', () {
      const qr =
          'quickremote://192.168.1.20:8765:482913:q0kVb3cKm1d_8FzXk2a9Lw-Hn4YtR6Up0sEe7JgWiAo';
      final out = r('Scanned $qr');
      expect(out, isNot(contains('482913')));
      expect(out, isNot(contains('q0kVb3cKm1d')));
      expect(out, isNot(contains('8765:')));
      expect(out, contains('quickremote://<redacted>'));
    });

    test('hides certificate fingerprints and the security code', () {
      const hex =
          '3fa94c21b0d8e7f6a5c4b3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2';
      expect(r('pinned $hex'), isNot(contains('3fa94c21')));
      expect(r('cert_fingerprint_192.168.1.20 = $hex'), isNot(contains(hex)));
      expect(
          r('fingerprint q0kVb3cKm1d_8FzXk2a9Lw-Hn4YtR6Up0sEe7JgWiAo mismatch'),
          isNot(contains('q0kVb3cKm1d')));
      expect(r('code 3FA9-4C21-B0D8-E7F6 shown'), isNot(contains('3FA9-4C21')));
      expect(r('SHA256 3F:A9:4C:21:B0:D8:E7:F6:A5:C4:B3:D2:E1:F0:A9:B8:C7:D6'),
          isNot(contains('3F:A9')));
      expect(r('{"fingerprint": "abc"}'), isNot(contains('abc')));
    });

    test('hides passwords, secrets and tokens, whatever the name around them', () {
      for (final line in [
        'password=hunter2 next',
        'QR_CERT_PASSWORD=AbCdEfGh1234567890AbCdEfGh123456',
        'cert password: AbCdEfGh1234567890',
        '{"password": "hunter2"}',
        "{secret: hunter2, volume: 4}",
        'api_token = hunter2;',
        'Authorization: Bearer hunter2.abc-def',
      ]) {
        expect(r(line), isNot(contains('hunter2')), reason: line);
        expect(r(line), isNot(contains('AbCdEfGh')), reason: line);
      }
      expect(r("{secret: hunter2, volume: 4}"), contains('volume: 4'));
    });

    test('hides notes and media titles', () {
      final json = r(
          '{"type":"SLIDE_STATE","current":3,"notes":"Mention the \\"secret\\" Q3 figures","total":12}');
      expect(json, isNot(contains('secret')));
      expect(json, contains('"current":3'));
      expect(json, contains('"total":12'));
      final map =
          r('state: {current: 3, notes: Mention the Q3 figures, total: 12}');
      expect(map, isNot(contains('Q3 figures')));
      expect(map, contains('total: 12'));
      expect(r("{'title': 'My private song', 'artist': 'Someone'}"),
          isNot(contains('private song')));
      expect(
          r('FormatException: Unexpected end of input (at character 30)\n{"notes":"half a sentence'),
          isNot(contains('half a sentence')));
    });

    test('hides file paths and home folders', () {
      expect(
          r("FileSystemException: Cannot open file, path = '/home/berat/Belgeler/talk.odp'"),
          allOf(isNot(contains('berat')), isNot(contains('talk.odp'))));
      expect(r('deck /home/berat/My Decks/q3 plan.pptx opened'),
          isNot(contains('My Decks')));
      expect(r(r'Slide export failed: C:\Users\Berat Kaan\Documents\deck.pptx'),
          allOf(isNot(contains('Berat')), isNot(contains('deck.pptx'))));
      expect(r(r'"C:\\Users\\berat\\AppData\\Roaming\\x.txt"'),
          isNot(contains('berat')));
      expect(
          r(r'share \\fileserver\talks\q3.pptx'), isNot(contains('q3.pptx')));
      expect(r('loading file:///home/berat/Masa%C3%BCst%C3%BC/x.odp'),
          isNot(contains('berat')));
      expect(
          r('/run/media/berat/USB/deck.odp missing'), isNot(contains('berat')));
      expect(r('~/Desktop/deck.odp'), isNot(contains('Desktop')));
      expect(r('{"deckKey": "/home/b/x.odp|1700000000"}'),
          isNot(contains('x.odp')));
      expect(
        r('home is somewhere: /home/berat (the user)', homes: ['/home/berat']),
        isNot(contains('berat')),
      );
      expect(r(r'C:\Users\berat\x', homes: [r'C:\Users\berat']),
          isNot(contains('berat')));
    });

    test('keeps what a bug report needs', () {
      const line =
          'Client auth failed (wrong PIN) from 192.168.1.5 on port 8765';
      expect(r(line), line);
      expect(r('Refused connection from fe80::1c2d:3e4f (rate limit)'),
          contains('fe80::1c2d:3e4f'));
      expect(r('Client "Pixel 8 Pro" connected from 10.0.0.7'),
          contains('Pixel 8 Pro'));
      expect(r('uinput: cannot open /dev/uinput (permission missing?)'),
          contains('/dev/uinput'));
      expect(r('Executed: START_AT:12'), 'Executed: START_AT:12');
      expect(r('see https://github.com/berat-kaan-akcan/QuickRemote/issues'),
          contains('https://github.com/berat-kaan-akcan/QuickRemote/issues'));
      expect(r('ImpressBridge exited with code 1'),
          'ImpressBridge exited with code 1');
      expect(r('{"ok":false,"error":"NO_SHOW","code":"NO_SPOTLIGHT"}'),
          contains('NO_SPOTLIGHT'));
      expect(r('#0 main (package:quick_remote_pc/main.dart:12:5)'),
          contains('package:quick_remote_pc/main.dart:12:5'));
      expect(
          r('took 20 ms, ~120 Hz, 1/2 done'), 'took 20 ms, ~120 Hz, 1/2 done');
      expect(r('IP changed: 192.168.1.4 -> 192.168.1.9'),
          'IP changed: 192.168.1.4 -> 192.168.1.9');
    });
  });

  group('AppLog files', () {
    late Directory dir;
    final console = <String>[];

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('applog_test');
      console.clear();
      await AppLog.init(dir, console: console.add, homes: const []);
    });

    tearDown(() async {
      await AppLog.reset();
      await dir.delete(recursive: true);
    });

    test('writes redacted lines to the console and the file', () async {
      AppLog.log('PIN 482913 for 192.168.1.5');
      expect(console.single, 'PIN <pin> for 192.168.1.5');
      final text = await AppLog.collect();
      expect(text, contains('PIN <pin> for 192.168.1.5'));
      expect(text, isNot(contains('482913')));
      expect(File('${dir.path}/quickremote.log').existsSync(), isTrue);
    });

    test('logs errors with their stack', () async {
      AppLog.error(
          'test', StateError('boom'), StackTrace.fromString('#0 here'));
      final text = await AppLog.collect();
      expect(text, contains('ERROR (test): Bad state: boom'));
      expect(text, contains('#0 here'));
    });

    test('rotates at 1 MB and keeps 3 files', () async {
      final line = 'x' * 1000;
      for (var round = 0; round < 4; round++) {
        for (var i = 0; i < 1100; i++) {
          AppLog.log(line);
        }
        await AppLog.flush();
      }
      final files = AppLog.files();
      expect(files.length, AppLog.keepFiles);
      for (final f in files) {
        expect(f.lengthSync(),
            lessThanOrEqualTo(AppLog.maxFileBytes + 1100 * 1030));
      }
      expect(File('${dir.path}/quickremote.3.log').existsSync(), isFalse);
    });

    test('drops the oldest lines past the queue limit', () async {
      for (var i = 0; i < AppLog.maxPending + 10; i++) {
        AppLog.log('line $i');
      }
      final text = await AppLog.collect();
      expect(text, contains('10 lines dropped'));
      expect(text, isNot(contains('line 9\n')));
      expect(text, contains('line ${AppLog.maxPending + 9}'));
    });

    test('cuts very long lines', () async {
      AppLog.log('y' * (AppLog.maxLineLength + 500));
      expect(console.single.length, lessThan(AppLog.maxLineLength + 40));
    });
  });

  test('logs to the console only before init', () async {
    await AppLog.reset();
    AppLog.log('early');
    expect(AppLog.files(), isEmpty);
  });

  test('issueUrl fills in a new GitHub issue', () {
    final url = AppLog.issueUrl(title: 'Laser & ink', body: 'Version: 1.0\nPlatform: linux');
    expect(url.toString(), startsWith('https://github.com/berat-kaan-akcan/QuickRemote/issues/new?'));
    expect(url.queryParameters['title'], 'Laser & ink');
    expect(url.queryParameters['body'], 'Version: 1.0\nPlatform: linux');
    expect(url.toString(), isNot(contains(' ')));
  });
}
