import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../providers/server_provider.dart';
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
    final qrData = 'quickremote://${provider.localIP}:${provider.port}:${provider.pin}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NetworkStatusBanner(
          isPublic: provider.publicNetwork,
          server: provider.server,
        ),
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
                                    width: 160,
                                    height: 160,
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
                                else ...[
                                  QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                    size: 160,
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
                          provider.isStarting ? 'Ağ bilgileri alınıyor...' : 'Bağlanmak için QR kodu tarayın',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
                                provider.isStarting ? 'PIN: ...' : 'PIN: ${provider.pin}',
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
        const SizedBox(height: 16),
        HoverScale(
          scale: 1.05,
          onTap: () async {
            await provider.stopServer();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
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
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
