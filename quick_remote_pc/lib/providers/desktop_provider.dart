import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../app_version.dart';
import '../l10n/app_localizations.dart';
import '../services/desktop/app_tray.dart';
import '../services/desktop/autostart.dart';
import '../services/desktop/desktop_policy.dart';
import '../services/desktop/update_checker.dart';
import '../services/server/network_manager.dart';
import 'server_provider.dart';

/// The app on the desktop: the tray icon, what closing the window does,
/// starting at login and the server on launch, and the update check
/// (Settings → Startup and tray).
class DesktopProvider extends ChangeNotifier with WindowListener {
  DesktopProvider({
    required this.server,
    required this.navigatorKey,
    Autostart? autostart,
    UpdateChecker? updateChecker,
  }) : _autostart = autostart ?? Autostart.instance,
       _updateChecker = updateChecker ?? UpdateChecker();

  static const _closeToTrayKey = 'close_to_tray';
  static const _trayNoticeKey = 'tray_notice_shown';
  static const _startServerKey = 'start_server_on_launch';
  static const _checkUpdatesKey = 'check_updates';

  /// How often the update check runs while the app stays open.
  static const updateInterval = Duration(hours: 24);

  final WebSocketServerProvider server;

  /// Shows the tray notice over whatever screen is open.
  final GlobalKey<NavigatorState> navigatorKey;
  final Autostart? _autostart;
  final UpdateChecker _updateChecker;

  AppTray? _tray;
  Timer? _updateTimer;
  AppLocalizations? _l10n;
  bool _quitting = false;

  bool _closeToTray = true;
  bool _launchAtLogin = false;
  bool _startServerOnLaunch = false;
  bool _checkUpdates = true;
  bool _heldBack = false;
  ReleaseInfo? _update;

  /// A tray icon is shown (Windows; Linux with a StatusNotifierWatcher).
  bool get trayShown => _tray?.shown ?? false;
  bool get closeToTray => _closeToTray;

  /// Null where the platform has no autostart.
  bool? get launchAtLogin => _autostart == null ? null : _launchAtLogin;
  bool get startServerOnLaunch => _startServerOnLaunch;

  /// Null when the build has the check compiled out (UPDATE_CHECK=false).
  bool? get checkUpdates => updateCheckEnabled ? _checkUpdates : null;

  /// The server would have started by itself, but the network is public.
  bool get heldBack => _heldBack && !server.isRunning;

  /// A newer release on GitHub, if one was found.
  ReleaseInfo? get update => _update;

  /// The UI's words, for the tray; set from `MaterialApp.builder`.
  set l10n(AppLocalizations value) {
    if (identical(value, _l10n)) return;
    _l10n = value;
    // Not during the build that set it.
    scheduleMicrotask(_refreshTray);
  }

  /// Runs once after `runApp`: the tray, the window, the server, updates.
  Future<void> start({required bool minimized}) async {
    final prefs = await SharedPreferences.getInstance();
    _closeToTray = prefs.getBool(_closeToTrayKey) ?? true;
    _startServerOnLaunch = prefs.getBool(_startServerKey) ?? false;
    _checkUpdates = prefs.getBool(_checkUpdatesKey) ?? true;
    final autostart = _autostart;
    if (autostart != null) {
      _launchAtLogin = await autostart.isEnabled();
      if (_launchAtLogin) unawaited(autostart.refresh());
    }

    final tray = AppTray(
      onShow: showWindow,
      onToggleServer: _toggleServer,
      onOpenUpdate: openUpdate,
      onQuit: quit,
    );
    if (await tray.create()) {
      _tray = tray;
      await windowManager.setPreventClose(true);
    }
    windowManager.addListener(this);
    server.addListener(_onServerChanged);
    notifyListeners();
    await _refreshTray();

    if (showWindowAtStart(minimized: minimized, trayShown: trayShown) &&
        minimized) {
      // Started at login with no tray to come back from: the runner kept the
      // window hidden, so it is shown here.
      await showWindow();
    }

    unawaited(_startServerIfAsked());
    _scheduleUpdateCheck();
  }

  void _onServerChanged() {
    // Started by hand: the hold-back is over for this run.
    if (server.isRunning && _heldBack) {
      _heldBack = false;
      notifyListeners();
    }
    unawaited(_refreshTray());
  }

