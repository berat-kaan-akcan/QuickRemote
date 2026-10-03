import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../providers/server_provider.dart';
import '../../../../services/websocket_server.dart';
import '../../../../widgets/hover_scale.dart';
import '../../../../widgets/hover_glow_container.dart';
import 'network_status_banner.dart';
import 'public_network_warning_dialog.dart';

class RunningDashboard extends StatefulWidget {
  final WebSocketServerProvider provider;

  const RunningDashboard({super.key, required this.provider});

  @override
  State<RunningDashboard> createState() => _RunningDashboardState();
}

class _RunningDashboardState extends State<RunningDashboard> {
  bool _hasShownDialogForCurrentRun = false;
  bool _isShowingNetworkDialog = false;
  /// The user asked to see the QR code and PIN after a phone paired.
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_checkAndShowWarning);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowWarning());
  }

  @override
  void dispose() {
    widget.provider.removeListener(_checkAndShowWarning);
    super.dispose();
  }

  void _checkAndShowWarning() {
    if (widget.provider.publicNetwork && widget.provider.isRunning) {
      if (!_isShowingNetworkDialog && !_hasShownDialogForCurrentRun) {
        _hasShownDialogForCurrentRun = true;
        _showNetworkChangeWarning();
      }
    } else {
      _hasShownDialogForCurrentRun = false;
    }
  }

  Future<void> _showNetworkChangeWarning() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hideWarning = prefs.getBool('hide_public_network_warning') ?? false;
    if (hideWarning || !mounted) return;

    _isShowingNetworkDialog = true;
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PublicNetworkWarningDialog(
        server: widget.provider.server,
      ),
    );
    _isShowingNetworkDialog = false;

    if (proceed != true && mounted) {
      await widget.provider.stopServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    // Once a phone has paired, the code stays hidden until asked for: the
    // screen is often projected, and anyone who scans it can pair.
    if (!provider.pairedOnce) _revealed = false;
    final hidden = provider.pairedOnce && !_revealed;
    // Phones connecting without the QR code ask the user to compare this.
    final fingerprintHex =
        provider.certFingerprint == null ? null : PairingPayload.fingerprintToHex(provider.certFingerprint!);
    final qrData = PairingPayload(
      host: provider.localIP,
      port: provider.port,
      pin: provider.pin,
      certFingerprint: provider.certFingerprint,
    ).encode();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NetworkStatusBanner(
          trust: provider.networkTrust,
          server: provider.server,
        ),
        if (provider.pairingPaused) ...[
          const SizedBox(height: 8),
          const _PairingPausedBanner(),
        ],
        const SizedBox(height: 8),
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HoverGlowContainer(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: provider.isStarting ? Colors.transparent : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (provider.isStarting)
                                  SizedBox(
                                    width: 184,
                                    height: 184,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 4,
                                            strokeCap: StrokeCap.round,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                                            backgroundColor: Color(0x3300BCD4),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/logo.png', 
                                              width: 36, 
                                              height: 36,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (hidden)
                                  _HiddenCode(onReveal: () => setState(() => _revealed = true))
                                else ...[
                                  QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                    size: 184,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.circle,
                                      color: Color(0xFF0F172A),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.circle,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/logo.png', 
                                        width: 36, 
                                        height: 36,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.isStarting
                              ? 'Ağ bilgileri alınıyor...'
                              : hidden
                                  ? 'Başka bir cihaz eşleştirmek için kodu gösterin'
                                  : 'Bağlanmak için QR kodu tarayın',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        if (provider.pairedOnce && _revealed)
                          TextButton.icon(
                            onPressed: () => setState(() => _revealed = false),
                            icon: const Icon(Icons.visibility_off_rounded, size: 16),
                            label: const Text('Kodu gizle'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          Platform.localHostname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'IP: ${provider.localIP}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Consolas',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: provider.port != 8090 
                                  ? const Color(0xFFFFB74D).withValues(alpha: 0.2)
                                  : const Color(0xFF00BCD4).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: provider.port != 8090 
                                    ? const Color(0xFFFFB74D).withValues(alpha: 0.5)
                                    : const Color(0xFF00BCD4).withValues(alpha: 0.5),
                                )
                              ),
                              child: Text(
                                'Port: ${provider.port}',
                                style: TextStyle(
                                  color: provider.port != 8090 
                                    ? const Color(0xFFFFB74D) 
                                    : const Color(0xFF00BCD4),
                                  fontFamily: 'Consolas',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (fingerprintHex != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Güvenlik kodu: ${PairingPayload.verificationCode(fingerprintHex)}',
                            style: const TextStyle(color: Colors.white54, fontFamily: 'Consolas', fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, color: Color(0xFFFF9800), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                provider.isStarting
                                    ? 'PIN: ...'
                                    : hidden
                                        ? 'PIN: ••••••'
                                        : 'PIN: ${provider.pin}',
                                style: const TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Consolas',
                                  letterSpacing: 3,
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
            ),
          ),
        ),
        if (provider.connectedClients.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ConnectedClients(
            clients: provider.connectedClients,
            onKick: provider.server.kickClient,
          ),
        ],
        const SizedBox(height: 12),
        HoverScale(
          scale: 1.05,
          onTap: () async {
            await provider.stopServer();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _PairingPausedBanner extends StatelessWidget {
  const _PairingPausedBanner();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF44336);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.gpp_maybe_rounded, color: color, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Çok fazla hatalı PIN denemesi. Eşleştirme 1 dakika duraklatıldı ve PIN yenilendi.',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the QR code once a phone has paired.
class _HiddenCode extends StatelessWidget {
  const _HiddenCode({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      height: 184,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 72, color: Color(0x330F172A)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('Kodu göster'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paired phones, each with a button that disconnects it.
class _ConnectedClients extends StatelessWidget {
  const _ConnectedClients({required this.clients, required this.onKick});

  final List<ConnectedClient> clients;
  final void Function(int id) onKick;

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bağlı cihazlar (${clients.length})',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          for (final client in clients)
            Row(
              children: [
                const Icon(Icons.smartphone_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.name != null)
                        Text(
                          client.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      // Two phones of the same model differ here.
                      Text(
                        '${client.address}  ·  ${_time(client.since)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: client.name == null ? Colors.white : Colors.white60,
                          fontFamily: 'Consolas',
                          fontSize: client.name == null ? 13 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Bağlantıyı keser ve PIN\'i yeniler. Diğer cihazlar bağlı kalır.',
                  child: TextButton(
                    onPressed: () => onKick(client.id),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5252),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Çıkar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
