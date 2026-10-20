# PC tepsisi, güncelleme, kurulum, telefon kısayolu, CI ve hata günlüğü: inceleme raporu

Tarih: 2026-10-20. Durum: yalnızca inceleme. Kod yazılmadı, hiçbir şey denenmedi.
Önceki raporlar: [OVERLAY_RAPOR.md](OVERLAY_RAPOR.md), [ACIK_ISLER_RAPOR.md](ACIK_ISLER_RAPOR.md).

## Bugünkü durum (depoda bakıldı)

| Konu | Durum |
|---|---|
| Sistem tepsisi | Yok. `window_manager` var, pencere kapanınca uygulama kapanıyor. |
| Oturum açılınca başlama | Yok. |
| Tek örnek (ikinci açılış) | Yok. Linux'ta `G_APPLICATION_NON_UNIQUE`; Windows runner'da mutex yok. İkinci kopya aynı portu açmaya çalışır. Otomatik başlama gelince bu sık yaşanır. |
| Sürüm | İki uygulama da `0.1.0+1`. GitHub'da hiç release yok. Repo açık (public). |
| Kurulum | Windows için yok. Linux'ta `linux/packaging/` içinde yalnızca `.desktop` dosyası ve `install-uinput-rule.sh` var. |
| Telefon kısayolları | Yok. Manifest'te yalnızca `quickremote://watch` bağlantısı var; `flutter_deeplinking_enabled=false`, yani bağlantıyı uygulama kendisi işliyor. |
| CI | Yok (`.github/` klasörü yok). |
| Günlük | PC'de 116, telefonda 27 `debugPrint`; hiçbiri dosyaya yazılmıyor. `FlutterError.onError` ya da `PlatformDispatcher.onError` hiçbir yerde yok. |

## Özet ve önerilen sıra

| # | İş | Büyüklük | Öneri |
|---|---|---|---|
| 1 | CI (GitHub Actions) | 1-2 gün | **İlk bu.** Diğerlerinin hepsi (release, kurulum paketleri) üstüne kurulur. |
| 2 | Tek örnek, tepsi, otomatik başlama | 3-4 gün | Yap |
| 3 | Kurulum paketleri ve release akışı | 4-6 gün | Windows Inno Setup; Linux tarball, AUR, .deb. Flatpak yok. |
| 4 | Güncelleme denetimi | 1 gün | 3'ten sonra; release yokken bakacak bir şey yok |
| 5 | Telefon: uygulama kısayolları ve Hızlı Ayarlar kutucuğu | 2-3 gün | Yap; ana ekran widget'ı sonra |
| 6 | Yerel hata günlüğü ve dışa aktarma | 2 gün | Yap. Uzak çökme raporu şimdilik yok. |

---

## 1. CI (GitHub Actions)

Repo açık olduğu için GitHub Actions dakikaları ücretsiz, Windows runner'ı dahil.

### İşler

Her biri yalnızca kendi klasörü değişince çalışır (`paths` filtresi).

| İş | Runner | Adımlar |
|---|---|---|
| shared | ubuntu | `dart pub get`, `dart analyze`, `dart test` |
| pc-linux | ubuntu | `flutter pub get`, `dart analyze`, `flutter test`, `flutter build linux` |
| pc-windows | windows | `flutter test`, `flutter build windows` |
| python | ubuntu + windows | `python -m unittest discover -s quick_remote_pc/test/python` |
| app | ubuntu | `dart analyze`, `flutter test`, `flutter build apk --debug --target-platform android-arm64` |
| wear | ubuntu | JDK 21, `./gradlew :app:testDebugUnitTest :app:lintDebug` |

Notlar:

