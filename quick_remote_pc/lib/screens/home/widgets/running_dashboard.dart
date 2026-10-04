import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/server_provider.dart';
import '../../../widgets/hover_scale.dart';
import 'connected_clients_list.dart';
import 'network_status_banner.dart';
import 'pairing_card.dart';
import 'public_network_warning_dialog.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

class RunningDashboard extends StatefulWidget {
  final WebSocketServerProvider provider;

  const RunningDashboard({super.key, required this.provider});

  @override
  State<RunningDashboard> createState() => _RunningDashboardState();
}

class _RunningDashboardState extends State<RunningDashboard> {
  bool _hasShownDialogForCurrentRun = false;
  bool _isShowingNetworkDialog = false;
  /// The user asked to see the QR code and PIN after a phone paired.
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_checkAndShowWarning);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowWarning());
  }

  @override
  void dispose() {
    widget.provider.removeListener(_checkAndShowWarning);
    super.dispose();
  }

  void _checkAndShowWarning() {
    if (widget.provider.publicNetwork && widget.provider.isRunning) {
      if (!_isShowingNetworkDialog && !_hasShownDialogForCurrentRun) {
        _hasShownDialogForCurrentRun = true;
        _showNetworkChangeWarning();
      }
    } else {
      _hasShownDialogForCurrentRun = false;
    }
  }

  Future<void> _showNetworkChangeWarning() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hideWarning = prefs.getBool('hide_public_network_warning') ?? false;
    if (hideWarning || !mounted) return;

    _isShowingNetworkDialog = true;
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PublicNetworkWarningDialog(
        server: widget.provider.server,
      ),
    );
    _isShowingNetworkDialog = false;

    if (proceed != true && mounted) {
      await widget.provider.stopServer();
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    if (!provider.pairedOnce) _revealed = false;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NetworkStatusBanner(
          trust: provider.networkTrust,
          server: provider.server,
        ),
        if (provider.pairingPaused) ...[
          const SizedBox(height: 8),
          const _PairingPausedBanner(),
        ],
        const SizedBox(height: 8),
        Flexible(
          child: PairingCard(
            provider: provider,
            revealed: _revealed,
            onRevealChanged: (revealed) => setState(() => _revealed = revealed),
          ),
        ),
        if (provider.connectedClients.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConnectedClientsList(
            clients: provider.connectedClients,
            onKick: provider.server.kickClient,
          ),
        ],
        const SizedBox(height: 12),
        _StopButton(onStop: provider.stopServer),
      ],
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onStop});

  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    const red = AppColors.stop;
    return HoverScale(
      scale: 1.05,
      onTap: onStop,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: red.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.power_settings_new_rounded,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PairingPausedBanner extends StatelessWidget {
  const _PairingPausedBanner();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.alert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.gpp_maybe_rounded, color: color, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.pairingPaused,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
