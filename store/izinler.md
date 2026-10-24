# İzin denetimi ve Play beyan metinleri

Tarih: 2026-10-22. Kaynak: `quick_remote_app/android/app/src/main/AndroidManifest.xml`, eklentilerin kendi manifestleri (pub önbelleğinde okundu) ve `quick_remote_wear/app/src/main/AndroidManifest.xml`.

**Önemli:** Bu makinede Android SDK indirilemedi (dl.google.com ve Google Maven ağ ilkesiyle kapalı), bu yüzden *birleştirilmiş* manifest derlenip okunamadı. Aşağıdaki liste kaynak manifestlerden çıkarıldı. İlk AAB derlenince `build/app/intermediates/merged_manifests/release/` ya da Play Console > Uygulama paketi gezgini > Manifest bölümüyle karşılaştır (kontrol listesi: `store/KONTROL_LISTESI.md`).

## 1. Telefon uygulaması

| İzin / özellik | Nereden | Neden | Tür | Play'de beyan |
|---|---|---|---|---|
| `CAMERA` | uygulama + `mobile_scanner` | Yalnız PC ekranındaki eşleştirme QR kodunu okur. Görüntü kaydedilmez, saklanmaz, gönderilmez. | Çalışma zamanı | Ayrı form yok. Gizlilik politikasında anılır. `uses-feature camera required=false`: kamerasız cihaz da kurabilir (IP + PIN elle yazılır). |
| `INTERNET` | uygulama | Kullanıcının kendi bilgisayarına yerel ağda TLS WebSocket bağlantısı. | Normal | Yok |
| `ACCESS_NETWORK_STATE` | uygulama | Ağ durumu sorgusu (Flutter şablonundan kalma; kodda doğrudan çağrısı yok, zararsız normal izin). Kaldırılabilir; kaldırmak için önce cihazda mDNS taramasının etkilenmediğini denemek gerekir, bu yüzden dokunulmadı. | Normal | Yok |
| `CHANGE_WIFI_MULTICAST_STATE` | uygulama (`nsd`) | mDNS (`_quickremote._tcp`) ile PC'yi bulmak için çok noktaya yayın kilidi (`nsd_android` MulticastLock). Aynı zamanda `connectedDevice` ön plan hizmetinin Android 14 önkoşulu. | Normal | Yok |
| `WAKE_LOCK` | uygulama + `flutter_background` + `wakelock_plus` | Telefon kilitliyken bağlantıyı ve Wi-Fi kilidini tutmak; kumanda açıkken ekranın kapanmaması. | Normal | Yok |
| `FOREGROUND_SERVICE` | `flutter_background` | Aşağıdaki ön plan hizmeti. | Normal | Ön plan hizmeti beyanı (bölüm 3) |
| `FOREGROUND_SERVICE_CONNECTED_DEVICE` | uygulama | Hizmetin türü `connectedDevice` (Android 14+ zorunlu). | Normal | Ön plan hizmeti beyanı (bölüm 3) |
| `POST_NOTIFICATIONS` | uygulama + `permission_handler` | Ön plan hizmetinin zorunlu bildirimi ("QuickRemote bağlı"). Android 13+ ilk kumanda ekranında sorulur. Reddedilirse uygulama çalışır, bildirim görünmeyebilir. | Çalışma zamanı | Yok |
| `BLUETOOTH_CONNECT` | uygulama | Bluetooth HID profili (telefon klavye/fare olur), eşleşmiş bilgisayarı bulmak (`bondedDevices`); ayrıca saatin lazer soketi (`WearDirect`). | Çalışma zamanı (Android 12+) | "Yakındaki cihazlar". Tarama yapılmaz. |
| `BLUETOOTH_ADVERTISE` | uygulama | Yalnız "Telefonu görünür yap" düğmesi (`ACTION_REQUEST_DISCOVERABLE`), böylece bilgisayar telefonu bulup eşleştirebilir. | Çalışma zamanı (Android 12+) | "Yakındaki cihazlar" |
| `BLUETOOTH`, `BLUETOOTH_ADMIN` (`maxSdkVersion=30`) | uygulama | Android 11 ve altında aynı işler için eski izinler. | Normal | Yok |
| `VIBRATE` | `vibration` eklentisi (birleşmiş manifestte) | Zamanlayıcı uyarıları. | Normal | Yok |
| `BLUETOOTH_SCAN` | **yok** | Uygulama cihaz taramaz. Eklenmemeli. | | |
| Konum (`ACCESS_FINE/COARSE_LOCATION`) | **yok** | Hiçbir yerde istenmiyor; mDNS ve Bluetooth için gerekmez. | | |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | `flutter_background` bildiriyordu | **Kaldırıldı** (2026-10-22). Play bu izni yalnız dar bir kullanım listesine veriyor; incelemede reddedilme riski en yüksek maddeydi. Manifestte `tools:node="remove"`, `BackgroundSession` eklentiye pil muafiyeti istememesini söylüyor (`shouldRequestBatteryOptimizationsOff: false`). Ön plan hizmeti + kısmi wake lock + Wi-Fi kilidi bağlantıyı tutar. **Cihazda denenmedi:** kilitli telefonla yarım saatten uzun, ekran kapalı oturumda Doze bağlantıyı koparıyor mu? Koparırsa geri alma: izin satırını ve bayrağı eski hâline getir, Play Console'da gerekçe yaz (bölüm 4). | | Yok (artık) |
| `AD_ID` | **yok**, savunma amaçlı `tools:node="remove"` | Uygulamada reklam yok, reklam kimliği okunmuyor. Console'daki "Reklam kimliği" beyanı: **Hayır**. | | |