- **Flutter sürümü** sabitlenir: `subosito/flutter-action`, 3.47.5. Böylece CI ile makinen aynı sürümü kullanır.
- **Depo yolu**: CI'daki yolda Türkçe karakter yok. `flutter analyze` çökmesi orada olmaz, ama CLAUDE.md'ye uyum için yine `dart analyze` kullanılır.
- **TLS testleri**: Hafızadaki not, `tls_handshake_gate_test`'in yalnızca `very_good` tek-paket modunda bozulduğunu söylüyor. Düz `flutter test` her dosyayı ayrı çalıştırır; CI'da sorun beklenmez. **DOĞRULANACAK**.
- **Windows'ta ne yakalanır**:
  - Linux'taki `dart analyze` Windows Dart kodunu zaten derler; iki platformun kodu aynı programda.
  - Windows runner'ın ek yakaladıkları: C++ runner'ın derlenmesi, testlerde `Platform.isWindows` dalları, Python köprü testlerinin Windows davranışı.
  - Ucuz bir ek: PowerShell betikleri `pwsh` ayrıştırıcısından geçirilebilir (`[System.Management.Automation.Language.Parser]::ParseInput`). Betikler Dart dizgilerinin içinde; bunun için betikleri dışarı yazan küçük bir test yardımcısı gerekir.
- **İlk koşu**: Windows'ta hangi testlerin Linux'a bağlı olduğu bilinmiyor. İlk koşuda kırılanlar `skip: Platform.isWindows` ile işaretlenir ya da düzeltilir.
- **Gradle**: `compileSdk = 37` için runner'da `sdkmanager "platforms;android-37"` gerekir. APK derlemesi ~10 dakika; yalnızca `quick_remote_app/android` değişince ya da günde bir kez çalışabilir.

**Durum (2026-10-20):** Yazıldı, GitHub'da henüz hiç koşmadı. `.github/workflows/ci.yml`: altı iş (shared, pc-linux, pc-windows, python ubuntu+windows, app, wear), `dorny/paths-filter` ile yalnızca değişen klasörler; `packages/` kendisine bağlı her şeyi, saatin testlerinin okuduğu telefon dosyaları saati çalıştırır; `v*` etiketi, haftalık (pazartesi 04:00 UTC) ve elle koşu hepsini çalıştırır. Flutter 3.47.5 sabit, `dart analyze`, JDK 21, `sdkmanager "platforms;android-37"`, pc-linux'ta `libx11-dev`, `libxi-dev` ve paketleme betiklerinin `sh -n` denetimi. Üçüncü taraf eylemler commit SHA'sına sabitlendi. `actionlint` (shellcheck ile) temiz. İlk koşuda Windows'ta Linux'a bağlı testler kırılabilir (yukarıdaki not).

---

## 2. Tek örnek, sistem tepsisi, oturum açılınca başlama

**Durum (2026-10-20):** Kodlandı, birim testleri geçiyor, `flutter build linux --debug` derleniyor; uygulama çalıştırılıp elle denenmedi. Linux runner tekil (ikinci açılış ilk pencereyi gösterir); Windows `main.cpp` `Local\QuickRemotePC` mutex'iyle ikinci kopyayı kapatır (Windows'ta hiç derlenmedi). Tepsi `tray_manager` 0.8 ile (nativeapi; appindicator gerekmiyor, derlemede GTK 3, X11, Xi geliştirme paketleri yeter); menü Göster · Sunucuyu başlat/durdur · telefon sayısı · yeni sürüm · Çıkış; simge logo üstünde durum noktası (gri, yeşil, mavi, sarı). Linux'ta tepsi yalnızca `org.kde.StatusNotifierWatcher` varsa; yoksa kapatınca uygulama kapanır. Ayarlar'da "Kapatınca tepsiye küçült" (ilk seferde bir kez bilgi penceresi), "Oturum açılınca başlat" (Linux `~/.config/autostart`, Windows HKCU Run, ikisi de `--minimized`), "Açılınca sunucuyu başlat" (ortak ağda kendiliğinden başlamaz, durum kartının altında sarı satır). CI, release ve paket dosyaları da buna göre güncellendi (`libx11-dev libxi-dev`).

### Tek örnek (önce bu)

- **Linux**: `NON_UNIQUE` bayrağı kaldırılır. GtkApplication ikinci açılışı ilk kopyaya iletir (`activate`); ilk kopya penceresini gösterir.
- **Windows**: Adlandırılmış bir mutex (`Local\QuickRemotePC`). İkinci kopya ilk kopyanın penceresini öne getirip kapanır.

