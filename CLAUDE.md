# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

QuickRemote is a presentation/PC remote built as three Dart projects (no workspace tooling; each is built separately):

- `quick_remote_app/`: Flutter mobile client (Android primary; iOS has no Bluetooth HID).
- `quick_remote_pc/`: Flutter desktop server for Windows (controls PowerPoint) and Linux (controls LibreOffice Impress).
- `packages/quick_remote_shared/`: pure-Dart package with `RemoteCommands` (command strings, allowlists), referenced by both apps via a `path:` dependency.

`landing-page/` is a static HTML/CSS site. README and many code comments are in Turkish.

## Commands

Run inside `quick_remote_app/` or `quick_remote_pc/` (Flutter SDK, Dart `^3.11`):

```bash
flutter pub get
flutter analyze                  # lints: flutter_lints
flutter test
flutter test test/settings_provider_test.dart   # single file (app); PC: test/linux_support_test.dart
flutter test --plain-name "<test name>"          # single test
flutter run -d windows           # PC server (or -d linux)
flutter run                      # mobile client
```

`quick_remote_pc/test.dart` and `test_str.dart` are ad-hoc PowerShell scratch scripts, not a test suite.

`flutter analyze` crashes (LSP `FormatException`) because the repo path contains non-ASCII characters (`Masaüstü`). Use `dart analyze` instead, or run from an ASCII symlink to the repo.

The Impress bridge can be exercised on its own: `echo '{"id":1,"cmd":"state"}' | python3 quick_remote_pc/assets/linux/impress_bridge.py 2002`.

## Architecture

### Wire protocol (mobile ↔ PC)

- The PC runs a TLS WebSocket server (`dart:io HttpServer`, self-signed cert generated on first run) and advertises `_quickremote._tcp` over mDNS (`nsd` on Windows, Avahi on Linux). The mobile app finds it via mDNS, a QR code, or manual IP entry.
- Auth: the server sends `AUTH_REQUIRED`, the client replies with SHA-256 of the 4-digit session PIN. The server enforces a 10 s auth timeout and blocks an IP for 60 s after 5 failures (`services/server/auth_manager.dart`). The client pins the cert fingerprint in SharedPreferences (`cert_fingerprint_<host>`) and asks the user if it changes.
- **Text frames** are JSON commands. The server rejects anything not in `RemoteCommands.allowedCommands` or whose `PREFIX:` part is not in `allowedPrefixes` (`SET_PEN_COLOR`, `START_AT`, `VOLUME_SET`). **To add a command, update `remote_commands.dart` first**, then the PC dispatcher and `InputService`.
- **Binary frames** (high-frequency mouse movement) are exactly 9 bytes: `uint8 type` (0 = TOUCH, 1 = LASER) + `float32 dx` + `float32 dy`, little-endian. The server throttles them to ~125 Hz and drops LASER frames unless a slideshow is active. Encoder: `quick_remote_app/lib/services/websocket/websocket_client.dart`; decoder: `quick_remote_pc/lib/services/websocket_server.dart`.
- Server → client pushes: `STATUS`, `SLIDE_STATE`, `SMTC_STATE` (now-playing), volume state, `ack`, `auth`. These are produced by the polling loop in `services/server/state_broadcaster.dart`.

### PC server (`quick_remote_pc/lib`)

- `ServerProvider` (Provider/ChangeNotifier) owns `WebSocketServer`, which composes `AuthManager`, `NetworkManager` and `StateBroadcaster`. `NetworkManager` handles local IP, TLS cert, network profile and firewall; it is a static facade over `server/network/platform_network.dart` (`windows_network.dart` / `linux_network.dart`).
- Everything OS-specific goes through platform interfaces. Shared code must not call PowerShell or shell tools directly.
  - `services/input/input_service.dart` is the interface. `services/input_simulator.dart` is the static facade the rest of the code calls; it picks the implementation by `Platform`. `mouse_controller.dart` is abstracted the same way.
  - `services/input/command_router.dart` parses and validates every command (including `PREFIX:value`) and maps it to `InputService` methods, identically on both platforms. When adding a command, add an `InputService` method and implement it on **both** platforms.
