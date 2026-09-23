import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/discovery_service.dart';
import '../../repositories/device_history_repository.dart';
import 'scan_screen.dart';
import 'remote_screen.dart';
import 'bluetooth_connect_screen.dart';
import 'settings/settings_screen.dart';
import 'home/utils/connection_handler.dart';
import 'home/widgets/manual_connect_dialog.dart';
import 'home/widgets/spinning_refresh_icon.dart';

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
        name = dev.name;
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

    await _executeConnection(host, port, pin);
  }

  Future<void> _executeConnection(String host, int port, String pin) async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    final connResult = await ConnectionHandler.connect(context, host, port, pin: pin);
    
    if (!mounted) return;

    if (connResult.success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return;
      setState(() => _connecting = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RemoteScreen()),
      );
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

  Future<void> _showManualConnect(BuildContext context, {String? defaultIp, String? defaultPort}) async {
    final result = await ManualConnectDialog.show(
      context, 
      defaultIp: defaultIp, 
      defaultPort: defaultPort
    );
    
    if (result != null && mounted) {
      _executeConnection(result.host, result.port, result.pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Row
            ColoredBox(
              color: scaffoldBg,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white54),
                      tooltip: 'Ayarlar',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Branding section
            Expanded(
              flex: 2,
              child: RepaintBoundary(
                child: ColoredBox(
                  color: scaffoldBg,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF005B96).withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png', 
                                width: 88, 
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'QuickRemote',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sunumlarınızı telefondan kontrol edin',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons section
            ColoredBox(
              color: scaffoldBg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error message
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Connect button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2979FF), Color(0xFF00BCD4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2979FF).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _connecting ? null : _scanAndConnect,
                        icon: _connecting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                        label: Text(
                          _connecting ? 'Bağlanıyor...' : 'QR Kod ile Bağlan',
                          style: const TextStyle(
                            fontSize: 17, 
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF64B5F6), width: 2),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _connecting ? null : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BluetoothConnectScreen()),
                            );
                          },
                          icon: const Icon(Icons.bluetooth_rounded, color: Color(0xFF64B5F6), size: 24),
                          label: const Text(
                            'Bluetooth ile Bağlan',
                            style: TextStyle(
                              fontSize: 17, 
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64B5F6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Manual connect hint
                    TextButton(
                      onPressed: () => _showManualConnect(context),
                      child: Text(
                        'Manuel bağlantı',
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
            ),

            // Device lists section
            Expanded(
              flex: 3,
              child: RepaintBoundary(
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Consumer<DiscoveryService>(
                      builder: (context, discovery, child) {
                        return Column(
                          children: [
                            // Discovered devices header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ağdaki Cihazlar',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                InkWell(
                                  onTap: discovery.isDiscovering ? null : () => discovery.startScanning(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SpinningRefreshIcon(isSpinning: discovery.isDiscovering),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Scrollable device list
                            Expanded(
                              child: ListView(
                                clipBehavior: Clip.hardEdge,
                                padding: EdgeInsets.zero,
                                children: [
                                  // Discovered device items
                                  if (discovery.devices.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text('Cihaz aranıyor...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                                    )
                                  else
                                    ...discovery.devices.map((dev) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        onTap: () => _showManualConnect(context, defaultIp: dev.ip, defaultPort: dev.port.toString()),
                                        tileColor: const Color(0xFF005B96).withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        leading: const Icon(Icons.computer_rounded, color: Color(0xFF005B96)),
                                        title: Text(dev.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                        subtitle: Text('${dev.ip}:${dev.port}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                                      ),
                                    )),

                                  const SizedBox(height: 8),

                                  // Recent devices
                                  if (_recentDevices.isNotEmpty) ...[
                                    const Text(
                                      'Son Bağlanılanlar',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._recentDevices.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final dev = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          onTap: () => _executeConnection(dev['host'], dev['port'], dev['pin']),
                                          tileColor: Colors.white.withValues(alpha: 0.05),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          leading: const Icon(Icons.history_rounded, color: Colors.white54),
                                          title: Text(dev['name'] ?? dev['host'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                          subtitle: Text('${dev['host']}:${dev['port']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                                            tooltip: 'Geçmişten Sil',
                                            onPressed: () => _removeRecentDevice(index),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