### Tepsi

- **Paket**: `tray_manager`. `window_manager` ile aynı yazarın; Windows ve Linux'u destekliyor.
  - ~~Linux'ta `libayatana-appindicator3` ister.~~ Düzeltme: 0.8 sürümü tepsiyi D-Bus üzerinden kendisi gösteriyor; derlemede GTK 3, `libx11-dev`, `libxi-dev`, çalışırken libx11 ve libxi yeter.
  - Alternatif: StatusNotifierItem'ı D-Bus üzerinden kendimiz yazmak (`dbus` paketi zaten bağımlılık). Yeni kütüphane gerekmez, ama menü protokolü (dbusmenu) epey iş.
- **Menü**: Göster · Sunucu: Açık/Kapalı · Bağlı telefonlar (sayı) · Çıkış.
- **Simge** durumu gösterir: kapalı, açık, telefon bağlı.
- **Pencere kapanınca** tepsiye iner. İlk seferde bir kez "QuickRemote arka planda çalışıyor" bildirimi çıkar; Ayarlar'da "Kapatınca tepsiye küçült" anahtarı.
- **GNOME**: Tepsi yalnızca AppIndicator eklentisiyle var. Ubuntu'da hazır, Fedora'da yok. Tepsi yoksa pencere kapanınca uygulama bugünkü gibi kapanır. Tepsinin varlığı D-Bus'ta `org.kde.StatusNotifierWatcher` ile anlaşılır.

### Oturum açılınca başlama

