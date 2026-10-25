import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../../services/presentation_timer_controller.dart';
import '../../../widgets/presentation_timer.dart';
import '../../remote/widgets/shared_buttons.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The Bluetooth remote's controls: the Wi-Fi layout without what a keyboard
/// cannot know (slide number, go to slide), and Start and End apart. The
/// talk's clock runs from Start to End, as on the watch.
class BtMainControlsView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;
  final String? activeScreen;

  /// The computer the phone is the keyboard of.
  final String pcName;
  final PresentationTimerController timer;

  const BtMainControlsView({
    super.key,
    required this.send,
    required this.isConnected,
    required this.activeScreen,
    required this.pcName,
    required this.timer,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.xxs,
                AppSpace.page,
                AppSpace.sm,
              ),
              child: Column(
                children: [
                  FadeSlideIn(
                    child: _ModeCard(
                      isConnected: isConnected,
                      pcName: pcName,
                      activeScreen: activeScreen,
                      send: send,
                      timer: timer,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  FadeSlideIn(
                    index: 1,
                    child: StartEndPair(
                      onStart: !isConnected
                          ? null
                          : () => send(RemoteCommands.start),
                      onEnd: !isConnected
                          ? null
                          : () => send(RemoteCommands.end),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Expanded(
                    child: FadeSlideIn(
                      index: 2,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 150),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 112,
                              child: BigSlideButton(
                                next: false,
                                label: context.l10n.actionPrev,
                                onTap: !isConnected
                                    ? null
                                    : () => send(RemoteCommands.prev),
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: BigSlideButton(
                                next: true,
                                label: context.l10n.actionNext,
                                onTap: !isConnected
                                    ? null
                                    : () => send(RemoteCommands.next),
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// "Bluetooth HID mode": whose keyboard the phone is, the black and white
/// screen keys and the talk's clock. Amber, without the keys, while the link
/// is down.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.isConnected,
    required this.pcName,
    required this.activeScreen,
    required this.send,
    required this.timer,
  });

  final bool isConnected;
  final String pcName;
  final String? activeScreen;
  final Future<void> Function(String) send;
  final PresentationTimerController timer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = isConnected ? p.info : p.warning;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.base),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.md, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [Color.lerp(p.surfaceRaised, p.info, 0.08)!, p.surface],
        ),
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(
                icon: isConnected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_searching_rounded,
                color: tone,
                size: 46,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.btModeTitle,
                      style: AppType.titleSmall.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? context.l10n.btModeSubtitle(pcName)
                          : context.l10n.statusDisconnected,
                      style: AppType.bodySmall.copyWith(
                        color: isConnected ? p.textSecondary : p.warning,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: AppSpace.sm),
            Divider(height: 1, thickness: 1, color: p.border),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                ScreenKey(
                  white: false,
                  label: context.l10n.blackScreen,
                  active: activeScreen == 'BLACK',
                  onTap: () => send(RemoteCommands.blackScreen),
                ),
                const SizedBox(width: 6),
                ScreenKey(
                  white: true,
                  label: context.l10n.whiteScreen,
                  active: activeScreen == 'WHITE',
                  onTap: () => send(RemoteCommands.whiteScreen),
                ),
                // The keys carry their names for screen readers, as on the
                // Wi-Fi remote's slide card; the timer took their caption's place.
                const Spacer(),
                PresentationTimer(controller: timer),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
