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
  /// **'Sunumlarınızı telefondan kontrol edin'**
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

  /// No description provided for @verifyContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu PC ile ilk kez bağlanıyorsunuz. PC ekranındaki güvenlik kodu şu olmalı:\n\n{code}\n\nKodlar aynı değilse bağlanmayın: ağdaki başka bir cihaz PC gibi davranıyor olabilir. QR kodu okutarak bu adımı atlayabilirsiniz.'**
  String verifyContent(String code);

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

  /// No description provided for @certWarningContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı.\n\nPC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir. PC ekranındaki güvenlik kodu şu olmalı:\n\n{code}\n\nKodlar aynı değilse bağlanmayın.'**
  String certWarningContent(String code);

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
  /// **'Slayt Notları'**
  String get notesTitle;

  /// No description provided for @notesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu slayt için not bulunmuyor.'**
  String get notesEmpty;

  /// No description provided for @startPresentation.
  ///
  /// In tr, this message translates to:
  /// **'Sunuma Başla'**
  String get startPresentation;

  /// No description provided for @slidePickerRange.
  ///
  /// In tr, this message translates to:
  /// **'Slayt (1-{total})'**
  String slidePickerRange(int total);

  /// No description provided for @slidePickerHint.
  ///
  /// In tr, this message translates to:
  /// **'Slayt Numarası (Örn: 5)'**
  String get slidePickerHint;

  /// No description provided for @slidePickerMax.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum {total} slayt girebilirsiniz.'**
  String slidePickerMax(int total);

  /// No description provided for @slidePickerEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Boş bırakırsanız baştan başlar.'**
  String get slidePickerEmpty;

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

  /// No description provided for @notes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notes;

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
  /// **'Geri'**
  String get actionPrev;

  /// No description provided for @actionNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get actionNext;

  /// Joins program names: "PowerPoint or WPS Office". Keep the spaces.
  ///
  /// In tr, this message translates to:
  /// **' veya '**
  String get listOr;

  /// No description provided for @mediaControlTitle.
  ///
  /// In tr, this message translates to:
  /// **'Medya Kontrolü'**
  String get mediaControlTitle;

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

  /// No description provided for @toolHighlighter.
  ///
  /// In tr, this message translates to:
  /// **'Vurgulayıcı'**
  String get toolHighlighter;

  /// No description provided for @tapForTool.
  ///
  /// In tr, this message translates to:
  /// **'Tek dokunuş → {tool}'**
  String tapForTool(String tool);

  /// No description provided for @doubleTapSelected.
  ///
  /// In tr, this message translates to:
  /// **'Çift dokunuş → Seçili Araç'**
  String get doubleTapSelected;

  /// No description provided for @volumeMuted.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz'**
  String get volumeMuted;

  /// No description provided for @volumeOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get volumeOn;

  /// No description provided for @btUnsupportedLong.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz Bluetooth HID özelliğini desteklemiyor.\nWiFi modunu kullanın.'**
  String get btUnsupportedLong;

  /// No description provided for @btPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth izni reddedildi. Ayarlardan izin vermelisiniz.'**
  String get btPermissionDenied;

  /// No description provided for @btDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth kapalı. Açıp tekrar deneyin.'**
  String get btDisabled;

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
  /// **'Bilgisayar telefonu ancak görünürken listesinde bulur.'**
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
  /// **'Bilgisayar telefonu klavye olarak tanımıyor'**
  String get btHostUnawareTitle;

  /// No description provided for @btHostUnawareBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefon bu bilgisayarla QuickRemote açık değilken eşleştirilmiş. Bilgisayarda bir kez şunu yapın:'**
  String get btHostUnawareBody;

  /// No description provided for @btHostUnawareWindows.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar → Bluetooth ve cihazlar\'da telefonu kaldırın, sonra bu ekran açıkken yeniden ekleyin.'**
  String get btHostUnawareWindows;

  /// No description provided for @btHostUnawareLinux.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth ayarlarında telefonun bağlantısını kesip yeniden bağlayın. Olmazsa telefonu kaldırıp bu ekran açıkken yeniden eşleştirin.'**
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

  /// No description provided for @btWaitingConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı bekleniyor...'**
  String get btWaitingConnection;

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
  /// **'Bilgisayarınızda şunları yapın:'**
  String get btOnYourComputer;

  /// No description provided for @btLinuxStep1.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Ayarları\'nı açın (KDE: Bluetooth, GNOME: Ayarlar → Bluetooth)'**
  String get btLinuxStep1;

  /// No description provided for @btLinuxStep2.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth\'un açık olduğundan emin olun'**
  String get btLinuxStep2;

  /// No description provided for @btLinuxStep3.
  ///
  /// In tr, this message translates to:
  /// **'\"Yeni cihaz ekle\" / cihaz aramayı başlatın'**
  String get btLinuxStep3;

  /// No description provided for @btStepPickPhone.
  ///
  /// In tr, this message translates to:
  /// **'Listeden telefonunuzun adını seçin'**
  String get btStepPickPhone;

  /// No description provided for @btStepConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirmeyi onaylayın'**
  String get btStepConfirm;

  /// No description provided for @btWindowsStep1.
  ///
  /// In tr, this message translates to:
  /// **'Windows Ayarlar\'ı açın'**
  String get btWindowsStep1;

  /// No description provided for @btWindowsStep2.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth ve diğer cihazlar\'a gidin'**
  String get btWindowsStep2;

  /// No description provided for @btWindowsStep3.
  ///
  /// In tr, this message translates to:
  /// **'\"Cihaz ekle\" butonuna basın'**
  String get btWindowsStep3;

  /// No description provided for @btPairOnce.
  ///
  /// In tr, this message translates to:
  /// **'Bu ekran açıkken bir kez eşleştirmeniz yeterli; sonraki bağlantılar otomatiktir.'**
  String get btPairOnce;

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

  /// No description provided for @btTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef:'**
  String get btTarget;

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