- **Linux**: `~/.config/autostart/com.quickremote.quick_remote_pc.desktop`, `Exec=... --minimized`. `DesktopEntry` bu dosyayı yazmayı zaten biliyor; yeni paket gerekmez.
- **Windows (Inno Setup ya da zip)**: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` anahtarına `--minimized` ile bir değer. `win32` paketiyle yazılır.
- **Windows (MSIX)**: Kayıt defteri yolu çalışmaz; manifest'te `windows.startupTask` gerekir.
- `launch_at_startup` paketi bunları sarıyor, ama kendi yazdığımız daha az bağımlılık demek.
- **Ayar** (PC Ayarlar'ı): "Oturum açılınca başlat" ve "Açılınca sunucuyu başlat".
- **Güvenlik**: Otomatik açılışta ağ **Ortak** (public) ise sunucu kendiliğinden başlamaz; tepsi simgesi sarı olur. `NetworkManager` ağın profilini zaten biliyor.
- **Küçültülmüş başlama**: `--minimized` ile pencere hiç gösterilmez. `waitUntilReadyToShow` içindeki `show()` atlanır.

---

## 3. Kurulum paketleri ve release akışı

### Windows

- **Önerim: Inno Setup.**
  - Kullanıcı başına kurulum (yönetici izni gerekmez). Başlat menüsü kısayolu ve otomatik başlama seçeneği var.
  - İsteğe bağlı yönetici adımı: güvenlik duvarı kuralı. Bunu kurulum yazarsa uygulamanın içindeki güvenlik duvarı sorusu çoğu kullanıcıya hiç çıkmaz.
  - VC++ çalışma zamanı DLL'leri (`msvcp140.dll`, `vcruntime140*.dll`) paketin içine konur. Flutter Windows uygulamaları bunları ister, ama hazır gelmez.
- **İmzasız kurulum**: SmartScreen "Windows bilgisayarınızı korudu" uyarısı çıkarır. Çözüm kod imzalama sertifikası:
  - Klasik sertifika yılda ~100-400 $.
  - Azure Trusted Signing ayda ~10 $, ama bireylere yalnızca bazı ülkelerde açık; Türkiye için **kontrol edilmeli**.
  - İlk sürümde imzasız gidip README'de uyarıyı anlatmak da olur.
- **Sonra: Microsoft Store'da MSIX** (`msix` paketi).
  - Store imzalar ve güncellemeleri kendisi yapar; SmartScreen sorunu kalkar.
  - Güvenlik duvarı kuralı manifest'e yazılabilir (`desktop2:FirewallRules`).
  - PowerPoint COM'u ve PowerShell alt süreçleri MSIX'te çalışmalı. **DOĞRULANACAK**
- **winget**: Inno kurulumu release'e konunca bir manifest PR'ıyla eklenir. Ucuz.

### Linux

| Biçim | Uygunluk | Neden |
|---|---|---|
| **tar.gz** (`flutter build linux` çıktısı) | Evet | Her şeyin temeli; diğer paketler bundan yapılır |
| **AUR** (`quickremote-pc-bin`) | Evet, ilk | Sen Arch tabanlı CachyOS kullanıyorsun; en hızlı denenecek yol. Bağımlılıklar: `gtk3`, `libx11`, `libxi`, `python`, isteğe bağlı `libreoffice`, `avahi`. |
| **.deb** | Evet | Ubuntu, Debian ve **Pardus** (Türkiye'deki okullar ve kurumlar için önemli). `postinst` udev kuralını kurulumda yazar, uygulamadaki "İzin ver" adımı gereksizleşir. `python3-uno` "Önerilen" bağımlılık. |
| **.rpm** | Sonra | Fedora ve openSUSE; .deb ile aynı iş |
| **AppImage** | Belki | Tek dosya, her yerde çalışır. Ama Ubuntu 22.04 ve sonrasında `libfuse2` kurulu değil. udev kuralı uygulamanın `pkexec` adımıyla yazılır (bugünkü gibi). |
| **Flatpak** | **Hayır** | Ayrıntılar aşağıda |

Flatpak neden uymuyor:

- `/dev/uinput` için `--device=all` gerekir.
- `pkexec` ile udev kuralı yazılamaz.
- LibreOffice'in UNO borusu ana sistemin `/tmp`'sinde; kum havuzunun `/tmp`'si ayrı.
- Ana sistemin `python3-uno`'su ve WPS içeride görünmez.
- Hepsi `flatpak-spawn --host` ister. Bu, kum havuzundan kaçmak demek ve Flathub kabul etmez.

### Release akışı (CI'ın üstüne)

- `v0.2.0` gibi bir etiket itilince GitHub Actions şunları yapar:
  - Windows kurulumunu, Linux tar.gz ve .deb paketlerini derler.
  - Telefonun ve saatin APK'larını isteğe bağlı olarak ekler (Play dışı kurulum için).
  - Hepsini bir GitHub release'e koyar; release notunu değişikliklerden taslak olarak yazar.
- **İmza anahtarları**: Telefonun `key.properties` dosyası ve keystore'u gerekir. Bunlar GitHub Secrets'a konur. Yerel dosyada kalmak istersen APK'lar elle eklenir.
- **Sürüm numarası** tek yerden gelmeli. Etiketten okunup `--build-name` ile derlemeye verilir.

**Durum (2026-10-20):** Yazıldı, GitHub'da henüz hiç koşmadı. `.github/workflows/release.yml`: `v*` etiketinde sürüm etiketten (`--build-name`, `--dart-define=APP_VERSION`; Android versionCode = MAJOR·10000 + MINOR·100 + PATCH, saat +1 000 000); Windows Inno Setup kurulumu (`windows/installer/quickremote.iss`, kullanıcı başına, imzasız, VC++ DLL'leri içinde, runner'da sessiz kurulum denemesi); Linux tar.gz, AUR için `-noupdate` tar.gz (`UPDATE_CHECK=false`) ve .deb (ubuntu-22.04'te derlenir, glibc 2.35); .deb `debian:12` ve `ubuntu:22.04` kapsayıcılarında kurulur, eksik kütüphane aranır, Xvfb'de 15 sn açık kalması ve kaldırılması denenir; imza sırları varsa telefon ve saat APK'ları (aynı imza denetlenir), yoksa atlanır; taslak GitHub release (oluşturulan notlar + kurulum notu + commit listesi, `SHA256SUMS.txt`). AUR PKGBUILD'i sürüm ve sha256 doldurulmuş olarak `aur-pkgbuild` artifact'ı olur; AUR'a elle itilir. .deb udev kuralını paket dosyası olarak (`/usr/lib/udev/rules.d`) taşır. Elle koşu (workflow_dispatch) release açmadan her şeyi derleyip dener. Yerelde: `actionlint`, `shellcheck`, `makepkg --printsrcinfo`, sahte bir bundle ile tarball, .deb ağacı ve `makepkg` paketi denendi; Flutter derlemesi, Inno Setup ve gerçek `dpkg-deb` denenmedi. README'ye kurulum bölümü eklendi. Kullanıcının yapacakları: Android imza sırları (isteğe bağlı), AUR hesabı ve `quickremote-pc-bin` deposu, bir lisans seçimi (PKGBUILD'de `LicenseRef-QuickRemote`, depoda LICENSE yok), Pardus sanal makinesinde bir kez deneme.

---

## 4. Güncelleme denetimi

**Durum (2026-10-20):** Kodlandı ve test edildi (sürüm karşılaştırma, cevap ayrıştırma, sahte istekle denetim). Açılışta ve 24 saatte bir `releases/latest` sorulur, `APP_VERSION` ile karşılaştırılır; yeniyse durum kartının altında "Yeni sürüm: X · İndir" satırı ve tepside bir öğe çıkar, ikisi de release sayfasını tarayıcıda açar. Ayarlar'da "Güncellemeleri denetle" (açık başlar); `--dart-define=UPDATE_CHECK=false` ile derlemede kapanır. Gerçek GitHub'a karşı denenmedi (henüz release yok).

- **Kaynak**: `GET https://api.github.com/repos/berat-kaan-akcan/QuickRemote/releases/latest`.
  - Kimliksiz istekler IP başına saatte 60 hakla sınırlı; açılışta ve 24 saatte bir bakmak bunun çok altında kalır.
  - PC'ye ayrıca `http` paketi eklemeye gerek yok; `dart:io HttpClient` yeterli.