  Future<void> _startServerIfAsked() async {
    if (!_startServerOnLaunch) return;
    final trust = await NetworkManager.checkNetworkProfile();
    switch (launchStart(startServerOnLaunch: true, trust: trust)) {
      case LaunchStart.start:
        await server.startServer();
      case LaunchStart.heldBack:
        _heldBack = true;
        notifyListeners();
        await _refreshTray();
      case LaunchStart.off:
        break;
    }
  }

  Future<void> setCloseToTray(bool value) async {
    _closeToTray = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_closeToTrayKey, value);
  }

  /// False when the system refused the change.
  Future<bool> setLaunchAtLogin(bool value) async {
    final autostart = _autostart;
    if (autostart == null) return false;
    final ok = await autostart.setEnabled(value);
    _launchAtLogin = await autostart.isEnabled();
    notifyListeners();
    return ok;
  }

  Future<void> setStartServerOnLaunch(bool value) async {
    _startServerOnLaunch = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startServerKey, value);
  }

  Future<void> setCheckUpdates(bool value) async {
    _checkUpdates = value;
    if (!value) _update = null;
    notifyListeners();
    _scheduleUpdateCheck();
    await _refreshTray();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_checkUpdatesKey, value);
  }

  void _scheduleUpdateCheck() {
    _updateTimer?.cancel();
    _updateTimer = null;
    if (!updateCheckEnabled || !_checkUpdates) return;
    unawaited(_checkForUpdate());
    _updateTimer = Timer.periodic(updateInterval, (_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final release = await _updateChecker.check();
    if (!_checkUpdates || release == null) return;
    if (release.version == _update?.version) return;
    _update = release;
    notifyListeners();
    await _refreshTray();
  }

  /// Opens the newest release's page in the browser; nothing is downloaded.
  void openUpdate() {
    final update = _update;
    if (update != null) unawaited(openInBrowser(update.page));
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _toggleServer() async {
    if (server.isStarting) return;
    if (server.isRunning) {
      await server.stopServer();
      return;
    }
    _heldBack = false;
    await server.startServer();
    // The public-network warning and start errors are in the window.
    if (server.publicNetwork || server.startError != null) await showWindow();
  }

  /// Stops the server and ends the app (the tray's Quit).
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    _updateTimer?.cancel();
    server.removeListener(_onServerChanged);
    try {
      await server.stopServer();
    } catch (e) {
      debugPrint('DesktopProvider: stop on quit: $e');
    }
    _tray?.dispose();
    _tray = null;
    await AppLog.flush();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    if (_quitting) return;
    switch (closeAction(trayShown: trayShown, closeToTray: _closeToTray)) {
      case CloseAction.quit:
        await quit();
      case CloseAction.hideToTray:
        await _showTrayNoticeOnce();
        await windowManager.hide();
    }
  }

  /// The first time the window goes to the tray, says that the app runs on.
  Future<void> _showTrayNoticeOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_trayNoticeKey) ?? false) return;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    unawaited(prefs.setBool(_trayNoticeKey, true));
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.trayNoticeTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(l10n.trayNoticeBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.trayNoticeOk),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTray() async {
    final tray = _tray;
    final l10n = _l10n;
    if (tray == null || l10n == null) return;
    final status = trayStatus(
      running: server.isRunning,
      clients: server.clientCount,
      heldBack: heldBack,
    );
    final update = _update;
    await tray.update(
      status,
      TrayTexts(
        tooltip: switch (status) {
          TrayStatus.off => l10n.trayTooltipOff,
          TrayStatus.attention => l10n.trayTooltipHeldBack,
          TrayStatus.on || TrayStatus.connected => l10n.trayTooltipOn,
        },
        show: l10n.trayShow,
        server: server.isRunning ? l10n.trayStopServer : l10n.trayStartServer,
        phones: l10n.trayPhones(server.isRunning ? server.clientCount : 0),
        update: update == null
            ? null
            : l10n.updateAvailable(update.version.toString()),
        quit: l10n.trayQuit,
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    server.removeListener(_onServerChanged);
    windowManager.removeListener(this);
    _tray?.dispose();
    super.dispose();
  }
}
