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
    var connResult = await ws.connect(host, port, pin: pin);

    if (!mounted) return;

    if (!connResult.success && connResult.error == ConnectionError.certMismatch) {
      final accepted = await _showCertMismatchDialog();
      if (!mounted) return;
      if (accepted && connResult.newFingerprint != null) {
        connResult = await ws.acceptCertificateAndReconnect(
          host,
          connResult.newFingerprint!,
          port: port,
          pin: pin,
        );
        if (!mounted) return;
      } else {
        setState(() {
          _connecting = false;
          _error = null;
        });
        return;
      }
    }

    if (connResult.success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return;
      setState(() => _connecting = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RemoteScreen()),
      );
    } else {
      setState(() {
        _connecting = false;
        _error = connResult.message ?? 'Bağlantı kurulamadı.\n$host:$port adresini kontrol edin.';
      });
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
            // Header Row — opaque background prevents any bleed-through
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

            // Branding section — opaque background + RepaintBoundary isolates
            // the BoxShadow's saveLayer from the scroll layer entirely.
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
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF005B96), Color(0xFF00BCD4)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF005B96).withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.electric_bolt_rounded,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons section — opaque background blocks any
            // scroll content from showing through this area.
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
                          backgroundColor: const Color(0xFF005B96),
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

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Device lists section — ClipRect hard-clips scroll content at
            // the viewport boundary so nothing can paint outside this area.
            // RepaintBoundary isolates scroll repaints from upper layers.
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
                            // Discovered devices header — pinned, does not scroll
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
                                    child: _SpinningRefreshIcon(isSpinning: discovery.isDiscovering),
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
                                          onTap: () => _connectManually(dev['host'], dev['port'], pin: dev['pin']),
                                          tileColor: Colors.white.withValues(alpha: 0.05),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          leading: const Icon(Icons.history_rounded, color: Colors.white54),
                                          title: Text(dev['host'], style: const TextStyle(color: Colors.white)),
                                          subtitle: Text('Port: ${dev['port']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

  void _showManualConnect(BuildContext context, {String? defaultIp, String? defaultPort}) {
    final hostController = TextEditingController(text: defaultIp);
    final portController = TextEditingController(text: defaultPort ?? '8090');
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  final ipRegex = RegExp(r'^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}|localhost|([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}|\[[a-fA-F0-9:]+\]|[a-zA-Z0-9-]+)$');
                  if (!ipRegex.hasMatch(host)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçersiz Hostname veya IP adresi')),
                    );
                    return;
                  }
                  final octetsValid = host.split('.').every((p) {
                    final n = int.tryParse(p);
                    return n != null && n >= 0 && n <= 255;
                  });
                  if (!octetsValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçersiz Hostname veya IP adresi')),
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
                  backgroundColor: const Color(0xFF005B96),
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
    var connResult = await ws.connect(host, port, pin: pin);

    if (!mounted) return;

    if (!connResult.success && connResult.error == ConnectionError.certMismatch) {
      final accepted = await _showCertMismatchDialog();
      if (!mounted) return;
      if (accepted && connResult.newFingerprint != null) {
        connResult = await ws.acceptCertificateAndReconnect(
          host,
          connResult.newFingerprint!,
          port: port,
          pin: pin,
        );
        if (!mounted) return;
      } else {
        setState(() {
          _connecting = false;
          _error = null;
        });
        return;
      }
    }

    if (connResult.success) {
      await _saveRecentDevice(host, port, pin);
      if (!mounted) return;
      setState(() => _connecting = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RemoteScreen()),
      );
    } else {
      setState(() {
        _connecting = false;
        _error = connResult.message ?? 'Bağlantı kurulamadı.\n$host:$port adresini kontrol edin.';
      });
    }
  }

  Future<bool> _showCertMismatchDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.shield_rounded, color: Color(0xFFFF9800), size: 48),
        title: const Text(
          'Güvenlik Uyarısı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı.\n\n'
          'PC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir.\n\n'
          'Emin değilseniz bağlanmayın.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'İptal Et',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Yine de Bağlan ve Güncelle',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _SpinningRefreshIcon extends StatefulWidget {
  final bool isSpinning;
  const _SpinningRefreshIcon({required this.isSpinning});

  @override
  State<_SpinningRefreshIcon> createState() => _SpinningRefreshIconState();
}

class _SpinningRefreshIconState extends State<_SpinningRefreshIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_SpinningRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _controller.repeat();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.refresh_rounded,
        color: widget.isSpinning ? const Color(0xFF005B96) : Colors.white54,
        size: 20,
      ),
    );
  }
}
