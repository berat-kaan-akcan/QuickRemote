import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/background_session.dart';
import '../../services/bluetooth/bt_hid_service.dart';
import '../bt_remote/bt_remote_screen.dart';
import '../../utils/ui/app_top_bar.dart';
import 'widgets/bt_pairing_guide.dart';
import 'widgets/bt_status_views.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

/// Bluetooth Classic HID connection screen.
/// Registers the phone as a BT HID device and guides the user through
/// pairing on the computer, then navigates to [BtRemoteScreen] on success.
///
/// Android drops the HID registration of an app that leaves the foreground
/// without a foreground service, e.g. for its own Bluetooth settings while the
/// computer pairs, which would then pair without our record. So this screen
/// holds a [BackgroundSession] too, and registers again when the app returns.
class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _bt = BtHidService.instance;
  StreamSubscription<BtHidConnectionState>? _sub;
  late AnimationController _pulseController;

  BtHidConnectionState _state = BtHidConnectionState.disconnected;

  /// The phone has waited for a computer: a later disconnect means retrying,
  /// not preparing.
  bool _advertised = false;
  String? _errorMessage;
  bool _holdsBackground = false;

  /// The error on screen is the refused Bluetooth permission; [_permanentlyDenied]
  /// when Android no longer asks and only the settings can give it.
  bool _permissionError = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addObserver(this);
    _sub = _bt.stateStream.listen(_onStateChanged);
    _startAdvertising();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_permissionError) {
      // Back from the settings: go on if the permission was given there.
      Permission.bluetoothConnect.isGranted.then((granted) {
        if (granted && mounted && _permissionError) _retry();
      });
      return;
    }
    _bt.ensureConnected();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The breathing texts hold still when the system asks for less motion.
    if (AppMotion.reduced(context)) {
      _pulseController.stop();
      _pulseController.value = 1;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _pulseController.dispose();
    if (_holdsBackground) BackgroundSession.release();
    // Don't stop advertising if we successfully connected (screen popped but BT still active)
    if (_state != BtHidConnectionState.connected) {
      _bt.stopAdvertising();
    }
    super.dispose();
  }

  Future<void> _startAdvertising() async {
    final supported = await _bt.isSupported();
    if (!mounted) return;

    if (!supported) {
      setState(() {
        _state = BtHidConnectionState.unsupported;
        _errorMessage = context.l10n.btUnsupportedLong;
      });
      return;
    }

    // CONNECT for the HID profile; ADVERTISE is asked for only when the user
    // makes the phone visible. Below Android 12 permission_handler reports it
    // as granted.
    final statuses = await [Permission.bluetoothConnect].request();

    final connectStatus = statuses[Permission.bluetoothConnect];
    if (connectStatus == PermissionStatus.denied ||
        connectStatus == PermissionStatus.permanentlyDenied) {
      // A permission refused for good in an earlier run comes back as plain
      // denied, without a dialog; Android asks again only while it would show
      // a rationale. Otherwise "Allow" would do nothing, so send to Settings.
      final permanently =
          connectStatus == PermissionStatus.permanentlyDenied ||
          !await Permission.bluetoothConnect.shouldShowRequestRationale;
      if (!mounted) return;
      setState(() {
        _state = BtHidConnectionState.error;
        _permissionError = true;
        _permanentlyDenied = permanently;
        _errorMessage = permanently
            ? '${context.l10n.btPermissionDenied}\n\n${context.l10n.btPermissionSettingsHint}'
            : context.l10n.btPermissionDenied;
      });
      return;
    }

    // Before registering: the dialogs it may open (notifications, battery
    // optimization) would put the app in the background and drop the
    // registration.
    if (!_holdsBackground) {
      _holdsBackground = true;
      await BackgroundSession.acquire();
      if (!mounted) return;
    }
    await _bt.startAdvertising();
  }

  void _onStateChanged(BtHidConnectionState state) {
    if (!mounted) return;
    // A permission error stays until the permission is given (_retry).
    if (_permissionError) return;
    setState(() {
      _state = state;
      if (state != BtHidConnectionState.disconnected) _advertised = true;
      if (state == BtHidConnectionState.error) {
        _errorMessage = switch (_bt.errorReason) {
          'hid_unavailable' => context.l10n.btHidUnavailable,
          _ => context.l10n.btErrorRetry,
        };
      }
    });
    if (state == BtHidConnectionState.connected) {
      // Small delay so user sees "Bağlandı!" before navigating
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_state != BtHidConnectionState.connected) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BtRemoteScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.l10n.homeConnectBluetooth),
      body: SafeArea(top: false, child: ContentWidth(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    final p = context.palette;
    final l10n = context.l10n;
    void cancel() => Navigator.of(context).pop();
    final target = _bt.targetName;
    final body = switch (_state) {
      BtHidConnectionState.unsupported => BtStateView(
        icon: Icons.bluetooth_disabled_rounded,
        color: p.textMuted,
        neutral: true,
        title: l10n.btUnsupported,
        message: _errorMessage ?? l10n.btUnsupportedShort,
        actions: [AppButton(label: l10n.btUseWifi, icon: Icons.wifi_rounded, onPressed: cancel)],
      ),
      BtHidConnectionState.error when _permissionError => BtStateView(
        icon: Icons.devices_other_rounded,
        color: p.warning,
        title: l10n.btPermissionTitle,
        message: l10n.btPermissionDenied,
        actions: [
          _permanentlyDenied
              ? AppButton(label: l10n.btPermissionSettings, icon: Icons.settings_rounded, onPressed: openAppSettings)
              : AppButton(label: l10n.btPermissionAllow, onPressed: _retry),
          if (_permanentlyDenied) BtActionHint(l10n.btPermissionSettingsHint),
        ],
      ),
      BtHidConnectionState.error => BtStateView(
        icon: Icons.error_rounded,
        color: p.danger,
        title: l10n.errorTitle,
        message: _errorMessage ?? l10n.btErrorOccurred,
        actions: [AppButton(label: l10n.tryAgain, icon: Icons.refresh_rounded, onPressed: _retry)],
      ),
      BtHidConnectionState.bluetoothOff => BtStateView(
        icon: Icons.bluetooth_disabled_rounded,
        color: p.textMuted,
        neutral: true,
        title: l10n.btOffTitle,
        message: l10n.btOffBody,
        actions: [
          AppButton(label: l10n.btTurnOn, icon: Icons.bluetooth_rounded, tone: AppTone.info, onPressed: _bt.requestEnable),
        ],
      ),
      BtHidConnectionState.connected => BtStateView(
        icon: Icons.check_circle_rounded,
        color: p.success,
        title: l10n.btConnected,
        message: '${_bt.connectedDeviceName ?? l10n.unknownDevice} · ${l10n.btOpeningRemote}',
      ),
      BtHidConnectionState.hostUnaware => BtHostSetupView(dots: _pulseController),
      BtHidConnectionState.refreshing => BtWaitingView(
        icon: Icons.sync_rounded,
        title: l10n.btHostRefreshing,
        message: l10n.btRefreshingBody,
        dots: _pulseController,
        onCancel: cancel,
      ),
      // Trying a computer the phone knows.
      BtHidConnectionState.advertising when target != null => BtWaitingView(
        icon: Icons.bluetooth_connected_rounded,
        title: l10n.btConnectingTo(target),
        message: l10n.btConnectingBody,
        dots: _pulseController,
        onCancel: cancel,
      ),
      BtHidConnectionState.advertising => BtPairingView(dots: _pulseController, onCancel: cancel),
      // Down after it was up: the phone tries again by itself.
      _ when _advertised => BtWaitingView(
        icon: Icons.bluetooth_searching_rounded,
        title: l10n.btNotConnectedRetrying,
        message: target != null ? l10n.btRetryingBody(target) : l10n.btRetryingBodyUnknown,
        dots: _pulseController,
        onCancel: cancel,
      ),
      _ => BtWaitingView(
        icon: Icons.bluetooth_searching_rounded,
        title: l10n.btPreparing,
        message: l10n.btPreparingBody,
        dots: _pulseController,
        onCancel: cancel,
      ),
    };
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.slow),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      child: KeyedSubtree(
        key: ValueKey((_state, _permissionError, _state == BtHidConnectionState.advertising && target != null)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
          child: body,
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _state = BtHidConnectionState.disconnected;
      _advertised = false;
      _errorMessage = null;
      _permissionError = false;
      _permanentlyDenied = false;
    });
    _startAdvertising();
  }
}