- **Karşılaştırma**: `tag_name` ile derlenen sürüm (`--build-name` ile verilir, `--dart-define` ile koda girer) karşılaştırılır.
- **Gösterim**: Durum kartının altında "Yeni sürüm: 0.3.0 · İndir" satırı ve tepside bir not. Tuş release sayfasını tarayıcıda açar.
- **Kendiliğinden indirip kurma yok**: Bunun için indirilen dosyanın imzasını doğrulamak gerekir. Önce imzalı paketler gelmeli.
- **Kapatılabilir**: Ayarlar'da "Güncellemeleri denetle" anahtarı (açık başlar). GitHub'a bağlanmak IP adresini gösterir; gizlilik notunda yazar.
- **Kendi güncellemesi olan paketler**: AUR, Store, winget ve .deb (depodan kurulursa) sürümlerinde denetim derlemede kapatılır (`--dart-define=UPDATE_CHECK=false`).
- **Ek fikir, ucuz**: `auth` cevabında PC'nin sürümü zaten gönderilebilir. Telefon, PC eskiyse "PC uygulamasını güncelleyin" der. Protokol farkı olan özelliklerde (önizleme, `caps`) kullanıcı neden çalışmadığını anlar.
- **Telefon**: Güncellemeleri Play Store yapar. `in_app_update` paketiyle uygulama içinde güncelleme istenebilir; acil değil.

---

## 5. Telefon: tek dokunuşla son PC'ye bağlanma

Bağlantı Dart'ta yaşıyor. Hangi kısayol olursa olsun yapacağı iş aynı: uygulamayı `quickremote://connect/last` gibi bir niyetle (intent) açmak. Dart bu niyeti alınca:

- Son PC'ye (`DeviceHistoryRepository`, kayıtlı PIN ile) bağlanır.
- Sertifika parmak izi kayıtlı olduğu için güvenlik aynı kalır.
- PC'nin IP'si değişmişse (DHCP) mDNS'te aynı adı arar.
- Bulamazsa ana ekranı açar ve "PC bulunamadı" der.

`quickremote://watch` için yazılan yol örnek alınır. `flutter_deeplinking_enabled=false` olduğu için niyeti MethodChannel ile uygulama kendisi okur.

