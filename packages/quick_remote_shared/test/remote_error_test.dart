import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  test('codes are unique and round-trip', () {
    final codes = RemoteError.values.map((e) => e.code).toList();
    expect(codes.toSet(), hasLength(codes.length));
    for (final error in RemoteError.values) {
      expect(RemoteError.fromCode(error.code), error);
    }
    expect(RemoteError.fromCode('SOMETHING_NEW'), isNull);
    expect(RemoteError.fromCode(null), isNull);
  });

  test('status carries the code, info and the legacy text', () {
    expect(RemoteError.slideshowNotRunning.status(), {
      'type': 'STATUS',
      'state': 'COMMAND_FAILED',
      'code': 'NOT_RUNNING',
      'detail': 'Slayt gösterisi aktif değil.',
    });
    final status = RemoteError.commandFailed.status('BRIDGE_DIED');
    expect(status['info'], 'BRIDGE_DIED');
    expect(status['detail'], 'Sunum komutu başarısız: BRIDGE_DIED');
  });
}
