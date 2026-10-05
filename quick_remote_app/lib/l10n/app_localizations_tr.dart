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
  String get homeTagline => 'Sunumlarınızı telefondan kontrol edin';

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
  String get homeRecent => 'Son Bağlanılanlar';

  @override
  String get homeRemoveFromHistory => 'Geçmişten Sil';

  @override
  String get unknownPc => 'Bilinmeyen PC';

  @override
  String get verifyTitle => 'Güvenlik Kodunu Karşılaştırın';

  @override
  String verifyContent(String code) {
    return 'Bu PC ile ilk kez bağlanıyorsunuz. PC ekranındaki güvenlik kodu şu olmalı:\n\n$code\n\nKodlar aynı değilse bağlanmayın: ağdaki başka bir cihaz PC gibi davranıyor olabilir. QR kodu okutarak bu adımı atlayabilirsiniz.';
  }

  @override
  String get verifyConfirm => 'Kodlar Aynı, Bağlan';

  @override
  String get cancelAction => 'İptal Et';

  @override
  String get certWarningTitle => 'Güvenlik Uyarısı';

  @override
  String certWarningContent(String code) {
    return 'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı.\n\nPC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir. PC ekranındaki güvenlik kodu şu olmalı:\n\n$code\n\nKodlar aynı değilse bağlanmayın.';
  }

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
  String get notesTitle => 'Slayt Notları';

  @override
  String get notesEmpty => 'Bu slayt için not bulunmuyor.';

  @override
  String get startPresentation => 'Sunuma Başla';

  @override
  String slidePickerRange(int total) {
    return 'Slayt (1-$total)';
  }

  @override
  String get slidePickerHint => 'Slayt Numarası (Örn: 5)';

  @override
  String slidePickerMax(int total) {
    return 'Maksimum $total slayt girebilirsiniz.';
  }

  @override
  String get slidePickerEmpty => 'Boş bırakırsanız baştan başlar.';

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
  String get notes => 'Notlar';

  @override
  String presentationNotOpen(String programs) {
    return 'Sunum Açık Değil, $programs\'i başlatın';
  }

  @override
  String get actionEnd => 'Bitir';

  @override
  String get blackScreen => 'Siyah Ekran';

  @override
  String get whiteScreen => 'Beyaz Ekran';

  @override
  String get actionPrev => 'Geri';

  @override
  String get actionNext => 'İleri';

  @override
  String get listOr => ' veya ';

  @override
  String get mediaControlTitle => 'Medya Kontrolü';

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
  String get toolHighlighter => 'Vurgulayıcı';

  @override
  String tapForTool(String tool) {
    return 'Tek dokunuş → $tool';
  }

  @override
  String get doubleTapSelected => 'Çift dokunuş → Seçili Araç';

  @override
  String get volumeMuted => 'Sessiz';

  @override
  String get volumeOn => 'Açık';

  @override
  String get btUnsupportedLong =>
      'Bu cihaz Bluetooth HID özelliğini desteklemiyor.\nWiFi modunu kullanın.';

  @override
  String get btPermissionDenied =>
      'Bluetooth izni reddedildi. Ayarlardan izin vermelisiniz.';

  @override
  String get btDisabled => 'Bluetooth kapalı. Açıp tekrar deneyin.';

  @override
  String btConnectingTo(String device) {
    return '$device ile bağlantı kuruluyor...';
  }

  @override
  String get btMakeVisible => 'Telefonu görünür yap';

  @override
  String get btMakeVisibleHint =>
      'Bilgisayar telefonu ancak görünürken listesinde bulur.';

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
      'Bilgisayar telefonu klavye olarak tanımıyor';

  @override
  String get btHostUnawareBody =>
      'Telefon bu bilgisayarla QuickRemote açık değilken eşleştirilmiş. Bilgisayarda bir kez şunu yapın:';

  @override
  String get btHostUnawareWindows =>
      'Ayarlar → Bluetooth ve cihazlar\'da telefonu kaldırın, sonra bu ekran açıkken yeniden ekleyin.';

  @override
  String get btHostUnawareLinux =>
      'Bluetooth ayarlarında telefonun bağlantısını kesip yeniden bağlayın. Olmazsa telefonu kaldırıp bu ekran açıkken yeniden eşleştirin.';

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
  String get btWaitingConnection => 'Bağlantı bekleniyor...';

  @override
  String get btPreparing => 'Hazırlanıyor...';

  @override
  String get btNotConnectedRetrying => 'Bağlanılmadı, tekrar deneniyor';

  @override
  String get btOnYourComputer => 'Bilgisayarınızda şunları yapın:';

  @override
  String get btLinuxStep1 =>
      'Sistem Ayarları\'nı açın (KDE: Bluetooth, GNOME: Ayarlar → Bluetooth)';

  @override
  String get btLinuxStep2 => 'Bluetooth\'un açık olduğundan emin olun';

  @override
  String get btLinuxStep3 => '\"Yeni cihaz ekle\" / cihaz aramayı başlatın';

  @override
  String get btStepPickPhone => 'Listeden telefonunuzun adını seçin';

  @override
  String get btStepConfirm => 'Eşleştirmeyi onaylayın';

  @override
  String get btWindowsStep1 => 'Windows Ayarlar\'ı açın';

  @override
  String get btWindowsStep2 => 'Bluetooth ve diğer cihazlar\'a gidin';

  @override
  String get btWindowsStep3 => '\"Cihaz ekle\" butonuna basın';

  @override
  String get btPairOnce =>
      'Bu ekran açıkken bir kez eşleştirmeniz yeterli; sonraki bağlantılar otomatiktir.';

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
  String get btTarget => 'Hedef:';

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
}
