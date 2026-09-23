import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                                'Bluetooth modunda medya bilgisi ve ses seviyesi göstergesi görüntülenemez. Tam özellik için WiFi modunu kullanın.',
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
    return _BtGlassPanel(
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
                _BtMediaBtn(
                  icon: Icons.skip_previous_rounded,
                  label: '',
                  color: Colors.white,
                  onTap: isConnected ? () => send('SYSTEM_MEDIA_PREV') : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BtMediaBtn(
                    icon: Icons.play_arrow_rounded,
                    label: 'Oynat / Duraklat',
                    color: Colors.white,
                    large: true,
                    glow: true,
                    onTap: isConnected ? () => send('SYSTEM_MEDIA_PLAY_PAUSE') : null,
                  ),
                ),
                const SizedBox(width: 8),
                _BtMediaBtn(
                  icon: Icons.skip_next_rounded,
                  label: '',
                  color: Colors.white,
                  onTap: isConnected ? () => send('SYSTEM_MEDIA_NEXT') : null,
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
    return _BtGlassPanel(
      borderColor: accent.withValues(alpha: 0.3),
      gradientColors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
      child: Column(
        children: [
          // Mute butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: isConnected
                    ? () {
                        HapticFeedback.lightImpact();
                        send('VOLUME_MUTE');
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_off_rounded, color: accent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Sessiz',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '–',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Volume up/down buttons
          Row(
            children: [
              GestureDetector(
                onTap: isConnected ? () { HapticFeedback.lightImpact(); send('VOLUME_DOWN'); } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_rounded, color: accent, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isConnected ? () { HapticFeedback.lightImpact(); send('VOLUME_UP'); } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: accent, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Glassmorphism Panel (WiFi media_control_view ile aynı) ─────────────────
class _BtGlassPanel extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Color borderColor;

  const _BtGlassPanel({
    required this.child,
    this.gradientColors = const [Colors.white10, Colors.white12],
    this.borderColor = Colors.white12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: child,
      ),
    );
  }
}

// ─── Premium Media Button (WiFi media_control_view ile aynı) ─────────────────
class _BtMediaBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool large;
  final bool glow;
  final VoidCallback? onTap;

  const _BtMediaBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.large = false,
    this.glow = false,
    this.onTap,
  });

  @override
  State<_BtMediaBtn> createState() => _BtMediaBtnState();
}

class _BtMediaBtnState extends State<_BtMediaBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 16 : 14,
              vertical: widget.large ? 12 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.2),
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: widget.glow ? 0.4 : 0.1),
                  blurRadius: widget.glow ? 16 : 8,
                  spreadRadius: widget.glow ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: widget.large ? 24 : 20),
                if (widget.large) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
