import 'package:flutter/material.dart';
import '../../../services/websocket_server.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'home_card.dart';

/// Paired phones, each with a button that disconnects it. In a card of its
/// own; in the wide window's side pane, without one.
class ConnectedClientsList extends StatelessWidget {
  const ConnectedClientsList({
    super.key,
    required this.clients,
    required this.onKick,
    this.framed = true,
  });

  final List<ConnectedClient> clients;
  final void Function(int id) onKick;
  final bool framed;

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionLabel(context.l10n.connectedDevices(clients.length)),
        const SizedBox(height: AppSpace.xxs),
        for (final client in clients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.16),
                        borderRadius: AppRadius.all(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.smartphone_rounded,
                        color: p.primaryText,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: p.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: p.surface,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.name != null)
                        Text(
                          client.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.titleSmall.copyWith(
                            color: p.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      // Two phones of the same model differ here.
                      Text(
                        '${client.address}  ·  ${_time(client.since)}',
                        overflow: TextOverflow.ellipsis,
                        style: AppType.mono.copyWith(
                          color: client.name == null
                              ? p.textPrimary
                              : p.textSecondary,
                          fontSize: client.name == null ? 13 : 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: context.l10n.removeDevice,
                  icon: Icons.link_off_rounded,
                  tooltip: context.l10n.removeDeviceTooltip,
                  variant: AppButtonVariant.ghost,
                  tone: AppTone.danger,
                  expand: false,
                  height: 34,
                  onPressed: () => onKick(client.id),
                ),
              ],
            ),
          ),
      ],
    );
    if (!framed) return column;
    return HomeCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, 10, 6),
      child: column,
    );
  }
}
