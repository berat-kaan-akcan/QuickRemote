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
  String get settingsTimerTitle => 'Presentation Timer';

  @override
  String get settingsTimerSubtitle =>
      'Auto start, vibration and early warnings';

  @override
  String get settingsHistoryTitle => 'Presentation History';

  @override
  String get settingsHistorySubtitle =>
      'Statistics and notes from earlier presentations';

  @override
  String get settingsKeepInkTitle => 'Keep Drawings When the Slide Changes';

  @override
  String get settingsKeepInkSubtitle =>
      'Drawings stay on their slide and reappear when you return to it. When off, pen drawings are erased as you go forward or back.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get errorSlideshowNotRunning => 'No slideshow is running.';

  @override
  String get errorSlideshowStartFailed => 'Couldn\'t start the slideshow.';

  @override
  String errorSlideStateFailed(String info) {
    return 'Couldn\'t read the slide state: $info';
  }

  @override
  String get errorPresenterNotResponding =>
      'The presentation program is not responding.';

  @override
  String get errorPresenterUnreachable =>
      'Couldn\'t reach the presentation program.';

  @override
  String get errorPenColorFailed => 'Couldn\'t change the pen color.';

  @override
  String get errorInkEraseFailed => 'Couldn\'t erase the ink.';

  @override
  String get errorPointerBusy =>
      'Another device is using the laser or pen right now.';

  @override
  String get errorNoMedia => 'This slide has no media.';

  @override
  String get errorMediaReloaded =>
      'The slide was reloaded and the video restarted. Try again to control it.';

  @override
  String get errorMediaNoTrigger =>
      'The media on this slide can\'t be controlled from the remote.';

  @override
  String get errorMediaNeedsFullscreen =>
      'Slide media can only be controlled in a full-screen slideshow.';

  @override
  String get errorScreenBlanked =>
      'Slide media can\'t be controlled while the screen is blanked.';

  @override
  String get errorImpressUnreachable =>
      'Couldn\'t connect to LibreOffice Impress.';

  @override
  String get errorImpressNoUno =>
      'LibreOffice Python (UNO) support was not found.';

  @override
  String get errorImpressUntrustedPipe =>
      'The LibreOffice connection socket belongs to another user, so QuickRemote didn\'t connect.';

  @override
  String get errorWpsNotInstalled => 'WPS support is not installed.';

  @override
  String get errorWpsNoPresentation => 'No presentation is open in WPS.';

  @override
  String get errorWpsStartFailed => 'Couldn\'t start WPS.';

  @override
  String get errorWpsOpenFromApp =>
      'In WPS this only works in a presentation opened from QuickRemote (\"Open presentation with WPS\").';

  @override
  String get errorWpsHighlighterNeedsFocus =>
      'In WPS the highlighter can only be selected while the slideshow has the focus.';

  @override
  String get errorWpsNoMediaRewind => 'WPS can\'t rewind the video.';

  @override
  String get errorLockFailed => 'Couldn\'t lock the computer.';

  @override
  String errorCommandFailed(String info) {
    return 'Presentation command failed: $info';
  }

  @override
  String get errorUnknown => 'The action failed.';

  @override
  String get connectionPinEmpty => 'The PIN can\'t be empty.';

  @override
  String get connectionWrongPin => 'Wrong PIN.';

  @override
  String get connectionRateLimited =>
      'Too many wrong attempts. Try again in a minute.';

  @override
  String get connectionTimeout => 'The connection timed out.';

  @override
  String get connectionAuthTimeout => 'Authentication timed out.';

  @override
  String connectionServerNotFound(String detail) {
    return 'Couldn\'t reach the server: $detail';
  }

  @override
  String get connectionCertMismatch =>
      'The certificate changed! This may be a MITM attack, or the PC was reinstalled.';

  @override
  String get connectionCertRejected =>
      'The PC\'s certificate doesn\'t match the QR code. The connection isn\'t safe, so QuickRemote didn\'t connect. Scan the QR code again.';

  @override
  String get connectionUnverified =>
      'First connection to this PC: compare the security code.';

  @override
  String get connectionClosedByPc =>
      'The PC disconnected this device. Scan the QR code again to reconnect.';

  @override
  String get connectionClosed => 'The connection closed unexpectedly.';

  @override
  String connectionUnknown(String detail) {
    return 'Connection error: $detail';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeTagline => 'Control your presentations from your phone';

  @override
  String get homeConnecting => 'Connecting...';

  @override
  String get homeConnectQr => 'Connect with QR Code';

  @override
  String get homeConnectBluetooth => 'Connect with Bluetooth';

  @override
  String get homeManualConnection => 'Manual connection';

  @override
  String get homeNetworkDevices => 'Devices on the Network';

  @override
  String get homeSearching => 'Searching for devices...';

  @override
  String get homeNoDevices => 'No devices found on the network';

  @override
  String get homeRescan => 'Scan Again';

  @override
  String get homeRecent => 'Recent Connections';

  @override
  String get homeRemoveFromHistory => 'Remove from History';

  @override
  String get unknownPc => 'Unknown PC';

  @override
  String get verifyTitle => 'Compare the Security Code';

  @override
  String verifyContent(String code) {
    return 'This is your first connection to this PC. The security code on the PC screen should be:\n\n$code\n\nIf the codes differ, don\'t connect: another device on the network may be pretending to be the PC. Scanning the QR code skips this step.';
  }

  @override
  String get verifyConfirm => 'Codes Match, Connect';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get certWarningTitle => 'Security Warning';

  @override
  String certWarningContent(String code) {
    return 'This device\'s identity (certificate) differs from the one saved earlier.\n\nThis is normal if you reinstalled your PC or renewed the certificate. The security code on the PC screen should be:\n\n$code\n\nIf the codes differ, don\'t connect.';
  }

  @override
  String get certWarningConfirm => 'Connect Anyway and Update';

  @override
  String get manualTitle => 'Manual Connection';

  @override
  String get manualIp => 'IP Address';

  @override
  String get manualPinHint => 'PIN shown on the PC';

  @override
  String get manualConnect => 'Connect';

  @override
  String get manualWaitingIp => 'Waiting for IP...';

  @override
  String get manualWaitingPin => 'Waiting for PIN...';

  @override
  String get manualPortRange => 'Port must be between 1 and 65535';

  @override
  String get qrNotQuickRemote =>
      'Invalid QR code. Expected the \"quickremote://\" format.';

  @override
  String get qrMissingHost => 'The QR code has no IP address.';

  @override
  String get qrInvalidPort => 'The QR code has an invalid port number.';

  @override
  String get qrInvalidPin =>
      'The PIN in the QR code is invalid. Scan the code again.';

  @override
  String get qrInvalidFingerprint =>
      'The certificate data in the QR code is corrupt. Scan the code again.';

  @override
  String get qrBadFormat =>
      'The QR code is not in the expected format.\nFormat: quickremote://IP:PORT:PIN';

  @override
  String get scanTitle => 'Scan QR Code';

  @override
  String get scanHint => 'Scan the QR code on the PC screen';

  @override
  String get remoteConnectionLost => 'Connection lost, reconnecting...';

  @override
  String get remoteReconnected => 'Reconnected!';

  @override
  String get remoteTabControls => 'Controls';

  @override
  String get remoteTabTouchpad => 'Touchpad';

  @override
  String get remoteTabMedia => 'Media';

  @override
  String get remoteConnectFailedTitle => 'Couldn\'t Connect';

  @override
  String get remoteServerUnreachable =>
      'Can\'t reach the server. Make sure the PC app is running.';

  @override
  String get remoteBackHome => 'Back to Home';

  @override
  String get remoteReconnect => 'Reconnect';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get disconnectTitle => 'Disconnect';

  @override
  String get disconnectContent => 'Disconnect and go back to the home screen?';

  @override
  String get notesTitle => 'Slide Notes';

  @override
  String get notesEmpty => 'This slide has no notes.';

  @override
  String get startPresentation => 'Start Presentation';

  @override
  String slidePickerRange(int total) {
    return 'Slide (1-$total)';
  }

  @override
  String get slidePickerHint => 'Slide Number (e.g. 5)';

  @override
  String slidePickerMax(int total) {
    return 'You can enter up to slide $total.';
  }

  @override
  String get slidePickerEmpty => 'Leave empty to start from the beginning.';

  @override
  String get actionStart => 'Start';

  @override
  String slidePickerInvalid(int max) {
    return 'Enter a valid slide number (1-$max)';
  }

  @override
  String get slideshowOpen => 'Slideshow is running';

  @override
  String slideCounter(int current, String total) {
    return 'Slide: $current / $total';
  }

  @override
  String get notes => 'Notes';

  @override
  String presentationNotOpen(String programs) {
    return 'No Presentation Open, start $programs';
  }

  @override
  String get actionEnd => 'End';

  @override
  String get blackScreen => 'Black Screen';

  @override
  String get whiteScreen => 'White Screen';

  @override
  String get actionPrev => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get listOr => ' or ';

  @override
  String get mediaControlTitle => 'Media Control';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get systemVolume => 'System Volume';

  @override
  String get slideMedia => 'Slide Media';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorWhite => 'White';

  @override
  String get colorPurple => 'Purple';

  @override
  String get penColorTitle => 'Pen Color';

  @override
  String get highlighterColorTitle => 'Highlighter Color';

  @override
  String get toolPen => 'Pen';

  @override
  String get toolHighlight => 'Highlight';

  @override
  String get toolEraser => 'Eraser';

  @override
  String selectTool(String tool) {
    return 'Select the $tool tool';
  }

  @override
  String get clearInk => 'Clear';

  @override
  String get clearInkTooltip => 'Clear all drawings';

  @override
  String get toolLaser => 'Laser';

  @override
  String get unknownMedia => 'Unknown Media';

  @override
  String get noMedia => 'No Media';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get nothingPlaying => 'Nothing is playing';

  @override
  String get mediaPause => 'Pause';

  @override
  String get mediaPlay => 'Play';

  @override
  String get mediaRewind => 'Rewind';

  @override
  String get toolHighlighter => 'Highlighter';

  @override
  String tapForTool(String tool) {
    return 'Single tap → $tool';
  }

  @override
  String get doubleTapSelected => 'Double tap → Selected Tool';

  @override
  String get volumeMuted => 'Muted';

  @override
  String get volumeOn => 'On';

  @override
  String get btUnsupportedLong =>
      'This device doesn\'t support Bluetooth HID.\nUse Wi-Fi mode.';

  @override
  String get btPermissionDenied =>
      'Bluetooth permission was denied. Allow it in Settings.';

  @override
  String get btDisabled => 'Bluetooth is off. Turn it on and try again.';

  @override
  String btConnectingTo(String device) {
    return 'Connecting to $device...';
  }

  @override
  String get btMakeVisible => 'Make the phone visible';

  @override
  String get btMakeVisibleHint =>
      'The computer finds the phone in its list only while the phone is visible.';

  @override
  String btVisibleFor(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'The phone is visible for $minutes minutes.',
      one: 'The phone is visible for 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get btVisibleRefused => 'The phone was not made visible.';

  @override
  String get btHidUnavailable =>
      'The phone could not register as a keyboard. If another Bluetooth keyboard app is open, close it and try again.';

  @override
  String get btHostRefreshing =>
      'QuickRemote PC is preparing the connection...';

  @override
  String get btHostUnawareTitle =>
      'The computer doesn\'t know the phone as a keyboard';

  @override
  String get btHostUnawareBody =>
      'The phone was paired with this computer while QuickRemote was not open. Do this once on the computer:';

  @override
  String get btHostUnawareWindows =>
      'In Settings → Bluetooth & devices, remove the phone, then add it again while this screen is open.';

  @override
  String get btHostUnawareLinux =>
      'In the Bluetooth settings, disconnect the phone and connect it again. If that doesn\'t help, remove the phone and pair it again while this screen is open.';

  @override
  String get btHostUnawareAuto =>
      'If QuickRemote PC is open on the computer, it does this by itself.';

  @override
  String get btHostUnawareWaiting =>
      'The remote opens by itself once the computer accepts it.';

  @override
  String get btErrorRetry => 'Bluetooth error. Try again.';

  @override
  String get btWaitingPairing => 'Waiting for pairing...';

  @override
  String get btWaitingConnection => 'Waiting for connection...';

  @override
  String get btPreparing => 'Preparing...';

  @override
  String get btNotConnectedRetrying => 'Not connected, retrying';

  @override
  String get btOnYourComputer => 'On your computer:';

  @override
  String get btLinuxStep1 =>
      'Open System Settings (KDE: Bluetooth, GNOME: Settings → Bluetooth)';

  @override
  String get btLinuxStep2 => 'Make sure Bluetooth is on';

  @override
  String get btLinuxStep3 => 'Start \"Add new device\" / a device search';

  @override
  String get btStepPickPhone => 'Pick your phone\'s name from the list';

  @override
  String get btStepConfirm => 'Confirm the pairing';

  @override
  String get btWindowsStep1 => 'Open Windows Settings';

  @override
  String get btWindowsStep2 => 'Go to Bluetooth & devices';

  @override
  String get btWindowsStep3 => 'Press \"Add device\"';

  @override
  String get btPairOnce =>
      'Pair once while this screen is open; later connections are automatic.';

  @override
  String get btConnected => 'Connected!';

  @override
  String get unknownDevice => 'Unknown device';

  @override
  String get btOpeningRemote => 'Opening the remote...';

  @override
  String get btUnsupported => 'Not Supported';

  @override
  String get btUnsupportedShort =>
      'This device doesn\'t support Bluetooth HID.';

  @override
  String get btUseWifi => 'Use Wi-Fi Mode';

  @override
  String get errorTitle => 'Error';

  @override
  String get btErrorOccurred => 'A Bluetooth error occurred.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get btConnectionLost => 'Bluetooth connection lost. Reconnecting...';

  @override
  String btConnectedTo(String device) {
    return 'Bluetooth connected: $device';
  }

  @override
  String get btDisconnectContent =>
      'The Bluetooth connection will close and you will return to the home screen.';

  @override
  String get btModeTitle => 'Bluetooth HID Mode';

  @override
  String get systemMedia => 'System Media';

  @override
  String get btMediaLimits =>
      'Bluetooth mode can\'t show media info or the volume level, and has no PowerPoint media controls. Use Wi-Fi mode for every feature.';

  @override
  String get btNoMediaInfo => 'No media info in BT mode';

  @override
  String get mediaPlayPause => 'Play / Pause';

  @override
  String get toolCursor => 'Cursor';

  @override
  String get btTarget => 'Target:';

  @override
  String durationHms(int h, int m, int s) {
    return '${h}h ${m}m ${s}s';
  }

  @override
  String durationMs(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String durationS(int s) {
    return '${s}s';
  }

  @override
  String durationMinutes(int m) {
    return '$m min';
  }

  @override
  String durationMinSec(int m, int s) {
    return '$m min $s s';
  }

  @override
  String durationSeconds(int s) {
    return '$s s';
  }

  @override
  String get timerSettingsTitle => 'Presentation Timer';

  @override
  String get timerAutoStartTitle => 'Start as Soon as a Time Is Picked';

  @override
  String get timerAutoStartSubtitle =>
      'When off, tap the timer to start it after picking a time.';

  @override
  String get earlyWarningTitle => 'Early Warning Vibration';

  @override
  String get earlyWarningSubtitle => 'Vibrates when the chosen times are left.';

  @override
  String get warningTimes => 'Warning Times';

  @override
  String get noWarningTimes => 'No warning times yet.';

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String get addWarning => 'Add Warning';

  @override
  String get whenTimeIsUp => 'When Time Is Up';

  @override
  String get endVibration => 'End Vibration';

  @override
  String get vibrationPattern => 'Vibration Pattern';

  @override
  String vibrationFor(String time) {
    return 'Vibration at $time Left';
  }

  @override
  String get tapToPreview => 'Tap an option to preview it';

  @override
  String get vibrationShort => 'Short Vibration';

  @override
  String get vibrationDouble => 'Double Vibration';

  @override
  String get vibrationLong => 'Long Vibration';

  @override
  String get vibrationTriple => 'Triple Vibration';

  @override
  String get newWarningTime => 'New Warning Time';

  @override
  String get enterTime => 'Enter a time';

  @override
  String get unitSecondsLong => 'Seconds';

  @override
  String get unitMinutesLong => 'Minutes';

  @override
  String get enterValidNumber => 'Enter a valid number.';

  @override
  String get add => 'Add';

  @override
  String get patternShort => 'Short';

  @override
  String get patternLong => 'Long';

  @override
  String get patternTriple => 'Triple';

  @override
  String get patternDouble => 'Double';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get noHistory => 'No presentation data yet';

  @override
  String get noHistoryHint =>
      'Data shows up here after you\nstart and end a presentation.';

  @override
  String get historyDeleted => 'Presentation record deleted';

  @override
  String slideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slides',
      one: '1 slide',
    );
    return '$_temp0';
  }

  @override
  String get clearHistoryContent =>
      'All presentation history will be deleted. This can\'t be undone.';

  @override
  String get clear => 'Clear';

  @override
  String get historyCleared => 'Presentation history cleared';

  @override
  String get timeUp => 'Time\'s up!';

  @override
  String timeRemaining(String time) {
    return '$time left!';
  }

  @override
  String get enterValidDuration =>
      'Enter a valid time in minutes and/or seconds.';

  @override
  String get setPresentationTime => 'Set Presentation Time';

  @override
  String get noTimeLimit => 'No Limit';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitSeconds => 'sec';

  @override
  String get startWhenPicked => 'Start as soon as picked';

  @override
  String get timerHelp =>
      'Tap: start/pause · Hold: new time · ↻: back to the picked time';

  @override
  String get actionSet => 'Set';

  @override
  String get reportTitle => 'Presentation Report';

  @override
  String get totalTime => 'Total Time';

  @override
  String get slideCountLabel => 'Slides';

  @override
  String get avgPerSlideShort => 'Avg/Slide';

  @override
  String totalTransitions(int count) {
    return 'Transitions: $count';
  }

  @override
  String get timePerSlide => 'Time per Slide';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get ok => 'OK';

  @override
  String get presentationDetails => 'Presentation Details';

  @override
  String get reportDate => 'Date';

  @override
  String get reportAvgPerSlide => 'Avg. Time/Slide';

  @override
  String get reportTransitions => 'Transitions';

  @override
  String get reportSlideDetails => 'Slide Details';

  @override
  String reportSlide(int n) {
    return 'Slide $n';
  }

  @override
  String get reportCopied => 'Report copied to clipboard';

  @override
  String get noSlideData => 'No slide data';

  @override
  String get backgroundNotification => 'Staying connected in the background...';

  @override
  String get homeHeroSubtitle =>
      'Scan the QR code shown by QuickRemote PC, or connect the phone over Bluetooth as a keyboard and mouse.';

  @override
  String get slideLabel => 'Slide';

  @override
  String get settingsSectionPresentation => 'Presentation';

  @override
  String get settingsSectionGeneral => 'General';
}
