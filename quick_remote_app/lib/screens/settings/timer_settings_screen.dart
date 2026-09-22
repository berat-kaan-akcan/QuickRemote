import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui/app_bottom_sheet.dart';
import '../../utils/ui/app_popup_theme.dart';

class TimerSettingsScreen extends StatelessWidget {
  const TimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sunum Sayacı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Erken Uyarı Titreşimi',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Sürenin bitimine seçilen süreler kala uyarır.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  value: settings.earlyWarningHaptic,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    context.read<SettingsProvider>().setEarlyWarningHaptic(val);
                  },
                ),
                if (settings.earlyWarningHaptic) ...[
                  const Divider(color: Colors.white12, height: 32),
                  const Text(
                    'Uyarı Süreleri',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settings.warningTimes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final timeInSeconds = settings.warningTimes[index];
                      final pattern = settings.warningVibrations[timeInSeconds] ?? 'double';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${_formatSecondsToText(timeInSeconds)} kala',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showPatternDialog(context, timeInSeconds, pattern),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.vibration_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getPatternName(pattern),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => context.read<SettingsProvider>().removeWarningTime(timeInSeconds),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddWarningTimeDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Yeni Uyarı Ekle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 32),
                  const Text(
                    'Süre Bittiğinde (0 dk)',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF262C4A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          title: const Text(
                            'Bitiş Titreşimi',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          value: settings.timeOutVibrationEnabled,
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            context.read<SettingsProvider>().setTimeOutVibrationEnabled(val);
                          },
                        ),
                        if (settings.timeOutVibrationEnabled) ...[
                          const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            title: const Text('Titreşim Deseni', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            trailing: GestureDetector(
                              onTap: () => _showPatternDialog(context, null, settings.timeOutVibrationPattern),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.vibration_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getPatternName(settings.timeOutVibrationPattern),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSecondsToText(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      if (s == 0) return '$m dk';
      return '$m dk $s sn';
    }
    return '$seconds sn';
  }

  String _getPatternName(String pattern) {
    switch (pattern) {
      case 'short': return 'Kısa';
      case 'long': return 'Uzun';
      case 'triple': return 'Üçlü';
      case 'double':
      default: return 'Çift';
    }
  }

  void _showPatternDialog(BuildContext context, int? timeInSeconds, String currentPattern) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheet.buildTitle(
              timeInSeconds != null 
                ? '${_formatSecondsToText(timeInSeconds)} İçin Titreşim'
                : 'Bitiş Titreşimi',
              icon: Icons.vibration_rounded,
            ),
            const SizedBox(height: 6),
            const Text(
              'Önizlemek için seçeneklere dokunun',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'short', 'Kısa Titreşim', Icons.short_text_rounded),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'double', 'Çift Titreşim', Icons.view_stream_rounded),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'long', 'Uzun Titreşim', Icons.horizontal_rule_rounded),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'triple', 'Üçlü Titreşim', Icons.dehaze_rounded),
            const SizedBox(height: 16),
            AppBottomSheet.buildCancelButton(ctx),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSheetOption(BuildContext context, int? timeInSeconds, String currentPattern, String value, String label, IconData icon) {
    final isSelected = currentPattern == value;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.mediumImpact();
        _previewVibration(value);
        if (timeInSeconds != null) {
          context.read<SettingsProvider>().updateWarningPattern(timeInSeconds, value);
        } else {
          context.read<SettingsProvider>().setTimeOutVibrationPattern(value);
        }
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!context.mounted) return;
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.white54, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _previewVibration(String pattern) {
    switch (pattern) {
      case 'short': Vibration.vibrate(pattern: [0, 300]); break;
      case 'long': Vibration.vibrate(pattern: [0, 800]); break;
      case 'triple': Vibration.vibrate(pattern: [0, 500, 150, 500, 150, 800]); break;
      case 'double':
      default: Vibration.vibrate(pattern: [0, 300, 100, 300]); break;
    }
  }

  void _showAddWarningTimeDialog(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        bool isMinutes = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBottomSheet.buildTitle('Yeni Uyarı Süresi', icon: Icons.timer_rounded),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: AppPopupTheme.inputDecoration(
                    context: context,
                    hintText: 'Süre girin',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: 'Saniye',
                        isSelected: !isMinutes,
                        onTap: () => setState(() => isMinutes = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeChip(
                        label: 'Dakika',
                        isSelected: isMinutes,
                        onTap: () => setState(() => isMinutes = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'İptal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            final val = int.tryParse(controller.text);
                            if (val != null && val > 0) {
                              final seconds = isMinutes ? val * 60 : val;
                              context.read<SettingsProvider>().addWarningTime(seconds);
                              Navigator.of(ctx).pop();
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Lütfen geçerli bir sayı girin.')),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
                            ),
                          ),
                          child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
