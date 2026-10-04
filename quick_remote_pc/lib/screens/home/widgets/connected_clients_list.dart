import 'package:flutter/material.dart';
import '../../../services/websocket_server.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Paired phones, each with a button that disconnects it.
class ConnectedClientsList extends StatelessWidget {
  const ConnectedClientsList({super.key, required this.clients, required this.onKick});

  final List<ConnectedClient> clients;
  final void Function(int id) onKick;

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.connectedDevices(clients.length),
            style: AppType.overline.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpace.xxs),
          for (final client in clients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconBadge(icon: Icons.smartphone_rounded, color: p.primaryText, size: 38),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle),
                          child: PulseDot(color: p.success, size: 8),
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
                            style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
                          ),
                        // Two phones of the same model differ here.
                        Text(
                          '${client.address}  ·  ${_time(client.since)}',
                          overflow: TextOverflow.ellipsis,
                          style: AppType.mono.copyWith(
                            color: client.name == null ? p.textPrimary : p.textSecondary,
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
                    height: 36,
                    onPressed: () => onKick(client.id),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
