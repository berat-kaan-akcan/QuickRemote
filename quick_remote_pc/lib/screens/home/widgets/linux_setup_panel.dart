import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../providers/server_provider.dart';
import '../../../../services/linux/linux_setup.dart';
import '../../../../services/server/network_manager.dart';
import '../../../../widgets/hover_scale.dart';

/// Linux-only status rows: input permission, Impress connection, mDNS and
/// firewall. Each problem comes with a one-click fix where possible.
class LinuxSetupPanel extends StatefulWidget {
  final WebSocketServerProvider provider;

  const LinuxSetupPanel({super.key, required this.provider});

  @override
  State<LinuxSetupPanel> createState() => _LinuxSetupPanelState();
}

class _LinuxSetupPanelState extends State<LinuxSetupPanel> {
  static const _green = Color(0xFF4CAF50);
  static const _orange = Color(0xFFFF9800);
  static const _cyan = Color(0xFF00BCD4);
  static const _red = Color(0xFFFF5252);
  static const _grey = Color(0xFF90A4AE);

  Timer? _timer;
  bool _uinputOk = true;
  ImpressStatus? _impress;
  FirewallStatus _firewall = FirewallStatus.open;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final uinputOk = LinuxSetup.uinputAccessible;
    final impress = await LinuxSetup.impressStatus();
    final firewall = widget.provider.isRunning
        ? await NetworkManager.checkFirewall(widget.provider.port)
        : FirewallStatus.open;
    if (!mounted) return;
    setState(() {
      _uinputOk = uinputOk;
      _impress = impress;
      _firewall = firewall;
    });
  }

  Future<void> _run(Future<bool> Function() action, String success, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? success : failure, style: const TextStyle(color: Colors.white)),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (!_uinputOk)
        _row(
          Icons.keyboard_alt_outlined,
          _orange,
          'Klavye/fare simülasyonu için izin gerekli',
          action: 'İzin ver',
          onTap: () => _run(
            LinuxSetup.installUinputRule,
            'Giriş izni verildi.',
            'İzin verilemedi. Yönetici parolası gerekiyor.',
          ),
        ),
      if (_impress != null) _impressRow(_impress!),
      if (widget.provider.isRunning && !widget.provider.mdnsAvailable)
        _row(
          Icons.wifi_find_rounded,
          _orange,
          'Otomatik keşif kapalı (avahi-daemon). QR veya IP ile bağlanın.',
        ),
      if (widget.provider.isRunning && _firewall != FirewallStatus.open)
        _row(
          Icons.security_rounded,
          _orange,
          _firewall == FirewallStatus.blocked
              ? 'Güvenlik duvarı bağlantıları engelliyor'
              : 'ufw etkin: 8090-8099 portları açık olmalı',
          action: 'Portları aç',
          onTap: () => _run(
            NetworkManager.openFirewallPorts,
            'Güvenlik duvarında portlar açıldı.',
            'Portlar açılamadı.',
          ),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (final row in rows) ...[row, const SizedBox(height: 6)],
        ],
      ),
    );
  }

  Widget _impressRow(ImpressStatus status) {
    Future<bool> enable() => LinuxSetup.enableImpressConnection();
    return switch (status) {
      ImpressStatus.connected => _row(Icons.slideshow_rounded, _green, 'LibreOffice Impress bağlı'),
      ImpressStatus.readyWhenOpened =>
        _row(Icons.slideshow_rounded, _cyan, 'Impress: LibreOffice açılınca bağlanır'),
      ImpressStatus.notConfigured => _row(
          Icons.slideshow_rounded,
          _orange,
          'Impress bağlantısı kapalı',
          action: 'Etkinleştir',
          onTap: () => _run(enable, 'Impress bağlantısı etkinleştirildi.', 'LibreOffice ayarı yazılamadı.'),
        ),
      ImpressStatus.runningNotListening => _row(
          Icons.slideshow_rounded,
          _orange,
          'LibreOffice açık ama bağlantı kabul etmiyor',
          action: 'Bağlan',
          onTap: () => _run(enable, 'LibreOffice bağlantıyı kabul ediyor.', 'LibreOffice\'e ulaşılamadı.'),
        ),
      ImpressStatus.notInstalled =>
        _row(Icons.slideshow_rounded, _grey, 'LibreOffice yok: sunum yalnızca klavye ile kontrol edilir'),
      ImpressStatus.noUno =>
        _row(Icons.error_outline_rounded, _red, 'python3 veya LibreOffice Python (UNO) desteği bulunamadı'),
    };
  }

  Widget _row(IconData icon, Color color, String text, {String? action, VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(width: 8),
            HoverScale(
              scale: 1.1,
              onTap: _busy ? () {} : onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _busy ? '...' : action,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
