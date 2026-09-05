import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketServerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Blobs
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Positioned(
                top: -50 + (_bgAnimController.value * 30),
                left: -100 + (_bgAnimController.value * 20),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF005B96).withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF005B96).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 40)
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Positioned(
                bottom: -100 - (_bgAnimController.value * 40),
                right: -50 + (_bgAnimController.value * 20),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00BCD4).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 40)
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png', 
                            width: 52, 
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QuickRemote PC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Sunum Kontrol Merkezi',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.isRunning)
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                          onPressed: () {
                            provider.triggerSlideStateUpdate();
                          },
                          tooltip: 'Slayt Durumunu Yenile',
                        ),
                      _StatusChip(
                        isRunning: provider.isRunning,
                        clientCount: provider.clientCount,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => const _SettingsDialog(),
                          );
                        },
                        tooltip: 'Ayarlar',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main Content
                  Expanded(
                    child: provider.isRunning
                        ? _RunningDashboard(provider: provider)
                        : const _StoppedDashboard(),
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

class _StatusChip extends StatelessWidget {
  final bool isRunning;
  final int clientCount;

  const _StatusChip({required this.isRunning, required this.clientCount});

  @override
  Widget build(BuildContext context) {
    final color = isRunning ? const Color(0xFF00BCD4) : const Color(0xFFFF5252);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isRunning ? '$clientCount Bağlı' : 'Kapalı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningDashboard extends StatelessWidget {
  final WebSocketServerProvider provider;

  const _RunningDashboard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final qrData = 'quickremote://${provider.localIP}:${provider.port}:${provider.pin}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glassmorphic QR Card
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
                        // QR Code
                    _HoverGlowContainer(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bağlanmak için QR kodu tarayın',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
                    Text(
                      '${provider.localIP}:${provider.port}',
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // PIN Pill
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
                            'PIN: ${provider.pin}',
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

        // Stop Server Button
        _HoverScale(
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

class _StoppedDashboard extends StatelessWidget {
  const _StoppedDashboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HoverScale(
            scale: 1.05,
            onTap: () async {
              final provider = context.read<WebSocketServerProvider>();
              try {
                await provider.startServer();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sunucu başlatılamadı: Port kullanımda. Lütfen 8090-8099 portlarını kullanan uygulamaları kapatıp tekrar deneyin.',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              // Notify user if server started on a non-default port
              final actualPort = provider.server.port;
              if (actualPort != 8090 && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Port 8090 kullanımda olduğu için sunucu $actualPort portunda başlatıldı.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange.shade700,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              // Show public network warning if detected
              if (provider.publicNetwork) {
                final prefs = await SharedPreferences.getInstance();
                final hideWarning = prefs.getBool('hide_public_network_warning') ?? false;

                if (!hideWarning && context.mounted) {
                  final proceed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const _PublicNetworkWarningDialog(),
                  );

                  if (proceed != true) {
                    await provider.stopServer();
                  }
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF005B96), Color(0xFF00BCD4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF005B96).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sunucu Kapalı',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Telefonunuzdan bağlanmak ve sunumunuzu\nkontrol etmek için sunucuyu başlatın.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PublicNetworkWarningDialog extends StatefulWidget {
  const _PublicNetworkWarningDialog();

  @override
  State<_PublicNetworkWarningDialog> createState() => _PublicNetworkWarningDialogState();
}

class _PublicNetworkWarningDialogState extends State<_PublicNetworkWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFFFF9800), size: 48),
      title: const Text(
        'Ortak Ağ Uyarısı',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Şu an ortak (Public) bir ağdasınız. Bu ağdaki diğer kişiler '
            'QuickRemote sunucunuzu görebilir.\n\n'
            'Güvenilir bir ağda olduğunuzdan emin olun.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _dontShowAgain,
                  activeColor: const Color(0xFFFF9800),
                  side: const BorderSide(color: Colors.white54),
                  onChanged: (val) {
                    setState(() => _dontShowAgain = val ?? false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                  child: const Text(
                    'Bu uyarıyı bir daha gösterme',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (context.mounted) Navigator.of(context).pop(false);
          },
          child: const Text('Sunucuyu Durdur', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () async {
            if (_dontShowAgain) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hide_public_network_warning', true);
            }
            if (context.mounted) Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const _HoverScale({required this.child, this.onTap, this.scale = 1.05});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class _HoverGlowContainer extends StatefulWidget {
  final Widget child;

  const _HoverGlowContainer({required this.child});

  @override
  State<_HoverGlowContainer> createState() => _HoverGlowContainerState();
}

class _HoverGlowContainerState extends State<_HoverGlowContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: const Color(0xFF005B96).withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 2,
              )
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  bool _hideWarning = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideWarning = prefs.getBool('hide_public_network_warning') ?? false;
    });
  }

  Future<void> _saveSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_public_network_warning', value);
    setState(() {
      _hideWarning = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.settings_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Ayarlar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text(
              'Ortak Ağ Uyarılarını Gizle',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            subtitle: const Text(
              'Ortak ağlara bağlanırken güvenlik uyarısı gösterme.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            value: _hideWarning,
            activeTrackColor: const Color(0xFF00BCD4).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF00BCD4),
            onChanged: _saveSettings,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
