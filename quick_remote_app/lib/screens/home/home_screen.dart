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
import '../../theme/app_colors.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 24, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white54,
                    ),
                    tooltip: context.l10n.homeSettingsTooltip,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              flex: 2,
              child: RepaintBoundary(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: HomeBranding(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    _ErrorBox(message: _error!),
                    const SizedBox(height: 16),
                  ],
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
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showManualConnect(context),
                    child: Text(
                      context.l10n.homeManualConnection,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
