import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../remote/widgets/media_labels.dart';
import '../../remote/widgets/now_playing_card.dart';
import '../../remote/widgets/volume_panel.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The Bluetooth remote's media, laid out as the Wi-Fi remote's: the
/// computer's volume keys, then its media keys. A keyboard gets no answer,
/// so the panels show no level, title or slide media.
class BtMediaView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;

  const BtMediaView({super.key, required this.send, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(
      AppSpace.page,
      AppSpace.xxs,
      AppSpace.page,
      AppSpace.lg,
    );
    return ContentWidth(
      // The panels sit in the middle of the tab, as on the Wi-Fi remote's
      // media tab, and scroll on a short screen.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - padding.vertical).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: VolumePanel(
                    isConnected: isConnected,
                    levelKnown: false,
                    volume: -1,
                    muted: false,
                    onVolumeUp: () => send(RemoteCommands.volumeUp),
                    onVolumeDown: () => send(RemoteCommands.volumeDown),
                    onMute: () => send(RemoteCommands.volumeMute),
                    onSetVolume: (_) {},
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                FadeSlideIn(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MediaSectionHeader(
                        icon: Icons.album_rounded,
                        label: context.l10n.nowPlaying,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      NowPlayingCard(
                        hasMedia: false,
                        infoKnown: false,
                        isPlaying: false,
                        isConnected: isConnected,
                        onPlayPause: () =>
                            send(RemoteCommands.sysMediaPlayPause),
                        onNext: () => send(RemoteCommands.sysMediaNext),
                        onPrev: () => send(RemoteCommands.sysMediaPrev),
                        onStop: () => send(RemoteCommands.sysMediaStop),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                FadeSlideIn(
                  index: 2,
                  child: InlineAlert(
                    dense: true,
                    icon: Icons.info_outline_rounded,
                    message: context.l10n.btMediaLimits,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
