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
  String get settingsHidePublicNetworkWarning => 'Ortak Ağ Uyarılarını Gizle';

  @override
  String get settingsHidePublicNetworkWarningSubtitle =>
      'Ortak ağlara bağlanırken güvenlik uyarısı gösterme.';

  @override
  String get settingsLanguageTitle => 'Dil';

  @override
  String get languageSystem => 'Sistem dili';

  @override
  String get close => 'Kapat';

  @override
  String get homeTagline => 'Sunum Kontrol Merkezi';

  @override
  String get refreshSlideState => 'Slayt Durumunu Yenile';

  @override
  String get portsOpened => 'Güvenlik duvarında portlar açıldı.';

  @override
  String get portsOpenFailed => 'Portlar açılamadı.';

  @override
  String get firewallDialogTitle => 'Portları Açmanız Gerekiyor';

  @override
  String get firewallDialogContent =>
      'Güvenlik duvarı telefonun bu bilgisayara bağlanmasını engelliyor. Uygulamayı kullanmak için 8090-8099 portlarını açmalısınız.\n\nPortlar bu ağ bölgesinde kalıcı olarak açılır. Yönetici parolanız bir kez sorulacak.';

  @override
  String get later => 'Daha Sonra';

  @override
  String get openPortsButton => 'Portları Aç';

  @override
  String get uinputNeeded => 'Klavye/fare simülasyonu için izin gerekli';

  @override
  String get grantPermission => 'İzin ver';

  @override
  String get uinputGranted => 'Giriş izni verildi.';

  @override
  String get uinputFailed => 'İzin verilemedi. Yönetici parolası gerekiyor.';

  @override
  String get mdnsOff =>
      'Otomatik keşif kapalı (avahi-daemon). QR veya IP ile bağlanın.';

  @override
  String get firewallBlocked =>
      'Güvenlik duvarı telefonun bağlanmasını engelliyor. Kullanmak için portları açın.';

  @override
  String get firewallUnknown =>
      'Güvenlik duvarı kuralları okunamadı: 8090-8099 portları açık olmalı';

  @override
  String get openPortsAction => 'Portları aç';

  @override
  String get impressConnected => 'LibreOffice Impress bağlı';

  @override
  String get impressReadyWhenOpened => 'Impress: LibreOffice açılınca bağlanır';

  @override
  String get impressOff => 'Impress bağlantısı kapalı';

  @override
  String get enable => 'Etkinleştir';

  @override
  String get impressEnabled => 'Impress bağlantısı etkinleştirildi.';

  @override
  String get libreOfficeWriteFailed => 'LibreOffice ayarı yazılamadı.';

  @override
  String get impressLegacy =>
      'Impress bağlantısı eski yöntemi kullanıyor: bu bilgisayardaki her kullanıcıya ve uygulamaya açık bir port. Güncelleyin.';

  @override
  String get update => 'Güncelle';

  @override
  String get impressUpdated => 'Impress bağlantısı güvenli yönteme geçirildi.';

  @override
  String get impressLegacyRunning =>
      'Impress bağlantısı eski yöntemi kullanıyor: bu bilgisayardaki her kullanıcıya ve uygulamaya açık bir port. Güncellemek için LibreOffice\'i kapatın.';

  @override
  String get libreOfficeNotListening =>
      'LibreOffice açık ama bağlantı kabul etmiyor';

  @override
  String get connect => 'Bağlan';

  @override
  String get libreOfficeListening => 'LibreOffice bağlantıyı kabul ediyor.';

  @override
  String get libreOfficeUnreachable => 'LibreOffice\'e ulaşılamadı.';

  @override
  String get libreOfficeMissing =>
      'LibreOffice yok: sunum yalnızca klavye ile kontrol edilir';

  @override
  String get unoMissing =>
      'python3 veya LibreOffice Python (UNO) desteği bulunamadı';

  @override
  String get wpsConnected =>
      'WPS bağlı: buradan açılan sunum tam kontrol edilir';

  @override
  String get openPresentation => 'Sunum aç';

  @override
  String get wpsReady =>
      'WPS: slayt numarası, notlar ve kalem rengi için sunumu buradan açın';

  @override
  String get wpsNoRpc =>
      'WPS yalnızca klavye ile kontrol ediliyor. Tam kontrol için WPS desteğini kurun (pywpsrpc, internet gerekir).';

  @override
  String get install => 'Kur';

  @override
  String get wpsInstalled => 'WPS desteği kuruldu.';

  @override
  String get wpsInstallFailed =>
      'WPS desteği kurulamadı (python3-venv ve internet gerekir).';

  @override
  String get presentationsFileType => 'Sunumlar';

  @override
  String get wpsOpened =>
      'Sunum WPS\'te açıldı. Gösteriyi telefondan başlatabilirsiniz.';

  @override
  String get wpsOpenFailed => 'Sunum WPS\'te açılamadı.';

  @override
  String get networkTrusted => 'Güvenilir Ağ';

  @override
  String get networkUntrusted => 'Güvenilmeyen Ağ';

  @override
  String get networkZoneUnknown => 'Ağ türü bilinmiyor';

  @override
  String get networkPrivate => 'Özel Ağ';

  @override
  String get networkPublic => 'Ortak Ağ';

  @override
  String get networkUnreadable => 'Ağ türü okunamadı';

  @override
  String get publicNetworkTitle => 'Ortak Ağ Uyarısı';

  @override
  String get publicNetworkLinux =>
      'Bu ağ, güvenlik duvarında güvenilmeyen ağ olarak tanımlı. Bu ağdaki diğer kişiler QuickRemote sunucunuzu görebilir.\n\nGüvenilir bir ağda olduğunuzdan emin olun.';

  @override
  String get publicNetworkWindows =>
      'Şu an ortak bir ağdasınız. Bu ağdaki diğer kişiler QuickRemote sunucunuzu görebilir.\n\nGüvenilir bir ağda olduğunuzdan emin olun.';

  @override
  String get openNetworkSettings => 'Ağ Ayarlarını Aç';

  @override
  String get dontShowAgain => 'Bu uyarıyı bir daha gösterme';

  @override
  String get stopServer => 'Sunucuyu Durdur';

  @override
  String get continueAction => 'Devam Et';

  @override
  String get loadingNetwork => 'Ağ bilgileri alınıyor...';

  @override
  String get showCodeToPair => 'Başka bir cihaz eşleştirmek için kodu gösterin';

  @override
  String get scanToConnect => 'Bağlanmak için QR kodu tarayın';

  @override
  String get hideCode => 'Kodu gizle';

  @override
  String securityCode(String code) {
    return 'Güvenlik kodu: $code';
  }

  @override
  String get pairingPaused =>
      'Çok fazla hatalı PIN denemesi. Eşleştirme 1 dakika duraklatıldı ve PIN yenilendi.';

  @override
  String get showCode => 'Kodu göster';

  @override
  String connectedDevices(int count) {
    return 'Bağlı cihazlar ($count)';
  }

  @override
  String get removeDeviceTooltip =>
      'Bağlantıyı keser ve PIN\'i yeniler. Diğer cihazlar bağlı kalır.';

  @override
  String get removeDevice => 'Çıkar';

  @override
  String clientsConnected(int count) {
    return '$count Bağlı';
  }

  @override
  String get serverOff => 'Kapalı';

  @override
  String get portsInUse =>
      'Sunucu başlatılamadı: Port kullanımda. Lütfen 8090-8099 portlarını kullanan uygulamaları kapatıp tekrar deneyin.';

  @override
  String serverStartFailed(String error) {
    return 'Sunucu başlatılamadı: $error';
  }

  @override
  String portFallback(int port) {
    return 'Port 8090 kullanımda olduğu için sunucu $port portunda başlatıldı.';
  }

  @override
  String get serverStopped => 'Sunucu Kapalı';

  @override
  String get serverStoppedHint =>
      'Telefonunuzdan bağlanmak ve sunumunuzu\nkontrol etmek için sunucuyu başlatın.';

  @override
  String get opensslMissing =>
      'openssl bulunamadı. TLS sertifikası için openssl paketini kurun.';

  @override
  String tlsKeyReadable(String path) {
    return 'TLS anahtarı başka kullanıcılar tarafından okunabiliyor: $path';
  }
}
