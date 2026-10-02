# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

QuickRemote is a presentation/PC remote built as three Dart projects (no workspace tooling; each is built separately):

- `quick_remote_app/`: Flutter mobile client, Android only (there is no `ios/` project).
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

The shared package and the Impress bridge have their own tests:

```bash
cd packages/quick_remote_shared && dart test
python3 -m unittest discover -s quick_remote_pc/test/python   # from the repo root; no LibreOffice needed
```

`WebSocketServer` tests (`quick_remote_pc/test/websocket_server_test.dart`) run the real server over plain `ws://` through `serveForTesting`, with `InputSimulator.instance` and the `MouseController` replaced by the fakes in `test/fakes.dart`.

`flutter analyze` crashes (LSP `FormatException`) because the repo path contains non-ASCII characters (`Masaüstü`). Use `dart analyze` instead, or run from an ASCII symlink to the repo.

The Impress bridge can be exercised on its own: `echo '{"id":1,"cmd":"state"}' | python3 quick_remote_pc/assets/linux/impress_bridge.py quickremote` (the argument is the UNO pipe name; a number selects a localhost TCP port, for manual tests only).

### Android build toolchain (`quick_remote_app/android`)

- Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0 match the Flutter 3.47 template. Flutter's `DependencyVersionChecker` fails the build below Gradle 8.14, AGP 8.11.1 or KGP 2.2.20, and warns below Gradle 9.1, AGP 9.0.1 or KGP 2.3.20. Upgrade these three together, in `gradle/wrapper/gradle-wrapper.properties` and `settings.gradle.kts`.
- Build with **JDK 21**, set via `flutter config --jdk-dir ~/.jdks/jdk-21.0.12.1+1`. Flutter's Java/Gradle table stops at Java 25, and the system default JDK 27 is not supported. Run `./gradlew` as `JAVA_HOME=~/.jdks/jdk-21.0.12.1+1 ./gradlew ...`.
- Never put `org.gradle.java.home` in the repo's `gradle.properties`, because it is machine-specific. It belongs in `~/.gradle/gradle.properties`.
- `compileSdk = 37` because `permission_handler_android` 14.x needs it. `targetSdk` still follows Flutter (36). The app's Kotlin target uses the `kotlin { compilerOptions { jvmTarget } }` DSL, not `kotlinOptions`.
- `android.builtInKotlin=false` and `android.newDsl=false` in `gradle.properties` must stay. Removing them breaks plugins that still apply KGP (`flutter_background`, `nsd_android`). Remove them only after those plugins migrate to built-in Kotlin, and drop `kotlin-android` from the app at the same time.
- `android.overridePathCheck=true` is required because the repo path contains non-ASCII characters.

## Architecture

### Wire protocol (mobile ↔ PC)

