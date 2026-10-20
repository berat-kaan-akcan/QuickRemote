import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/discovery_service.dart';
import '../../services/launch_actions.dart';
import '../../services/websocket_service.dart';
import '../../repositories/device_history_repository.dart';
import '../scan/scan_screen.dart';
import '../remote/remote_screen.dart';
import '../bt_connect/bluetooth_connect_screen.dart';
import '../settings/settings_screen.dart';
import 'utils/connection_handler.dart';
import 'widgets/manual_connect_dialog.dart';
import 'widgets/connect_buttons.dart';
import 'widgets/device_lists.dart';
import 'widgets/home_branding.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

/// Home screen - connection hub to scan QR and connect to PC.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _connecting = false;
  String? _error;
  List<Map<String, dynamic>> _recentDevices = [];
  final DeviceHistoryRepository _repository = DeviceHistoryRepository();

  @override
  void initState() {
    super.initState();
    _loadRecentDevices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryService>().startScanning();
      LaunchActions.instance.watchConnection(context.read<WebSocketService>());
      LaunchActions.instance.listen(_onLaunchAction);
    });
  }

  @override
  void dispose() {
    LaunchActions.instance.listen(null);
    super.dispose();
  }

  Future<void> _loadRecentDevices() async {
    final data = await _repository.getRecentDevices();
    if (!mounted) return;
    _setRecentDevices(data);
  }

  /// The first recent PC is the one the app shortcut and the tile connect to.
  void _setRecentDevices(List<Map<String, dynamic>> data) {
    setState(() => _recentDevices = data);
    LaunchActions.instance.setLastPc(
      PcAddress.fromRecent(data.firstOrNull)?.name,
    );
  }

  Future<void> _saveRecentDevice(
    String host,
    int port,
    String pin, {
    String? name,
  }) async {
    name ??= _nameOf(host);
    final data = await _repository.saveRecentDevice(host, port, pin, name);
    if (mounted) _setRecentDevices(data);
  }

  /// The PC's mDNS name, else the host name it gave on connecting, else its
  /// address: "connect to the last PC" looks for it under this name when its
  /// address changes.
  String _nameOf(String host) {
    final found = context
        .read<DiscoveryService>()
        .devices
        .where((d) => d.ip == host && d.name.isNotEmpty)
        .firstOrNull;
    return found?.name ?? context.read<WebSocketService>().pcName ?? host;
  }

  Future<void> _removeRecentDevice(int index) async {
    final data = await _repository.removeRecentDevice(index);
    if (mounted) _setRecentDevices(data);
  }

  /// A link from an app shortcut or the Quick Settings tile.
  void _onLaunchAction(LaunchAction action) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    switch (action) {
      case LaunchAction.connectLast:
        // Already connected: the app is back in front, on its remote.
        if (context.read<WebSocketService>().isConnected || _connecting) return;
        navigator.popUntil((route) => route.isFirst);
        _connectLast();
      case LaunchAction.bluetooth:
        navigator.popUntil((route) => route.isFirst);
        navigator.push(
          MaterialPageRoute(builder: (_) => const BluetoothConnectScreen()),
        );
      case LaunchAction.scan:
        navigator.popUntil((route) => route.isFirst);
        _scanAndConnect();
    }
  }

  /// quickremote://connect/last (LastPcConnect): the last PC with its saved
  /// PIN, looked up by name over mDNS when its address changed.
  Future<void> _connectLast() async {
    _clearError();
    setState(() => _connecting = true);
    final discovery = context.read<DiscoveryService>();
    String? failure;
    final outcome = await LastPcConnect.run(
      recent: await _repository.getRecentDevices(),
      found: () => discovery.devices,
      fingerprintOf: LastPcConnect.pinnedFingerprint,
      connect: (pc, fingerprint) async {
        if (!mounted) return ConnectionError.none;
        final result = await ConnectionHandler.connect(
          context,
          pc.host,
          pc.port,
          pin: pc.pin,
          certFingerprint: fingerprint,
        );
        if (result.success) return null;
        failure = result.errorMessage;
        if (result.wasCancelled || !mounted) return ConnectionError.none;
        return result.error ?? ConnectionError.unknown;
      },
    );
    if (!mounted) return;
    final l10n = context.l10n;
    switch (outcome) {
      case LastPcConnected(:final pc, :final movedFrom):
        if (movedFrom != null) {
          await _repository.removeDevice(movedFrom.host, movedFrom.port);
        }
        await _saveRecentDevice(pc.host, pc.port, pc.pin, name: pc.name);
        if (!mounted) return;
        setState(() => _connecting = false);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RemoteScreen()));
      case LastPcMissing():
        setState(() {
          _connecting = false;
          _error = l10n.launchNoRecentPc;
        });
      case LastPcNotFound(:final pc):
        setState(() {
          _connecting = false;
          _error = l10n.launchPcNotFound(pc.name);
        });
      case LastPcFailed(:final pc, :final error):
        setState(() {
          _connecting = false;
          _error = error == ConnectionError.none ? null : failure;
        });
        // The PC has a new PIN since: ask for it, as a tap on it would.
        if (error == ConnectionError.wrongPin) {
          _clearError();
          await _showManualConnect(
            context,
            defaultIp: pc.host,
            defaultPort: pc.port.toString(),
          );
        }
    }
  }

  /// A failed attempt's alert stays until the next one starts: the user
  /// read an old "wrong PIN" as the answer to a QR scan that then connected.
  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _scanAndConnect() async {
    _clearError();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (result == null || !mounted) return;

    final host = result['host'] as String;
    final port = result['port'] as int;
    final pin = result['pin'] as String? ?? '';
    final fingerprint = result['fingerprint'] as String?;

    await _executeConnection(host, port, pin, certFingerprint: fingerprint);
  }

  /// A PC found on the network that is also a recent connection is opened
  /// with the PIN that worked last time; the PIN dialog comes only when the
  /// PC has a new one since.
  Future<void> _connectDiscovered(DiscoveredDevice dev) async {
    _clearError();
    final recent = _recentDevices
        .where((d) => d['host'] == dev.ip && d['port'] == dev.port)
        .firstOrNull;
    final pin = recent?['pin'] as String? ?? '';
    if (pin.isEmpty) {
      await _showManualConnect(
        context,
        defaultIp: dev.ip,
        defaultPort: dev.port.toString(),
      );
      return;
    }
    final error = await _executeConnection(dev.ip, dev.port, pin);
    if (!mounted) return;
    if (error == ConnectionError.wrongPin) {
      _clearError();
      await _showManualConnect(
        context,
        defaultIp: dev.ip,
        defaultPort: dev.port.toString(),
      );
    }
  }

  /// Returns the error of a failed attempt, null otherwise.
  Future<ConnectionError?> _executeConnection(
    String host,
    int port,
    String pin, {
    String? certFingerprint,
  }) async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    final connResult = await ConnectionHandler.connect(
      context,
      host,
      port,
      pin: pin,
      certFingerprint: certFingerprint,
    );

    if (!mounted) return null;

    if (connResult.success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return null;
      setState(() => _connecting = false);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RemoteScreen()));
      return null;
    }
    setState(() {
      _connecting = false;
      _error = connResult.wasCancelled ? null : connResult.errorMessage;
    });
    return connResult.error;
  }

  Future<void> _showManualConnect(
    BuildContext context, {
    String? defaultIp,
    String? defaultPort,
  }) async {
    _clearError();
    String? resolvedPort = defaultPort;
    if (resolvedPort == null && _recentDevices.isNotEmpty) {
      resolvedPort = _recentDevices.first['port']?.toString();
    }

    final result = await ManualConnectDialog.show(
      context,
      defaultIp: defaultIp,
      defaultPort: resolvedPort,
    );

    if (result != null && mounted) {
      _executeConnection(result.host, result.port, result.pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Stack(
        children: [
          // A pool of light behind the top right corner.
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.primaryBright.withValues(alpha: p.isDark ? 0.32 : 0.16),
                      p.primaryBright.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.65],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ContentWidth(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.page,
                        AppSpace.xs,
                        AppSpace.page,
                        MediaQuery.paddingOf(context).bottom + AppSpace.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeTopBar(
                            onSettings: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpace.md),
                          const FadeSlideIn(child: RepaintBoundary(child: HomeBranding())),
                          const SizedBox(height: AppSpace.sm),
                          FadeSlideIn(
                            index: 1,
                            child: ConnectButtons(
                              connecting: _connecting,
                              onScan: _scanAndConnect,
                              onBluetooth: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const BluetoothConnectScreen()),
                                );
                              },
                            ),
                          ),
                          Reveal(
                            child: _error == null
                                ? null
                                : Padding(
                                    key: ValueKey(_error),
                                    padding: const EdgeInsets.only(top: AppSpace.sm),
                                    child: InlineAlert(message: _error!, tone: AppTone.danger),
                                  ),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          FadeSlideIn(
                            index: 2,
                            child: DeviceLists(
                              recentDevices: _recentDevices,
                              onDiscoveredTap: _connectDiscovered,
                              onRecentTap: (dev) => _executeConnection(dev['host'], dev['port'], dev['pin']),
                              onRecentRemove: _removeRecentDevice,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: AppSpace.md),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _showManualConnect(context),
                              icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                              label: Text(context.l10n.homeManualConnection),
                              style: TextButton.styleFrom(
                                foregroundColor: p.primaryText,
                                textStyle: AppType.label.copyWith(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
