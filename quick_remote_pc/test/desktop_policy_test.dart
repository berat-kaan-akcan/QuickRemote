import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/desktop/desktop_policy.dart';
import 'package:quick_remote_pc/services/server/network_manager.dart';

void main() {
  test('--minimized marks a start at login', () {
    expect(startedMinimized(['--minimized']), isTrue);
    expect(startedMinimized([]), isFalse);
  });

  test('a minimized start shows the window when there is no tray', () {
    expect(showWindowAtStart(minimized: true, trayShown: true), isFalse);
    expect(showWindowAtStart(minimized: true, trayShown: false), isTrue);
    expect(showWindowAtStart(minimized: false, trayShown: true), isTrue);
  });

  test('closing goes to the tray only with a tray and the setting on', () {
    expect(closeAction(trayShown: true, closeToTray: true), CloseAction.hideToTray);
    expect(closeAction(trayShown: true, closeToTray: false), CloseAction.quit);
    expect(closeAction(trayShown: false, closeToTray: true), CloseAction.quit);
  });

  test('the server never starts by itself on a public network', () {
    expect(launchStart(startServerOnLaunch: false, trust: NetworkTrust.trusted), LaunchStart.off);
    expect(launchStart(startServerOnLaunch: true, trust: NetworkTrust.trusted), LaunchStart.start);
    expect(launchStart(startServerOnLaunch: true, trust: NetworkTrust.unknown), LaunchStart.start);
    expect(launchStart(startServerOnLaunch: true, trust: NetworkTrust.untrusted), LaunchStart.heldBack);
  });

  test('the tray icon follows the server', () {
    expect(trayStatus(running: false, clients: 0, heldBack: false), TrayStatus.off);
    expect(trayStatus(running: false, clients: 0, heldBack: true), TrayStatus.attention);
    expect(trayStatus(running: true, clients: 0, heldBack: false), TrayStatus.on);
    expect(trayStatus(running: true, clients: 2, heldBack: true), TrayStatus.connected);
  });
}
