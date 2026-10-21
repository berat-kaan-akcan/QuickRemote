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
  String get settingsSlidePreviewTitle => 'Slide Preview';

  @override
  String get settingsSlidePreviewSubtitle =>
      'Shows a picture of the slide on the remote. It is the slide as saved: the current animation step, drawings and a playing video do not show.';

  @override
  String get presenterViewTitle => 'Presenter view';

  @override
  String get presenterViewOpenHint => 'Open the presenter view';

  @override
  String get presenterNextUp => 'Next up';

  @override
  String get presenterLastSlide => 'Last slide';

  @override
  String slidePreviewLabel(int slide) {
    return 'Preview of slide $slide';
  }

  @override
  String get screenPreviewLabel => 'The PC\'s screen';

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
  String get errorWpsTakeOverNoWps => 'No open WPS was found on the PC.';

  @override
  String get errorWpsTakeOverNoFile =>
      'The presentation isn\'t saved: save it in WPS first.';

  @override
  String get errorWpsTakeOverNotClosed =>
      'WPS didn\'t close: answer its save question on the PC and try again.';

  @override
  String get errorWpsTakeOverFailed =>
      'Couldn\'t open the presentation in QuickRemote\'s WPS.';

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
  String get homeTagline => 'The presentation remote in your pocket';

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
  String get homeSaved => 'Saved';

  @override
  String get homeSavedHint => 'Connects with the saved PIN';

  @override
  String get launchNoRecentPc =>
      'No PC to connect to yet. Connect once with the QR code or the PIN.';

  @override
  String launchPcNotFound(String name) {
    return '$name was not found on the network. Is QuickRemote PC running?';
  }

  @override
  String get unknownPc => 'Unknown PC';

  @override
  String get verifyTitle => 'Compare the Security Code';

  @override
  String get verifyConfirm => 'Codes Match, Connect';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get certWarningTitle => 'Security Warning';

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
  String get remoteNewPinTitle => 'The PC\'s PIN changed';

  @override
  String get remoteNewPinMessage =>
      'The PC made a new PIN when it restarted. Enter the PIN shown on the PC to reconnect to it.';

  @override
  String get remoteEnterPin => 'Enter PIN';

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
  String get notesTitle => 'Speaker Notes';

  @override
  String get notesEmpty => 'This slide has no notes.';

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
  String presentationNotOpen(String programs) {
    return 'No Presentation Open, start $programs';
  }

  @override
  String get actionEnd => 'End';

  @override
  String get actionFullScreen => 'Full screen';

  @override
  String viewerInFront(String front) {
    String _temp0 = intl.Intl.selectLogic(front, {
      'browser': 'Browser in front · page turns and full screen only',
      'other': 'PDF open · page turns and full screen only',
    });
    return '$_temp0';
  }

  @override
  String get blackScreen => 'Black Screen';

  @override
  String get whiteScreen => 'White Screen';

  @override
  String get actionPrev => 'Previous';

  @override
  String get actionNext => 'Next';

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
  String get clearInkUndoTooltip =>
      'Clear all drawings; hold to undo the last stroke';

  @override
  String get toolSpotlight => 'Spotlight';

  @override
  String get toolZoom => 'Magnifier';

  @override
  String get laserStyleTitle => 'Laser style';

  @override
  String get laserStyleSpotlightNote =>
      'The spotlight darkens the screen and keeps a circle under your finger lit.';

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
  String tapForTool(String tool) {
    return 'Single tap → $tool';
  }

  @override
  String get doubleTapSelected => 'Double tap → Selected tool';

  @override
  String get volumeMuted => 'Muted';

  @override
  String get volumeOn => 'Sound on';

  @override
  String get volumeMuteToggle => 'Mute / Unmute';

  @override
  String get btUnsupportedLong =>
      'This device doesn\'t support Bluetooth HID.\nUse Wi-Fi mode.';

  @override
  String get btPermissionTitle => 'Permission needed';

  @override
  String get btPermissionDenied =>
      'The phone needs the “Nearby devices” permission to connect as a keyboard and mouse.';

  @override
  String btConnectingTo(String device) {
    return 'Connecting to $device...';
  }

  @override
  String get btMakeVisible => 'Make the phone visible';

  @override
  String get btMakeVisibleHint =>
      'The computer lists the phone only while the phone is visible.';

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
      'The computer doesn\'t accept the phone as a keyboard';

  @override
  String get btHostUnawareBody =>
      'This mostly happens when the phone was paired with this computer before, while QuickRemote was not open (for audio or file transfer, say): the computer doesn\'t know it as a keyboard. Do this once on the computer:';

  @override
  String get btHostUnawareWindows =>
      'In Settings → Bluetooth & devices → Devices, find the phone and choose “Remove device” from its “…” menu. Then add it again with “Add device” while this screen is open.';

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
  String get btPreparing => 'Preparing...';

  @override
  String get btNotConnectedRetrying => 'Not connected, retrying';

  @override
  String get btOnYourComputer => 'Pair once on your computer';

  @override
  String get btLinuxStep1 =>
      'Open the Bluetooth settings: in KDE, System Settings → Bluetooth; in GNOME, Settings → Bluetooth.';

  @override
  String get btLinuxStep2 =>
      'Turn Bluetooth on and start a device search. In KDE, press “Add device”; GNOME searches by itself while that page is open.';

  @override
  String get btStepPickPhone =>
      'Pick your phone\'s name in the list. If it isn\'t there, press “Make the phone visible” above.';

  @override
  String get btStepConfirm =>
      'The phone and the computer show the same 6-digit code. If the codes match, confirm on both.';

  @override
  String get btWindowsStep1 => 'Open Settings (Windows key + I).';

  @override
  String get btWindowsStep2 =>
      'Choose Bluetooth & devices → Add device → Bluetooth. On Windows 10: Bluetooth & other devices → Add Bluetooth or other device.';

  @override
  String get btPermissionAllow => 'Allow';

  @override
  String get btPermissionSettings => 'Open settings';

  @override
  String get btPermissionSettingsHint =>
      'The permission was refused before, so it can now be given only in Settings: Permissions → Nearby devices → Allow.';

  @override
  String get btOffTitle => 'Bluetooth is off';

  @override
  String get btOffBody =>
      'The phone connects to the computer over Bluetooth as a keyboard and mouse. Once Bluetooth is on, connecting goes on by itself.';

  @override
  String get btTurnOn => 'Turn on Bluetooth';

  @override
  String get btOffDuringRemote =>
      'The phone\'s Bluetooth turned off. The remote reconnects once it is on.';

  @override
  String btStepPickPhoneNamed(String name) {
    return 'Pick “$name” in the list. If it isn\'t there, press “Make the phone visible” above.';
  }

  @override
  String get btTroubleTitle => 'Not connecting?';

  @override
  String get btTroubleNearby =>
      'Keep the computer\'s Bluetooth on, the computer awake and the phone within a few meters of it.';

  @override
  String get btTroubleNotListed =>
      'If the phone isn\'t in the list, press “Make the phone visible” and start the search on the computer again.';

  @override
  String get btTroubleAlreadyPaired =>
      'If the computer already shows the phone as paired but it doesn\'t connect, remove the phone on the computer and add it again while this screen is open.';

  @override
  String get btTroubleBlocked =>
      'If the phone is blocked in the computer\'s Bluetooth settings, unblock it.';

  @override
  String get btTroubleSeveral =>
      'A phone paired with more than one computer can\'t tell which one to connect to: in the Bluetooth settings of the computer you want, choose “Connect” for the phone.';

  @override
  String get btTroubleOtherApp =>
      'The phone can be a keyboard for only one app at a time. If another Bluetooth keyboard or mouse app is open, close it.';

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

  @override
  String get remoteProgramHint => 'Choose the presentation program';

  @override
  String get programSheetTitle => 'Presentation program';

  @override
  String programSheetBody(String pc) {
    return '$pc can control these programs. The one running a slideshow is used automatically.';
  }

  @override
  String programShowOpenSlide(int slide) {
    return 'Slideshow running · Slide $slide';
  }

  @override
  String get programShowOpen => 'Slideshow running';

  @override
  String get programShowClosed => 'No slideshow';

  @override
  String get programPdfNote =>
      'PDFs are not chosen here; if the front window is a PDF, that is controlled.';

  @override
  String get programBluetoothNote =>
      'In Bluetooth mode the program is chosen here (PowerPoint / Impress / WPS).';

  @override
  String get goToSlide => 'Go to slide';

  @override
  String goToSlideRange(int total) {
    return 'A number from 1 to $total';
  }

  @override
  String get goToSlideNumber => 'Slide number';

  @override
  String get goAction => 'Go';

  @override
  String notesSlide(int slide) {
    return 'Slide $slide';
  }

  @override
  String get notesOpenHint => 'Open the whole note';

  @override
  String get unreadableShow =>
      'WPS does not report the slide number; the buttons still work.';

  @override
  String get unreadableShowUserWps =>
      'QuickRemote did not open this WPS: no slide number or notes, and the buttons work while the WPS window is in front.';

  @override
  String get takeOverHint =>
      'QuickRemote didn\'t open this WPS: no slide numbers or notes. Take over closes WPS on the PC and opens the presentation at the same slide with full control.';

  @override
  String get takeOverAction => 'Take over';

  @override
  String get takeOverStarted =>
      'WPS is reopening on the PC; if it asks to save, answer on the PC.';

  @override
  String get drawToolsNeedShow =>
      'The drawing tools work while a slideshow is running.';

  @override
  String get toolArrow => 'Arrow';

  @override
  String get colorUnavailableTitle => 'No colors in this program.';

  @override
  String get colorUnavailableBody =>
      'QuickRemote did not open this WPS, so the pen draws in WPS\'s own color.';

  @override
  String slideMediaOnSlide(int slide, String suffix) {
    return 'Media on slide $slide';
  }

  @override
  String get slideMediaPlaying => 'Playing';

  @override
  String get slideMediaNotPlaying => 'Not playing';

  @override
  String get slideMediaStateUnknown =>
      'WPS does not report whether it is playing';

  @override
  String get volumeDown => 'Volume down';

  @override
  String get volumeUp => 'Volume up';

  @override
  String get mediaStop => 'Stop';

  @override
  String btModeSubtitle(String device) {
    return 'The phone is $device\'s keyboard and mouse';
  }

  @override
  String get btScreenKeys => 'Black · White screen';

  @override
  String get btPreparingBody =>
      'The phone is registering as a keyboard and mouse.';

  @override
  String get btConnectingBody => 'The remote opens by itself once connected.';

  @override
  String btRetryingBody(String device) {
    return 'If $device is on with Bluetooth on, it connects within a few seconds.';
  }

  @override
  String get btRetryingBodyUnknown =>
      'If the computer is on with Bluetooth on, it connects within a few seconds.';

  @override
  String get btRefreshingBody =>
      'The computer is reading the phone\'s keyboard record again.';

  @override
  String get btProgramSheetBody =>
      'Over Bluetooth the computer cannot tell the program; keys are sent as the shortcuts of the program you pick.';

  @override
  String get btToolsFull => 'Laser, pen, highlighter, eraser';

  @override
  String get btToolsImpress => 'Cursor, pen';

  @override
  String get btImpressToolsNote =>
      'Impress has no laser, highlighter or eraser shortcut; the cursor is the pointer.';

  @override
  String get btWpsToolsNote =>
      'In WPS the laser opens with Ctrl+R; in WPS on Windows the eraser may do something else.';

  @override
  String get verifyIntro =>
      'This is your first connection to this PC. The security code on the PC screen should be:';

  @override
  String get verifyNote =>
      'If the codes differ, don\'t connect: another device on the network may be pretending to be the PC. Scanning the QR code skips this step.';

  @override
  String get certWarningIntro =>
      'This device\'s identity (certificate) differs from the one saved earlier. This is normal if you reinstalled your PC or renewed the certificate. The security code on the PC screen should be:';

  @override
  String get certWarningNote => 'If the codes differ, don\'t connect.';

  @override
  String get homeNoDevicesHint =>
      'QuickRemote PC must be open on the computer, on the same Wi-Fi.';

  @override
  String get languageSystemNote =>
      'System language follows the phone\'s language; if it is neither Turkish nor English, English is used.';

  @override
  String get historySwipeHint => 'Swipe left to delete';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String settingsThemeSubtitle(String theme, String mode) {
    return '$theme · $mode';
  }

  @override
  String get themeModeHeader => 'Light / Dark';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeColorHeader => 'Color theme';

  @override
  String get themeCobaltNote =>
      'Cobalt follows the system\'s light or dark mode; you can also pick one.';

  @override
  String get themeDarkOnlyNote =>
      'This theme is dark only, made for a dark room.';

  @override
  String get themeLightOnlyNote => 'Sunset is light only, for bright rooms.';

  @override
  String get themeCobalt => 'Cobalt';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeHighContrast => 'High contrast';

  @override
  String get themeMint => 'Mint';

  @override
  String get themeViolet => 'Violet';

  @override
  String get themeSunset => 'Sunset';

  @override
  String get themeWatchHeader => 'Watch';

  @override
  String get themeWatchTitle => 'Use on the watch too';

  @override
  String get themeWatchSubtitle =>
      'The QuickRemote watch app takes this color theme.';

  @override
  String get themeWatchSunsetNote =>
      'The watch is always dark: Sunset shows as Cobalt there.';

  @override
  String get settingsSectionHelp => 'Help';

  @override
  String get settingsShareLogTitle => 'Share error log';

  @override
  String get settingsShareLogSubtitle =>
      'The log stays on this phone and is never sent anywhere by itself. PINs, pairing codes, notes and file paths are not written; IP addresses and device names are.';

  @override
  String get settingsReportProblemTitle => 'Report a problem';

  @override
  String get settingsReportProblemSubtitle =>
      'Opens a new issue on GitHub; you attach the log there yourself.';

  @override
  String get logShareFailed => 'Could not share the log.';

  @override
  String get logShareEmpty => 'The log is empty so far.';

  @override
  String get issueOpenFailed => 'Could not open the browser.';

  @override
  String issueBody(
    String version,
    String platform,
    String presenters,
    String btTarget,
  ) {
    return '**What happened?**\n\n\n**How can it be reproduced?**\n\n\n---\nQuickRemote $version (phone)\nPlatform: $platform\nPrograms on the PC: $presenters\nBluetooth target: $btTarget\n\nYou can attach the log (Settings → Share error log) on this page.';
  }

  @override
  String get settingsCapabilitiesTitle => 'What works where';

  @override
  String get settingsCapabilitiesSubtitle =>
      'Which feature works in which program, side by side';

  @override
  String get capTitle => 'What works where';

  @override
  String get capIntro =>
      'Pick the connection, the computer and the program to see what works. Compare puts every program on that computer side by side.';

  @override
  String get capConnection => 'Connection';

  @override
  String get capComputer => 'Computer';

  @override
  String get capViewOne => 'One program';

  @override
  String get capViewCompare => 'Compare';

  @override
  String get capFootnoteWifi =>
      'With the PC app\'s Laser setting on Auto. In Compare, tap a ringed mark to read its note.';

  @override
  String get capFootnoteBluetooth =>
      'Over Bluetooth the phone is the computer\'s keyboard and mouse: no PC app is needed, but the computer tells the phone nothing. In Compare, tap a ringed mark to read its note.';

  @override
  String get capProgramWpsApp => 'WPS (opened by the app)';

  @override
  String get capProgramWpsOwn => 'WPS (opened by you)';

  @override
  String get capProgramPdf => 'PDF and browser';

  @override
  String get capShortWpsApp => 'WPS\nby app';

  @override
  String get capShortWpsOwn => 'WPS\nby you';

  @override
  String get capNextPrev => 'Next / previous slide';

  @override
  String get capStartEnd => 'Start / end the show';

  @override
  String get capGoTo => 'Go to slide';

  @override
  String get capLaser => 'Laser';

  @override
  String get capInk => 'Pen and highlighter';

  @override
  String get capEraser => 'Eraser and clear';

  @override
  String get capBlank => 'Black / white screen';

  @override
  String get capSlideInfo => 'Slide number and notes';

  @override
  String get capPreview => 'Slide preview';

  @override
  String get capSlideMedia => 'Video on the slide';

  @override
  String get capSpotlight => 'Spotlight and magnifier';

  @override
  String get capVolume => 'Computer\'s volume and media';

  @override
  String get capNoteOverlay =>
      'QuickRemote draws it on its own layer, over videos too.';

  @override
  String get capNoteFocus => 'Only while the WPS window is in front.';

  @override
  String get capNoteFullscreen => 'Goes full screen or into presentation mode.';

  @override
  String get capNoteNoJump => 'Does not jump to the page.';

  @override
  String get capNoteFirstSlide => 'The show starts at the first slide.';

  @override
  String get capNoteShowOnly => 'Only that a show is open is known.';

  @override
  String get capNoteScreenOnly =>
      'Only a picture of the screen; no next slide.';

  @override
  String get capNoteFullscreenOnly =>
      'Only in full screen, a picture of the screen.';

  @override
  String get capNotePlayOnly => 'Play and pause, no rewind.';

  @override
  String get capNoteMediaReload => 'The first press may reload the slide once.';

  @override
  String get capNoteNoMagnifier => 'Spotlight, no magnifier.';

  @override
  String get capNoteWpsArrow =>
      'An arrow pointer instead of the laser while the show is not in front.';

  @override
  String get capNoteHighlighterFocus =>
      'The highlighter needs the show in front.';

  @override
  String get capNoteCursor => 'No laser shortcut; the mouse pointer is used.';

  @override
  String get capNotePenOnly => 'Pen only; no highlighter.';

  @override
  String get capNoteClearOnly => 'Clear all only; no eraser.';

  @override
  String get capNoteWpsEraser =>
      'In WPS on Windows the eraser shortcut may do something else.';

  @override
  String get capNoteNoAnswer =>
      'Over Bluetooth the computer sends the phone nothing.';

  @override
  String get capNoteKeysOnly => 'Keys only; no level or song title.';

  @override
  String get capNoteWpsNoMedia => 'Videos in WPS cannot be played remotely.';

  @override
  String get capLevelYes => 'Works';

  @override
  String get capLevelPartial => 'Partly';

  @override
  String get capLevelNo => 'Doesn\'t work';
}
