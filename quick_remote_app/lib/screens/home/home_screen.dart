import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/discovery_service.dart';
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
    });
  }

  Future<void> _loadRecentDevices() async {
    final data = await _repository.getRecentDevices();
    if (!mounted) return;
    setState(() {
      _recentDevices = data;
    });
  }

  Future<void> _saveRecentDevice(String host, int port, String pin) async {
    String name = host;
    if (mounted) {
      try {
        final discovery = context.read<DiscoveryService>();
        final dev = discovery.devices.firstWhere((d) => d.ip == host);
        if (dev.name.isNotEmpty) name = dev.name;
      } catch (_) {
        // Fallback to host
      }
    }
    final data = await _repository.saveRecentDevice(host, port, pin, name);
    if (mounted) {
      setState(() {
        _recentDevices = data;
      });
    }
  }

  Future<void> _removeRecentDevice(int index) async {
    final data = await _repository.removeRecentDevice(index);
    if (mounted) {
      setState(() {
        _recentDevices = data;
      });
    }
  }

  Future<void> _scanAndConnect() async {
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

  Future<void> _executeConnection(
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

    if (!mounted) return;

    if (connResult.success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return;
      setState(() => _connecting = false);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RemoteScreen()));
    } else {
      if (!connResult.wasCancelled) {
        setState(() {
          _connecting = false;
          _error = connResult.errorMessage;
        });
      } else {
        setState(() {
          _connecting = false;
          _error = null;
        });
      }
    }
  }

  Future<void> _showManualConnect(
    BuildContext context, {
    String? defaultIp,
    String? defaultPort,
  }) async {
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
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: ContentWidth(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.sm + 4, 0),
                  sliver: SliverToBoxAdapter(
                    child: HomeTopBar(
                      onSettings: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.page,
                    AppSpace.lg,
                    AppSpace.page,
                    MediaQuery.paddingOf(context).bottom + AppSpace.xl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      FadeSlideIn(
                        child: AppCard(
                          elevated: true,
                          radius: AppRadius.xl,
                          tint: p.primary,
                          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const RepaintBoundary(child: HomeBranding()),
                              const SizedBox(height: AppSpace.xl),
                              ConnectButtons(
                                connecting: _connecting,
                                onScan: _scanAndConnect,
                                onBluetooth: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BluetoothConnectScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpace.xxs),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _showManualConnect(context),
                                  icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                                  label: Text(context.l10n.homeManualConnection),
                                  style: TextButton.styleFrom(foregroundColor: p.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Reveal(
                        child: _error == null
                            ? null
                            : Padding(
                                key: ValueKey(_error),
                                padding: const EdgeInsets.only(top: AppSpace.md),
                                child: InlineAlert(
                                  message: _error!,
                                  tone: AppTone.danger,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      FadeSlideIn(
                        index: 2,
                        child: DeviceLists(
                          recentDevices: _recentDevices,
                          onDiscoveredTap: (dev) => _showManualConnect(
                            context,
                            defaultIp: dev.ip,
                            defaultPort: dev.port.toString(),
                          ),
                          onRecentTap: (dev) =>
                              _executeConnection(dev['host'], dev['port'], dev['pin']),
                          onRecentRemove: _removeRecentDevice,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
