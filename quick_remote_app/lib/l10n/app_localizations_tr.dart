// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsTimerTitle => 'Sunum Sayacı Ayarları';

  @override
  String get settingsTimerSubtitle =>
      'Otomatik başlatma, titreşim ve erken uyarılar';

  @override
  String get settingsHistoryTitle => 'Sunum Geçmişi';

  @override
  String get settingsHistorySubtitle =>
      'Önceki sunum istatistikleri ve notları';

  @override
  String get settingsKeepInkTitle => 'Slayt Değişince Çizimleri Koru';

  @override
  String get settingsKeepInkSubtitle =>
      'Çizimler kendi slaytında kalır, o slayta dönünce yeniden görünür. Kapalıyken ileri veya geri gidince kalemle çizilenler silinir.';

  @override
  String get settingsSlidePreviewTitle => 'Slayt Önizlemesi';

  @override
  String get settingsSlidePreviewSubtitle =>
      'Bilgisayardaki slaydın resmi kumandada görünür. Resim slaydın kaydedilmiş hâlidir: animasyonun o anki adımı, çizimler ve oynayan video görünmez.';

  @override
  String get presenterViewTitle => 'Sunucu görünümü';

  @override
  String get presenterViewOpenHint => 'Sunucu görünümünü aç';

  @override
  String get presenterNextUp => 'Sıradaki';

  @override
  String get presenterLastSlide => 'Son slayt';

  @override
  String get presenterLaserHint => 'Lazeri perdede göstermek için slayta dokun';

  @override
  String slidePreviewLabel(int slide) {
    return 'Slayt $slide önizlemesi';
  }

  @override
  String get screenPreviewLabel => 'Bilgisayarın ekranı';

  @override
  String get settingsLanguageTitle => 'Dil';

  @override
  String get languageSystem => 'Sistem dili';

  @override
  String get errorSlideshowNotRunning => 'Slayt gösterisi aktif değil.';

  @override
  String get errorSlideshowStartFailed => 'Slayt gösterisi başlatılamadı.';

  @override
  String errorSlideStateFailed(String info) {
    return 'Slayt durumu alınamadı: $info';
  }

  @override
  String get errorPresenterNotResponding => 'Sunum programı yanıt vermiyor.';

  @override
  String get errorPresenterUnreachable => 'Sunum programına ulaşılamadı.';

  @override
  String get errorPenColorFailed => 'Kalem rengi değiştirilemedi.';

  @override
  String get errorInkEraseFailed => 'Mürekkep silinemedi.';

  @override
  String get errorPointerBusy =>
      'Başka bir cihaz şu an lazeri veya kalemi kullanıyor.';

  @override
  String get errorNoMedia => 'Bu slaytta medya yok.';

  @override
  String get errorMediaReloaded =>
      'Slayt yeniden yüklendi, video baştan başladı. Kontrol için tekrar deneyin.';

  @override
  String get errorMediaNoTrigger =>
      'Bu slayttaki medya kumandadan kontrol edilemiyor.';

  @override
  String get errorMediaNeedsFullscreen =>
      'Slayt medyası yalnızca tam ekran slayt gösterisinde kontrol edilebilir.';

  @override
  String get errorScreenBlanked =>
      'Ekran karartılmışken slayt medyası kontrol edilemez.';

  @override
  String get errorImpressUnreachable => 'LibreOffice Impress\'e bağlanılamadı.';

  @override
  String get errorImpressNoUno =>
      'LibreOffice Python (UNO) desteği bulunamadı.';

  @override
  String get errorImpressUntrustedPipe =>
      'LibreOffice bağlantı soketi başka bir kullanıcıya ait; bağlanılmadı.';

  @override
  String get errorWpsNotInstalled => 'WPS desteği kurulu değil.';

  @override
  String get errorWpsNoPresentation => 'WPS\'te açık sunum yok.';

  @override
  String get errorWpsStartFailed => 'WPS başlatılamadı.';

  @override
  String get errorWpsOpenFromApp =>
      'WPS\'te bu özellik yalnızca QuickRemote\'tan açılan sunumda çalışır (\"Sunumu WPS ile aç\").';

  @override
  String get errorWpsHighlighterNeedsFocus =>
      'WPS\'te fosforlu kalem yalnızca slayt gösterisi odaktayken seçilebilir.';

  @override
  String get errorWpsNoMediaRewind => 'WPS\'te video başa sarılamıyor.';

  @override
  String get errorWpsTakeOverNoWps => 'PC\'de açık bir WPS bulunamadı.';

  @override
  String get errorWpsTakeOverNoFile =>
      'Sunum kaydedilmemiş: önce WPS\'te kaydedin.';

  @override
  String get errorWpsTakeOverNotClosed =>
      'WPS kapanmadı: PC\'deki kaydetme sorusunu yanıtlayıp tekrar deneyin.';

  @override
  String get errorWpsTakeOverFailed =>
      'Sunum QuickRemote\'un WPS\'inde açılamadı.';

  @override
  String get errorLockFailed => 'Bilgisayar kilitlenemedi.';

  @override
  String errorCommandFailed(String info) {
    return 'Sunum komutu başarısız: $info';
  }

  @override
  String get errorUnknown => 'İşlem başarısız oldu.';

  @override
  String get connectionPinEmpty => 'PIN kodu boş olamaz.';

  @override
  String get connectionWrongPin => 'PIN kodu yanlış.';

  @override
  String get connectionRateLimited =>
      'Çok fazla hatalı deneme. Bir dakika sonra tekrar deneyin.';

  @override
  String get connectionTimeout => 'Bağlantı zaman aşımına uğradı.';

  @override
  String get connectionAuthTimeout => 'Kimlik doğrulama zaman aşımına uğradı.';

  @override
  String connectionServerNotFound(String detail) {
    return 'Sunucuya ulaşılamadı: $detail';
  }

  @override
  String get connectionCertMismatch =>
      'Sertifika değişti! Olası MITM saldırısı veya cihaz formatlanmış olabilir.';

  @override
  String get connectionCertRejected =>
      'PC\'nin sertifikası QR kodundakiyle eşleşmiyor. Bağlantı güvenli değil, bağlanılmadı. QR kodunu yeniden tarayın.';

  @override
  String get connectionUnverified =>
      'Bu PC ile ilk bağlantı: güvenlik kodunu karşılaştırın.';

  @override
  String get connectionClosedByPc =>
      'PC bu cihazın bağlantısını kesti. Yeniden bağlanmak için QR kodu tekrar okutun.';

  @override
  String get connectionClosed => 'Bağlantı beklenmedik şekilde kapandı.';

  @override
  String connectionUnknown(String detail) {
    return 'Bağlantı hatası: $detail';
  }

  @override
  String get cancel => 'İptal';

  @override
  String get close => 'Kapat';

  @override
  String get homeSettingsTooltip => 'Ayarlar';

  @override
  String get homeTagline => 'Sunum kumandanız cebinizde';

  @override
  String get homeConnecting => 'Bağlanıyor...';

  @override
  String get homeConnectQr => 'QR Kod ile Bağlan';

  @override
  String get homeConnectBluetooth => 'Bluetooth ile Bağlan';

  @override
  String get homeManualConnection => 'Manuel bağlantı';

  @override
  String get homeNetworkDevices => 'Ağdaki Cihazlar';

  @override
  String get homeSearching => 'Cihaz aranıyor...';

  @override
  String get homeNoDevices => 'Ağda cihaz bulunamadı';

  @override
  String get homeRescan => 'Yeniden Tara';

  @override
  String get homeSaved => 'Kayıtlı';

  @override
  String get homeSavedHint => 'Kayıtlı PIN ile bağlanır';

  @override
  String get launchNoRecentPc =>
      'Bağlanılacak bir PC henüz yok. Önce QR kodla ya da PIN ile bir kez bağlanın.';

  @override
  String launchPcNotFound(String name) {
    return '$name ağda bulunamadı. QuickRemote PC açık mı?';
  }

  @override
  String get unknownPc => 'Bilinmeyen PC';

  @override
  String get verifyTitle => 'Güvenlik Kodunu Karşılaştırın';

  @override
  String get verifyConfirm => 'Kodlar Aynı, Bağlan';

  @override
  String get cancelAction => 'İptal Et';

  @override
  String get certWarningTitle => 'Güvenlik Uyarısı';

  @override
  String get certWarningConfirm => 'Yine de Bağlan ve Güncelle';

  @override
  String get manualTitle => 'Manuel Bağlantı';

  @override
  String get manualIp => 'IP Adresi';

  @override
  String get manualPinHint => 'PC ekranındaki PIN';

  @override
  String get manualConnect => 'Bağlan';

  @override
  String get manualWaitingIp => 'IP Bekleniyor...';

  @override
  String get manualWaitingPin => 'PIN Bekleniyor...';

  @override
  String get manualPortRange => 'Port 1-65535 arası olmalı';

  @override
  String get qrNotQuickRemote =>
      'Geçersiz QR kodu. \"quickremote://\" formatı bekleniyor.';

  @override
  String get qrMissingHost => 'QR kodunda IP adresi eksik.';

  @override
  String get qrInvalidPort => 'QR kodunda geçersiz port numarası.';

  @override
  String get qrInvalidPin => 'QR kodundaki PIN geçersiz. Kodu yeniden tarayın.';

  @override
  String get qrInvalidFingerprint =>
      'QR kodundaki sertifika bilgisi bozuk. Kodu yeniden tarayın.';

  @override
  String get qrBadFormat =>
      'QR kodu beklenen formatta değil.\nFormat: quickremote://IP:PORT:PIN';

  @override
  String get scanTitle => 'QR Kodu Tara';

  @override
  String get scanHint => 'PC ekranındaki QR kodu tarayın';

  @override
  String get remoteConnectionLost => 'Bağlantı koptu, otomatik bağlanılıyor...';

  @override
  String get remoteReconnected => 'Yeniden bağlanıldı!';

  @override
  String get remoteTabControls => 'Kontroller';

  @override
  String get remoteTabTouchpad => 'Touchpad';

  @override
  String get remoteTabMedia => 'Medya';

  @override
  String get remoteConnectFailedTitle => 'Bağlantı Kurulamadı';

  @override
  String get remoteServerUnreachable =>
      'Sunucuya ulaşılamıyor. Lütfen PC uygulamasının açık olduğundan emin olun.';

  @override
  String get remoteBackHome => 'Ana Ekrana Dön';

  @override
  String get remoteNewPinTitle => 'PC\'nin PIN\'i değişti';

  @override
  String get remoteNewPinMessage =>
      'PC yeniden başlatıldığı için yeni bir PIN üretti. PC ekranındaki PIN\'i girin, aynı bilgisayara yeniden bağlanalım.';

  @override
  String get remoteEnterPin => 'PIN\'i gir';

  @override
  String get remoteReconnect => 'Yeniden Bağlan';

  @override
  String get statusConnected => 'Bağlı';

  @override
  String get statusDisconnected => 'Kopuk';

  @override
  String get disconnectTitle => 'Bağlantıyı Kes';

  @override
  String get disconnectContent =>
      'Bağlantıyı kesmek ve ana ekrana dönmek istediğinize emin misiniz?';

  @override
  String get notesTitle => 'Konuşmacı Notları';

  @override
  String get notesEmpty => 'Bu slayt için not bulunmuyor.';

  @override
  String get actionStart => 'Başlat';

  @override
  String slidePickerInvalid(int max) {
    return 'Geçerli bir slayt numarası girin (1-$max)';
  }

  @override
  String get slideshowOpen => 'Slayt gösterisi açık';

  @override
  String slideCounter(int current, String total) {
    return 'Slayt: $current / $total';
  }

  @override
  String presentationNotOpen(String programs) {
    return 'Sunum Açık Değil, $programs\'i başlatın';
  }

  @override
  String get actionEnd => 'Bitir';

  @override
  String get actionFullScreen => 'Tam ekran';

  @override
  String viewerInFront(String front) {
    String _temp0 = intl.Intl.selectLogic(front, {
      'browser': 'Tarayıcı önde · yalnız sayfa geçişi ve tam ekran',
      'other': 'PDF açık · yalnız sayfa geçişi ve tam ekran',
    });
    return '$_temp0';
  }

  @override
  String get blackScreen => 'Siyah Ekran';

  @override
  String get whiteScreen => 'Beyaz Ekran';

  @override
  String get actionPrev => 'Önceki';

  @override
  String get actionNext => 'Sonraki';

  @override
  String get nowPlaying => 'Şu An Çalan';

  @override
  String get systemVolume => 'Sistem Sesi';

  @override
  String get slideMedia => 'Slayt Medyası';

  @override
  String get colorRed => 'Kırmızı';

  @override
  String get colorBlue => 'Mavi';

  @override
  String get colorGreen => 'Yeşil';

  @override
  String get colorYellow => 'Sarı';

  @override
  String get colorWhite => 'Beyaz';

  @override
  String get colorPurple => 'Mor';

  @override
  String get penColorTitle => 'Kalem Rengi';

  @override
  String get highlighterColorTitle => 'Vurgulayıcı Rengi';

  @override
  String get toolPen => 'Kalem';

  @override
  String get toolHighlight => 'Vurgula';

  @override
  String get toolEraser => 'Silgi';

  @override
  String selectTool(String tool) {
    return '$tool aracını seç';
  }

  @override
  String get clearInk => 'Temizle';

  @override
  String get clearInkTooltip => 'Tüm çizimleri temizle';

  @override
  String get clearInkUndoTooltip =>
      'Tüm çizimleri temizle; basılı tutunca son çizgiyi geri alır';

  @override
  String get toolSpotlight => 'Spot ışığı';

  @override
  String get toolZoom => 'Büyüteç';

  @override
  String get laserStyleTitle => 'Lazer türü';

  @override
  String get laserStyleSpotlightNote =>
      'Spot ışığında ekran kararır, parmağınızın altı aydınlık kalır.';

  @override
  String get toolLaser => 'Lazer';

  @override
  String get unknownMedia => 'Bilinmeyen Medya';

  @override
  String get noMedia => 'Medya Yok';

  @override
  String get unknownArtist => 'Bilinmeyen Sanatçı';

  @override
  String get nothingPlaying => 'Şu an bir şey çalmıyor';

  @override
  String get mediaPause => 'Duraklat';

  @override
  String get mediaPlay => 'Oynat';

  @override
  String get mediaRewind => 'Başa Sar';

  @override
  String tapForTool(String tool) {
    return 'Tek dokunuş → $tool';
  }

  @override
  String get doubleTapSelected => 'Çift dokunuş → Seçili araç';

  @override
  String get volumeMuted => 'Sessiz';

  @override
  String get volumeOn => 'Sesli';

  @override
  String get volumeMuteToggle => 'Sesi kapat / aç';

  @override
  String get btUnsupportedLong =>
      'Bu cihaz Bluetooth HID özelliğini desteklemiyor.\nWiFi modunu kullanın.';

  @override
  String get btPermissionTitle => 'İzin gerekiyor';

  @override
  String get btPermissionDenied =>
      'Telefonun klavye ve fare olarak bağlanabilmesi için “Yakındaki cihazlar” izni gerekiyor.';

  @override
  String btConnectingTo(String device) {
    return '$device ile bağlantı kuruluyor...';
  }

  @override
  String get btMakeVisible => 'Telefonu görünür yap';

  @override
  String get btMakeVisibleHint =>
      'Bilgisayar telefonu yalnızca telefon görünürken listeler.';

  @override
  String btVisibleFor(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Telefon $minutes dakika boyunca görünür.',
    );
    return '$_temp0';
  }

  @override
  String get btVisibleRefused => 'Telefon görünür yapılmadı.';

  @override
  String get btHidUnavailable =>
      'Telefon klavye olarak kaydedilemedi. Başka bir Bluetooth klavye uygulaması açıksa kapatıp tekrar deneyin.';

  @override
  String get btHostRefreshing => 'QuickRemote PC bağlantıyı hazırlıyor...';

  @override
  String get btHostUnawareTitle =>
      'Bilgisayar telefonu klavye olarak kabul etmiyor';

  @override
  String get btHostUnawareBody =>
      'Bu çoğunlukla telefon bu bilgisayarla daha önce, QuickRemote açık değilken eşleştirildiğinde olur (örneğin ses ya da dosya aktarımı için): bilgisayar telefonu klavye olarak tanımaz. Bilgisayarda bir kez şunu yapın:';

  @override
  String get btHostUnawareWindows =>
      'Ayarlar → Bluetooth ve cihazlar → Cihazlar’da telefonu bulun ve “…” menüsünden “Cihazı kaldır”ı seçin. Sonra bu ekran açıkken “Cihaz ekle” ile yeniden ekleyin.';

  @override
  String get btHostUnawareLinux =>
      'Bluetooth ayarlarında telefonun bağlantısını kesip yeniden bağlayın. Olmazsa telefonu kaldırın ve bu ekran açıkken yeniden eşleştirin.';

  @override
  String get btHostUnawareAuto =>
      'Bilgisayarda QuickRemote PC açıksa bunu kendisi yapar.';

  @override
  String get btHostUnawareWaiting =>
      'Bilgisayar kabul edince kumanda kendiliğinden açılır.';

  @override
  String get btErrorRetry => 'Bluetooth hatası. Tekrar deneyin.';

  @override
  String get btWaitingPairing => 'Eşleştirme bekleniyor...';

  @override
  String get btPreparing => 'Hazırlanıyor...';

  @override
  String get btNotConnectedRetrying => 'Bağlanılmadı, tekrar deneniyor';

  @override
  String get btOnYourComputer => 'Bilgisayarda bir kez eşleştirin';

  @override
  String get btLinuxStep1 =>
      'Bluetooth ayarlarını açın: KDE’de Sistem Ayarları → Bluetooth, GNOME’da Ayarlar → Bluetooth.';

  @override
  String get btLinuxStep2 =>
      'Bluetooth’u açın ve cihaz aramayı başlatın. KDE’de “Cihaz ekle”ye basın; GNOME bu sayfa açıkken kendisi arar.';

  @override
  String get btStepPickPhone =>
      'Listede telefonunuzun adını seçin. Görünmüyorsa yukarıdaki “Telefonu görünür yap”a basın.';

  @override
  String get btStepConfirm =>
      'Telefonda ve bilgisayarda aynı 6 haneli kod çıkar. Kodlar aynıysa ikisinde de onaylayın.';

  @override
  String get btWindowsStep1 => 'Ayarlar’ı açın (Windows tuşu + I).';

  @override
  String get btWindowsStep2 =>
      'Bluetooth ve cihazlar → Cihaz ekle → Bluetooth’u seçin. Windows 10’da: Bluetooth ve diğer cihazlar → Bluetooth veya başka cihaz ekle.';

  @override
  String get btPermissionAllow => 'İzin ver';

  @override
  String get btPermissionSettings => 'Ayarları aç';

  @override
  String get btPermissionSettingsHint =>
      'İzin daha önce reddedildiği için artık yalnızca Ayarlar’dan verilebilir: İzinler → Yakındaki cihazlar → İzin ver.';

  @override
  String get btOffTitle => 'Bluetooth kapalı';

  @override
  String get btOffBody =>
      'Telefon bilgisayara Bluetooth ile klavye ve fare olarak bağlanır. Bluetooth açılınca bağlantı kendiliğinden sürer.';

  @override
  String get btTurnOn => 'Bluetooth’u aç';

  @override
  String get btOffDuringRemote =>
      'Telefonun Bluetooth’u kapandı. Açılınca kumanda yeniden bağlanır.';

  @override
  String btStepPickPhoneNamed(String name) {
    return 'Listede “$name” adını seçin. Görünmüyorsa yukarıdaki “Telefonu görünür yap”a basın.';
  }

  @override
  String get btTroubleTitle => 'Bağlanmıyor mu?';

  @override
  String get btTroubleNearby =>
      'Bilgisayarın Bluetooth’u açık olsun, bilgisayar uykuda olmasın ve telefon birkaç metre yakınında dursun.';

  @override
  String get btTroubleNotListed =>
      'Telefon listede yoksa “Telefonu görünür yap”a basın ve bilgisayarda aramayı yeniden başlatın.';

  @override
  String get btTroubleAlreadyPaired =>
      'Telefon bilgisayarda zaten eşleştirilmiş görünüyor ama bağlanmıyorsa telefonu bilgisayardan kaldırın ve bu ekran açıkken yeniden ekleyin.';

  @override
  String get btTroubleBlocked =>
      'Bilgisayarın Bluetooth ayarlarında telefon engellenmişse engeli kaldırın.';

  @override
  String get btTroubleSeveral =>
      'Telefon birden fazla bilgisayarla eşleştirilmişse hangisine bağlanacağını bilemez: istediğiniz bilgisayarın Bluetooth ayarlarında telefona “Bağlan” deyin.';

  @override
  String get btTroubleOtherApp =>
      'Telefon aynı anda tek bir uygulama için klavye olabilir. Başka bir Bluetooth klavye ya da fare uygulaması açıksa kapatın.';

  @override
  String get btConnected => 'Bağlandı!';

  @override
  String get unknownDevice => 'Bilinmeyen cihaz';

  @override
  String get btOpeningRemote => 'Uzaktan kontrol açılıyor...';

  @override
  String get btUnsupported => 'Desteklenmiyor';

  @override
  String get btUnsupportedShort => 'Bu cihaz Bluetooth HID\'i desteklemiyor.';

  @override
  String get btUseWifi => 'WiFi Modunu Kullan';

  @override
  String get errorTitle => 'Hata';

  @override
  String get btErrorOccurred => 'Bluetooth hatası oluştu.';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get btConnectionLost =>
      'Bluetooth bağlantısı koptu. Yeniden bağlanılıyor...';

  @override
  String btConnectedTo(String device) {
    return 'Bluetooth bağlandı: $device';
  }

  @override
  String get btDisconnectContent =>
      'Bluetooth bağlantısı kesilecek ve ana ekrana dönülecek.';

  @override
  String get btModeTitle => 'Bluetooth HID Modu';

  @override
  String get systemMedia => 'Sistem Medyası';

  @override
  String get btMediaLimits =>
      'Bluetooth modunda medya bilgisi, ses seviyesi göstergesi ve PowerPoint medya kontrolleri kullanılamaz. Tam özellik için WiFi modunu kullanın.';

  @override
  String get btNoMediaInfo => 'BT modunda medya bilgisi alınamaz';

  @override
  String get mediaPlayPause => 'Oynat / Duraklat';

  @override
  String get toolCursor => 'İmleç';

  @override
  String durationHms(int h, int m, int s) {
    return '${h}s ${m}dk ${s}sn';
  }

  @override
  String durationMs(int m, int s) {
    return '${m}dk ${s}sn';
  }

  @override
  String durationS(int s) {
    return '${s}sn';
  }

  @override
  String durationMinutes(int m) {
    return '$m dk';
  }

  @override
  String durationMinSec(int m, int s) {
    return '$m dk $s sn';
  }

  @override
  String durationSeconds(int s) {
    return '$s sn';
  }

  @override
  String get timerSettingsTitle => 'Sunum Sayacı';

  @override
  String get timerAutoStartTitle => 'Süre Seçilince Hemen Başlat';

  @override
  String get timerAutoStartSubtitle =>
      'Kapalıyken süre seçildikten sonra sayaca dokunarak başlatılır.';

  @override
  String get earlyWarningTitle => 'Erken Uyarı Titreşimi';

  @override
  String get earlyWarningSubtitle =>
      'Sürenin bitimine seçilen süreler kala uyarır.';

  @override
  String get warningTimes => 'Uyarı Süreleri';

  @override
  String get noWarningTimes => 'Henüz uyarı süresi yok.';

  @override
  String timeLeft(String time) {
    return '$time kala';
  }

  @override
  String get addWarning => 'Yeni Uyarı Ekle';

  @override
  String get whenTimeIsUp => 'Süre Bittiğinde';

  @override
  String get endVibration => 'Bitiş Titreşimi';

  @override
  String get vibrationPattern => 'Titreşim Deseni';

  @override
  String vibrationFor(String time) {
    return '$time İçin Titreşim';
  }

  @override
  String get tapToPreview => 'Önizlemek için seçeneklere dokunun';

  @override
  String get vibrationShort => 'Kısa Titreşim';

  @override
  String get vibrationDouble => 'Çift Titreşim';

  @override
  String get vibrationLong => 'Uzun Titreşim';

  @override
  String get vibrationTriple => 'Üçlü Titreşim';

  @override
  String get newWarningTime => 'Yeni Uyarı Süresi';

  @override
  String get enterTime => 'Süre girin';

  @override
  String get unitSecondsLong => 'Saniye';

  @override
  String get unitMinutesLong => 'Dakika';

  @override
  String get enterValidNumber => 'Lütfen geçerli bir sayı girin.';

  @override
  String get add => 'Ekle';

  @override
  String get patternShort => 'Kısa';

  @override
  String get patternLong => 'Uzun';

  @override
  String get patternTriple => 'Üçlü';

  @override
  String get patternDouble => 'Çift';

  @override
  String get clearHistory => 'Geçmişi Temizle';

  @override
  String get noHistory => 'Henüz sunum verisi yok';

  @override
  String get noHistoryHint =>
      'Bir sunum başlatıp bitirdikten sonra\nveriler burada görünecek.';

  @override
  String get historyDeleted => 'Sunum kaydı silindi';

  @override
  String slideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slayt',
    );
    return '$_temp0';
  }

  @override
  String get clearHistoryContent =>
      'Tüm sunum geçmişi silinecek. Bu işlem geri alınamaz.';

  @override
  String get clear => 'Temizle';

  @override
  String get historyCleared => 'Sunum geçmişi temizlendi';

  @override
  String get timeUp => 'Sunum süresi doldu!';

  @override
  String timeRemaining(String time) {
    return 'Sürenin bitimine $time kaldı!';
  }

  @override
  String get enterValidDuration =>
      'Lütfen dakika ve/veya saniye olarak geçerli bir süre girin.';

  @override
  String get setPresentationTime => 'Sunum Süresi Belirle';

  @override
  String get noTimeLimit => 'Serbest';

  @override
  String get unitMinutes => 'dk';

  @override
  String get unitSeconds => 'sn';

  @override
  String get startWhenPicked => 'Seçince hemen başlat';

  @override
  String get timerHelp =>
      'Dokun: başlat/duraklat · Basılı tut: yeni süre · ↻: seçili süreye dön';

  @override
  String get actionSet => 'Ayarla';

  @override
  String get reportTitle => 'Sunum Raporu';

  @override
  String get totalTime => 'Toplam Süre';

  @override
  String get slideCountLabel => 'Slayt Sayısı';

  @override
  String get avgPerSlideShort => 'Ort/Slayt';

  @override
  String totalTransitions(int count) {
    return 'Toplam Geçiş: $count';
  }

  @override
  String get timePerSlide => 'Slayt Bazlı Süre';

  @override
  String get copyToClipboard => 'Panoya Kopyala';

  @override
  String get ok => 'Tamam';

  @override
  String get presentationDetails => 'Sunum Detayı';

  @override
  String get reportDate => 'Tarih';

  @override
  String get reportAvgPerSlide => 'Ort. Süre/Slayt';

  @override
  String get reportTransitions => 'Geçiş Sayısı';

  @override
  String get reportSlideDetails => 'Slayt Detayları';

  @override
  String reportSlide(int n) {
    return 'Slayt $n';
  }

  @override
  String get reportCopied => 'Rapor panoya kopyalandı';

  @override
  String get noSlideData => 'Slayt verisi bulunamadı';

  @override
  String get backgroundNotification => 'Arka planda bağlantı devam ediyor...';

  @override
  String get homeHeroSubtitle =>
      'Bilgisayardaki QuickRemote PC\'nin QR kodunu tarayın ya da telefonu Bluetooth ile klavye ve fare olarak bağlayın.';

  @override
  String get slideLabel => 'Slayt';

  @override
  String get settingsSectionPresentation => 'Sunum';

  @override
  String get settingsSectionGeneral => 'Genel';

  @override
  String get remoteProgramHint => 'Sunum programını seç';

  @override
  String get programSheetTitle => 'Sunum programı';

  @override
  String programSheetBody(String pc) {
    return '$pc şu programları kontrol edebilir. Gösterisi açık olan kendiliğinden kullanılır.';
  }

  @override
  String programShowOpenSlide(int slide) {
    return 'Gösteri açık · Slayt $slide';
  }

  @override
  String get programShowOpen => 'Gösteri açık';

  @override
  String get programShowClosed => 'Gösteri açık değil';

  @override
  String get programPdfNote =>
      'PDF\'ler ayrıca seçilmez; öndeki pencere PDF ise o kontrol edilir.';

  @override
  String get programBluetoothNote =>
      'Bluetooth modunda program buradan seçilir (PowerPoint / Impress / WPS).';

  @override
  String get goToSlide => 'Slayta git';

  @override
  String goToSlideRange(int total) {
    return '1–$total arası bir numara';
  }

  @override
  String get goToSlideNumber => 'Slayt numarası';

  @override
  String get goAction => 'Git';

  @override
  String notesSlide(int slide) {
    return 'Slayt $slide';
  }

  @override
  String get notesOpenHint => 'Notun tamamını aç';

  @override
  String get unreadableShow =>
      'WPS slayt numarasını bildirmiyor; tuşlar yine çalışır.';

  @override
  String get unreadableShowUserWps =>
      'Bu WPS\'i QuickRemote açmadı: slayt numarası ve notlar gelmez, tuşlar WPS penceresi öndeyken çalışır.';

  @override
  String get takeOverHint =>
      'Bu WPS\'i QuickRemote açmadı: slayt numarası ve notlar gelmiyor. Devral ile PC\'deki WPS kapanıp sunum aynı slayttan tam kontrolle açılır.';

  @override
  String get takeOverAction => 'Devral';

  @override
  String get takeOverStarted =>
      'WPS PC\'de yeniden açılıyor; kaydetme sorusu çıkarsa PC\'de yanıtlayın.';

  @override
  String get drawToolsNeedShow =>
      'Çizim araçları slayt gösterisi açıkken çalışır.';

  @override
  String get toolArrow => 'Ok';

  @override
  String get colorUnavailableTitle => 'Bu programda renk seçilemez.';

  @override
  String get colorUnavailableBody =>
      'WPS\'i QuickRemote açmadığı için kalem WPS\'in kendi rengiyle çizer.';

  @override
  String slideMediaOnSlide(int slide, String suffix) {
    String _temp0 = intl.Intl.selectLogic(suffix, {
      'de': 'deki',
      'da': 'daki',
      'te': 'teki',
      'ta': 'taki',
      'other': 'deki',
    });
    return 'Slayt $slide\'$_temp0 medya';
  }

  @override
  String get slideMediaPlaying => 'Oynatılıyor';

  @override
  String get slideMediaNotPlaying => 'Oynatılmıyor';

  @override
  String get slideMediaStateUnknown => 'WPS oynatma durumunu bildirmiyor';

  @override
  String get volumeDown => 'Sesi kıs';

  @override
  String get volumeUp => 'Sesi aç';

  @override
  String get mediaStop => 'Durdur';

  @override
  String btModeSubtitle(String device) {
    return 'Telefon, $device için klavye ve fare';
  }

  @override
  String get btScreenKeys => 'Siyah · Beyaz ekran';

  @override
  String get btPreparingBody => 'Telefon klavye ve fare olarak kaydediliyor.';

  @override
  String get btConnectingBody => 'Bağlanınca kumanda kendiliğinden açılır.';

  @override
  String btRetryingBody(String device) {
    return '$device açık ve Bluetooth\'u açıksa birkaç saniye içinde bağlanır.';
  }

  @override
  String get btRetryingBodyUnknown =>
      'Bilgisayar açık ve Bluetooth\'u açıksa birkaç saniye içinde bağlanır.';

  @override
  String get btRefreshingBody =>
      'Bilgisayar telefonun klavye kaydını yeniden okuyor.';

  @override
  String get btProgramSheetBody =>
      'Bluetooth\'ta bilgisayar programı bildiremez; tuşlar seçtiğiniz programın kısayollarıyla gönderilir.';

  @override
  String get btToolsFull => 'Lazer, kalem, vurgula, silgi';

  @override
  String get btToolsImpress => 'İmleç, kalem';

  @override
  String get btImpressToolsNote =>
      'Impress\'te lazer, vurgulayıcı ve silgi kısayolu yok; imleç işaretçi olur.';

  @override
  String get btWpsToolsNote =>
      'WPS\'te lazer Ctrl+R ile açılır; Windows\'taki WPS\'te Silgi başka bir iş yapabilir.';

  @override
  String get verifyIntro =>
      'Bu PC ile ilk kez bağlanıyorsunuz. PC ekranındaki güvenlik kodu şu olmalı:';

  @override
  String get verifyNote =>
      'Kodlar aynı değilse bağlanmayın: ağdaki başka bir cihaz PC gibi davranıyor olabilir. QR kodu okutarak bu adımı atlayabilirsiniz.';

  @override
  String get certWarningIntro =>
      'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı. PC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir. PC ekranındaki güvenlik kodu şu olmalı:';

  @override
  String get certWarningNote => 'Kodlar aynı değilse bağlanmayın.';

  @override
  String get homeNoDevicesHint =>
      'Bilgisayarda QuickRemote PC açık ve aynı Wi-Fi\'da olmalı.';

  @override
  String get languageSystemNote =>
      'Sistem dili, telefonun dilini izler; Türkçe ya da İngilizce değilse İngilizce olur.';

  @override
  String get historySwipeHint => 'Silmek için sola kaydırın';

  @override
  String get settingsThemeTitle => 'Tema';

  @override
  String settingsThemeSubtitle(String theme, String mode) {
    return '$theme · $mode';
  }

  @override
  String get themeModeHeader => 'Açık / Koyu';

  @override
  String get themeModeSystem => 'Sistem';

  @override
  String get themeModeLight => 'Açık';

  @override
  String get themeModeDark => 'Koyu';

  @override
  String get themeColorHeader => 'Renk teması';

  @override
  String get themeCobaltNote =>
      'Kobalt sistemle birlikte açık ya da koyu olur; elle de seçilebilir.';

  @override
  String get themeDarkOnlyNote =>
      'Bu tema yalnız koyu; karanlık salon için tasarlandı.';

  @override
  String get themeLightOnlyNote =>
      'Gün Batımı yalnız açık; aydınlık odalar için.';

  @override
  String get themeCobalt => 'Kobalt';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeHighContrast => 'Yüksek kontrast';

  @override
  String get themeMint => 'Nane';

  @override
  String get themeViolet => 'Mor';

  @override
  String get themeSunset => 'Gün Batımı';

  @override
  String get themeWatchHeader => 'Saat';

  @override
  String get themeWatchTitle => 'Saatte de kullan';

  @override
  String get themeWatchSubtitle =>
      'QuickRemote saat uygulaması bu renk temasını alır.';

  @override
  String get themeWatchSunsetNote =>
      'Saat hep koyu: Gün Batımı saatte Kobalt görünür.';

  @override
  String get settingsSectionHelp => 'Yardım';

  @override
  String get settingsShareLogTitle => 'Hata günlüğünü paylaş';

  @override
  String get settingsShareLogSubtitle =>
      'Günlük yalnızca bu telefonda tutulur ve kendiliğinden hiçbir yere gönderilmez. PIN, eşleştirme kodu, notlar ve dosya yolları yazılmaz; IP adresleri ve cihaz adları yazılır.';

  @override
  String get settingsReportProblemTitle => 'Sorun bildir';

  @override
  String get settingsReportProblemSubtitle =>
      'GitHub\'da yeni bir sorun sayfası açar; günlüğü oraya sen eklersin.';

  @override
  String get logShareFailed => 'Günlük paylaşılamadı.';

  @override
  String get logShareEmpty => 'Günlük henüz boş.';

  @override
  String get issueOpenFailed => 'Tarayıcı açılamadı.';

  @override
  String issueBody(
    String version,
    String platform,
    String presenters,
    String btTarget,
  ) {
    return '**Ne oldu?**\n\n\n**Nasıl tekrarlanır?**\n\n\n---\nQuickRemote $version (telefon)\nPlatform: $platform\nBilgisayardaki programlar: $presenters\nBluetooth hedefi: $btTarget\n\nGünlüğü (Ayarlar → Hata günlüğünü paylaş) bu sayfaya ekleyebilirsin.';
  }

  @override
  String get settingsCapabilitiesTitle => 'Neler yapılabilir?';

  @override
  String get settingsCapabilitiesSubtitle =>
      'Hangi programda hangi özellik çalışır, karşılaştır';

  @override
  String get capTitle => 'Neler yapılabilir?';

  @override
  String get capIntro =>
      'Bağlantıyı, bilgisayarı ve programı seç; çalışan özellikleri gör. Karşılaştır, o bilgisayardaki bütün programları yan yana koyar.';

  @override
  String get capConnection => 'Bağlantı';

  @override
  String get capComputer => 'Bilgisayar';

  @override
  String get capViewOne => 'Program seç';

  @override
  String get capViewCompare => 'Karşılaştır';

  @override
  String get capFootnoteWifi =>
      'PC uygulamasının Lazer ayarı Otomatik\'ken. Karşılaştır\'da halkalı işarete dokununca notu görünür.';

  @override
  String get capFootnoteBluetooth =>
      'Bluetooth\'ta telefon bilgisayarın klavyesi ve faresi olur; PC uygulaması gerekmez ama bilgisayar hiçbir şey bildirmez. Karşılaştır\'da halkalı işarete dokununca notu görünür.';

  @override
  String get capProgramWpsApp => 'WPS (uygulamanın açtığı)';

  @override
  String get capProgramWpsOwn => 'WPS (kendin açtığın)';

  @override
  String get capProgramPdf => 'PDF ve tarayıcı';

  @override
  String get capShortWpsApp => 'WPS\nuygulama';

  @override
  String get capShortWpsOwn => 'WPS\nkendin';

  @override
  String get capNextPrev => 'Sonraki / önceki slayt';

  @override
  String get capStartEnd => 'Gösteriyi başlat / bitir';

  @override
  String get capGoTo => 'Slayta git';

  @override
  String get capLaser => 'Lazer';

  @override
  String get capInk => 'Kalem ve vurgulayıcı';

  @override
  String get capEraser => 'Silgi ve temizle';

  @override
  String get capBlank => 'Siyah / beyaz ekran';

  @override
  String get capSlideInfo => 'Slayt numarası ve notlar';

  @override
  String get capPreview => 'Slayt önizlemesi';

  @override
  String get capSlideMedia => 'Slayttaki video';

  @override
  String get capSpotlight => 'Spot ışığı ve büyüteç';

  @override
  String get capVolume => 'Bilgisayarın sesi ve medyası';

  @override
  String get capNoteOverlay =>
      'QuickRemote kendi katmanında çizer, videonun üstünde de görünür.';

  @override
  String get capNoteFocus => 'Yalnızca WPS penceresi öndeyken.';

  @override
  String get capNoteFullscreen => 'Tam ekrana ya da sunum moduna geçer.';

  @override
  String get capNoteNoJump => 'Sayfaya atlamaz.';

  @override
  String get capNoteFirstSlide => 'Gösteri ilk slayttan başlar.';

  @override
  String get capNoteShowOnly => 'Yalnızca gösterinin açık olduğu bilinir.';

  @override
  String get capNoteScreenOnly =>
      'Yalnızca o anki ekranın resmi; sıradaki slayt görünmez.';

  @override
  String get capNoteFullscreenOnly =>
      'Yalnızca tam ekrandayken, o anki ekranın resmi.';

  @override
  String get capNotePlayOnly => 'Oynat ve duraklat var, başa sarma yok.';

  @override
  String get capNoteMediaReload =>
      'İlk basışta slayt bir kez yeniden yüklenebilir.';

  @override
  String get capNoteNoMagnifier => 'Spot ışığı var, büyüteç yok.';

  @override
  String get capNoteWpsArrow => 'Gösteri önde değilken lazer yerine ok imleci.';

  @override
  String get capNoteHighlighterFocus => 'Vurgulayıcı için gösteri önde olmalı.';

  @override
  String get capNoteCursor => 'Lazer kısayolu yok; fare imleci kullanılır.';

  @override
  String get capNotePenOnly => 'Yalnızca kalem; vurgulayıcı yok.';

  @override
  String get capNoteClearOnly => 'Yalnızca hepsini temizle; silgi yok.';

  @override
  String get capNoteWpsEraser =>
      'Windows\'taki WPS\'te silgi kısayolu başka bir iş yapabilir.';

  @override
  String get capNoteNoAnswer =>
      'Bluetooth\'ta bilgisayar telefona bilgi göndermez.';

  @override
  String get capNoteKeysOnly =>
      'Yalnızca tuşlar; ses seviyesi ve şarkı adı görünmez.';

  @override
  String get capNoteWpsNoMedia => 'WPS\'teki video uzaktan oynatılamıyor.';

  @override
  String get capLevelYes => 'Çalışır';

  @override
  String get capLevelPartial => 'Kısmen';

  @override
  String get capLevelNo => 'Çalışmaz';
}
