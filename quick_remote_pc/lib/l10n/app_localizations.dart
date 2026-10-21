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

  /// No description provided for @wpsUserStarted.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'i siz açtınız: telefon onu yalnızca tuşlarla yönetir, slayt numarası ve notlar görünmez. \"Devral\" WPS\'i kapatıp sunumu QuickRemote\'un WPS\'inde aynı slayttan açar.'**
  String get wpsUserStarted;

  /// No description provided for @takeOver.
  ///
  /// In tr, this message translates to:
  /// **'Devral'**
  String get takeOver;

  /// No description provided for @wpsTakenOver.
  ///
  /// In tr, this message translates to:
  /// **'Sunum QuickRemote\'un WPS\'inde açıldı.'**
  String get wpsTakenOver;

  /// No description provided for @wpsTakeOverNoWps.
  ///
  /// In tr, this message translates to:
  /// **'Açık bir WPS bulunamadı.'**
  String get wpsTakeOverNoWps;

  /// No description provided for @wpsTakeOverNoFile.
  ///
  /// In tr, this message translates to:
  /// **'Sunum kaydedilmemiş: önce WPS\'te kaydedin.'**
  String get wpsTakeOverNoFile;

  /// No description provided for @wpsTakeOverNotClosed.
  ///
  /// In tr, this message translates to:
  /// **'WPS kapanmadı: kaydetme sorusunu yanıtlayıp tekrar deneyin.'**
  String get wpsTakeOverNotClosed;

  /// No description provided for @wpsTakeOverFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sunum QuickRemote\'un WPS\'inde açılamadı.'**
  String get wpsTakeOverFailed;

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
  /// **'Telefonunuzdan bağlanmak ve sunumunuzu kontrol etmek için sunucuyu başlatın.'**
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

  /// Button and tooltip that starts the server.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuyu Başlat'**
  String get startServer;

  /// No description provided for @serverRunning.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu Açık'**
  String get serverRunning;

  /// No description provided for @serverStarting.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu açılıyor'**
  String get serverStarting;

  /// No description provided for @serverStoppedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefondan bağlanmak için başlatın.'**
  String get serverStoppedSubtitle;

  /// No description provided for @waitingForPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon bekleniyor'**
  String get waitingForPhone;

  /// No description provided for @linuxSetupHeader.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum · Linux'**
  String get linuxSetupHeader;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get appearanceDark;

  /// No description provided for @appearanceNote.
  ///
  /// In tr, this message translates to:
  /// **'Ekran projeksiyona yansıyorsa aydınlık salonda Açık daha iyi okunur.'**
  String get appearanceNote;

  /// No description provided for @settingsLaser.
  ///
  /// In tr, this message translates to:
  /// **'Lazer'**
  String get settingsLaser;

  /// No description provided for @laserOverlayAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get laserOverlayAuto;

  /// No description provided for @laserOverlayAlways.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote'**
  String get laserOverlayAlways;

  /// No description provided for @laserOverlayNever.
  ///
  /// In tr, this message translates to:
  /// **'Program'**
  String get laserOverlayNever;

  /// No description provided for @laserOverlayNote.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote lazeri her pencerenin üstünde çizer: Impress\'te videonun üstünde, PDF\'te, tarayıcıda ve gösteri dışında da. Otomatik\'te PowerPoint ve WPS kendi lazerini kullanır. Gösteri dışındaki lazer, telefon yeniden bağlanınca açılır.'**
  String get laserOverlayNote;

  /// No description provided for @phonesConnected.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 telefon bağlı} other{{count} telefon bağlı}}'**
  String phonesConnected(int count);

  /// No description provided for @noPhonesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bağlanan telefon yok.'**
  String get noPhonesYet;

  /// No description provided for @settingsStartup.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç ve tepsi'**
  String get settingsStartup;

  /// No description provided for @settingsCloseToTray.
  ///
  /// In tr, this message translates to:
  /// **'Kapatınca tepsiye küçült'**
  String get settingsCloseToTray;

  /// No description provided for @settingsCloseToTraySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Pencere kapanınca QuickRemote tepside çalışmayı sürdürür; bağlı telefonlar kopmaz.'**
  String get settingsCloseToTraySubtitle;

  /// No description provided for @settingsNoTray.
  ///
  /// In tr, this message translates to:
  /// **'Bu masaüstünde sistem tepsisi yok; pencere kapanınca uygulama kapanır. GNOME\'da AppIndicator eklentisiyle tepsi gelir.'**
  String get settingsNoTray;

  /// No description provided for @settingsLaunchAtLogin.
  ///
  /// In tr, this message translates to:
  /// **'Oturum açılınca başlat'**
  String get settingsLaunchAtLogin;

  /// No description provided for @settingsLaunchAtLoginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Pencere açılmadan, tepside başlar.'**
  String get settingsLaunchAtLoginSubtitle;

  /// No description provided for @settingsStartServerOnLaunch.
  ///
  /// In tr, this message translates to:
  /// **'Açılınca sunucuyu başlat'**
  String get settingsStartServerOnLaunch;

  /// No description provided for @settingsStartServerOnLaunchSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ortak (public) bir ağda sunucu kendiliğinden başlamaz.'**
  String get settingsStartServerOnLaunchSubtitle;

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In tr, this message translates to:
  /// **'Güncellemeleri denetle'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsCheckUpdatesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Açılışta ve günde bir kez GitHub\'a yeni sürüm olup olmadığını sorar; hiçbir şey indirmez. GitHub bu sırada IP adresini görür.'**
  String get settingsCheckUpdatesSubtitle;

  /// No description provided for @autostartFailed.
  ///
  /// In tr, this message translates to:
  /// **'Oturum açılınca başlatma ayarı değiştirilemedi.'**
  String get autostartFailed;

  /// No description provided for @updateAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Yeni sürüm: {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateDownload.
  ///
  /// In tr, this message translates to:
  /// **'İndir'**
  String get updateDownload;

  /// No description provided for @serverHeldBack.
  ///
  /// In tr, this message translates to:
  /// **'Ortak bir ağda olduğun için sunucu kendiliğinden başlamadı. Bu ağa güveniyorsan başlat.'**
  String get serverHeldBack;

  /// No description provided for @trayShow.
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get trayShow;

  /// No description provided for @trayStartServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuyu başlat'**
  String get trayStartServer;

  /// No description provided for @trayStopServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuyu durdur'**
  String get trayStopServer;

  /// No description provided for @trayPhones.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Bağlı telefon yok} other{Bağlı telefon: {count}}}'**
  String trayPhones(int count);

  /// No description provided for @trayQuit.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış'**
  String get trayQuit;

  /// No description provided for @trayTooltipOff.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote PC · Sunucu kapalı'**
  String get trayTooltipOff;

  /// No description provided for @trayTooltipOn.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote PC · Sunucu açık'**
  String get trayTooltipOn;

  /// No description provided for @trayTooltipHeldBack.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote PC · Ortak ağ: sunucu başlamadı'**
  String get trayTooltipHeldBack;

  /// No description provided for @trayNoticeTitle.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote arka planda çalışıyor'**
  String get trayNoticeTitle;

  /// No description provided for @trayNoticeBody.
  ///
  /// In tr, this message translates to:
  /// **'Pencere kapandı, ama sunucu ve bağlı telefonlar çalışmayı sürdürüyor. Pencereyi tepsideki simgeden açabilir, uygulamadan oradaki Çıkış ile çıkabilirsin. Ayarlar\'da \"Kapatınca tepsiye küçült\" kapatılırsa pencereyi kapatmak uygulamayı kapatır.'**
  String get trayNoticeBody;

  /// No description provided for @trayNoticeOk.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get trayNoticeOk;

  /// No description provided for @settingsTroubleshooting.
  ///
  /// In tr, this message translates to:
  /// **'Sorun giderme'**
  String get settingsTroubleshooting;

  /// No description provided for @settingsExportLog.
  ///
  /// In tr, this message translates to:
  /// **'Günlüğü dışa aktar'**
  String get settingsExportLog;

  /// No description provided for @settingsReportProblem.
  ///
  /// In tr, this message translates to:
  /// **'Sorun bildir'**
  String get settingsReportProblem;

  /// No description provided for @settingsLogPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Günlük yalnızca bu bilgisayarda tutulur ve hiçbir yere kendiliğinden gönderilmez. PIN, eşleştirme kodu, güvenlik kodu, notlar ve dosya yolları yazılmaz; IP adresleri ve cihaz adları yazılır. \"Sorun bildir\" GitHub\'da yeni bir sorun sayfası açar; günlüğü oraya sen eklersin.'**
  String get settingsLogPrivacy;

  /// No description provided for @logExported.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kaydedildi.'**
  String get logExported;

  /// No description provided for @logExportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kaydedilemedi.'**
  String get logExportFailed;

  /// No description provided for @issueBody.
  ///
  /// In tr, this message translates to:
  /// **'**Ne oldu?**\n\n\n**Nasıl tekrarlanır?**\n\n\n---\nQuickRemote PC {version}\nPlatform: {platform}\nProgramlar: {presenters}\n\nGünlüğü (Ayarlar → Günlüğü dışa aktar) bu sayfaya sürükleyip bırakabilirsin.'**
  String issueBody(String version, String platform, String presenters);
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