- The PC runs a TLS WebSocket server (`dart:io HttpServer`, self-signed cert generated on first run) and advertises `_quickremote._tcp` over mDNS (`nsd` on Windows, Avahi on Linux). The mobile app finds it via mDNS, a QR code, or manual IP entry.
- Auth: the client's first message is `{"auth": PIN}` (6-digit session PIN, plain inside TLS; the manual-entry dialog also accepts the 4 digits of older PCs). The server closes unauthenticated sockets after 5 s. `AuthManager` (`services/server/auth_manager.dart`) blocks an IP for 60 s after 5 failures and re-checks that on every attempt, allows at most 3 unauthenticated sockets per IP and 32 in total, and pauses all pairing for 60 s after more than 20 failures within a minute (the PIN is then replaced and the PC UI says so). Limits are counted per `AuthManager.clientKey`: IPv4-mapped addresses as plain IPv4, IPv6 per /64. Upgrade requests carrying an `Origin` header (browsers) are refused.
- The handshake is written by `PreAuthByteLimit.upgrade` (`services/server/pre_auth_byte_limit.dart`), not `WebSocketTransformer.upgrade`: permessage-deflate is never negotiated, frames are capped at 4 KB, and a client that sends more than 4 KB before authenticating is dropped (dart:io buffers a whole fragmented message with no total limit).
- Pairing QR: `quickremote://HOST:PORT:PIN[:FINGERPRINT]`, built and parsed by `PairingPayload` in the shared package. FINGERPRINT is the base64url SHA-256 of the certificate DER; the server reads its own certificate through a loopback TLS handshake. The client pins a QR fingerprint for that connection (a mismatch is a hard failure, no override). Without one (mDNS or manual entry, no stored pin) it aborts the TLS handshake before sending the PIN and asks the user to compare the security code (`PairingPayload.verificationCode`, the first 64 bits of the fingerprint, shown on the PC dashboard); a later certificate change asks again with the code. An approved fingerprint is pinned for that attempt and stored in SharedPreferences (`cert_fingerprint_<host>`) only after auth succeeds. The client's `HttpClient` has no trusted roots, so the pin is checked even for CA-signed certificates.
- **Text frames** are JSON commands. The server rejects anything not in `RemoteCommands.allowedCommands` or whose `PREFIX:` part is not in `allowedPrefixes` (`SET_PEN_COLOR`, `START_AT`, `VOLUME_SET`). **To add a command, update `remote_commands.dart` first**, then the PC dispatcher and `InputService`. Both apps use the `RemoteCommands` constants and builders (`startAt`, `penColor`, `volumeSet`), never string literals. Commands that only make sense in a running slideshow (drawing modes, ERASE_ALL, BLACK/WHITE_SCREEN) go in `_slideshowOnlyCommands` in `websocket_server.dart`, otherwise they type shortcuts into whatever window has focus. On Windows these shortcuts are also sent only while PowerPoint has the focus (`PptController.pressInSlideShow`), and START_AT jumps with COM `View.GotoSlide` instead of typing the number. When a client disconnects while holding LEFT_DOWN, the server sends LEFT_UP. After the first pairing the PC hides the QR code and PIN until the user shows them, and lists connected phones; removing one closes it with code 4005 (the app does not reconnect) and replaces the PIN.
- **Binary frames** (high-frequency mouse movement) are exactly 9 bytes: `uint8 type` (0 = TOUCH, 1 = LASER) + `float32 dx` + `float32 dy`, little-endian. The server coalesces them to ~125 Hz (summed, never dropped: `services/server/move_coalescer.dart`) and ignores LASER frames unless a slideshow is active. The client splits large deltas into steps of at most ±500, the server's per-frame limit. Encoder: `quick_remote_app/lib/services/websocket/websocket_client.dart`; decoder: `quick_remote_pc/lib/services/websocket_server.dart`.
- Server → client pushes: `STATUS`, `SLIDE_STATE`, `SMTC_STATE` (now-playing), volume state, `ack`, `auth`. These are produced by the polling loop in `services/server/state_broadcaster.dart`.

### PC server (`quick_remote_pc/lib`)

- `ServerProvider` (Provider/ChangeNotifier) owns `WebSocketServer`, which composes `AuthManager`, `NetworkManager` and `StateBroadcaster`. `NetworkManager` handles local IP, TLS cert, network profile and firewall; it is a static facade over `server/network/platform_network.dart` (`windows_network.dart` / `linux_network.dart`).
- Everything OS-specific goes through platform interfaces. Shared code must not call PowerShell or shell tools directly.
  - `services/input/input_service.dart` is the interface. `services/input_simulator.dart` is the static facade the rest of the code calls; it picks the implementation by `Platform`. `mouse_controller.dart` is abstracted the same way.
  - `services/input/command_router.dart` parses and validates every command (including `PREFIX:value`) and maps it to `InputService` methods, identically on both platforms. When adding a command, add an `InputService` method and implement it on **both** platforms.
- **Windows** (`services/input/windows/`): win32 FFI (`SendInput`), plus PowerPoint COM, SMTC and volume via PowerShell scripts run by `PowerShellRunner`. That runner keeps two persistent `powershell.exe` processes (started from the absolute System32 path; command and polling), queues jobs, and uses a `___PS_DONE___` sentinel line. In Dart `'''` strings, escape PowerShell `$` as `\$` but never escape a Dart `${...}` interpolation.
- **Linux** (`services/input/linux/`):
  - `uinput_device.dart`: a virtual keyboard/mouse through `/dev/uinput` (FFI `ioctl`). Works on X11 and Wayland. Windows VK codes are mapped in `evdev_keys.dart`.
  - `impress_bridge.dart`: drives a persistent `python3 assets/linux/impress_bridge.py` process (LibreOffice UNO over the pipe `quickremote`, a Unix socket only the user can open; the script refuses the socket if another user owns it) with JSON lines matched by `id`.
  - `pactl_volume.dart` for volume and `mpris_controller.dart` (D-Bus MPRIS) as the SMTC counterpart.
  - `server/network/avahi_publisher.dart` replaces `nsd` for mDNS, since `nsd` has no Linux implementation. mDNS goes through `PlatformNetwork.advertise`/`unadvertise` on both platforms.
  - `services/linux/linux_setup.dart` plus `linux_setup_panel.dart` implement the one-time setup: the udev rule via `pkexec`, the LibreOffice `ooSetupConnectionURL` profile entry, and firewalld/ufw ports. Profiles still holding the old `socket,host=localhost,port=2002` entry show as `ImpressStatus.legacyListener` with an update button.
