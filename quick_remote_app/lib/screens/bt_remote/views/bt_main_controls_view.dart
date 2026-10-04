import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../remote/widgets/shared_buttons.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Tab 0: Main Controls View  (WiFi MainControlsView ile aynı tasarım)
// ═════════════════════════════════════════════════════════════════════════════

class BtMainControlsView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;
  final String? activeScreen;

  const BtMainControlsView({
    super.key,
    required this.send,
    required this.isConnected,
    required this.activeScreen,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, AppSpace.md),
              child: Column(
                children: [
                  // BT bilgi bandı (slayt sayısı yerine)
                  FadeSlideIn(
                    child: AppCard(
                      tint: p.info,
                      elevated: true,
                      radius: AppRadius.xl,
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: Row(
                        children: [
                          IconBadge(icon: Icons.bluetooth_connected_rounded, color: p.info, size: 48),
                          const SizedBox(width: AppSpace.md - 2),
                          Expanded(
                            child: Text(
                              context.l10n.btModeTitle,
                              style: AppType.title.copyWith(color: p.textPrimary),
                            ),
                          ),
                          StatusPill(
                            color: isConnected ? p.success : p.danger,
                            label: isConnected ? context.l10n.statusConnected : context.l10n.statusDisconnected,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpace.xl),
                  // Başlat / Bitir
                  FadeSlideIn(
                    index: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: context.l10n.actionStart,
                            color: p.success,
                            onTap: !isConnected ? null : () => send(RemoteCommands.start),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: ActionButton(
                            icon: Icons.stop_rounded,
                            label: context.l10n.actionEnd,
                            color: p.danger,
                            onTap: !isConnected ? null : () => send(RemoteCommands.end),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  // Siyah Ekran / Beyaz Ekran
                  FadeSlideIn(
                    index: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: ScreenToggleButton(
                            label: context.l10n.blackScreen,
                            white: false,
                            isActive: activeScreen == 'BLACK',
                            onTap: !isConnected ? null : () => send(RemoteCommands.blackScreen),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: ScreenToggleButton(
                            label: context.l10n.whiteScreen,
                            white: true,
                            isActive: activeScreen == 'WHITE',
                            onTap: !isConnected ? null : () => send(RemoteCommands.whiteScreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  // Geri / İleri
                  FadeSlideIn(
                    index: 3,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SlideButton(
                            icon: Icons.arrow_back_rounded,
                            label: context.l10n.actionPrev,
                            onTap: !isConnected ? null : () => send(RemoteCommands.prev),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          flex: 3,
                          child: SlideButton(
                            icon: Icons.arrow_forward_rounded,
                            label: context.l10n.actionNext,
                            isPrimary: true,
                            onTap: !isConnected ? null : () => send(RemoteCommands.next),
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
      ],
    );
  }
}
