import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/bluetooth/bt_hid_service.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('com.quickremote.quick_remote_app/bt_hid');
  const events = EventChannel('com.quickremote.quick_remote_app/bt_hid_events');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test('refusals from the computer reach the screen and survive a resume', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return null;
    });
    late MockStreamHandlerEventSink sink;
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(onListen: (_, s) => sink = s),
    );
    final bt = BtHidService.instance;
    final states = <BtHidConnectionState>[];
    final sub = bt.stateStream.listen(states.add);

    await bt.startAdvertising();
    expect(calls.single.method, 'startAdvertising');
    expect(calls.single.arguments, {'repairUuid': BtHidRepair.serviceUuid});

    sink.success('refreshing');
    await Future<void>.delayed(Duration.zero);
    expect(bt.connectionState, BtHidConnectionState.refreshing);

    sink.success('host_unaware');
    await Future<void>.delayed(Duration.zero);
    expect(bt.connectionState, BtHidConnectionState.hostUnaware);

    // Coming back to the app must not hide what the user has to do.
    await bt.ensureConnected();
    expect(bt.connectionState, BtHidConnectionState.hostUnaware);
    expect(calls.last.arguments, {'repairUuid': BtHidRepair.serviceUuid});

    sink.success('connected:berat-cachyos');
    await Future<void>.delayed(Duration.zero);
    expect(bt.connectionState, BtHidConnectionState.connected);
    expect(bt.connectedDeviceName, 'berat-cachyos');

    expect(states, [
      BtHidConnectionState.advertising,
      BtHidConnectionState.refreshing,
      BtHidConnectionState.hostUnaware,
      BtHidConnectionState.connected,
    ]);

    await bt.stopAdvertising();
    await sub.cancel();
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  test('names the computer being tried, without changing the state', () async {
    messenger.setMockMethodCallHandler(methods, (call) async => null);
    late MockStreamHandlerEventSink sink;
    messenger.setMockStreamHandler(events, MockStreamHandler.inline(onListen: (_, s) => sink = s));
    final bt = BtHidService.instance;
    final states = <BtHidConnectionState>[];
    final sub = bt.stateStream.listen(states.add);

    await bt.startAdvertising();
    expect(bt.targetName, isNull);
    sink.success('target:berat-cachyos');
    await Future<void>.delayed(Duration.zero);
    expect(bt.targetName, 'berat-cachyos');
    expect(bt.connectionState, BtHidConnectionState.advertising);
    // Listeners hear about it to redraw the name.
    expect(states, [BtHidConnectionState.advertising, BtHidConnectionState.advertising]);

    sink.success('error:hid_unavailable');
    await Future<void>.delayed(Duration.zero);
    expect(bt.connectionState, BtHidConnectionState.error);
    expect(bt.errorReason, 'hid_unavailable');
    expect(bt.isAdvertisingRequested, isFalse);

    await bt.stopAdvertising();
    await sub.cancel();
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  test('making the phone visible answers the seconds, 0 when refused', () async {
    var answer = 300;
    messenger.setMockMethodCallHandler(methods, (call) async {
      expect(call.method, 'requestDiscoverable');
      return answer;
    });
    expect(await BtHidService.instance.requestDiscoverable(), 300);
    answer = 0;
    expect(await BtHidService.instance.requestDiscoverable(), 0);
    messenger.setMockMethodCallHandler(methods, (call) async => throw PlatformException(code: 'x'));
    expect(await BtHidService.instance.requestDiscoverable(), 0);
    messenger.setMockMethodCallHandler(methods, null);
  });
}
