import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Encrypts or decrypts bytes for the current user; null when it cannot.
typedef BytesTransform = Uint8List? Function(Uint8List data);

/// Where the Windows server keeps its certificate's password: encrypted
/// for the user ([protect], DPAPI) in `cert_pwd.dpapi`, so another user of
/// the PC, or someone with a copy of the folder, cannot open the `.pfx`.
/// Before 2026-11 it was plain text in `cert_pwd.txt`, protected by the
/// folder's permissions only: such a file is read once, stored encrypted
/// and deleted. Where encryption fails the plain file is kept as before.
///
/// A password that cannot be decrypted reads as none, and the server then
/// makes a new certificate: phones ask for the security code again. That
/// is meant: DPAPI's key belongs to the Windows user on this PC, so it
/// happens when the app's folder was copied to another PC or user, or the
/// user's password was reset by an administrator. An older version of the
/// app does not know `cert_pwd.dpapi` and makes a new certificate too.
class CertPasswordStore {
  CertPasswordStore(this.directory, {required this.protect, required this.unprotect});

  final String directory;
  final BytesTransform protect;
  final BytesTransform unprotect;

  File get _sealed => File(p.join(directory, 'cert_pwd.dpapi'));
  File get _plain => File(p.join(directory, 'cert_pwd.txt'));

  /// The stored password; null when there is none or it cannot be read
  /// (the server then makes a new certificate).
  String? read() {
    if (_sealed.existsSync()) {
      try {
        final bytes = unprotect(_sealed.readAsBytesSync());
        if (bytes != null) {
          final password = utf8.decode(bytes);
          if (password.isNotEmpty) return password;
        }
      } catch (e) {
        // Unreadable file or bytes that are no text: as if not decrypted.
      }
      debugPrint('Certificate password could not be decrypted');
      return null;
    }
    if (_plain.existsSync()) {
      final password = _plain.readAsStringSync().trim();
      if (password.isEmpty) return null;
      // An older version's plain file: encrypted from now on. The password
      // is good either way: a failure here must not cost the certificate.
      try {
        write(password);
      } catch (e) {
        debugPrint('Certificate password stays in the plain file: $e');
      }
      return password;
    }
    return null;
  }

  /// Stores [password] encrypted, and removes a plain copy; plain only
  /// when encryption fails.
  void write(String password) {
    final sealed = protect(Uint8List.fromList(utf8.encode(password)));
    if (sealed == null) {
      debugPrint('Certificate password stored without encryption: DPAPI failed');
      _plain.writeAsStringSync(password, flush: true);
      if (_sealed.existsSync()) _sealed.deleteSync();
      return;
    }
    // Written beside and renamed: a crash never leaves half a file, which
    // would read as "cannot be decrypted" and cost the certificate.
    final part = File('${_sealed.path}.part')..writeAsBytesSync(sealed, flush: true);
    part.renameSync(_sealed.path);
    if (_plain.existsSync()) _plain.deleteSync();
  }
}
