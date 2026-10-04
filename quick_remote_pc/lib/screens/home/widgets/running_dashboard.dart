import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/server_provider.dart';
import 'connected_clients_list.dart';
import 'network_status_banner.dart';
import 'pairing_card.dart';
import 'public_network_warning_dialog.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

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

    final status = <Widget>[
      NetworkStatusBanner(
        trust: provider.networkTrust,
        server: provider.server,
      ),
      Reveal(
        child: provider.pairingPaused
            ? const Padding(
                padding: EdgeInsets.only(top: AppSpace.xs),
                child: _PairingPausedBanner(),
              )
            : null,
      ),
    ];
    final pairing = PairingCard(
      provider: provider,
      revealed: _revealed,
      onRevealChanged: (revealed) => setState(() => _revealed = revealed),
    );
    final clients = Reveal(
      child: provider.connectedClients.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: ConnectedClientsList(
                clients: provider.connectedClients,
                onKick: provider.server.kickClient,
              ),
            ),
    );
    final stop = _StopButton(onStop: provider.stopServer);

    return LayoutBuilder(
      builder: (context, constraints) {
        // A wide window puts the code beside the status column.
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: FadeSlideIn(child: pairing)),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                flex: 4,
                child: FadeSlideIn(
                  index: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...status,
                        clients,
                        const SizedBox(height: AppSpace.lg),
                        Align(alignment: Alignment.centerLeft, child: stop),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...status,
            const SizedBox(height: AppSpace.sm),
            Flexible(child: FadeSlideIn(child: pairing)),
            clients,
            const SizedBox(height: AppSpace.md),
            Center(child: stop),
          ],
        );
      },
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onStop});

  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: context.l10n.stopServer,
      icon: Icons.power_settings_new_rounded,
      variant: AppButtonVariant.tonal,
      tone: AppTone.danger,
      expand: false,
      height: 46,
      onPressed: onStop,
    );
  }
}

class _PairingPausedBanner extends StatelessWidget {
  const _PairingPausedBanner();

  @override
  Widget build(BuildContext context) {
    return InlineAlert(
      tone: AppTone.danger,
      icon: Icons.gpp_maybe_rounded,
      message: context.l10n.pairingPaused,
    );
  }
}
