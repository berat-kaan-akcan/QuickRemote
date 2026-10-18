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

  /// No description provided for @settingsTimerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Sayacı Ayarları'**
  String get settingsTimerTitle;

  /// No description provided for @settingsTimerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik başlatma, titreşim ve erken uyarılar'**
  String get settingsTimerSubtitle;

  /// No description provided for @settingsHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Geçmişi'**
  String get settingsHistoryTitle;

  /// No description provided for @settingsHistorySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Önceki sunum istatistikleri ve notları'**
  String get settingsHistorySubtitle;

  /// No description provided for @settingsKeepInkTitle.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Değişince Çizimleri Koru'**
  String get settingsKeepInkTitle;

  /// No description provided for @settingsKeepInkSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizimler kendi slaytında kalır, o slayta dönünce yeniden görünür. Kapalıyken ileri veya geri gidince kalemle çizilenler silinir.'**
  String get settingsKeepInkSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguageTitle;

  /// Language option that follows the device language.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili'**
  String get languageSystem;

  /// No description provided for @errorSlideshowNotRunning.
  ///
  /// In tr, this message translates to:
  /// **'Slayt gösterisi aktif değil.'**
  String get errorSlideshowNotRunning;

  /// No description provided for @errorSlideshowStartFailed.
  ///
  /// In tr, this message translates to:
  /// **'Slayt gösterisi başlatılamadı.'**
  String get errorSlideshowStartFailed;

  /// No description provided for @errorSlideStateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Slayt durumu alınamadı: {info}'**
  String errorSlideStateFailed(String info);

  /// No description provided for @errorPresenterNotResponding.
  ///
  /// In tr, this message translates to:
  /// **'Sunum programı yanıt vermiyor.'**
  String get errorPresenterNotResponding;

  /// No description provided for @errorPresenterUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'Sunum programına ulaşılamadı.'**
  String get errorPresenterUnreachable;

  /// No description provided for @errorPenColorFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kalem rengi değiştirilemedi.'**
  String get errorPenColorFailed;

  /// No description provided for @errorInkEraseFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mürekkep silinemedi.'**
  String get errorInkEraseFailed;

  /// No description provided for @errorPointerBusy.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir cihaz şu an lazeri veya kalemi kullanıyor.'**
  String get errorPointerBusy;

  /// No description provided for @errorNoMedia.
  ///
  /// In tr, this message translates to:
  /// **'Bu slaytta medya yok.'**
  String get errorNoMedia;

  /// No description provided for @errorMediaReloaded.
  ///
  /// In tr, this message translates to:
  /// **'Slayt yeniden yüklendi, video baştan başladı. Kontrol için tekrar deneyin.'**
  String get errorMediaReloaded;

  /// No description provided for @errorMediaNoTrigger.
  ///
  /// In tr, this message translates to:
  /// **'Bu slayttaki medya kumandadan kontrol edilemiyor.'**
  String get errorMediaNoTrigger;

  /// No description provided for @errorMediaNeedsFullscreen.
  ///
  /// In tr, this message translates to:
  /// **'Slayt medyası yalnızca tam ekran slayt gösterisinde kontrol edilebilir.'**
  String get errorMediaNeedsFullscreen;

  /// No description provided for @errorScreenBlanked.
  ///
  /// In tr, this message translates to:
  /// **'Ekran karartılmışken slayt medyası kontrol edilemez.'**
  String get errorScreenBlanked;

  /// No description provided for @errorImpressUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice Impress\'e bağlanılamadı.'**
  String get errorImpressUnreachable;

  /// No description provided for @errorImpressNoUno.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice Python (UNO) desteği bulunamadı.'**
  String get errorImpressNoUno;

  /// No description provided for @errorImpressUntrustedPipe.
  ///
  /// In tr, this message translates to:
  /// **'LibreOffice bağlantı soketi başka bir kullanıcıya ait; bağlanılmadı.'**
  String get errorImpressUntrustedPipe;

  /// No description provided for @errorWpsNotInstalled.
  ///
  /// In tr, this message translates to:
  /// **'WPS desteği kurulu değil.'**
  String get errorWpsNotInstalled;

  /// No description provided for @errorWpsNoPresentation.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'te açık sunum yok.'**
  String get errorWpsNoPresentation;

  /// No description provided for @errorWpsStartFailed.
  ///
  /// In tr, this message translates to:
  /// **'WPS başlatılamadı.'**
  String get errorWpsStartFailed;

  /// No description provided for @errorWpsOpenFromApp.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'te bu özellik yalnızca QuickRemote\'tan açılan sunumda çalışır (\"Sunumu WPS ile aç\").'**
  String get errorWpsOpenFromApp;

  /// No description provided for @errorWpsHighlighterNeedsFocus.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'te fosforlu kalem yalnızca slayt gösterisi odaktayken seçilebilir.'**
  String get errorWpsHighlighterNeedsFocus;

  /// No description provided for @errorWpsNoMediaRewind.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'te video başa sarılamıyor.'**
  String get errorWpsNoMediaRewind;

  /// No description provided for @errorLockFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar kilitlenemedi.'**
  String get errorLockFailed;

  /// No description provided for @errorCommandFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sunum komutu başarısız: {info}'**
  String errorCommandFailed(String info);

  /// No description provided for @errorUnknown.
  ///
  /// In tr, this message translates to:
  /// **'İşlem başarısız oldu.'**
  String get errorUnknown;

  /// No description provided for @connectionPinEmpty.
  ///
  /// In tr, this message translates to:
  /// **'PIN kodu boş olamaz.'**
  String get connectionPinEmpty;

  /// No description provided for @connectionWrongPin.
  ///
  /// In tr, this message translates to:
  /// **'PIN kodu yanlış.'**
  String get connectionWrongPin;

  /// No description provided for @connectionRateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla hatalı deneme. Bir dakika sonra tekrar deneyin.'**
  String get connectionRateLimited;

  /// No description provided for @connectionTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zaman aşımına uğradı.'**
  String get connectionTimeout;

  /// No description provided for @connectionAuthTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama zaman aşımına uğradı.'**
  String get connectionAuthTimeout;

  /// No description provided for @connectionServerNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamadı: {detail}'**
  String connectionServerNotFound(String detail);

  /// No description provided for @connectionCertMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Sertifika değişti! Olası MITM saldırısı veya cihaz formatlanmış olabilir.'**
  String get connectionCertMismatch;

  /// No description provided for @connectionCertRejected.
  ///
  /// In tr, this message translates to:
  /// **'PC\'nin sertifikası QR kodundakiyle eşleşmiyor. Bağlantı güvenli değil, bağlanılmadı. QR kodunu yeniden tarayın.'**
  String get connectionCertRejected;

  /// No description provided for @connectionUnverified.
  ///
  /// In tr, this message translates to:
  /// **'Bu PC ile ilk bağlantı: güvenlik kodunu karşılaştırın.'**
  String get connectionUnverified;

  /// No description provided for @connectionClosedByPc.
  ///
  /// In tr, this message translates to:
  /// **'PC bu cihazın bağlantısını kesti. Yeniden bağlanmak için QR kodu tekrar okutun.'**
  String get connectionClosedByPc;

  /// No description provided for @connectionClosed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı beklenmedik şekilde kapandı.'**
  String get connectionClosed;

  /// No description provided for @connectionUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı hatası: {detail}'**
  String connectionUnknown(String detail);

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get homeSettingsTooltip;

  /// No description provided for @homeTagline.
  ///
  /// In tr, this message translates to:
  /// **'Sunum kumandanız cebinizde'**
  String get homeTagline;

  /// No description provided for @homeConnecting.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanıyor...'**
  String get homeConnecting;

  /// No description provided for @homeConnectQr.
  ///
  /// In tr, this message translates to:
  /// **'QR Kod ile Bağlan'**
  String get homeConnectQr;

  /// No description provided for @homeConnectBluetooth.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth ile Bağlan'**
  String get homeConnectBluetooth;

  /// No description provided for @homeManualConnection.
  ///
  /// In tr, this message translates to:
  /// **'Manuel bağlantı'**
  String get homeManualConnection;

  /// No description provided for @homeNetworkDevices.
  ///
  /// In tr, this message translates to:
  /// **'Ağdaki Cihazlar'**
  String get homeNetworkDevices;

  /// No description provided for @homeSearching.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz aranıyor...'**
  String get homeSearching;

  /// No description provided for @homeNoDevices.
  ///
  /// In tr, this message translates to:
  /// **'Ağda cihaz bulunamadı'**
  String get homeNoDevices;

  /// No description provided for @homeRescan.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Tara'**
  String get homeRescan;

  /// No description provided for @homeRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son Bağlanılanlar'**
  String get homeRecent;

  /// No description provided for @homeRemoveFromHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişten Sil'**
  String get homeRemoveFromHistory;

  /// No description provided for @unknownPc.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen PC'**
  String get unknownPc;

  /// No description provided for @verifyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Kodunu Karşılaştırın'**
  String get verifyTitle;

  /// No description provided for @verifyConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Kodlar Aynı, Bağlan'**
  String get verifyConfirm;

  /// No description provided for @cancelAction.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get cancelAction;

  /// No description provided for @certWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Uyarısı'**
  String get certWarningTitle;

  /// No description provided for @certWarningConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yine de Bağlan ve Güncelle'**
  String get certWarningConfirm;

  /// No description provided for @manualTitle.
  ///
  /// In tr, this message translates to:
  /// **'Manuel Bağlantı'**
  String get manualTitle;

  /// No description provided for @manualIp.
  ///
  /// In tr, this message translates to:
  /// **'IP Adresi'**
  String get manualIp;

  /// No description provided for @manualPinHint.
  ///
  /// In tr, this message translates to:
  /// **'PC ekranındaki PIN'**
  String get manualPinHint;

  /// No description provided for @manualConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get manualConnect;

  /// No description provided for @manualWaitingIp.
  ///
  /// In tr, this message translates to:
  /// **'IP Bekleniyor...'**
  String get manualWaitingIp;

  /// No description provided for @manualWaitingPin.
  ///
  /// In tr, this message translates to:
  /// **'PIN Bekleniyor...'**
  String get manualWaitingPin;

  /// No description provided for @manualPortRange.
  ///
  /// In tr, this message translates to:
  /// **'Port 1-65535 arası olmalı'**
  String get manualPortRange;

  /// No description provided for @qrNotQuickRemote.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz QR kodu. \"quickremote://\" formatı bekleniyor.'**
  String get qrNotQuickRemote;

  /// No description provided for @qrMissingHost.
  ///
  /// In tr, this message translates to:
  /// **'QR kodunda IP adresi eksik.'**
  String get qrMissingHost;

  /// No description provided for @qrInvalidPort.
  ///
  /// In tr, this message translates to:
  /// **'QR kodunda geçersiz port numarası.'**
  String get qrInvalidPort;

  /// No description provided for @qrInvalidPin.
  ///
  /// In tr, this message translates to:
  /// **'QR kodundaki PIN geçersiz. Kodu yeniden tarayın.'**
  String get qrInvalidPin;

  /// No description provided for @qrInvalidFingerprint.
  ///
  /// In tr, this message translates to:
  /// **'QR kodundaki sertifika bilgisi bozuk. Kodu yeniden tarayın.'**
  String get qrInvalidFingerprint;

  /// No description provided for @qrBadFormat.
  ///
  /// In tr, this message translates to:
  /// **'QR kodu beklenen formatta değil.\nFormat: quickremote://IP:PORT:PIN'**
  String get qrBadFormat;

  /// No description provided for @scanTitle.
  ///
  /// In tr, this message translates to:
  /// **'QR Kodu Tara'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In tr, this message translates to:
  /// **'PC ekranındaki QR kodu tarayın'**
  String get scanHint;

  /// No description provided for @remoteConnectionLost.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı koptu, otomatik bağlanılıyor...'**
  String get remoteConnectionLost;

  /// No description provided for @remoteReconnected.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden bağlanıldı!'**
  String get remoteReconnected;

  /// No description provided for @remoteTabControls.
  ///
  /// In tr, this message translates to:
  /// **'Kontroller'**
  String get remoteTabControls;

  /// No description provided for @remoteTabTouchpad.
  ///
  /// In tr, this message translates to:
  /// **'Touchpad'**
  String get remoteTabTouchpad;

  /// No description provided for @remoteTabMedia.
  ///
  /// In tr, this message translates to:
  /// **'Medya'**
  String get remoteTabMedia;

  /// No description provided for @remoteConnectFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı Kurulamadı'**
  String get remoteConnectFailedTitle;

  /// No description provided for @remoteServerUnreachable.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamıyor. Lütfen PC uygulamasının açık olduğundan emin olun.'**
  String get remoteServerUnreachable;

  /// No description provided for @remoteBackHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekrana Dön'**
  String get remoteBackHome;

  /// No description provided for @remoteReconnect.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Bağlan'**
  String get remoteReconnect;

  /// No description provided for @statusConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get statusConnected;

  /// No description provided for @statusDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Kopuk'**
  String get statusDisconnected;

  /// No description provided for @disconnectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Kes'**
  String get disconnectTitle;

  /// No description provided for @disconnectContent.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kesmek ve ana ekrana dönmek istediğinize emin misiniz?'**
  String get disconnectContent;

  /// No description provided for @notesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmacı Notları'**
  String get notesTitle;

  /// No description provided for @notesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu slayt için not bulunmuyor.'**
  String get notesEmpty;

  /// No description provided for @actionStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlat'**
  String get actionStart;

  /// No description provided for @slidePickerInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir slayt numarası girin (1-{max})'**
  String slidePickerInvalid(int max);

  /// No description provided for @slideshowOpen.
  ///
  /// In tr, this message translates to:
  /// **'Slayt gösterisi açık'**
  String get slideshowOpen;

  /// No description provided for @slideCounter.
  ///
  /// In tr, this message translates to:
  /// **'Slayt: {current} / {total}'**
  String slideCounter(int current, String total);

  /// No description provided for @presentationNotOpen.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Açık Değil, {programs}\'i başlatın'**
  String presentationNotOpen(String programs);

  /// No description provided for @actionEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get actionEnd;

  /// No description provided for @blackScreen.
  ///
  /// In tr, this message translates to:
  /// **'Siyah Ekran'**
  String get blackScreen;

  /// No description provided for @whiteScreen.
  ///
  /// In tr, this message translates to:
  /// **'Beyaz Ekran'**
  String get whiteScreen;

  /// No description provided for @actionPrev.
  ///
  /// In tr, this message translates to:
  /// **'Önceki'**
  String get actionPrev;

  /// No description provided for @actionNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get actionNext;

  /// No description provided for @nowPlaying.
  ///
  /// In tr, this message translates to:
  /// **'Şu An Çalan'**
  String get nowPlaying;

  /// No description provided for @systemVolume.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Sesi'**
  String get systemVolume;

  /// No description provided for @slideMedia.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Medyası'**
  String get slideMedia;

  /// No description provided for @colorRed.
  ///
  /// In tr, this message translates to:
  /// **'Kırmızı'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In tr, this message translates to:
  /// **'Mavi'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In tr, this message translates to:
  /// **'Sarı'**
  String get colorYellow;

  /// No description provided for @colorWhite.
  ///
  /// In tr, this message translates to:
  /// **'Beyaz'**
  String get colorWhite;

  /// No description provided for @colorPurple.
  ///
  /// In tr, this message translates to:
  /// **'Mor'**
  String get colorPurple;

  /// No description provided for @penColorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kalem Rengi'**
  String get penColorTitle;

  /// No description provided for @highlighterColorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vurgulayıcı Rengi'**
  String get highlighterColorTitle;

  /// No description provided for @toolPen.
  ///
  /// In tr, this message translates to:
  /// **'Kalem'**
  String get toolPen;

  /// No description provided for @toolHighlight.
  ///
  /// In tr, this message translates to:
  /// **'Vurgula'**
  String get toolHighlight;

  /// No description provided for @toolEraser.
  ///
  /// In tr, this message translates to:
  /// **'Silgi'**
  String get toolEraser;

  /// No description provided for @selectTool.
  ///
  /// In tr, this message translates to:
  /// **'{tool} aracını seç'**
  String selectTool(String tool);

  /// No description provided for @clearInk.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clearInk;

  /// No description provided for @clearInkTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Tüm çizimleri temizle'**
  String get clearInkTooltip;

  /// No description provided for @toolLaser.
  ///
  /// In tr, this message translates to:
  /// **'Lazer'**
  String get toolLaser;

  /// No description provided for @unknownMedia.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Medya'**
  String get unknownMedia;

  /// No description provided for @noMedia.
  ///
  /// In tr, this message translates to:
  /// **'Medya Yok'**
  String get noMedia;

  /// No description provided for @unknownArtist.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Sanatçı'**
  String get unknownArtist;

  /// No description provided for @nothingPlaying.
  ///
  /// In tr, this message translates to:
  /// **'Şu an bir şey çalmıyor'**
  String get nothingPlaying;

  /// No description provided for @mediaPause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get mediaPause;

  /// No description provided for @mediaPlay.
  ///
  /// In tr, this message translates to:
  /// **'Oynat'**
  String get mediaPlay;

  /// No description provided for @mediaRewind.
  ///
  /// In tr, this message translates to:
  /// **'Başa Sar'**
  String get mediaRewind;

  /// No description provided for @tapForTool.
  ///
  /// In tr, this message translates to:
  /// **'Tek dokunuş → {tool}'**
  String tapForTool(String tool);

  /// No description provided for @doubleTapSelected.
  ///
  /// In tr, this message translates to:
  /// **'Çift dokunuş → Seçili araç'**
  String get doubleTapSelected;

  /// No description provided for @volumeMuted.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz'**
  String get volumeMuted;

  /// No description provided for @volumeOn.
  ///
  /// In tr, this message translates to:
  /// **'Sesli'**
  String get volumeOn;

  /// No description provided for @btUnsupportedLong.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz Bluetooth HID özelliğini desteklemiyor.\nWiFi modunu kullanın.'**
  String get btUnsupportedLong;

  /// No description provided for @btPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzin gerekiyor'**
  String get btPermissionTitle;

  /// No description provided for @btPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun klavye ve fare olarak bağlanabilmesi için “Yakındaki cihazlar” izni gerekiyor.'**
  String get btPermissionDenied;

  /// No description provided for @btConnectingTo.
  ///
  /// In tr, this message translates to:
  /// **'{device} ile bağlantı kuruluyor...'**
  String btConnectingTo(String device);

  /// No description provided for @btMakeVisible.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu görünür yap'**
  String get btMakeVisible;

  /// No description provided for @btMakeVisibleHint.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar telefonu yalnızca telefon görünürken listeler.'**
  String get btMakeVisibleHint;

  /// No description provided for @btVisibleFor.
  ///
  /// In tr, this message translates to:
  /// **'{minutes, plural, other{Telefon {minutes} dakika boyunca görünür.}}'**
  String btVisibleFor(int minutes);

  /// No description provided for @btVisibleRefused.
  ///
  /// In tr, this message translates to:
  /// **'Telefon görünür yapılmadı.'**
  String get btVisibleRefused;

  /// No description provided for @btHidUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Telefon klavye olarak kaydedilemedi. Başka bir Bluetooth klavye uygulaması açıksa kapatıp tekrar deneyin.'**
  String get btHidUnavailable;

  /// No description provided for @btHostRefreshing.
  ///
  /// In tr, this message translates to:
  /// **'QuickRemote PC bağlantıyı hazırlıyor...'**
  String get btHostRefreshing;

  /// No description provided for @btHostUnawareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar telefonu klavye olarak kabul etmiyor'**
  String get btHostUnawareTitle;

  /// No description provided for @btHostUnawareBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu çoğunlukla telefon bu bilgisayarla daha önce, QuickRemote açık değilken eşleştirildiğinde olur (örneğin ses ya da dosya aktarımı için): bilgisayar telefonu klavye olarak tanımaz. Bilgisayarda bir kez şunu yapın:'**
  String get btHostUnawareBody;

  /// No description provided for @btHostUnawareWindows.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar → Bluetooth ve cihazlar → Cihazlar’da telefonu bulun ve “…” menüsünden “Cihazı kaldır”ı seçin. Sonra bu ekran açıkken “Cihaz ekle” ile yeniden ekleyin.'**
  String get btHostUnawareWindows;

  /// No description provided for @btHostUnawareLinux.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth ayarlarında telefonun bağlantısını kesip yeniden bağlayın. Olmazsa telefonu kaldırın ve bu ekran açıkken yeniden eşleştirin.'**
  String get btHostUnawareLinux;

  /// No description provided for @btHostUnawareAuto.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayarda QuickRemote PC açıksa bunu kendisi yapar.'**
  String get btHostUnawareAuto;

  /// No description provided for @btHostUnawareWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar kabul edince kumanda kendiliğinden açılır.'**
  String get btHostUnawareWaiting;

  /// No description provided for @btErrorRetry.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth hatası. Tekrar deneyin.'**
  String get btErrorRetry;

  /// No description provided for @btWaitingPairing.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme bekleniyor...'**
  String get btWaitingPairing;

  /// No description provided for @btPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor...'**
  String get btPreparing;

  /// No description provided for @btNotConnectedRetrying.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanılmadı, tekrar deneniyor'**
  String get btNotConnectedRetrying;

  /// No description provided for @btOnYourComputer.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayarda bir kez eşleştirin'**
  String get btOnYourComputer;

  /// No description provided for @btLinuxStep1.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth ayarlarını açın: KDE’de Sistem Ayarları → Bluetooth, GNOME’da Ayarlar → Bluetooth.'**
  String get btLinuxStep1;

  /// No description provided for @btLinuxStep2.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth’u açın ve cihaz aramayı başlatın. KDE’de “Cihaz ekle”ye basın; GNOME bu sayfa açıkken kendisi arar.'**
  String get btLinuxStep2;

  /// No description provided for @btStepPickPhone.
  ///
  /// In tr, this message translates to:
  /// **'Listede telefonunuzun adını seçin. Görünmüyorsa yukarıdaki “Telefonu görünür yap”a basın.'**
  String get btStepPickPhone;

  /// No description provided for @btStepConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda ve bilgisayarda aynı 6 haneli kod çıkar. Kodlar aynıysa ikisinde de onaylayın.'**
  String get btStepConfirm;

  /// No description provided for @btWindowsStep1.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar’ı açın (Windows tuşu + I).'**
  String get btWindowsStep1;

  /// No description provided for @btWindowsStep2.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth ve cihazlar → Cihaz ekle → Bluetooth’u seçin. Windows 10’da: Bluetooth ve diğer cihazlar → Bluetooth veya başka cihaz ekle.'**
  String get btWindowsStep2;

  /// No description provided for @btPermissionAllow.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get btPermissionAllow;

  /// No description provided for @btPermissionSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get btPermissionSettings;

  /// No description provided for @btPermissionSettingsHint.
  ///
  /// In tr, this message translates to:
  /// **'İzin daha önce reddedildiği için artık yalnızca Ayarlar’dan verilebilir: İzinler → Yakındaki cihazlar → İzin ver.'**
  String get btPermissionSettingsHint;

  /// No description provided for @btOffTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth kapalı'**
  String get btOffTitle;

  /// No description provided for @btOffBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefon bilgisayara Bluetooth ile klavye ve fare olarak bağlanır. Bluetooth açılınca bağlantı kendiliğinden sürer.'**
  String get btOffBody;

  /// No description provided for @btTurnOn.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth’u aç'**
  String get btTurnOn;

  /// No description provided for @btOffDuringRemote.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun Bluetooth’u kapandı. Açılınca kumanda yeniden bağlanır.'**
  String get btOffDuringRemote;

  /// No description provided for @btStepPickPhoneNamed.
  ///
  /// In tr, this message translates to:
  /// **'Listede “{name}” adını seçin. Görünmüyorsa yukarıdaki “Telefonu görünür yap”a basın.'**
  String btStepPickPhoneNamed(String name);

  /// No description provided for @btTroubleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanmıyor mu?'**
  String get btTroubleTitle;

  /// No description provided for @btTroubleNearby.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayarın Bluetooth’u açık olsun, bilgisayar uykuda olmasın ve telefon birkaç metre yakınında dursun.'**
  String get btTroubleNearby;

  /// No description provided for @btTroubleNotListed.
  ///
  /// In tr, this message translates to:
  /// **'Telefon listede yoksa “Telefonu görünür yap”a basın ve bilgisayarda aramayı yeniden başlatın.'**
  String get btTroubleNotListed;

  /// No description provided for @btTroubleAlreadyPaired.
  ///
  /// In tr, this message translates to:
  /// **'Telefon bilgisayarda zaten eşleştirilmiş görünüyor ama bağlanmıyorsa telefonu bilgisayardan kaldırın ve bu ekran açıkken yeniden ekleyin.'**
  String get btTroubleAlreadyPaired;

  /// No description provided for @btTroubleBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayarın Bluetooth ayarlarında telefon engellenmişse engeli kaldırın.'**
  String get btTroubleBlocked;

  /// No description provided for @btTroubleSeveral.
  ///
  /// In tr, this message translates to:
  /// **'Telefon birden fazla bilgisayarla eşleştirilmişse hangisine bağlanacağını bilemez: istediğiniz bilgisayarın Bluetooth ayarlarında telefona “Bağlan” deyin.'**
  String get btTroubleSeveral;

  /// No description provided for @btTroubleOtherApp.
  ///
  /// In tr, this message translates to:
  /// **'Telefon aynı anda tek bir uygulama için klavye olabilir. Başka bir Bluetooth klavye ya da fare uygulaması açıksa kapatın.'**
  String get btTroubleOtherApp;

  /// No description provided for @btConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlandı!'**
  String get btConnected;

  /// No description provided for @unknownDevice.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen cihaz'**
  String get unknownDevice;

  /// No description provided for @btOpeningRemote.
  ///
  /// In tr, this message translates to:
  /// **'Uzaktan kontrol açılıyor...'**
  String get btOpeningRemote;

  /// No description provided for @btUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmiyor'**
  String get btUnsupported;

  /// No description provided for @btUnsupportedShort.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz Bluetooth HID\'i desteklemiyor.'**
  String get btUnsupportedShort;

  /// No description provided for @btUseWifi.
  ///
  /// In tr, this message translates to:
  /// **'WiFi Modunu Kullan'**
  String get btUseWifi;

  /// No description provided for @errorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get errorTitle;

  /// No description provided for @btErrorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth hatası oluştu.'**
  String get btErrorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get tryAgain;

  /// No description provided for @btConnectionLost.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth bağlantısı koptu. Yeniden bağlanılıyor...'**
  String get btConnectionLost;

  /// No description provided for @btConnectedTo.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth bağlandı: {device}'**
  String btConnectedTo(String device);

  /// No description provided for @btDisconnectContent.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth bağlantısı kesilecek ve ana ekrana dönülecek.'**
  String get btDisconnectContent;

  /// No description provided for @btModeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth HID Modu'**
  String get btModeTitle;

  /// No description provided for @systemMedia.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Medyası'**
  String get systemMedia;

  /// No description provided for @btMediaLimits.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth modunda medya bilgisi, ses seviyesi göstergesi ve PowerPoint medya kontrolleri kullanılamaz. Tam özellik için WiFi modunu kullanın.'**
  String get btMediaLimits;

  /// No description provided for @btNoMediaInfo.
  ///
  /// In tr, this message translates to:
  /// **'BT modunda medya bilgisi alınamaz'**
  String get btNoMediaInfo;

  /// No description provided for @mediaPlayPause.
  ///
  /// In tr, this message translates to:
  /// **'Oynat / Duraklat'**
  String get mediaPlayPause;

  /// No description provided for @toolCursor.
  ///
  /// In tr, this message translates to:
  /// **'İmleç'**
  String get toolCursor;

  /// No description provided for @durationHms.
  ///
  /// In tr, this message translates to:
  /// **'{h}s {m}dk {s}sn'**
  String durationHms(int h, int m, int s);

  /// No description provided for @durationMs.
  ///
  /// In tr, this message translates to:
  /// **'{m}dk {s}sn'**
  String durationMs(int m, int s);

  /// No description provided for @durationS.
  ///
  /// In tr, this message translates to:
  /// **'{s}sn'**
  String durationS(int s);

  /// No description provided for @durationMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{m} dk'**
  String durationMinutes(int m);

  /// No description provided for @durationMinSec.
  ///
  /// In tr, this message translates to:
  /// **'{m} dk {s} sn'**
  String durationMinSec(int m, int s);

  /// No description provided for @durationSeconds.
  ///
  /// In tr, this message translates to:
  /// **'{s} sn'**
  String durationSeconds(int s);

  /// No description provided for @timerSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Sayacı'**
  String get timerSettingsTitle;

  /// No description provided for @timerAutoStartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Süre Seçilince Hemen Başlat'**
  String get timerAutoStartTitle;

  /// No description provided for @timerAutoStartSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kapalıyken süre seçildikten sonra sayaca dokunarak başlatılır.'**
  String get timerAutoStartSubtitle;

  /// No description provided for @earlyWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'Erken Uyarı Titreşimi'**
  String get earlyWarningTitle;

  /// No description provided for @earlyWarningSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sürenin bitimine seçilen süreler kala uyarır.'**
  String get earlyWarningSubtitle;

  /// No description provided for @warningTimes.
  ///
  /// In tr, this message translates to:
  /// **'Uyarı Süreleri'**
  String get warningTimes;

  /// No description provided for @noWarningTimes.
  ///
  /// In tr, this message translates to:
  /// **'Henüz uyarı süresi yok.'**
  String get noWarningTimes;

  /// No description provided for @timeLeft.
  ///
  /// In tr, this message translates to:
  /// **'{time} kala'**
  String timeLeft(String time);

  /// No description provided for @addWarning.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Uyarı Ekle'**
  String get addWarning;

  /// No description provided for @whenTimeIsUp.
  ///
  /// In tr, this message translates to:
  /// **'Süre Bittiğinde'**
  String get whenTimeIsUp;

  /// No description provided for @endVibration.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Titreşimi'**
  String get endVibration;

  /// No description provided for @vibrationPattern.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim Deseni'**
  String get vibrationPattern;

  /// No description provided for @vibrationFor.
  ///
  /// In tr, this message translates to:
  /// **'{time} İçin Titreşim'**
  String vibrationFor(String time);

  /// No description provided for @tapToPreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizlemek için seçeneklere dokunun'**
  String get tapToPreview;

  /// No description provided for @vibrationShort.
  ///
  /// In tr, this message translates to:
  /// **'Kısa Titreşim'**
  String get vibrationShort;

  /// No description provided for @vibrationDouble.
  ///
  /// In tr, this message translates to:
  /// **'Çift Titreşim'**
  String get vibrationDouble;

  /// No description provided for @vibrationLong.
  ///
  /// In tr, this message translates to:
  /// **'Uzun Titreşim'**
  String get vibrationLong;

  /// No description provided for @vibrationTriple.
  ///
  /// In tr, this message translates to:
  /// **'Üçlü Titreşim'**
  String get vibrationTriple;

  /// No description provided for @newWarningTime.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Uyarı Süresi'**
  String get newWarningTime;

  /// No description provided for @enterTime.
  ///
  /// In tr, this message translates to:
  /// **'Süre girin'**
  String get enterTime;

  /// No description provided for @unitSecondsLong.
  ///
  /// In tr, this message translates to:
  /// **'Saniye'**
  String get unitSecondsLong;

  /// No description provided for @unitMinutesLong.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get unitMinutesLong;

  /// No description provided for @enterValidNumber.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli bir sayı girin.'**
  String get enterValidNumber;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @patternShort.
  ///
  /// In tr, this message translates to:
  /// **'Kısa'**
  String get patternShort;

  /// No description provided for @patternLong.
  ///
  /// In tr, this message translates to:
  /// **'Uzun'**
  String get patternLong;

  /// No description provided for @patternTriple.
  ///
  /// In tr, this message translates to:
  /// **'Üçlü'**
  String get patternTriple;

  /// No description provided for @patternDouble.
  ///
  /// In tr, this message translates to:
  /// **'Çift'**
  String get patternDouble;

  /// No description provided for @clearHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişi Temizle'**
  String get clearHistory;

  /// No description provided for @noHistory.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sunum verisi yok'**
  String get noHistory;

  /// No description provided for @noHistoryHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir sunum başlatıp bitirdikten sonra\nveriler burada görünecek.'**
  String get noHistoryHint;

  /// No description provided for @historyDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Sunum kaydı silindi'**
  String get historyDeleted;

  /// No description provided for @slideCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} slayt}}'**
  String slideCount(int count);

  /// No description provided for @clearHistoryContent.
  ///
  /// In tr, this message translates to:
  /// **'Tüm sunum geçmişi silinecek. Bu işlem geri alınamaz.'**
  String get clearHistoryContent;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @historyCleared.
  ///
  /// In tr, this message translates to:
  /// **'Sunum geçmişi temizlendi'**
  String get historyCleared;

  /// No description provided for @timeUp.
  ///
  /// In tr, this message translates to:
  /// **'Sunum süresi doldu!'**
  String get timeUp;

  /// No description provided for @timeRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Sürenin bitimine {time} kaldı!'**
  String timeRemaining(String time);

  /// No description provided for @enterValidDuration.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen dakika ve/veya saniye olarak geçerli bir süre girin.'**
  String get enterValidDuration;

  /// No description provided for @setPresentationTime.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Süresi Belirle'**
  String get setPresentationTime;

  /// No description provided for @noTimeLimit.
  ///
  /// In tr, this message translates to:
  /// **'Serbest'**
  String get noTimeLimit;

  /// No description provided for @unitMinutes.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get unitMinutes;

  /// No description provided for @unitSeconds.
  ///
  /// In tr, this message translates to:
  /// **'sn'**
  String get unitSeconds;

  /// No description provided for @startWhenPicked.
  ///
  /// In tr, this message translates to:
  /// **'Seçince hemen başlat'**
  String get startWhenPicked;

  /// No description provided for @timerHelp.
  ///
  /// In tr, this message translates to:
  /// **'Dokun: başlat/duraklat · Basılı tut: yeni süre · ↻: seçili süreye dön'**
  String get timerHelp;

  /// No description provided for @actionSet.
  ///
  /// In tr, this message translates to:
  /// **'Ayarla'**
  String get actionSet;

  /// No description provided for @reportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Raporu'**
  String get reportTitle;

  /// No description provided for @totalTime.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Süre'**
  String get totalTime;

  /// No description provided for @slideCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Sayısı'**
  String get slideCountLabel;

  /// No description provided for @avgPerSlideShort.
  ///
  /// In tr, this message translates to:
  /// **'Ort/Slayt'**
  String get avgPerSlideShort;

  /// No description provided for @totalTransitions.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Geçiş: {count}'**
  String totalTransitions(int count);

  /// No description provided for @timePerSlide.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Bazlı Süre'**
  String get timePerSlide;

  /// No description provided for @copyToClipboard.
  ///
  /// In tr, this message translates to:
  /// **'Panoya Kopyala'**
  String get copyToClipboard;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @presentationDetails.
  ///
  /// In tr, this message translates to:
  /// **'Sunum Detayı'**
  String get presentationDetails;

  /// No description provided for @reportDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get reportDate;

  /// No description provided for @reportAvgPerSlide.
  ///
  /// In tr, this message translates to:
  /// **'Ort. Süre/Slayt'**
  String get reportAvgPerSlide;

  /// No description provided for @reportTransitions.
  ///
  /// In tr, this message translates to:
  /// **'Geçiş Sayısı'**
  String get reportTransitions;

  /// No description provided for @reportSlideDetails.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Detayları'**
  String get reportSlideDetails;

  /// No description provided for @reportSlide.
  ///
  /// In tr, this message translates to:
  /// **'Slayt {n}'**
  String reportSlide(int n);

  /// No description provided for @reportCopied.
  ///
  /// In tr, this message translates to:
  /// **'Rapor panoya kopyalandı'**
  String get reportCopied;

  /// No description provided for @noSlideData.
  ///
  /// In tr, this message translates to:
  /// **'Slayt verisi bulunamadı'**
  String get noSlideData;

  /// No description provided for @backgroundNotification.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda bağlantı devam ediyor...'**
  String get backgroundNotification;

  /// Home screen: how to connect, under the tagline.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki QuickRemote PC\'nin QR kodunu tarayın ya da telefonu Bluetooth ile klavye ve fare olarak bağlayın.'**
  String get homeHeroSubtitle;

  /// Label above the big slide number on the remote.
  ///
  /// In tr, this message translates to:
  /// **'Slayt'**
  String get slideLabel;

  /// Settings section header.
  ///
  /// In tr, this message translates to:
  /// **'Sunum'**
  String get settingsSectionPresentation;

  /// Settings section header.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get settingsSectionGeneral;

  /// Screen reader hint of the PC · program line in the remote header.
  ///
  /// In tr, this message translates to:
  /// **'Sunum programını seç'**
  String get remoteProgramHint;

  /// No description provided for @programSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sunum programı'**
  String get programSheetTitle;

  /// No description provided for @programSheetBody.
  ///
  /// In tr, this message translates to:
  /// **'{pc} şu programları kontrol edebilir. Gösterisi açık olan kendiliğinden kullanılır.'**
  String programSheetBody(String pc);

  /// No description provided for @programShowOpenSlide.
  ///
  /// In tr, this message translates to:
  /// **'Gösteri açık · Slayt {slide}'**
  String programShowOpenSlide(int slide);

  /// No description provided for @programShowOpen.
  ///
  /// In tr, this message translates to:
  /// **'Gösteri açık'**
  String get programShowOpen;

  /// No description provided for @programShowClosed.
  ///
  /// In tr, this message translates to:
  /// **'Gösteri açık değil'**
  String get programShowClosed;

  /// No description provided for @programPdfNote.
  ///
  /// In tr, this message translates to:
  /// **'PDF\'ler ayrıca seçilmez; öndeki pencere PDF ise o kontrol edilir.'**
  String get programPdfNote;

  /// No description provided for @programBluetoothNote.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth modunda program buradan seçilir (PowerPoint / Impress / WPS).'**
  String get programBluetoothNote;

  /// No description provided for @goToSlide.
  ///
  /// In tr, this message translates to:
  /// **'Slayta git'**
  String get goToSlide;

  /// No description provided for @goToSlideRange.
  ///
  /// In tr, this message translates to:
  /// **'1–{total} arası bir numara'**
  String goToSlideRange(int total);

  /// No description provided for @goToSlideNumber.
  ///
  /// In tr, this message translates to:
  /// **'Slayt numarası'**
  String get goToSlideNumber;

  /// No description provided for @goAction.
  ///
  /// In tr, this message translates to:
  /// **'Git'**
  String get goAction;

  /// No description provided for @notesSlide.
  ///
  /// In tr, this message translates to:
  /// **'Slayt {slide}'**
  String notesSlide(int slide);

  /// Screen reader hint of the two-line note on the slide card.
  ///
  /// In tr, this message translates to:
  /// **'Notun tamamını aç'**
  String get notesOpenHint;

  /// No description provided for @unreadableShow.
  ///
  /// In tr, this message translates to:
  /// **'WPS slayt numarasını bildirmiyor; tuşlar yine çalışır.'**
  String get unreadableShow;

  /// No description provided for @unreadableShowUserWps.
  ///
  /// In tr, this message translates to:
  /// **'Bu WPS\'i QuickRemote açmadı: slayt numarası ve notlar gelmez, tuşlar WPS penceresi öndeyken çalışır.'**
  String get unreadableShowUserWps;

  /// No description provided for @drawToolsNeedShow.
  ///
  /// In tr, this message translates to:
  /// **'Çizim araçları slayt gösterisi açıkken çalışır.'**
  String get drawToolsNeedShow;

  /// The laser tool where the program has no laser and the pointer arrow follows the phone (WPS on Windows).
  ///
  /// In tr, this message translates to:
  /// **'Ok'**
  String get toolArrow;

  /// No description provided for @colorUnavailableTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu programda renk seçilemez.'**
  String get colorUnavailableTitle;

  /// No description provided for @colorUnavailableBody.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'i QuickRemote açmadığı için kalem WPS\'in kendi rengiyle çizer.'**
  String get colorUnavailableBody;

  /// suffix: the Turkish locative ending of the number (turkishLocative).
  ///
  /// In tr, this message translates to:
  /// **'Slayt {slide}\'{suffix, select, de{deki} da{daki} te{teki} ta{taki} other{deki}} medya'**
  String slideMediaOnSlide(int slide, String suffix);

  /// No description provided for @slideMediaPlaying.
  ///
  /// In tr, this message translates to:
  /// **'Oynatılıyor'**
  String get slideMediaPlaying;

  /// No description provided for @slideMediaNotPlaying.
  ///
  /// In tr, this message translates to:
  /// **'Oynatılmıyor'**
  String get slideMediaNotPlaying;

  /// No description provided for @slideMediaStateUnknown.
  ///
  /// In tr, this message translates to:
  /// **'WPS oynatma durumunu bildirmiyor'**
  String get slideMediaStateUnknown;

  /// No description provided for @volumeDown.
  ///
  /// In tr, this message translates to:
  /// **'Sesi kıs'**
  String get volumeDown;

  /// No description provided for @volumeUp.
  ///
  /// In tr, this message translates to:
  /// **'Sesi aç'**
  String get volumeUp;

  /// No description provided for @mediaStop.
  ///
  /// In tr, this message translates to:
  /// **'Durdur'**
  String get mediaStop;

  /// No description provided for @btModeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon, {device} için klavye ve fare'**
  String btModeSubtitle(String device);

  /// No description provided for @btScreenKeys.
  ///
  /// In tr, this message translates to:
  /// **'Siyah · Beyaz ekran'**
  String get btScreenKeys;

  /// No description provided for @btPreparingBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefon klavye ve fare olarak kaydediliyor.'**
  String get btPreparingBody;

  /// No description provided for @btConnectingBody.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanınca kumanda kendiliğinden açılır.'**
  String get btConnectingBody;

  /// No description provided for @btRetryingBody.
  ///
  /// In tr, this message translates to:
  /// **'{device} açık ve Bluetooth\'u açıksa birkaç saniye içinde bağlanır.'**
  String btRetryingBody(String device);

  /// No description provided for @btRetryingBodyUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar açık ve Bluetooth\'u açıksa birkaç saniye içinde bağlanır.'**
  String get btRetryingBodyUnknown;

  /// No description provided for @btRefreshingBody.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayar telefonun klavye kaydını yeniden okuyor.'**
  String get btRefreshingBody;

  /// No description provided for @btProgramSheetBody.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth\'ta bilgisayar programı bildiremez; tuşlar seçtiğiniz programın kısayollarıyla gönderilir.'**
  String get btProgramSheetBody;

  /// No description provided for @btToolsFull.
  ///
  /// In tr, this message translates to:
  /// **'Lazer, kalem, vurgula, silgi'**
  String get btToolsFull;

  /// No description provided for @btToolsImpress.
  ///
  /// In tr, this message translates to:
  /// **'İmleç, kalem'**
  String get btToolsImpress;

  /// No description provided for @btImpressToolsNote.
  ///
  /// In tr, this message translates to:
  /// **'Impress\'te lazer, vurgulayıcı ve silgi kısayolu yok; imleç işaretçi olur.'**
  String get btImpressToolsNote;

  /// No description provided for @btWpsToolsNote.
  ///
  /// In tr, this message translates to:
  /// **'WPS\'te lazer Ctrl+R ile açılır; Windows\'taki WPS\'te Silgi başka bir iş yapabilir.'**
  String get btWpsToolsNote;

  /// No description provided for @verifyIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bu PC ile ilk kez bağlanıyorsunuz. PC ekranındaki güvenlik kodu şu olmalı:'**
  String get verifyIntro;

  /// No description provided for @verifyNote.
  ///
  /// In tr, this message translates to:
  /// **'Kodlar aynı değilse bağlanmayın: ağdaki başka bir cihaz PC gibi davranıyor olabilir. QR kodu okutarak bu adımı atlayabilirsiniz.'**
  String get verifyNote;

  /// No description provided for @certWarningIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı. PC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir. PC ekranındaki güvenlik kodu şu olmalı:'**
  String get certWarningIntro;

  /// No description provided for @certWarningNote.
  ///
  /// In tr, this message translates to:
  /// **'Kodlar aynı değilse bağlanmayın.'**
  String get certWarningNote;

  /// No description provided for @homeNoDevicesHint.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayarda QuickRemote PC açık ve aynı Wi-Fi\'da olmalı.'**
  String get homeNoDevicesHint;

  /// No description provided for @languageSystemNote.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili, telefonun dilini izler; Türkçe ya da İngilizce değilse İngilizce olur.'**
  String get languageSystemNote;

  /// No description provided for @historySwipeHint.
  ///
  /// In tr, this message translates to:
  /// **'Silmek için sola kaydırın'**
  String get historySwipeHint;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{theme} · {mode}'**
  String settingsThemeSubtitle(String theme, String mode);

  /// No description provided for @themeModeHeader.
  ///
  /// In tr, this message translates to:
  /// **'Açık / Koyu'**
  String get themeModeHeader;

  /// No description provided for @themeModeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeModeDark;

  /// No description provided for @themeColorHeader.
  ///
  /// In tr, this message translates to:
  /// **'Renk teması'**
  String get themeColorHeader;

  /// No description provided for @themeCobaltNote.
  ///
  /// In tr, this message translates to:
  /// **'Kobalt sistemle birlikte açık ya da koyu olur; elle de seçilebilir.'**
  String get themeCobaltNote;

  /// No description provided for @themeDarkOnlyNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu tema yalnız koyu; karanlık salon için tasarlandı.'**
  String get themeDarkOnlyNote;

  /// No description provided for @themeLightOnlyNote.
  ///
  /// In tr, this message translates to:
  /// **'Gün Batımı yalnız açık; aydınlık odalar için.'**
  String get themeLightOnlyNote;

  /// No description provided for @themeCobalt.
  ///
  /// In tr, this message translates to:
  /// **'Kobalt'**
  String get themeCobalt;

  /// No description provided for @themeOled.
  ///
  /// In tr, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @themeHighContrast.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek kontrast'**
  String get themeHighContrast;

  /// No description provided for @themeMint.
  ///
  /// In tr, this message translates to:
  /// **'Nane'**
  String get themeMint;

  /// No description provided for @themeViolet.
  ///
  /// In tr, this message translates to:
  /// **'Mor'**
  String get themeViolet;

  /// No description provided for @themeSunset.
  ///
  /// In tr, this message translates to:
  /// **'Gün Batımı'**
  String get themeSunset;
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
