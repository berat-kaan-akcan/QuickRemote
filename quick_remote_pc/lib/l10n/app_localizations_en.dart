// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsHidePublicNetworkWarning => 'Hide Public Network Warnings';

  @override
  String get settingsHidePublicNetworkWarningSubtitle =>
      'Don\'t show a security warning when connected to a public network.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get close => 'Close';

  @override
  String get homeTagline => 'Presentation Control Center';

  @override
  String get refreshSlideState => 'Refresh Slide State';

  @override
  String get portsOpened => 'Ports opened in the firewall.';

  @override
  String get portsOpenFailed => 'Couldn\'t open the ports.';

  @override
  String get firewallDialogTitle => 'You Need to Open the Ports';

  @override
  String get firewallDialogContent =>
      'The firewall blocks the phone from connecting to this computer. To use the app, open ports 8090-8099.\n\nThe ports stay open in this network zone. Your administrator password will be asked once.';

  @override
  String get later => 'Later';

  @override
  String get openPortsButton => 'Open Ports';

  @override
  String get uinputNeeded => 'Keyboard/mouse simulation needs permission';

  @override
  String get grantPermission => 'Allow';

  @override
  String get uinputGranted => 'Input permission granted.';

  @override
  String get uinputFailed =>
      'Couldn\'t grant the permission. The administrator password is needed.';

  @override
  String get mdnsOff =>
      'Automatic discovery is off (avahi-daemon). Connect with the QR code or IP.';

  @override
  String get firewallBlocked =>
      'The firewall blocks the phone. Open the ports to use the app.';

  @override
  String get firewallUnknown =>
      'Couldn\'t read the firewall rules: ports 8090-8099 must be open';

  @override
  String get openPortsAction => 'Open ports';

  @override
  String get impressConnected => 'LibreOffice Impress connected';

  @override
  String get impressReadyWhenOpened =>
      'Impress: connects when LibreOffice opens';

  @override
  String get impressOff => 'Impress connection is off';

  @override
  String get enable => 'Enable';

  @override
  String get impressEnabled => 'Impress connection enabled.';

  @override
  String get libreOfficeWriteFailed =>
      'Couldn\'t write the LibreOffice setting.';

  @override
  String get impressLegacy =>
      'The Impress connection uses the old method: a port open to every user and app on this computer. Update it.';

  @override
  String get update => 'Update';

  @override
  String get impressUpdated =>
      'The Impress connection now uses the secure method.';

  @override
  String get impressLegacyRunning =>
      'The Impress connection uses the old method: a port open to every user and app on this computer. Close LibreOffice to update it.';

  @override
  String get libreOfficeNotListening =>
      'LibreOffice is open but doesn\'t accept connections';

  @override
  String get connect => 'Connect';

  @override
  String get libreOfficeListening => 'LibreOffice accepts the connection.';

  @override
  String get libreOfficeUnreachable => 'Couldn\'t reach LibreOffice.';

  @override
  String get libreOfficeMissing =>
      'No LibreOffice: presentations are controlled with keys only';

  @override
  String get unoMissing =>
      'python3 or LibreOffice Python (UNO) support was not found';

  @override
  String get wpsConnected =>
      'WPS connected: a presentation opened here is fully controlled';

  @override
  String get openPresentation => 'Open presentation';

  @override
  String get wpsReady =>
      'WPS: open the presentation here for slide numbers, notes and pen colors';

  @override
  String get wpsNoRpc =>
      'WPS is controlled with keys only. Install WPS support for full control (pywpsrpc, needs internet).';

  @override
  String get install => 'Install';

  @override
  String get wpsInstalled => 'WPS support installed.';

  @override
  String get wpsInstallFailed =>
      'Couldn\'t install WPS support (needs python3-venv and internet).';

  @override
  String get presentationsFileType => 'Presentations';

  @override
  String get wpsOpened =>
      'The presentation opened in WPS. You can start the show from the phone.';

  @override
  String get wpsOpenFailed => 'Couldn\'t open the presentation in WPS.';

  @override
  String get networkTrusted => 'Trusted Network';

  @override
  String get networkUntrusted => 'Untrusted Network';

  @override
  String get networkZoneUnknown => 'Unknown network type';

  @override
  String get networkPrivate => 'Private Network';

  @override
  String get networkPublic => 'Public Network';

  @override
  String get networkUnreadable => 'Couldn\'t read the network type';

  @override
  String get publicNetworkTitle => 'Public Network Warning';

  @override
  String get publicNetworkLinux =>
      'The firewall treats this network as untrusted. Other people on it can see your QuickRemote server.\n\nMake sure you are on a trusted network.';

  @override
  String get publicNetworkWindows =>
      'You are on a public network. Other people on it can see your QuickRemote server.\n\nMake sure you are on a trusted network.';

  @override
  String get openNetworkSettings => 'Open Network Settings';

  @override
  String get dontShowAgain => 'Don\'t show this warning again';

  @override
  String get stopServer => 'Stop Server';

  @override
  String get continueAction => 'Continue';

  @override
  String get loadingNetwork => 'Getting network details...';

  @override
  String get showCodeToPair => 'Show the code to pair another device';

  @override
  String get scanToConnect => 'Scan the QR code to connect';

  @override
  String get hideCode => 'Hide code';

  @override
  String securityCode(String code) {
    return 'Security code: $code';
  }

  @override
  String get pairingPaused =>
      'Too many wrong PIN attempts. Pairing is paused for 1 minute and the PIN was replaced.';

  @override
  String get showCode => 'Show code';

  @override
  String connectedDevices(int count) {
    return 'Connected devices ($count)';
  }

  @override
  String get removeDeviceTooltip =>
      'Disconnects it and replaces the PIN. Other devices stay connected.';

  @override
  String get removeDevice => 'Remove';

  @override
  String clientsConnected(int count) {
    return '$count Connected';
  }

  @override
  String get serverOff => 'Off';

  @override
  String get portsInUse =>
      'Couldn\'t start the server: the port is in use. Close the apps using ports 8090-8099 and try again.';

  @override
  String serverStartFailed(String error) {
    return 'Couldn\'t start the server: $error';
  }

  @override
  String portFallback(int port) {
    return 'Port 8090 is in use, so the server started on port $port.';
  }

  @override
  String get serverStopped => 'Server Stopped';

  @override
  String get serverStoppedHint =>
      'Start the server to connect from your phone\nand control your presentation.';

  @override
  String get opensslMissing =>
      'openssl was not found. Install the openssl package for the TLS certificate.';

  @override
  String tlsKeyReadable(String path) {
    return 'Other users can read the TLS key: $path';
  }
}
