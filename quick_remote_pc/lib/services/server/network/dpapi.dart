import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// The Windows Data Protection API: bytes encrypted with a key of the
/// signed-in user, which only that user on this PC can decrypt. Used for
/// the certificate's password (CertPasswordStore). Windows only; written
/// on Linux and not yet run on Windows.
class Dpapi {
  Dpapi._();

  /// No dialog may be shown (CRYPTPROTECT_UI_FORBIDDEN).
  static const _uiForbidden = 0x1;

  /// The optional entropy, the same for both directions. It is no secret
  /// (it is in the program): it only keeps a blob of ours from being
  /// decrypted by a tool that calls CryptUnprotectData on every file it
  /// finds without knowing whose it is. Changing it makes every stored
  /// password unreadable (a new certificate).
  static const _entropy = 'QuickRemote PC certificate password v1';

  static Uint8List? protect(Uint8List data) => _run(data, encrypt: true);
  static Uint8List? unprotect(Uint8List data) => _run(data, encrypt: false);

  static Uint8List? _run(Uint8List data, {required bool encrypt}) {
    final salt = _entropy.codeUnits;
    final input = calloc<CRYPT_INTEGER_BLOB>();
    final entropy = calloc<CRYPT_INTEGER_BLOB>();
    final output = calloc<CRYPT_INTEGER_BLOB>();
    final bytes = calloc<Uint8>(data.isEmpty ? 1 : data.length);
    final saltBytes = calloc<Uint8>(salt.length);
    try {
      bytes.asTypedList(data.length).setAll(0, data);
      saltBytes.asTypedList(salt.length).setAll(0, salt);
      input.ref
        ..cbData = data.length
        ..pbData = bytes;
      entropy.ref
        ..cbData = salt.length
        ..pbData = saltBytes;
      final ok = encrypt
          ? CryptProtectData(input, null, entropy, null, _uiForbidden, output).value
          : CryptUnprotectData(input, null, entropy, null, _uiForbidden, output).value;
      if (!ok || output.ref.pbData.address == 0) return null;
      return Uint8List.fromList(output.ref.pbData.asTypedList(output.ref.cbData));
    } catch (_) {
      return null;
    } finally {
      // Neither the password given nor the one decrypted stays in freed
      // memory. The output buffer is the system's (LocalAlloc).
      final out = output.ref.pbData;
      if (out.address != 0) {
        out.asTypedList(output.ref.cbData).fillRange(0, output.ref.cbData, 0);
        LocalFree(HLOCAL(out));
      }
      bytes.asTypedList(data.length).fillRange(0, data.length, 0);
      calloc.free(bytes);
      calloc.free(saltBytes);
      calloc.free(input);
      calloc.free(entropy);
      calloc.free(output);
    }
  }
}