- Impress bridge gotchas:
  - Every UNO call runs on LibreOffice's main thread through `com.sun.star.awt.AsyncCallback`. Calling slideshow APIs from the remote UNO thread deadlocks LibreOffice under the Qt/KDE VCL plugin.
  - The laser, eraser and pen modes use `XSlideShow.setProperty` (`PointerVisible`, `PointerPosition`, `SwitchEraserMode`, `SwitchPenMode`), not `XSlideShowController`.
  - Only the newest waiting `pointer` update is applied, and the running show is cached (looking it up walks every open component, ~20 ms). A queue of pointer updates used to delay the laser and the next mode switch (pen) by seconds.
  - `XPresentation.start()` begins at the slide selected in the editor. START passes `FirstPage` (a custom show uses `start()`), as LibreOffice's F5 does.
  - `XSlideShow.startShapeActivity` is not implemented in LibreOffice. For media control the bridge adds animation triggers to media shapes (click: TOGGLEPAUSE, double click: PLAY then pause), marked with the `quickremote-media` UserData and removed when the show ends, and clicks the shape through `XToolkitRobot` in the `FullScreenPresentation` frame. The slideshow reads a slide's animations when it loads or prefetches the slide, so triggers go to the next few slides ahead of the show; a slide loaded without them is shown again on the first media command (`MEDIA_RELOADED`).
  - Presentation commands fall back to key presses when no Impress slideshow is reachable.
- The Linux server still reports "not running" as `STATUS: POWERPOINT_NOT_RUNNING` for protocol compatibility. The `auth` ok reply carries `presenter` (`powerpoint`/`impress`), which the mobile app uses for its texts.

### Mobile client (`quick_remote_app/lib`)

- State uses Provider: `WebSocketService`, `SettingsProvider` and `DiscoveryService` are registered in `main.dart`. `WebSocketService` is a facade over `websocket/websocket_client.dart` (transport, TLS and pinning), `presentation_state.dart` (slide/media state) and `analytics_tracker.dart` (per-slide timing for analytics reports).
- There are two independent control modes:
  - **Wi-Fi mode**: `screens/remote/` talks to the PC server.
  - **Bluetooth HID mode**: `screens/bt_remote/` makes the phone act as a Bluetooth keyboard and mouse, so no PC app is needed. `services/bluetooth/bt_hid_service.dart` bridges over the `com.quickremote.quick_remote_app/bt_hid` MethodChannel and the `bt_hid_events` EventChannel to the native `android/.../BluetoothHidService.kt` (`BluetoothHidDevice` API). `bt_key_mapping.dart` maps commands to HID key/consumer reports per `BtTarget` (user-selected PowerPoint or Impress, stored in `SettingsProvider`). Impress's slideshow has no keyboard shortcut for laser, highlighter or eraser, so those are no-ops. A left click without the pen advances the Impress slide, so the BT toolbar hides highlighter and eraser for that target.
- Hardware volume keys are captured natively in `MainActivity.kt` and exposed through the `.../volume_keys` MethodChannel (`screens/remote/utils/hardware_key_handler.dart`).
- `flutter_background` keeps the connection alive when the app is in the background or the phone is locked, but only while a remote screen (Wi-Fi or Bluetooth) is open: `services/background_session.dart` enables it on open and disables it on close. The plugin does not declare its `IsolateHolderService`, so the app manifest does, with `foregroundServiceType="connectedDevice"` and `FOREGROUND_SERVICE_CONNECTED_DEVICE` (required on Android 14+; its runtime prerequisite is covered by `CHANGE_WIFI_MULTICAST_STATE`).
