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
      'WPS is in basic mode: you can move between slides, but the phone can\'t show slide numbers or notes. Press \"Install\" for full control (needs internet once).';

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
  String get wpsUserStarted =>
      'You opened WPS yourself: the phone drives it with keys only, without slide numbers or notes. \"Take over\" closes WPS and opens the presentation in QuickRemote\'s WPS at the same slide.';

  @override
  String get takeOver => 'Take over';

  @override
  String get wpsTakenOver => 'The presentation is open in QuickRemote\'s WPS.';

  @override
  String get wpsTakeOverNoWps => 'No open WPS was found.';

  @override
  String get wpsTakeOverNoFile =>
      'The presentation isn\'t saved: save it in WPS first.';

  @override
  String get wpsTakeOverNotClosed =>
      'WPS didn\'t close: answer its save question and try again.';

  @override
  String get wpsTakeOverFailed =>
      'Couldn\'t open the presentation in QuickRemote\'s WPS.';

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
      'Start the server to connect from your phone and control your presentation.';

  @override
  String get opensslMissing =>
      'openssl was not found. Install the openssl package for the TLS certificate.';

  @override
  String tlsKeyReadable(String path) {
    return 'Other users can read the TLS key: $path';
  }

  @override
  String get startServer => 'Start Server';

  @override
  String get serverRunning => 'Server Running';

  @override
  String get serverStarting => 'Starting the server';

  @override
  String get serverStoppedSubtitle => 'Start it to connect from your phone.';

  @override
  String get waitingForPhone => 'Waiting for a phone';

  @override
  String get linuxSetupHeader => 'Setup · Linux';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceNote =>
      'When the screen is projected in a bright room, Light reads better.';

  @override
  String get settingsLaser => 'Laser';

  @override
  String get laserOverlayAuto => 'Automatic';

  @override
  String get laserOverlayAlways => 'QuickRemote';

  @override
  String get laserOverlayNever => 'Program';

  @override
  String get laserOverlayNote =>
      'QuickRemote draws the laser above every window: over Impress videos, in PDFs, in browsers and outside a slideshow too. Automatic leaves PowerPoint and WPS their own laser. The laser outside a slideshow turns on when the phone reconnects.';

  @override
  String phonesConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phones connected',
      one: '1 phone connected',
    );
    return '$_temp0';
  }

  @override
  String get noPhonesYet => 'No phone has connected yet.';

  @override
  String get settingsStartup => 'Startup and tray';

  @override
  String get settingsCloseToTray => 'Minimize to tray on close';

  @override
  String get settingsCloseToTraySubtitle =>
      'Closing the window keeps QuickRemote running in the tray; connected phones stay connected.';

  @override
  String get settingsNoTray =>
      'This desktop has no system tray, so closing the window quits the app. On GNOME the AppIndicator extension adds one.';

  @override
  String get settingsLaunchAtLogin => 'Start at login';

  @override
  String get settingsLaunchAtLoginSubtitle =>
      'Starts in the tray, without a window.';

  @override
  String get settingsStartServerOnLaunch => 'Start the server on launch';

  @override
  String get settingsStartServerOnLaunchSubtitle =>
      'On a public network the server does not start by itself.';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsCheckUpdatesSubtitle =>
      'Asks GitHub for a new version at launch and once a day; downloads nothing. GitHub sees your IP address when it does.';

  @override
  String get autostartFailed => 'Couldn\'t change the start at login setting.';

  @override
  String updateAvailable(String version) {
    return 'New version: $version';
  }

  @override
  String get updateDownload => 'Download';

  @override
  String get serverHeldBack =>
      'You\'re on a public network, so the server didn\'t start by itself. Start it if you trust this network.';

  @override
  String get trayShow => 'Show';

  @override
  String get trayStartServer => 'Start the server';

  @override
  String get trayStopServer => 'Stop the server';

  @override
  String trayPhones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phones connected',
      one: '1 phone connected',
      zero: 'No phone connected',
    );
    return '$_temp0';
  }

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayTooltipOff => 'QuickRemote PC · Server off';

  @override
  String get trayTooltipOn => 'QuickRemote PC · Server on';

  @override
  String get trayTooltipHeldBack =>
      'QuickRemote PC · Public network: server not started';

  @override
  String get trayNoticeTitle => 'QuickRemote keeps running';

  @override
  String get trayNoticeBody =>
      'The window is closed, but the server and connected phones keep running. Open the window from the tray icon, and quit with Quit there. If \"Minimize to tray on close\" is turned off in Settings, closing the window quits the app.';

  @override
  String get trayNoticeOk => 'Got it';

  @override
  String get settingsTroubleshooting => 'Troubleshooting';

  @override
  String get settingsExportLog => 'Export log';

  @override
  String get settingsReportProblem => 'Report a problem';

  @override
  String get settingsLogPrivacy =>
      'The log stays on this computer and is never sent anywhere by itself. PINs, pairing codes, security codes, notes and file paths are not written; IP addresses and device names are. \"Report a problem\" opens a new issue on GitHub; you attach the log there yourself.';

  @override
  String get logExported => 'Log saved.';

  @override
  String get logExportFailed => 'Could not save the log.';

  @override
  String issueBody(String version, String platform, String presenters) {
    return '**What happened?**\n\n\n**How can it be reproduced?**\n\n\n---\nQuickRemote PC $version\nPlatform: $platform\nPrograms: $presenters\n\nYou can drag the log (Settings → Export log) onto this page.';
  }

  @override
  String get startErrorPortsInUse =>
      'ports 8090-8099 are in use. Close the apps using them and try again.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'QuickRemote PC $version';
  }

  @override
  String get settingsLicenses => 'Open-source licenses';
}
