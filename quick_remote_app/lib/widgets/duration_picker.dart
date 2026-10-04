import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/ui/app_bottom_sheet.dart';
import '../utils/ui/app_popup_theme.dart';
import '../utils/ui/app_snackbar.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';

/// Preset minutes plus custom minute/second fields for the presentation timer.
class DurationPicker extends StatefulWidget {
  /// The duration selected before, shown in the custom fields.
  final int? initialSeconds;
  final void Function(int seconds, bool start) onSelected;

  const DurationPicker({super.key, required this.initialSeconds, required this.onSelected});

  @override
  State<DurationPicker> createState() => DurationPickerState();
}

class DurationPickerState extends State<DurationPicker> {
  static const _presetMinutes = [5, 10, 15, 20, 30, 45, 60];

  late final TextEditingController _minutes;
  late final TextEditingController _seconds;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSeconds;
    final hasInitial = initial != null && initial > 0;
    _minutes = TextEditingController(text: hasInitial ? '${initial ~/ 60}' : '');
    _seconds = TextEditingController(text: hasInitial && initial % 60 > 0 ? '${initial % 60}' : '');
  }

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _select(int seconds) {
    widget.onSelected(seconds, context.read<SettingsProvider>().timerAutoStart);
  }

  void _submitCustom() {
    final minutes = int.tryParse(_minutes.text.trim().isEmpty ? '0' : _minutes.text.trim());
    final seconds = int.tryParse(_seconds.text.trim().isEmpty ? '0' : _seconds.text.trim());
    final total = (minutes ?? -1) * 60 + (seconds ?? -1);
    if (minutes == null || seconds == null || total <= 0) {
      AppSnackbar.show(
        context,
        message: context.l10n.enterValidDuration,
        type: SnackbarType.error,
      );
      return;
    }
    _select(total);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final selected = widget.initialSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBottomSheet.buildTitle(context.l10n.setPresentationTime, icon: Icons.timer_outlined),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _DurationChip(label: context.l10n.noTimeLimit, selected: selected == 0, onTap: () => _select(0)),
            for (final m in _presetMinutes)
              _DurationChip(label: context.l10n.durationMinutes(m), selected: selected == m * 60, onTap: () => _select(m * 60)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _numberField(_minutes, context.l10n.unitMinutes, TextInputAction.next)),
            const SizedBox(width: 8),
            Expanded(child: _numberField(_seconds, context.l10n.unitSeconds, TextInputAction.done, maxValue: 59)),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _submitCustom,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius)),
              ),
              child: Text(
                settings.timerAutoStart ? context.l10n.actionStart : context.l10n.actionSet,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.l10n.startWhenPicked,
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          value: settings.timerAutoStart,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          onChanged: settings.setTimerAutoStart,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.timerHelp,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String unit, TextInputAction action, {int? maxValue}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      textInputAction: action,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
        if (maxValue != null)
          TextInputFormatter.withFunction(
            (old, value) => (int.tryParse(value.text) ?? 0) > maxValue ? old : value,
          ),
      ],
      decoration: AppPopupTheme.inputDecoration(context: context, hintText: '0').copyWith(suffixText: unit),
      onSubmitted: action == TextInputAction.done ? (_) => _submitCustom() : null,
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ActionChip(
      label: Text(label, style: TextStyle(color: selected ? primary : Colors.white)),
      backgroundColor: selected ? primary.withValues(alpha: 0.2) : AppColors.surface,
      side: selected ? BorderSide(color: primary) : BorderSide.none,
      onPressed: onTap,
    );
  }
}
