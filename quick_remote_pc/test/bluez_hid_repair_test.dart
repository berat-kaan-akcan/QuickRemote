import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/linux/bluez_hid_repair.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

class FakeBluezDevice implements BluezDevice {
  FakeBluezDevice({required this.resolved, this.busyTimes = 0});

  bool resolved;
  bool isConnected = true;
  int busyTimes;
  final calls = <String>[];

  @override
  Future<bool> get servicesResolved async => resolved;

  @override
  Future<bool> get connected async => isConnected;

  @override
  Future<void> disconnect() async {
    calls.add('Disconnect');
    isConnected = false;
    resolved = false;
  }

  @override
  Future<void> connect() async => calls.add('Connect');

  @override
  Future<void> connectProfile(String uuid) async {
    calls.add('ConnectProfile $uuid');
    if (busyTimes > 0) {
      busyTimes--;
      throw DBusMethodResponseException(DBusMethodErrorResponse('org.bluez.Error.InProgress'));
    }
    // What BlueZ answers after searching: no service of the phone has the UUID.
    throw DBusMethodResponseException(DBusMethodErrorResponse('org.bluez.Error.NotAvailable'));
  }
}

const _search = 'ConnectProfile ${BtHidRepair.serviceUuid}';

void main() {
  test('records not read on this connection: only searches them', () async {
    final device = FakeBluezDevice(resolved: false);
    await refreshServices(device, pollInterval: Duration.zero);
    expect(device.calls, [_search]);
  });

  test('records already read: reconnects around the search', () async {
    final device = FakeBluezDevice(resolved: true);
    await refreshServices(device, pollInterval: Duration.zero);
    expect(device.calls, ['Disconnect', _search, 'Connect']);
  });

  test('retries the search while BlueZ is busy', () async {
    final device = FakeBluezDevice(resolved: false, busyTimes: 2);
    await refreshServices(device, pollInterval: Duration.zero, busyRetryDelay: Duration.zero);
    expect(device.calls, [_search, _search, _search]);
  });

  test('one refresh per device per interval', () {
    final throttle = RepairThrottle(interval: const Duration(seconds: 30));
    final t0 = DateTime(2026);
    expect(throttle.tryAcquire('/org/bluez/hci0/dev_A', t0), isTrue);
    expect(throttle.tryAcquire('/org/bluez/hci0/dev_A', t0.add(const Duration(seconds: 10))), isFalse);
    expect(throttle.tryAcquire('/org/bluez/hci0/dev_B', t0.add(const Duration(seconds: 10))), isTrue);
    expect(throttle.tryAcquire('/org/bluez/hci0/dev_A', t0.add(const Duration(seconds: 30))), isTrue);
  });
}
