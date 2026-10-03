import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/l10n/failure_text.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

void main() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('a PC error code is shown in the phone\'s language', () {
    final failure = RemoteFailure.fromStatus(RemoteError.slideshowNotRunning.status());
    expect(failure.error, RemoteError.slideshowNotRunning);
    expect(tr.failure(failure), 'Slayt gösterisi aktif değil.');
    expect(en.failure(failure), 'No slideshow is running.');
  });

  test('info is kept untranslated', () {
    final failure = RemoteFailure.fromStatus(RemoteError.commandFailed.status('BRIDGE_DIED'));
    expect(en.failure(failure), 'Presentation command failed: BRIDGE_DIED');
  });

  test('without a known code the PC\'s own text is shown', () {
    const older = {'type': 'STATUS', 'state': 'COMMAND_FAILED', 'detail': 'Eski PC metni'};
    expect(en.failure(RemoteFailure.fromStatus(older)), 'Eski PC metni');
    const newer = {'type': 'STATUS', 'state': 'COMMAND_FAILED', 'code': 'NEW_CODE', 'detail': 'Yeni'};
    expect(en.failure(RemoteFailure.fromStatus(newer)), 'Yeni');
    expect(en.failure(const RemoteFailure(null)), en.errorUnknown);
  });

  test('every error has a text in every language', () {
    for (final l10n in [tr, en]) {
      for (final error in RemoteError.values) {
        expect(l10n.remoteError(error, 'x'), isNotEmpty, reason: '$error');
      }
      for (final error in ConnectionError.values) {
        expect(l10n.connectionError(error, 'x'), isNotEmpty, reason: '$error');
      }
    }
    expect(tr.connectionError(ConnectionError.serverNotFound, 'refused'), 'Sunucuya ulaşılamadı: refused');
  });

  test('the legacy Turkish text matches the phone\'s Turkish', () {
    // Older phones read legacyDetail; both should say the same thing.
    for (final error in RemoteError.values) {
      expect(error.legacyDetail('x'), tr.remoteError(error, 'x'), reason: '$error');
    }
  });
}