| Yol | İş | Ne verir |
|---|---|---|
| **Uygulama kısayolları** (simgeye basılı tutunca) | En az iş. `res/xml/shortcuts.xml` statik; "Son PC" adı dinamik bir kısayolla (`ShortcutManager`) eklenir. | "Son PC'ye bağlan", "Bluetooth kumanda", "QR tara". Her başlatıcıda var, ana ekrana da sabitlenebilir. |
| **Hızlı Ayarlar kutucuğu** (`TileService`, Android 7+) | Az | Bildirim panelinden tek dokunuş. Android 14+ `startActivityAndCollapse(PendingIntent)` ister, eskileri `Intent`. Alt yazıda (Android 10+) son PC'nin adı. Bağlıyken kutucuk "açık" görünebilir; bunun için Dart her bağlantıda `TileService.requestListeningState` çağırır. |
| **Ana ekran widget'ı** | Fazla | "Bağlan: <PC adı>" tuşu. Bağlıyken Önceki/Sonraki tuşları, ama bunlar yalnızca kumanda ekranı açıkken (arka plan oturumu) çalışır; kapalıyken uygulamayı açar. RemoteViews ya da Glance gerekir. Sonraya. |

- Metinler Android kaynaklarında olur (`values` ve `values-tr`), ARB'de değil. `l10n_test` yalnızca Dart'a baktığı için etkilenmez.
- Bluetooth modunda "Bluetooth kumanda" kısayolu son seçilen hedefle (`btTarget`) açılır.

**Durum (2026-10-20):** Uygulama kısayolları ve Hızlı Ayarlar kutucuğu yazıldı (widget yok). Statik "Bluetooth kumanda" ve "QR tara", dinamik "Bağlan: <son PC>"; kutucuk son PC'ye bağlar, Wi-Fi bağlıyken açık görünür, alt yazısı son PC'nin adı. Bağlantılar yalnızca açık niyetle gider (`ShortcutActivity` dışa kapalı, niyet filtresi yok). Dart tarafı `lib/services/launch_actions.dart` (`LaunchActions`, `LastPcConnect`): kayıtlı PIN ve sabitlenmiş parmak iziyle bağlanır; adres yanıt vermezse mDNS'te aynı adı 6 sn arar ve eski adresin parmak iziyle bağlanır; bulamazsa ana ekranda "PC bulunamadı" der. Birim testleri `test/launch_actions_test.dart`. Debug APK derlendi; telefonda (başlatıcı, kutucuk, dışa kapalı etkinliğin kısayoldan açılması) henüz denenmedi.

---

## 6. Hata günlüğü ve isteğe bağlı çökme raporu

### Önce yerel günlük (önerim)

- Küçük bir `AppLog` sınıfı yazılır. `debugPrint` çağrıları ona döner; günlük hem konsola hem dosyaya yazılır.
  - PC'de dosya uygulama destek klasöründe; telefonda uygulamanın kendi klasöründe.
  - Dosya 1 MB'a ulaşınca yenisine geçilir; 3 dosya tutulur.
