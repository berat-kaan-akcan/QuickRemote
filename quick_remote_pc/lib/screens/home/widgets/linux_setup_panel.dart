import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../providers/server_provider.dart';
import '../../../../services/linux/linux_setup.dart';
import '../../../../services/server/network_manager.dart';
import '../../../../widgets/hover_scale.dart';
import '../../../../widgets/status_snack_bar.dart';

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
  /// The blocked-ports dialog is shown once per server run.
  bool _firewallWarned = false;

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

  bool _refreshing = false;

  Future<void> _refresh() async {
    // A slow check (polkit, a busy LibreOffice) must not pile up runs every 5 s.
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _refreshNow();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refreshNow() async {
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
    if (!widget.provider.isRunning) {
      _firewallWarned = false;
    } else if (firewall == FirewallStatus.blocked && !_firewallWarned) {
      _firewallWarned = true;
      _showFirewallDialog();
    }
  }

  Future<void> _openPorts() => _run(
        NetworkManager.openFirewallPorts,
        'Güvenlik duvarında portlar açıldı.',
        'Portlar açılamadı.',
      );

  Future<void> _showFirewallDialog() async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.security_rounded, color: _orange, size: 48),
        title: const Text(
          'Portları Açmanız Gerekiyor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Güvenlik duvarı telefonun bu bilgisayara bağlanmasını '
          'engelliyor. Uygulamayı kullanmak için 8090-8099 portlarını açmalısınız.\n\n'
          'Portlar bu ağ bölgesinde kalıcı olarak açılır. Yönetici parolanız '
          'bir kez sorulacak.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Portları Aç',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (open == true && mounted) await _openPorts();
  }

  Future<void> _run(Future<bool> Function() action, String success, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    showStatusSnackBar(
      context,
      ok ? success : failure,
      kind: ok ? StatusKind.success : StatusKind.error,
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
              ? 'Güvenlik duvarı telefonun bağlanmasını engelliyor. Kullanmak için portları açın.'
              : 'Güvenlik duvarı kuralları okunamadı: 8090-8099 portları açık olmalı',
          action: 'Portları aç',
          onTap: _openPorts,
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
      ImpressStatus.legacyListener => _row(
          Icons.gpp_maybe_rounded,
          _orange,
          'Impress bağlantısı eski yöntemi kullanıyor: bu bilgisayardaki her kullanıcıya ve uygulamaya açık bir port. Güncelleyin.',
          action: 'Güncelle',
          onTap: () => _run(enable, 'Impress bağlantısı güvenli yönteme geçirildi.', 'LibreOffice ayarı yazılamadı.'),
        ),
      ImpressStatus.legacyListenerWhileRunning => _row(
          Icons.gpp_maybe_rounded,
          _orange,
          'Impress bağlantısı eski yöntemi kullanıyor: bu bilgisayardaki her kullanıcıya ve uygulamaya açık bir port. '
          'Güncellemek için LibreOffice\'i kapatın.',
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
