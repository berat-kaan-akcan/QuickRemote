import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../remote/widgets/glass_panel.dart';
import '../../remote/widgets/premium_media_btn.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 2: Media View  (WiFi MediaControlView ile aynı tasarım)
// BT HID'de çalışmayan özellikler kaldırıldı:
//   - Now Playing kartı (title, artist, thumbnail, progress) → yok
//   - Volume slider (VOLUME_SET komutu PC app gerektirir) → sadece +/- butonlar
//   - PPT Video kontrolleri (MEDIA_PLAY_PAUSE, MEDIA_REWIND) → yok
//   - REFRESH_STATE → yok
// ═════════════════════════════════════════════════════════════════════════════

class BtMediaView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;

  const BtMediaView({super.key, required this.send, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık — WiFi ile aynı
            const Row(
              children: [
                Icon(Icons.queue_music_rounded, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Text(
                  'Medya Kontrolü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sistem Medya Kontrolleri
                      _buildSectionLabel(
                        icon: Icons.album_rounded,
                        label: 'Sistem Medyası',
                        color: const Color(0xFFF43F5E),
                      ),
                      const SizedBox(height: 8),
                      _buildSystemMediaPanel(context),
                      const SizedBox(height: 24),

                      // Sistem Sesi
                      _buildSectionLabel(
                        icon: Icons.volume_up_rounded,
                        label: 'Sistem Sesi',
                        color: const Color(0xFF0EA5E9),
                      ),
                      const SizedBox(height: 8),
                      _buildVolumePanel(context),
                      const SizedBox(height: 24),

                      // BT mod uyarısı
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF64B5F6), size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bluetooth modunda medya bilgisi, ses seviyesi göstergesi ve PowerPoint medya kontrolleri kullanılamaz. Tam özellik için WiFi modunu kullanın.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemMediaPanel(BuildContext context) {
    const accent = Color(0xFFF43F5E);
    return GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
      child: Column(
        children: [
          // Medya bilgisi yok uyarısı
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Colors.white24, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sistem Medyası',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BT modunda medya bilgisi alınamaz',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                PremiumMediaBtn(
                  icon: Icons.skip_previous_rounded,
                  label: '',
                  color: Colors.white,
                  onTap: isConnected ? () => send(RemoteCommands.sysMediaPrev) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PremiumMediaBtn(
                    icon: Icons.play_arrow_rounded,
                    label: 'Oynat / Duraklat',
                    color: Colors.white,
                    large: true,
                    glow: true,
                    onTap: isConnected ? () => send(RemoteCommands.sysMediaPlayPause) : null,
                  ),
                ),
                const SizedBox(width: 8),
                PremiumMediaBtn(
                  icon: Icons.skip_next_rounded,
                  label: '',
                  color: Colors.white,
                  onTap: isConnected ? () => send(RemoteCommands.sysMediaNext) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumePanel(BuildContext context) {
    const accent = Color(0xFF38BDF8);
    return GlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              _PillBtn(
                icon: Icons.remove_rounded,
                color: accent,
                isLeft: true,
                onTap: isConnected ? () => send(RemoteCommands.volumeDown) : null,
              ),
              Container(width: 1, height: 28, color: accent.withValues(alpha: 0.2)),
              _PillBtn(
                icon: Icons.volume_off_rounded,
                color: accent,
                onTap: isConnected ? () => send(RemoteCommands.volumeMute) : null,
              ),
              Container(width: 1, height: 28, color: accent.withValues(alpha: 0.2)),
              _PillBtn(
                icon: Icons.add_rounded,
                color: accent,
                isRight: true,
                onTap: isConnected ? () => send(RemoteCommands.volumeUp) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium Pill Button Segment ──────────────────────────────────────────────
class _PillBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLeft;
  final bool isRight;

  const _PillBtn({
    required this.icon,
    required this.color,
    this.onTap,
    this.isLeft = false,
    this.isRight = false,
  });

  @override
  State<_PillBtn> createState() => _PillBtnState();
}

class _PillBtnState extends State<_PillBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _isPressed = false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedOpacity(
          opacity: enabled ? (_isPressed ? 0.7 : 1.0) : 0.45,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isPressed ? widget.color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: widget.isLeft ? const Radius.circular(40) : Radius.zero,
                right: widget.isRight ? const Radius.circular(40) : Radius.zero,
              ),
            ),
            child: Icon(widget.icon, color: widget.color, size: 24),
          ),
        ),
      ),
    );
  }
}
