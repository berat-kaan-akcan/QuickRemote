import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../services/discovery_service.dart';
import 'scan_screen.dart';
import 'remote_screen.dart';
import 'settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRecentDevices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryService>().startScanning();
    });
  }

  @override
  void dispose() {
    // stopScanning can be called safely without context if we hold a ref, but it's simpler to just let the service handle it or call it here.
    // Actually, provider might already be disposed if we pop, but home_screen doesn't pop.
    // Since home_screen is always alive, it's fine.
    // context.read<DiscoveryService>().stopScanning(); 
    super.dispose();
  }

  Future<void> _removeRecentDevice(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentDevices.removeAt(index);
    });
    final strList = _recentDevices.map((d) => jsonEncode(d)).toList();
    await prefs.setStringList('recent_devices', strList);
  }

  Future<void> _loadRecentDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('recent_devices') ?? [];
    setState(() {
      _recentDevices = data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveRecentDevice(String host, int port, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final device = {'host': host, 'port': port, 'pin': pin};
    
    _recentDevices.removeWhere((d) => d['host'] == host && d['port'] == port);
    _recentDevices.insert(0, device);
    if (_recentDevices.length > 5) _recentDevices.removeLast();
    
    await prefs.setStringList('recent_devices', _recentDevices.map((e) => jsonEncode(e)).toList());
    if (mounted) setState(() {});
  }

  Future<void> _scanAndConnect() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );

    if (result == null || !mounted) return;

    final host = result['host'] as String;
    final port = result['port'] as int;
    final pin = result['pin'] as String? ?? '';

    setState(() {
      _connecting = true;
      _error = null;
    });

    final ws = context.read<WebSocketService>();
    final success = await ws.connect(host, port, pin: pin);

    if (!mounted) return;

    if (success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return;
      setState(() => _connecting = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RemoteScreen()),
      );
    } else {
      setState(() {
        _connecting = false;
        _error = 'Bağlantı kurulamadı.\n$host:$port adresini kontrol edin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white54),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),

              // Logo & Title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 48,
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

              const Spacer(flex: 1),

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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _connecting ? null : _scanAndConnect,
                  icon: _connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    _connecting ? 'Bağlanıyor...' : 'QR Kod ile Bağlan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

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

              const SizedBox(height: 16),

              // Discovered Devices
              Consumer<DiscoveryService>(
                builder: (context, discovery, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          if (discovery.isDiscovering)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (discovery.devices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Cihaz aranıyor...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: discovery.devices.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final dev = discovery.devices[index];
                            return ListTile(
                              onTap: () => _showManualConnect(context, defaultIp: dev.ip, defaultPort: dev.port.toString()),
                              tileColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              leading: const Icon(Icons.computer_rounded, color: Color(0xFF6C63FF)),
                              title: Text(dev.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              subtitle: Text('${dev.ip}:${dev.port}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Recent Devices
              if (_recentDevices.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Son Bağlanılanlar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 2,
                  child: ListView.separated(
                    itemCount: _recentDevices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dev = _recentDevices[index];
                      return ListTile(
                        onTap: () => _connectManually(dev['host'], dev['port'], pin: dev['pin']),
                        tileColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.history_rounded, color: Colors.white54),
                        title: Text(dev['host'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Port: ${dev['port']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                          onPressed: () => _removeRecentDevice(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showManualConnect(BuildContext context, {String? defaultIp, String? defaultPort}) {
    final hostController = TextEditingController(text: defaultIp);
    final portController = TextEditingController(text: defaultPort ?? '8090');
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manuel Bağlantı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hostController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'IP Adresi',
                hintText: '192.168.1.x',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Port',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
              TextField(
              controller: pinController,
              onChanged: (_) => HapticFeedback.lightImpact(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: 'PC ekranındaki 4 haneli PIN',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final host = hostController.text.trim();
                  final port = int.tryParse(portController.text.trim()) ?? 0;
                  final pin = pinController.text.trim();

                  if (host.isEmpty) return;

                  // IP validation (regex + octet range)
                  final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                  if (!ipRegex.hasMatch(host)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçersiz IP adresi')),
                    );
                    return;
                  }
                  final octetsValid = host.split('.').every((p) {
                    final n = int.tryParse(p);
                    return n != null && n >= 0 && n <= 255;
                  });
                  if (!octetsValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçersiz IP adresi')),
                    );
                    return;
                  }

                  // Port range validation
                  if (port < 1 || port > 65535) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Port 1-65535 arası olmalı')),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  _connectManually(host, port, pin: pin);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Bağlan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectManually(String host, int port, {String pin = ''}) async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    final ws = context.read<WebSocketService>();
    final success = await ws.connect(host, port, pin: pin);

    if (!mounted) return;

    if (success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return;
      setState(() => _connecting = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RemoteScreen()),
      );
    } else {
      setState(() {
        _connecting = false;
        _error = 'Bağlantı kurulamadı.\n$host:$port adresini kontrol edin.';
      });
    }
  }
}
