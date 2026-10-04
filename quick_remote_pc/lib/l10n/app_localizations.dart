import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsHidePublicNetworkWarning.
  ///
  /// In tr, this message translates to:
  /// **'Ortak Ağ Uyarılarını Gizle'**
  String get settingsHidePublicNetworkWarning;

  /// No description provided for @settingsHidePublicNetworkWarningSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ortak ağlara bağlanırken güvenlik uyarısı gösterme.'**
  String get settingsHidePublicNetworkWarningSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguageTitle;

  /// Language option that follows the operating system language.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili'**
  String get languageSystem;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @homeTagline.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Kontrol Merkezi'**
  String get homeTagline;

  /// No description provided for @refreshSlideState.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Durumunu Yenile'**
  String get refreshSlideState;

  /// No description provided for @portsOpened.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik duvarında portlar açıldı.'**
  String get portsOpened;

  /// No description provided for @portsOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Portlar açılamadı.'**
  String get portsOpenFailed;

  /// No description provided for @firewallDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Portları Açmanız Gerekiyor'**
  String get firewallDialogTitle;

  /// No description provided for @firewallDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik duvarı telefonun bu bilgisayara bağlanmasını engelliyor. Uygulamayı kullanmak için 8090-8099 portlarını açmalısınız.\n\nPortlar bu ağ bölgesinde kalıcı olarak açılır. Yönetici parolanız bir kez sorulacak.'**
  String get firewallDialogContent;

  /// No description provided for @later.
  ///
  /// In tr, this message translates to:
  /// **'Daha Sonra'**
  String get later;

  /// No description provided for @openPortsButton.
  ///
  /// In tr, this message translates to:
  /// **'Portları Aç'**
  String get openPortsButton;

  /// No description provided for @uinputNeeded.
  ///
  /// In tr, this message translates to:
  /// **'Klavye/fare simülasyonu için izin gerekli'**
  String get uinputNeeded;

  /// No description provided for @grantPermission.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get grantPermission;

  /// No description provided for @uinputGranted.
  ///
  /// In tr, this message translates to:
  /// **'Giriş izni verildi.'**
  String get uinputGranted;

  /// No description provided for @uinputFailed.
  ///
  /// In tr, this message translates to:
  /// **'İzin verilemedi. Yönetici parolası gerekiyor.'**
  String get uinputFailed;

  /// No description provided for @mdnsOff.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik keşif kapalı (avahi-daemon). QR veya IP ile bağlanın.'**
  String get mdnsOff;

  /// No description provided for @firewallBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik duvarı telefonun bağlanmasını engelliyor. Kullanmak için portları açın.'**
  String get firewallBlocked;

  /// No description provided for @firewallUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik duvarı kuralları okunamadı: 8090-8099 portları açık olmalı'**
  String get firewallUnknown;

  /// No description provided for @openPortsAction.
  ///
  /// In tr, this message translates to:
  /// **'Portları aç'**
  String get openPortsAction;

  /// No description provided for @impressConnected.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice Impress bağlı'**
  String get impressConnected;

  /// No description provided for @impressReadyWhenOpened.
  ///
  /// In tr, this message translates to:
  /// **'Impress: LibreOffice açılınca bağlanır'**
  String get impressReadyWhenOpened;

  /// No description provided for @impressOff.
  ///
  /// In tr, this message translates to:
  /// **'Impress bağlantısı kapalı'**
  String get impressOff;

  /// No description provided for @enable.
  ///
  /// In tr, this message translates to:
  /// **'Etkinleştir'**
  String get enable;

  /// No description provided for @impressEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Impress bağlantısı etkinleştirildi.'**
  String get impressEnabled;

  /// No description provided for @libreOfficeWriteFailed.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice ayarı yazılamadı.'**
  String get libreOfficeWriteFailed;

  /// No description provided for @impressLegacy.
  ///
  /// In tr, this message translates to:
  /// **'Impress bağlantısı eski yöntemi kullanıyor: bu bilgisayardaki her kullanıcıya ve uygulamaya açık bir port. Güncelleyin.'**
  String get impressLegacy;

  /// No description provided for @update.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get update;

  /// No description provided for @impressUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Impress bağlantısı güvenli yönteme geçirildi.'**
  String get impressUpdated;

  /// No description provided for @impressLegacyRunning.
  ///
  /// In tr, this message translates to:
  /// **'Impress bağlantısı eski yöntemi kullanıyor: bu bilgisayardaki her kullanıcıya ve uygulamaya açık bir port. Güncellemek için LibreOffice\'i kapatın.'**
  String get impressLegacyRunning;

  /// No description provided for @libreOfficeNotListening.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice açık ama bağlantı kabul etmiyor'**
  String get libreOfficeNotListening;

  /// No description provided for @connect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get connect;

  /// No description provided for @libreOfficeListening.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice bağlantıyı kabul ediyor.'**
  String get libreOfficeListening;

  /// No description provided for @libreOfficeUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice\'e ulaşılamadı.'**
  String get libreOfficeUnreachable;

  /// No description provided for @libreOfficeMissing.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice yok: sunum yalnızca klavye ile kontrol edilir'**
  String get libreOfficeMissing;

  /// No description provided for @unoMissing.
  ///
  /// In tr, this message translates to:
  /// **'python3 veya LibreOffice Python (UNO) desteği bulunamadı'**
  String get unoMissing;

  /// No description provided for @wpsConnected.
  ///
  /// In tr, this message translates to:
  /// **'WPS bağlı: buradan açılan sunum tam kontrol edilir'**
  String get wpsConnected;

  /// No description provided for @openPresentation.
  ///
  /// In tr, this message translates to:
  /// **'Sunum aç'**
  String get openPresentation;

  /// No description provided for @wpsReady.
  ///
  /// In tr, this message translates to:
  /// **'WPS: slayt numarası, notlar ve kalem rengi için sunumu buradan açın'**
  String get wpsReady;

  /// No description provided for @wpsNoRpc.
  ///
  /// In tr, this message translates to:
  /// **'WPS şu an temel modda: slaytları ileri-geri alabilirsiniz ama telefonda slayt numarası ve notlar görünmez. Tam kontrol için \"Kur\"a basın (bir kez internet gerekir).'**
  String get wpsNoRpc;

  /// No description provided for @install.
  ///
  /// In tr, this message translates to:
  /// **'Kur'**
  String get install;

  /// No description provided for @wpsInstalled.
  ///
  /// In tr, this message translates to:
  /// **'WPS desteği kuruldu.'**
  String get wpsInstalled;

  /// No description provided for @wpsInstallFailed.
  ///
  /// In tr, this message translates to:
  /// **'WPS desteği kurulamadı (python3-venv ve internet gerekir).'**
  String get wpsInstallFailed;

  /// No description provided for @presentationsFileType.
  ///
  /// In tr, this message translates to:
  /// **'Sunumlar'**
  String get presentationsFileType;

  /// No description provided for @wpsOpened.
  ///
  /// In tr, this message translates to:
  /// **'Sunum WPS\'te açıldı. Gösteriyi telefondan başlatabilirsiniz.'**
  String get wpsOpened;

  /// No description provided for @wpsOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sunum WPS\'te açılamadı.'**
  String get wpsOpenFailed;

  /// No description provided for @networkTrusted.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilir Ağ'**
  String get networkTrusted;

  /// No description provided for @networkUntrusted.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilmeyen Ağ'**
  String get networkUntrusted;

  /// No description provided for @networkZoneUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Ağ türü bilinmiyor'**
  String get networkZoneUnknown;

  /// No description provided for @networkPrivate.
  ///
  /// In tr, this message translates to:
  /// **'Özel Ağ'**
  String get networkPrivate;

  /// No description provided for @networkPublic.
  ///
  /// In tr, this message translates to:
  /// **'Ortak Ağ'**
  String get networkPublic;

  /// No description provided for @networkUnreadable.
  ///
  /// In tr, this message translates to:
  /// **'Ağ türü okunamadı'**
  String get networkUnreadable;

  /// No description provided for @publicNetworkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ortak Ağ Uyarısı'**
  String get publicNetworkTitle;

  /// No description provided for @publicNetworkLinux.
  ///
  /// In tr, this message translates to:
  /// **'Bu ağ, güvenlik duvarında güvenilmeyen ağ olarak tanımlı. Bu ağdaki diğer kişiler QuickRemote sunucunuzu görebilir.\n\nGüvenilir bir ağda olduğunuzdan emin olun.'**
  String get publicNetworkLinux;

  /// No description provided for @publicNetworkWindows.
  ///
  /// In tr, this message translates to:
  /// **'Şu an ortak bir ağdasınız. Bu ağdaki diğer kişiler QuickRemote sunucunuzu görebilir.\n\nGüvenilir bir ağda olduğunuzdan emin olun.'**
  String get publicNetworkWindows;

  /// No description provided for @openNetworkSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ağ Ayarlarını Aç'**
  String get openNetworkSettings;

  /// No description provided for @dontShowAgain.
  ///
  /// In tr, this message translates to:
  /// **'Bu uyarıyı bir daha gösterme'**
  String get dontShowAgain;

  /// No description provided for @stopServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuyu Durdur'**
  String get stopServer;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueAction;

  /// No description provided for @loadingNetwork.
  ///
  /// In tr, this message translates to:
  /// **'Ağ bilgileri alınıyor...'**
  String get loadingNetwork;

  /// No description provided for @showCodeToPair.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir cihaz eşleştirmek için kodu gösterin'**
  String get showCodeToPair;

  /// No description provided for @scanToConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanmak için QR kodu tarayın'**
  String get scanToConnect;

  /// No description provided for @hideCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu gizle'**
  String get hideCode;

  /// No description provided for @securityCode.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik kodu: {code}'**
  String securityCode(String code);

  /// No description provided for @pairingPaused.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla hatalı PIN denemesi. Eşleştirme 1 dakika duraklatıldı ve PIN yenilendi.'**
  String get pairingPaused;

  /// No description provided for @showCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu göster'**
  String get showCode;

  /// No description provided for @connectedDevices.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı cihazlar ({count})'**
  String connectedDevices(int count);

  /// No description provided for @removeDeviceTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı keser ve PIN\'i yeniler. Diğer cihazlar bağlı kalır.'**
  String get removeDeviceTooltip;

  /// No description provided for @removeDevice.
  ///
  /// In tr, this message translates to:
  /// **'Çıkar'**
  String get removeDevice;

  /// No description provided for @clientsConnected.
  ///
  /// In tr, this message translates to:
  /// **'{count} Bağlı'**
  String clientsConnected(int count);

  /// No description provided for @serverOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get serverOff;

  /// No description provided for @portsInUse.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu başlatılamadı: Port kullanımda. Lütfen 8090-8099 portlarını kullanan uygulamaları kapatıp tekrar deneyin.'**
  String get portsInUse;

  /// No description provided for @serverStartFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu başlatılamadı: {error}'**
  String serverStartFailed(String error);

  /// No description provided for @portFallback.
  ///
  /// In tr, this message translates to:
  /// **'Port 8090 kullanımda olduğu için sunucu {port} portunda başlatıldı.'**
  String portFallback(int port);

  /// No description provided for @serverStopped.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu Kapalı'**
  String get serverStopped;

  /// No description provided for @serverStoppedHint.
  ///
  /// In tr, this message translates to:
  /// **'Telefonunuzdan bağlanmak ve sunumunuzu\nkontrol etmek için sunucuyu başlatın.'**
  String get serverStoppedHint;

  /// No description provided for @opensslMissing.
  ///
  /// In tr, this message translates to:
  /// **'openssl bulunamadı. TLS sertifikası için openssl paketini kurun.'**
  String get opensslMissing;

  /// No description provided for @tlsKeyReadable.
  ///
  /// In tr, this message translates to:
  /// **'TLS anahtarı başka kullanıcılar tarafından okunabiliyor: {path}'**
  String tlsKeyReadable(String path);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
