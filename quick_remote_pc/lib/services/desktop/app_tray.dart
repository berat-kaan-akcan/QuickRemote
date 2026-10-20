import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart' as tray;

import '../../theme/app_colors.dart';
import '../../widgets/brand/brand_mark.dart';
import 'desktop_policy.dart';

/// Whether a tray icon would be seen. Windows always has a notification
/// area. On Linux the icon is a StatusNotifierItem, shown only when a panel
/// runs a StatusNotifierWatcher (KDE, most desktops; GNOME only with the
/// AppIndicator extension).
Future<bool> systemTrayAvailable() async {
  if (Platform.isWindows) return true;
  if (!Platform.isLinux) return false;
  DBusClient? client;
  try {
    client = DBusClient.session();
    return await client
        .nameHasOwner('org.kde.StatusNotifierWatcher')
        .timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('systemTrayAvailable: $e');
    return false;
  } finally {
    await client?.close();
  }
}

/// The words in the tray, from the UI's [AppLocalizations].
@immutable
class TrayTexts {
  const TrayTexts({
    required this.tooltip,
    required this.show,
    required this.server,
    required this.phones,
    required this.update,
    required this.quit,
  });

  final String tooltip;
  final String show;

  /// Starts or stops the server ("Stop the server" while it runs).
  final String server;
  final String phones;

  /// "New version: X", null when there is none.
  final String? update;
  final String quit;
}

/// The tray icon (tray_manager): Show, start/stop the server, the phone
/// count, a newer version, Quit. Its picture is the logo with a dot for
/// [TrayStatus].
class AppTray {
  AppTray({
    required this.onShow,
    required this.onToggleServer,
    required this.onOpenUpdate,
    required this.onQuit,
  });

  final VoidCallback onShow;
  final VoidCallback onToggleServer;
  final VoidCallback onOpenUpdate;
  final VoidCallback onQuit;

  tray.TrayIcon? _icon;
  TrayStatus? _status;
  TrayTexts? _texts;
  // Kept: an item that is garbage-collected loses its click listener.
  final List<tray.MenuItem> _items = [];
  final Map<TrayStatus, String> _pictures = {};

  bool get shown => _icon != null;

  /// Puts the icon in the tray; false when there is no tray to put it in.
  Future<bool> create() async {
    if (_icon != null) return true;
    if (!await systemTrayAvailable()) return false;
    try {
      final icon = tray.TrayIcon.create();
      if (icon == null) return false;
      if (Platform.isWindows) {
        // A left click shows the window, a right click opens the menu. Linux
        // reports no clicks: its panel opens the menu.
        icon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
        icon.addListener((event) {
          if (event is tray.TrayIconClickedEvent ||
              event is tray.TrayIconDoubleClickedEvent) {
            onShow();
          }
        });
      }
      _icon = icon;
      return true;
    } catch (e) {
      debugPrint('AppTray: no tray icon: $e');
      return false;
    }
  }

  /// Shows [status] and [texts]; unchanged parts are not sent again.
  Future<void> update(TrayStatus status, TrayTexts texts) async {
    final icon = _icon;
    if (icon == null) return;
    try {
      if (status != _status) {
        _status = status;
        final picture = _pictures[status] ??= await renderTrayIcon(status);
        if (_icon != icon) return;
        icon.icon = tray.Image.fromBase64(picture);
        icon.setVisible(true);
      }
      final old = _texts;
      if (old == null ||
          old.tooltip != texts.tooltip ||
          (old.update == null) != (texts.update == null) ||
          old.show != texts.show ||
          old.quit != texts.quit) {
        icon.setTooltip(texts.tooltip);
        _buildMenu(icon, texts);
      } else {
        // Labels change in place; adding or removing an item needs a new menu.
        if (old.server != texts.server) _items[1].label = texts.server;
        if (old.phones != texts.phones) _items[2].label = texts.phones;
        if (old.update != texts.update) _items[3].label = texts.update;
      }
      _texts = texts;
    } catch (e) {
      debugPrint('AppTray: $e');
    }
  }

  void _buildMenu(tray.TrayIcon icon, TrayTexts texts) {
    final menu = tray.Menu.create();
    if (menu == null) return;
    tray.MenuItem item(String label, VoidCallback? onClick) {
      final item = tray.MenuItem.createWithLabelAndType(
        label,
        tray.MenuItemType.normal,
      )!;
      if (onClick == null) {
        item.isEnabled = false;
      } else {
        item.addListener((event) {
          if (event is tray.MenuItemClickedEvent) onClick();
        });
      }
      return item;
    }

    final items = [
      item(texts.show, onShow),
      item(texts.server, onToggleServer),
      item(texts.phones, null),
      if (texts.update case final update?) item(update, onOpenUpdate),
      item(texts.quit, onQuit),
    ];
    menu
      ..addItem(items[0])
      ..addSeparator()
      ..addItem(items[1])
      ..addItem(items[2]);
    if (texts.update != null) {
      menu
        ..addSeparator()
        ..addItem(items[3]);
    }
    menu
      ..addSeparator()
      ..addItem(items.last);
    icon.setContextMenu(menu);
    _items
      ..clear()
      ..addAll(items);
  }

  void dispose() {
    _icon?.dispose();
    _icon = null;
    _items.clear();
  }
}

/// The logo tile (always the dark one, as the launcher icon) with a status
/// dot in its lower left corner, as a base64 PNG data URI. The logo's laser
/// dot sits in the upper right.
Future<String> renderTrayIcon(TrayStatus status, {int size = 64}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final s = size.toDouble();
  BrandTilePainter(colors: BrandColors.dark).paint(canvas, ui.Size(s, s));
  final dot = switch (status) {
    TrayStatus.off => AppColors.paperTextMuted,
    TrayStatus.on => AppColors.success,
    TrayStatus.connected => AppColors.info,
    TrayStatus.attention => AppColors.warning,
  };
  final center = ui.Offset(s * 0.24, s * 0.76);
  canvas
    ..drawCircle(center, s * 0.22, ui.Paint()..color = AppColors.ink)
    ..drawCircle(center, s * 0.15, ui.Paint()..color = dot);
  final image = await recorder.endRecording().toImage(size, size);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return 'data:image/png;base64,${base64Encode(png!.buffer.asUint8List())}';
  } finally {
    image.dispose();
  }
}
