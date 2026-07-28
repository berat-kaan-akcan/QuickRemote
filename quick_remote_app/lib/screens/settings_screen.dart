import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white, fontWeight: 
FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Lazer Rengi
          const Text(
            'Lazer Rengi',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildColorOption(
                context, 
                color: const Color(0xFFFF1744), 
                label: 'Kırmızı', 
                index: 0, 
                currentIndex: settings.laserColorIndex,
              ),
              const SizedBox(width: 12),
              _buildColorOption(
                context, 
                color: const Color(0xFF00E676), 
                label: 'Yeşil', 
                index: 1, 
                currentIndex: settings.laserColorIndex,
              ),
              const SizedBox(width: 12),
              _buildColorOption(
                context, 
                color: const Color(0xFF2979FF), 
                label: 'Mavi', 
                index: 2, 
                currentIndex: settings.laserColorIndex,
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // Erken Uyarı
          const Text(
            'Sunum Sayacı',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Erken Uyarı Titreşimi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Sürenin bitimine 60 ve 30 saniye kala kısa titreşim ile uyarır.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              value: settings.earlyWarningHaptic,
              activeThumbColor: const Color(0xFF6C63FF),
              onChanged: (val) {
                context.read<SettingsProvider>().setEarlyWarningHaptic(val);
              },
            ),
          ),
          
          const SizedBox(height: 32),

          // Sunum Kontrolü
          const Text(
            'Sunum Kontrolü',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Geçişlerde Çizimleri Temizle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Slayt geçişlerinde ekrandaki çizimleri (kalem vb.) otomatik siler.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              value: settings.clearInkOnNext,
              activeThumbColor: const Color(0xFF6C63FF),
              onChanged: (val) {
                context.read<SettingsProvider>().setClearInkOnNext(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, {required Color color, required String label, required int index, required int currentIndex}) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<SettingsProvider>().setLaserColorIndex(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