- Yakalanmayan hatalar da günlüğe gider: `FlutterError.onError`, `PlatformDispatcher.instance.onError` ve isolate hataları.
  - Native çökmeler (FFI'da segfault) bu yolla yakalanmaz.
  - Linux'ta köprülerin stderr'i günlüğe yönlendirilebilir.
- **Gizlilik**: Bazı şeyler hiçbir zaman yazılmaz: PIN, eşleştirme QR'ının içeriği, notların metni, dosya yolları. IP adresleri ve cihaz adları yazılır (sorun çözmek için gerekli).
  - `AppLog.redact` testlerle korunur.
- **PC'de dışa aktarma**: Ayarlar'da "Günlüğü dışa aktar"; `file_selector` zaten bağımlılık.
- **Telefonda dışa aktarma**: Ayarlar'da "Hata günlüğünü paylaş" (Android paylaşım menüsü).
- **Hazır GitHub issue bağlantısı**: Sürüm, platform ve program bilgisi önceden doldurulmuş bir `issues/new?title=...&body=...` adresi. Günlüğü kullanıcı kendisi ekler; sunucu gerekmez.

- **Durum (2026-10-20):** Yerel günlük yapıldı. `AppLog` ortak pakette (dosya, 1 MB'ta döndürme, 3 dosya, arabellekli yazma, `redact` ve testleri); iki uygulamada `debugPrint` ve yakalanmayan hatalar ona gidiyor, Linux köprülerinin stderr'i de. PC'de Ayarlar → Sorun giderme ("Günlüğü dışa aktar", "Sorun bildir"), telefonda Ayarlar → Yardım ("Hata günlüğünü paylaş", `share_plus`; "Sorun bildir", `url_launcher`). Uzak çökme raporu yapılmadı (karar). Telefon APK'sı sürümü `--dart-define=APP_VERSION` ile almalı; release.yml'nin APK satırına eklenmeli. Windows'ta kaydetme penceresi ve tarayıcı, Android'de paylaşım menüsü elle denenmedi.

### Uzak çökme raporu (sonra, istenirse)

- **Sentry** (`sentry_flutter`) hem PC'de hem telefonda çalışır. Kendi sunucusu kurulabilir ya da ücretsiz bulut katmanı kullanılabilir.
- **Varsayılan kapalı.** İlk açılışta ya da Ayarlar'da açık bir onay istenir (KVKK ve GDPR).
- Play Console'un Veri güvenliği formu güncellenir.
- Gönderilen bilgide yerel günlükteki ayıklama kuralları geçerli olur.
- **Play'in kendi raporları**: Play Console native çökmeleri ve ANR'ları zaten topluyor (Android vitals). Uygulamayı çökertmeyen Dart hataları orada görünmez.

---

## Sorular ve önerilerim (2026-10-20)

1. **CI'ın kapsamı**: APK ve saat derlemeleri her PR'da mı çalışsın (yavaş), yoksa yalnızca kendi klasörleri değişince mi?
   - **Önerim: Yalnızca kendi klasörleri değişince.** `packages/` değişince ona bağlı olan her şey çalışır.
   - APK ve saat derlemesi ayrıca etiket (release) itilince her zaman çalışır.
   - Haftada bir tam koşu yapılır; araç zincirindeki bozulmaları yakalar.
2. **Windows imzası**: İlk sürüm imzasız mı çıksın, yoksa sertifika mı alınsın? Store'a başvurmayı düşünüyor musun?
   - **Önerim: İlk sürüm imzasız çıksın.** README'de SmartScreen uyarısı ("Ek bilgi → Yine de çalıştır") anlatılır. Ücretli sertifika alınmaz.
   - İmzalı yol Microsoft Store'daki MSIX olur: Store imzalar ve günceller. Store'a sonraki adımda başvurulur.
3. **Linux paketleri**: AUR + .deb + tar.gz ile başlamak uygun mu? Pardus'ta deneme yapabilecek misin?
   - **Önerim: Evet, bu üçüyle başlanır.** .deb, CI'da `debian:12` kapsayıcısında kurulup açılış denemesinden geçer. Pardus 23 Debian 12 tabanlı olduğu için bu Pardus'u da büyük ölçüde kapsar.
   - Gerçek Pardus denemesi bir sanal makinede, ilk release'ten önce bir kez yapılır.
   - AppImage ve .rpm sonra; Flatpak yok.
4. **Güncelleme denetimi**: Varsayılan açık mı olsun, kapalı mı?
   - **Önerim: Açık**; Ayarlar'dan kapatılabilir.
   - Kendi güncellemesi olan paketlerde (AUR, Store, winget) derlemede kapalı olur.
   - Yalnızca bildirir, hiçbir şey indirmez.
5. **Uzak çökme raporu**: Şimdilik yalnızca yerel günlük ve GitHub issue bağlantısı yeterli mi?
   - **Önerim: Evet.** Uzak çökme raporu (Sentry), kullanıcı sayısı artıp günlükler yetmezse yeniden düşünülür; o zaman da açık onayla ve varsayılan kapalı.
