import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/desktop_provider.dart';
import '../../providers/server_provider.dart';
import 'widgets/connected_clients_list.dart';
import 'widgets/linux_setup_panel.dart';
import 'widgets/pairing_card.dart';
import 'widgets/public_network_warning_dialog.dart';
import 'widgets/server_status_card.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/status_chip.dart';
import 'widgets/server_controls.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

/// The one screen. Narrow (the opening size): the server's status first,
/// then the code to pair with and the connected phones, and Start or Stop
/// across the bottom. Wider than 760 px: the status, phones and Stop in a
/// side pane, the code large beside it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebSocketServerProvider _provider = context
      .read<WebSocketServerProvider>();
  bool _hasShownDialogForCurrentRun = false;
  bool _isShowingNetworkDialog = false;

  /// The user asked to see the QR code and PIN after a phone paired.
  bool _revealed = false;

  static const _wideFrom = 760.0;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_checkAndShowWarning);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowWarning());
  }

  @override
  void dispose() {
    _provider.removeListener(_checkAndShowWarning);
    super.dispose();
  }

  void _checkAndShowWarning() {
    if (_provider.publicNetwork && _provider.isRunning) {
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
      builder: (ctx) => PublicNetworkWarningDialog(server: _provider.server),
    );
    _isShowingNetworkDialog = false;

    if (proceed != true && mounted) {
      await _provider.stopServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketServerProvider>();
    if (!provider.pairedOnce) _revealed = false;

    return Scaffold(
      // Static light pools; an endless animation would cost GPU for nothing.
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= _wideFrom
                ? _wide(context, provider)
                : _narrow(context, provider),
          ),
        ),
      ),
    );
  }

  bool _on(WebSocketServerProvider provider) =>
      provider.isRunning || provider.isStarting;

  PairingCard _pairing(
    WebSocketServerProvider provider, {
    required bool wide,
  }) => PairingCard(
    provider: provider,
    revealed: _revealed,
    onRevealChanged: (revealed) => setState(() => _revealed = revealed),
    wide: wide,
  );

  /// The status rows that follow the status card, each with the gap above it.
  List<Widget> _statusRows(
    WebSocketServerProvider provider, {
    required bool framed,
  }) => [
    ..._desktopRows(),
    if (Platform.isLinux)
      LinuxSetupPanel(provider: provider, framed: framed, topGap: AppSpace.sm),
    Reveal(
      child: provider.pairingPaused
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: InlineAlert(
                tone: AppTone.danger,
                icon: Icons.gpp_maybe_rounded,
                message: context.l10n.pairingPaused,
              ),
            )
          : null,
    ),
  ];

  /// The server held back on a public network, and a newer version. Not
  /// shown where no [DesktopProvider] runs (tests).
  List<Widget> _desktopRows() {
    final desktop = context.watch<DesktopProvider?>();
    if (desktop == null) return const [];
    final l10n = context.l10n;
    final update = desktop.update;
    return [
      Reveal(
        child: desktop.heldBack
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: InlineAlert(
                  tone: AppTone.warning,
                  icon: Icons.public_rounded,
                  message: l10n.serverHeldBack,
                ),
              )
            : null,
      ),
      Reveal(
        child: update != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: InlineAlert(
                  dense: true,
                  icon: Icons.system_update_alt_rounded,
                  message: l10n.updateAvailable(update.version.toString()),
                  actionLabel: l10n.updateDownload,
                  onAction: desktop.openUpdate,
                ),
              )
            : null,
      ),
    ];
  }

  Widget _clients(WebSocketServerProvider provider, {required bool framed}) =>
      Reveal(
        // The side pane says when no phone has connected yet.
        child: !provider.isRunning || (framed && provider.connectedClients.isEmpty)
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: ConnectedClientsList(
                  clients: provider.connectedClients,
                  onKick: provider.server.kickClient,
                  framed: framed,
                ),
              ),
      );

  Widget _narrow(BuildContext context, WebSocketServerProvider provider) {
    final on = _on(provider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, AppSpace.md, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(provider: provider),
          const SizedBox(height: AppSpace.sm),
          // A short window scrolls; Start and Stop stay at the bottom.
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: ServerStatusCard(provider: provider)),
                      ..._statusRows(provider, framed: true),
                      const SizedBox(height: AppSpace.sm),
                      if (on) ...[
                        FadeSlideIn(
                          index: 1,
                          child: _pairing(provider, wide: false),
                        ),
                        _clients(provider, framed: true),
                        const Spacer(),
                      ] else
                        const Expanded(child: StoppedPanel()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          ServerToggleButton(provider: provider),
        ],
      ),
    );
  }

  Widget _wide(BuildContext context, WebSocketServerProvider provider) {
    final p = context.palette;
    final on = _on(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: _Header(provider: provider),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 400,
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(right: BorderSide(color: p.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(
                              child: ServerStatusCard(provider: provider),
                            ),
                            ..._statusRows(provider, framed: false),
                            _clients(provider, framed: false),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    ServerToggleButton(provider: provider),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.slow),
                    switchInCurve: AppMotion.enter,
                    switchOutCurve: AppMotion.exit,
                    child: on
                        ? Center(
                            key: const ValueKey('pairing'),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: FadeSlideIn(
                                child: _pairing(provider, wide: true),
                              ),
                            ),
                          )
                        : const StoppedPanel(
                            key: ValueKey('stopped'),
                            framed: false,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        const BrandTile(size: 42),
        const SizedBox(width: 10),
        // One line each: wrapped header text took the room the code needs.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BrandWordmark(fontSize: 20, suffix: 'PC'),
              ),
              Text(
                context.l10n.homeTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodySmall.copyWith(
                  color: p.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (provider.isRunning) ...[
          _HeaderKey(
            icon: Icons.refresh_rounded,
            tooltip: context.l10n.refreshSlideState,
            onTap: provider.triggerSlideStateUpdate,
          ),
          const SizedBox(width: AppSpace.xs),
        ],
        StatusChip(
          isRunning: provider.isRunning,
          clientCount: provider.clientCount,
        ),
        const SizedBox(width: AppSpace.xs),
        _HeaderKey(
          icon: Icons.settings_rounded,
          tooltip: context.l10n.settingsTitle,
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => const SettingsDialog(),
          ),
        ),
      ],
    );
  }
}

/// A square key on the surface in the header.
class _HeaderKey extends StatelessWidget {
  const _HeaderKey({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      tooltip: tooltip,
      semanticLabel: tooltip,
      pressedScale: 0.9,
      hoveredScale: 1.06,
      borderRadius: radius,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: radius,
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, size: 20, color: p.textSecondary),
      ),
    );
  }
}
