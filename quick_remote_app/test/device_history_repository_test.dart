import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/repositories/device_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DeviceHistoryRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = DeviceHistoryRepository();
  });

  test('starts empty', () async {
    expect(await repo.getRecentDevices(), isEmpty);
  });

  test('newest first, and the data survives a reload', () async {
    await repo.saveRecentDevice('10.0.0.1', 8090, '111111', 'A');
    await repo.saveRecentDevice('10.0.0.2', 8090, '222222', 'B');
    final list = await DeviceHistoryRepository().getRecentDevices();
    expect(list.map((d) => d['name']), ['B', 'A']);
    expect(list.first, {
      'name': 'B',
      'host': '10.0.0.2',
      'port': 8090,
      'pin': '222222',
    });
  });

  test('the same host and port moves to the top with the new pin and name',
      () async {
    await repo.saveRecentDevice('10.0.0.1', 8090, '111111', 'A');
    await repo.saveRecentDevice('10.0.0.2', 8090, '222222', 'B');
    final list = await repo.saveRecentDevice('10.0.0.1', 8090, '333333', 'A2');
    expect(list.length, 2);
    expect(list.first['pin'], '333333');
    expect(list.first['name'], 'A2');
  });

  test('the same host on another port is another PC', () async {
    await repo.saveRecentDevice('10.0.0.1', 8090, '111111', 'A');
    final list = await repo.saveRecentDevice('10.0.0.1', 8091, '111111', 'A');
    expect(list.length, 2);
  });

  test('keeps the five most recent and drops the oldest', () async {
    for (var i = 1; i <= 7; i++) {
      await repo.saveRecentDevice('10.0.0.$i', 8090, '000000', 'PC$i');
    }
    final list = await repo.getRecentDevices();
    expect(list.map((d) => d['name']), ['PC7', 'PC6', 'PC5', 'PC4', 'PC3']);
  });

  test('removeDevice removes by address and ignores unknown ones', () async {
    await repo.saveRecentDevice('10.0.0.1', 8090, '111111', 'A');
    await repo.saveRecentDevice('10.0.0.2', 8090, '222222', 'B');
    var list = await repo.removeDevice('10.0.0.1', 8090);
    expect(list.map((d) => d['name']), ['B']);
    list = await repo.removeDevice('10.0.0.9', 1);
    expect(list.length, 1);
    expect((await repo.getRecentDevices()).length, 1);
  });

  test('removeRecentDevice by index, out of range changes nothing', () async {
    await repo.saveRecentDevice('10.0.0.1', 8090, '111111', 'A');
    await repo.saveRecentDevice('10.0.0.2', 8090, '222222', 'B');
    expect((await repo.removeRecentDevice(-1)).length, 2);
    expect((await repo.removeRecentDevice(2)).length, 2);
    final list = await repo.removeRecentDevice(0);
    expect(list.map((d) => d['name']), ['A']);
    expect((await repo.getRecentDevices()).single['name'], 'A');
  });

  test('a damaged entry does not lose the others', () async {
    SharedPreferences.setMockInitialValues({
      'recent_devices': [
        '{"name":"A","host":"10.0.0.1","port":8090,"pin":"111111"}',
        'not json',
        '[1,2]',
        '{"name":"B","host":"10.0.0.2","port":8090,"pin":"222222"}',
      ],
    });
    final list = await DeviceHistoryRepository().getRecentDevices();
    expect(list.map((d) => d['name']), ['A', 'B']);
  });
}