Diğer bileşenler (izin gerektirmez, Play beyanı gerekmez):
- `QuickTileService`: `BIND_QUICK_SETTINGS_TILE` korumalı, `exported=true` (sistem bağlanır).
- `WearListenerService`: Google Play hizmetleri bağlanır, yalnız `/quickremote` yolundaki Data Layer iletileri.
- `ShortcutActivity`: dışa açık değil. `MainActivity` yalnız `quickremote://watch` VIEW süzgecini taşır (saatten "telefonda aç").
- `allowBackup=false`: PIN'ler ve ayarlar bulut yedeğine girmez.
- `<queries>`: yalnız PROCESS_TEXT (Flutter), paket görünürlüğü beyanı gerekmez.

## 2. Saat uygulaması (`quick_remote_wear`)

| İzin | Neden | Tür |
|---|---|---|
| `VIBRATE` | Konuşma süresi uyarıları (`AlertService`). | Normal |
| `BLUETOOTH_CONNECT`, `BLUETOOTH` (≤30) | Lazerin telefonla doğrudan Bluetooth soketi (`DirectLink`). İsteğe bağlı; reddedilirse lazer Data Layer üzerinden gider. | Çalışma zamanı |
| `WAKE_LOCK` | Ortam (ambient) modu. | Normal |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE`, `CHANGE_NETWORK_STATE` | `PresentingService`: kumandayı Ongoing Activity olarak göstermek. `CHANGE_NETWORK_STATE` yalnız `connectedDevice` önkoşulu (uygulamayla birlikte verilir). | Normal |
| `POST_NOTIFICATIONS` | Aynı hizmetin bildirimi. | Çalışma zamanı |

`uses-feature android.hardware.type.watch`, `standalone=false`. Saat uygulaması kamera, konum, internet izni istemez. Ağ erişimi yok.

Gereksiz izin bulunmadı; saat manifestinde değişiklik yapılmadı.

## 3. Play Console: Ön plan hizmeti beyanı (Uygulama içeriği > Ön plan hizmeti izinleri)

İki hizmet için de tür **"Bağlı cihaz" (`connectedDevice`)**. İstenen alanlar: kullanım senaryosu, kullanıcıya etkisi, hizmet çalışmazsa ne olur, video bağlantısı.

### Telefon: `IsolateHolderService` (flutter_background)

**Türkçe**
> QuickRemote, telefonu bilgisayardaki sunumun kumandası yapar. Hizmet, kullanıcı bir kumanda ekranını (Wi-Fi ya da Bluetooth) açtığı sürece çalışır ve ekran kapanınca ya da kumandadan çıkılınca durur. Görevi, kullanıcının kendi bilgisayarıyla kurulu bağlantıyı (yerel ağda TLS WebSocket ya da Bluetooth HID klavye/fare) telefon kilitlenince ya da uygulama arka plana alınınca da canlı tutmaktır. Sunum yaparken telefon cebe konur ya da ekran kapanır; hizmet olmazsa Android bağlantıyı keser, Bluetooth HID kaydını düşürür ve kullanıcı slayt çeviremez. Hizmet kullanıcıya görünür bir bildirim gösterir. Kullanıcı bildirimin hizmetini durdurmak için kumandadan çıkar. Hizmet yalnızca bağlı bilgisayar/Bluetooth cihazı ile bağlantıyı sürdürmek içindir; başka veri toplamaz ve arka planda ayrı iş yapmaz.

**English**
> QuickRemote turns the phone into a remote control for a presentation on the user's computer. The service runs only while the user has a remote screen open (Wi-Fi or Bluetooth) and stops when the screen is left. Its job is to keep the connection to the user's own computer (a TLS WebSocket on the local network, or a Bluetooth HID keyboard/mouse) alive when the phone locks or the app goes to the background. While presenting, the phone is often put in a pocket or the screen turns off; without the service Android closes the connection and drops the Bluetooth HID registration, and the user can no longer change slides. The service shows a visible notification, and it is stopped by leaving the remote. It is used only to maintain the link with the connected computer or Bluetooth device; it collects no other data and does no other work in the background.

Video (liste dışı YouTube): telefonu kilitle, bildirim görünsün, kilitliyken kumandadan slayt çevir, kumandadan çık, bildirim kaybolsun. Bluetooth modunu da kısaca göster.

### Saat: `PresentingService`

**Türkçe**
> Saat uygulaması, sunum sırasında telefondaki QuickRemote üzerinden slaytları yöneten bir kumandadır. Hizmet, telefon bir bilgisayara bağlıyken çalışır ve kumandayı bir Ongoing Activity olarak gösterir; böylece saatin ekranı uyanınca kullanıcı saat kadranına değil kumandaya döner. Telefonla bağlantı koptuktan 60 saniye sonra kendiliğinden durur. Görünür bir bildirimi vardır; veri toplamaz.

**English**
> The watch app is a remote for slides controlled through the QuickRemote phone app. The service runs while the phone is connected to a computer and shows the remote as an Ongoing Activity, so that when the watch screen wakes, the user returns to the remote instead of the watch face. It stops by itself 60 seconds after the phone connection is lost. It has a visible notification and collects no data.

## 4. Gerekirse: pil optimizasyonu izni geri konursa

> The app keeps a user-initiated connection to the user's own computer alive while the phone is locked during a presentation (foreground service of type connectedDevice). Doze would close the socket and the Bluetooth HID link within minutes, which ends the presentation control. The permission is requested once, through the system dialog, only when the user opens a remote screen.

Şimdilik gerekmiyor.

## 5. Diğer Console beyanları (izinlerle ilgili)

- **Reklam kimliği:** Hayır.
- **Hassas izinler formu** (SMS, arama kaydı, konum arka plan, tüm dosyalar, erişilebilirlik, VPN, tam ekran bildirim, tam alarm): hiçbiri kullanılmıyor, form çıkmaz.
- **Bağlantı sorunu:** Android 14 `connectedDevice` önkoşulu: `CHANGE_WIFI_MULTICAST_STATE` (telefon) ve `CHANGE_NETWORK_STATE` (saat) ile karşılanıyor.
- **Android 16 (targetSdk 36):** büyük ekranda yön/yeniden boyutlandırma kısıtları yok sayılıyor; uygulama yön kilitlemiyor (`setPreferredOrientations` kullanılmıyor).
