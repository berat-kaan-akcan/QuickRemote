import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quick_remote_pc/services/server/network/cert_password_store.dart';

/// A stand-in for DPAPI: every byte flipped, so the file never holds the
/// password as it is.
Uint8List? _flip(Uint8List data) => Uint8List.fromList([for (final b in data) b ^ 0xFF]);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('certpwd'));
  tearDown(() => dir.deleteSync(recursive: true));

  CertPasswordStore store({BytesTransform protect = _flip, BytesTransform unprotect = _flip}) =>
      CertPasswordStore(dir.path, protect: protect, unprotect: unprotect);
  File file(String name) => File(p.join(dir.path, name));

  test('stores the password encrypted, never in plain text', () {
    store().write('s3cret-pass');
    expect(file('cert_pwd.txt').existsSync(), isFalse);
    expect(String.fromCharCodes(file('cert_pwd.dpapi').readAsBytesSync()).contains('s3cret'), isFalse);
    expect(store().read(), 's3cret-pass');
  });

  test('an older plain file is read once, then kept encrypted', () {
    file('cert_pwd.txt').writeAsStringSync('old-pass\n');
    expect(store().read(), 'old-pass');
    expect(file('cert_pwd.txt').existsSync(), isFalse);
    expect(file('cert_pwd.dpapi').existsSync(), isTrue);
    expect(store().read(), 'old-pass');
  });

  test('without a working DPAPI it keeps the plain file as before', () {
    store(protect: (_) => null).write('plain-pass');
    expect(file('cert_pwd.txt').readAsStringSync(), 'plain-pass');
    expect(file('cert_pwd.dpapi').existsSync(), isFalse);
    expect(store().read(), 'plain-pass');
  });

  test('a password that cannot be decrypted (another user) reads as none', () {
    store().write('mine');
    expect(store(unprotect: (_) => null).read(), isNull);
  });

  test('a broken encrypted file reads as none and does not throw', () {
    // Bytes that decrypt to no UTF-8 text, and an empty file.
    file('cert_pwd.dpapi').writeAsBytesSync([0x00, 0x3F, 0x00]);
    expect(store().read(), isNull);
    file('cert_pwd.dpapi').writeAsBytesSync([]);
    expect(store().read(), isNull);
    expect(store(unprotect: (_) => throw StateError('dpapi')).read(), isNull);
  });

  test('an encrypted file wins over a plain one left behind', () {
    store().write('new');
    file('cert_pwd.txt').writeAsStringSync('stale');
    expect(store().read(), 'new');
  });

  test('a plain file that cannot be encrypted still gives its password', () {
    file('cert_pwd.txt').writeAsStringSync('old-pass');
    // Encryption fails: the plain file stays and is read again next time.
    expect(store(protect: (_) => null).read(), 'old-pass');
    expect(file('cert_pwd.txt').readAsStringSync(), 'old-pass');
    // Encryption throws (or the encrypted file cannot be written): the
    // password is still returned, so the certificate is kept.
    expect(store(protect: (_) => throw StateError('disk')).read(), 'old-pass');
    expect(file('cert_pwd.txt').existsSync(), isTrue);
    expect(file('cert_pwd.dpapi').existsSync(), isFalse);
  });

  test('writing again replaces the password and leaves no part file', () {
    store().write('first');
    store().write('second');
    expect(store().read(), 'second');
    expect(dir.listSync().map((f) => p.basename(f.path)), ['cert_pwd.dpapi']);
  });

  test('switching from the plain fallback to encryption removes the plain file', () {
    store(protect: (_) => null).write('pass');
    store().write('pass');
    expect(file('cert_pwd.txt').existsSync(), isFalse);
    expect(store().read(), 'pass');
  });

  test('nothing stored reads as none', () {
    expect(store().read(), isNull);
  });
}