- **Windows** (`services/input/windows/`): win32 FFI (`SendInput`), plus PowerPoint COM, SMTC and volume via PowerShell scripts run by `PowerShellRunner`. That runner keeps two persistent `powershell` processes (command and polling), queues jobs, and uses a `___PS_DONE___` sentinel line. In Dart `'''` strings, escape PowerShell `$` as `\$` but never escape a Dart `${...}` interpolation.
- **Linux** (`services/input/linux/`):
  - `uinput_device.dart`: a virtual keyboard/mouse through `/dev/uinput` (FFI `ioctl`). Works on X11 and Wayland. Windows VK codes are mapped in `evdev_keys.dart`.
  - `impress_bridge.dart`: drives a persistent `python3 assets/linux/impress_bridge.py` process (LibreOffice UNO over `localhost:2002`) with JSON lines matched by `id`.
  - `pactl_volume.dart` for volume and `mpris_controller.dart` (D-Bus MPRIS) as the SMTC counterpart.
  - `server/network/avahi_publisher.dart` replaces `nsd` for mDNS, since `nsd` has no Linux implementation.
  - `services/linux/linux_setup.dart` plus `linux_setup_panel.dart` implement the one-time setup: the udev rule via `pkexec`, the LibreOffice `ooSetupConnectionURL` profile entry, and firewalld/ufw ports.
- Impress bridge gotchas:
  - Every UNO call runs on LibreOffice's main thread through `com.sun.star.awt.AsyncCallback`. Calling slideshow APIs from the remote UNO thread deadlocks LibreOffice under the Qt/KDE VCL plugin.
  - The laser, eraser and pen modes use `XSlideShow.setProperty` (`PointerVisible`, `PointerPosition`, `SwitchEraserMode`, `SwitchPenMode`), not `XSlideShowController`.
  - Presentation commands fall back to key presses when no Impress slideshow is reachable.
- The Linux server still reports "not running" as `STATUS: POWERPOINT_NOT_RUNNING` for protocol compatibility. The `auth` ok reply carries `presenter` (`powerpoint`/`impress`), which the mobile app uses for its texts.

### Mobile client (`quick_remote_app/lib`)

- State uses Provider: `WebSocketService`, `SettingsProvider` and `DiscoveryService` are registered in `main.dart`. `WebSocketService` is a facade over `websocket/websocket_client.dart` (transport, TLS and pinning), `presentation_state.dart` (slide/media state) and `analytics_tracker.dart` (per-slide timing for analytics reports).
- There are two independent control modes:
  - **Wi-Fi mode**: `screens/remote/` talks to the PC server.
  - **Bluetooth HID mode**: `screens/bt_remote/` makes the phone act as a Bluetooth keyboard and mouse, so no PC app is needed. `services/bluetooth/bt_hid_service.dart` bridges over the `com.quickremote.quick_remote_app/bt_hid` MethodChannel and the `bt_hid_events` EventChannel to the native `android/.../BluetoothHidService.kt` (`BluetoothHidDevice` API). `bt_key_mapping.dart` maps commands to HID key/consumer reports per `BtTarget` (user-selected PowerPoint or Impress, stored in `SettingsProvider`). Impress's slideshow has no keyboard shortcut for laser, highlighter or eraser, so those are no-ops. A left click without the pen advances the Impress slide, so the BT toolbar hides highlighter and eraser for that target.
- Hardware volume keys are captured natively in `MainActivity.kt` and exposed through the `.../volume_keys` MethodChannel (`screens/remote/utils/hardware_key_handler.dart`).
- `flutter_background` keeps the connection alive when the app is in the background or the phone is locked.
