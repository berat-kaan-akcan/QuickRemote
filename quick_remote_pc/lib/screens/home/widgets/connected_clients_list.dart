import 'package:flutter/material.dart';
import '../../../services/websocket_server.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

/// Paired phones, each with a button that disconnects it.
class ConnectedClientsList extends StatelessWidget {
  const ConnectedClientsList({super.key, required this.clients, required this.onKick});

  final List<ConnectedClient> clients;
  final void Function(int id) onKick;

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.connectedDevices(clients.length),
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          for (final client in clients)
            Row(
              children: [
                const Icon(Icons.smartphone_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.name != null)
                        Text(
                          client.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      // Two phones of the same model differ here.
                      Text(
                        '${client.address}  ·  ${_time(client.since)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: client.name == null ? Colors.white : Colors.white60,
                          fontFamily: 'Consolas',
                          fontSize: client.name == null ? 13 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: context.l10n.removeDeviceTooltip,
                  child: TextButton(
                    onPressed: () => onKick(client.id),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(context.l10n.removeDevice),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
