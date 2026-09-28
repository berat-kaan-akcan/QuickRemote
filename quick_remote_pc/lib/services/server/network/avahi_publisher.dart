import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

/// Publishes the mDNS service through avahi-daemon's D-Bus API (the `nsd`
/// plugin has no Linux implementation). The registration lives as long as the
/// D-Bus connection, so [unregister] simply closes it.
class AvahiPublisher {
  static const _bus = 'org.freedesktop.Avahi';
  static const _ifUnspec = -1;
  static const _protoUnspec = -1;

  DBusClient? _client;

  Future<bool> register({required String name, required String type, required int port}) async {
    await unregister();
    final client = DBusClient.system();
    try {
      final server = DBusRemoteObject(client, name: _bus, path: DBusObjectPath('/'));
      final reply = await server.callMethod(
        'org.freedesktop.Avahi.Server', 'EntryGroupNew', [],
        replySignature: DBusSignature('o'),
      );
      final group = DBusRemoteObject(client, name: _bus, path: reply.values.first.asObjectPath());
      await group.callMethod(
        'org.freedesktop.Avahi.EntryGroup', 'AddService',
        [
          const DBusInt32(_ifUnspec),
          const DBusInt32(_protoUnspec),
          const DBusUint32(0),
          DBusString(name),
          DBusString(type),
          const DBusString(''), // default domain
          const DBusString(''), // default host
          DBusUint16(port),
          DBusArray(DBusSignature('ay'), []),
        ],
        replySignature: DBusSignature(''),
      );
      await group.callMethod('org.freedesktop.Avahi.EntryGroup', 'Commit', [],
          replySignature: DBusSignature(''));
      _client = client;
      return true;
    } catch (e) {
      debugPrint('Avahi registration failed (is avahi-daemon running?): $e');
      await client.close();
      return false;
    }
  }

  Future<void> unregister() async {
    final client = _client;
    _client = null;
    await client?.close();
  }
}
