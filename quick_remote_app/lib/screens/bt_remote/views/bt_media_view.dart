import 'package:flutter/material.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../remote/widgets/media_labels.dart';
import '../../remote/widgets/now_playing_card.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The Bluetooth remote's media: the computer's media keys and its volume
/// keys. A keyboard gets no answer, so no title, level or slide media.
class BtMediaView extends StatelessWidget {
  final Future<void> Function(String) send;
  final bool isConnected;

  const BtMediaView({super.key, required this.send, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.xxs,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MediaSectionHeader(
                          icon: Icons.album_rounded,
                          label: context.l10n.systemMedia,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _SystemMediaCard(send: send, isConnected: isConnected),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  FadeSlideIn(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MediaSectionHeader(
                          icon: Icons.volume_up_rounded,
                          label: context.l10n.systemVolume,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _VolumeKeys(send: send, isConnected: isConnected),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpace.lg),
                  FadeSlideIn(
                    index: 2,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpace.sm),
                      decoration: BoxDecoration(
                        color: p.info.withValues(alpha: 0.08),
                        borderRadius: AppRadius.all(AppRadius.sm),
                        border: Border.all(
                          color: p.info.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: p.info,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.btMediaLimits,
                              style: AppType.bodySmall.copyWith(
                                color: p.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
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

class _SystemMediaCard extends StatelessWidget {
  const _SystemMediaCard({required this.send, required this.isConnected});

  final Future<void> Function(String) send;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.surfaceSunken,
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(Icons.music_note_rounded, color: p.textMuted),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.systemMedia,
                      style: AppType.titleSmall.copyWith(
                        color: p.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      context.l10n.btNoMediaInfo,
                      style: AppType.bodySmall.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MediaRoundKey(
                icon: Icons.skip_previous_rounded,
                label: context.l10n.actionPrev,
                onTap: isConnected
                    ? () => send(RemoteCommands.sysMediaPrev)
                    : null,
              ),
              const SizedBox(width: 22),
              // A keyboard cannot tell whether something plays.
              MediaRoundKey(
                icon: Icons.play_arrow_rounded,
                label: context.l10n.mediaPlayPause,
                main: true,
                both: true,
                onTap: isConnected
                    ? () => send(RemoteCommands.sysMediaPlayPause)
                    : null,
              ),
              const SizedBox(width: 22),
              MediaRoundKey(
                icon: Icons.skip_next_rounded,
                label: context.l10n.actionNext,
                onTap: isConnected
                    ? () => send(RemoteCommands.sysMediaNext)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Volume down, mute and up: the keyboard's volume keys.
class _VolumeKeys extends StatelessWidget {
  const _VolumeKeys({required this.send, required this.isConnected});

  final Future<void> Function(String) send;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    Widget key(Widget child, String label, String command, {double? width}) =>
        Pressable(
          onTap: isConnected ? () => send(command) : null,
          semanticLabel: label,
          tooltip: label,
          pressedScale: 0.94,
          borderRadius: radius,
          child: Container(
            width: width,
            height: 56,
            decoration: BoxDecoration(
              color: width != null ? p.surface : null,
              borderRadius: radius,
              border: Border.all(
                color: p.border,
                width: width != null ? 1 : 1.5,
              ),
            ),
            child: ExcludeSemantics(child: child),
          ),
        );

    return Row(
      children: [
        key(
          Icon(Icons.remove_rounded, color: p.textPrimary),
          context.l10n.volumeDown,
          RemoteCommands.volumeDown,
          width: 60,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: key(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_off_rounded, color: p.textPrimary, size: 22),
                const SizedBox(width: AppSpace.xs),
                Text(
                  context.l10n.volumeMuted,
                  style: AppType.label.copyWith(color: p.textPrimary),
                ),
              ],
            ),
            context.l10n.volumeMuted,
            RemoteCommands.volumeMute,
          ),
        ),
        const SizedBox(width: 10),
        key(
          Icon(Icons.add_rounded, color: p.textPrimary),
          context.l10n.volumeUp,
          RemoteCommands.volumeUp,
          width: 60,
        ),
      ],
    );
  }
}
