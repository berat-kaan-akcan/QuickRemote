# QuickRemote: yapılmayanlar

Son güncelleme: 2026-10-26. Bütün açık işler bu dosyada: denenmemiş özellikler, yazılmamış kod, bekleyen kararlar ve bilerek sonraya bırakılanlar. Bitenler [YAPILANLAR.md](YAPILANLAR.md)'de.

Bir madde bitince buradan silinir ve YAPILANLAR.md'deki ilgili bölüme sonucuyla (tarih, sürüm, ne görüldü) yazılır.

Bu dosyanın dışında kalan iki liste:

- [PPT_WEB_PLAN.md](PPT_WEB_PLAN.md): tarayıcıda PowerPoint ve Google Slaytlar. Kodu yazıldı; deneme listesi (6. bölüm) orada.
- [../../PLAY_STORE_YAPILACAKLAR.md](../../PLAY_STORE_YAPILACAKLAR.md) ve `store/KONTROL_LISTESI.md`: Play Store'a çıkış.

Bu dosya şunlardan toplandı (2026-10-26, eskileri silindi, geçmişi git'te): `DURUM.md`, `KALANLAR.md`, `WINDOWS-DENEME.md`, `docs/raporlar/` içindeki ACIK_ISLER, ALTYAPI, OVERLAY, SLIDE_PREVIEW (rapor ve görev), SITE_YENILEME, CI_RAPOR, GUVENLIK_DENETIMI ve KULLANICI_DENETIMI raporları.

**Uyarı:** Linux'taki ekran denemeleri tuşlara basar ve tam ekran açar. Başlamadan önce açık olan her şeyi kapat ya da küçült.

---

## 1. Senin kararını bekleyenler

- [ ] **Lisans.** Depoda LICENSE yok. Site "Açık kaynak", README "kişisel kullanım" diyor; AUR PKGBUILD'i yer tutucu `LicenseRef-QuickRemote` kullanıyor.
- [ ] **Paket adı (`applicationId`).** Şu an `com.quickremote.quick_remote_app`. Play'e ilk yüklemeden sonra hiç değişmez. Öneri: `io.github.beratkaanakcan.quickremote` ya da sahip olunan bir alan adı. Değişirse telefon ve saat birlikte değişir.
- [ ] **Uygulamanın adı.** Şimdilik QuickRemote (boşta olan aday SlideMando'ydu). Play'deki benzer adlara bakılmalı.
- [ ] Ücretsiz/ücretli ve sürüm numarası düzeni: PLAY_STORE_YAPILACAKLAR.md, 0. bölüm.

---

## 2. Yazılmamış kod

### Windows'ta Bluetooth klavye onarımı

Windows denemesi (2026-10-25) olumsuz çıktı: HID hizmetini kapatıp açmak telefonu klavye yapmadı, ama kaldırıp yeniden eşleştirmek yaptı (ayrıntı YAPILANLAR.md, "Windows Bluetooth denemesi"). Yazılacak olan, şunlardan biri:

- [ ] PC penceresinde **"Telefonu yeniden eşleştir"** tuşu: `BluetoothRemoveDevice`, ardından eşleştirme. Programla eşleştirme (`BluetoothAuthenticateDeviceEx`) denemede 1244 verdi ve iki cihazın onayı aynı ana denk gelmedi; tuş belki yalnızca kaldırıp Windows'un "Cihaz ekle" penceresini açmalı.
- [ ] Ya da hayalet HID aygıtını (`CM_PROB_PHANTOM`) silmek, ya da BLE klavye (HID over GATT).
- O zamana kadar uygulamanın bugünkü Windows talimatı (kaldır, yeniden eşleştir) doğru.

### Küçük işler ve fikirler

- [ ] **PC'nin sürümü `auth` yanıtında**: telefon eski bir PC'ye "PC uygulamasını güncelleyin" diyebilsin diye (önizleme, `caps`, `site` gibi protokol farklarında kullanıcı nedenini anlar).
- [ ] **Telefonda PDF tam ekranından çıkış tuşu**: PC tam ekran olup olmadığını bildirmiyor.
- [ ] **Saat, gösteri dışında siyah/beyaz ekranı soluk gösteriyor**: kaplama orada çalıştığı hâlde. Saate ayrı bir bayrak gerekiyor (`laserAnywhere` gibi).
- [ ] **Siyah ekran açıkken kaplamanın mürekkebi**: programın siyah ekranından dönünce mürekkep yoklama süresi kadar (≤2 sn) gecikmeyle yeniden çiziliyor.
- [ ] **Küçük uç durum**: PC `caps`'te kalemi listeleyip lazeri listelemezse dokunmatik alandaki tek dokunuş başarısız olur.
- [ ] **WPS'in ana sayfası Windows'ta "editor" sayılıyor** (`front`). START artık orada F5 basmıyor (`START_FAILED`), ama telefon "düzenleyici önde" sanıyor.
- [ ] **WPS gösterisi biterken telefon bir an "0 / 0" alıyor** (Windows, WPS 12.1).
- [ ] **Saat, bildirim izni reddedilince bunu söylemiyor**: Ongoing Activity görünmez, ekran uyanınca saat yüzü gelir. Hata değil, ama kullanıcı nedenini bilmez.
- [ ] Kaplama planında kalan komutlar: `SET_PEN_WIDTH:n` (kalem kalınlığı), `SET_LASER_STYLE` (lazer rengi, boyutu, izi). Çoklu telefonda her telefona ayrı renkli lazer (fikir).

### Güvenlik denetiminden açık kalanlar (2026-10)

- [ ] **`MainActivity` başka bir uygulamadan açılabiliyor** (düşük): `quickremote://connect/last|scan|bluetooth` açık (explicit) bir intent'le gönderilip son bilgisayara bağlanma ya da kamera açtırılabilir. Etkisi küçük (kendi bilgisayarına bağlanır). Öneri: `ShortcutActivity`/`QuickTileService` intent'ine süreç ömürlü rastgele bir jeton koyup `LaunchLink.linkOf`'ta denetlemek. Kotlin ve cihaz denemesi ister.
- [ ] **Windows sertifika parolası `cert_pwd.txt` olarak `.pfx`'in yanında**: koruma yalnızca dosya izinleri. DPAPI ile korunabilir; Windows'ta yazılıp denenmeli.
- [ ] **İkili hareket çerçeveleri sınırsız işleniyor** (kimliği doğrulanmış istemci; birleştirici ucuz). Gerçek bir dokunmatik akışı 250 Hz'e çıkabildiği için eşik cihazda ölçülmeden konmadı.
- [ ] **Saniyedeki yeni TLS bağlantısı sınırsız**: eşzamanlı handshake sınırlı, ama yerel ağdaki biri RSA el sıkışmalarıyla işlemci harcatabilir. Gerçek ağda ölçülmeli.
- [ ] **PowerShell çıktı işareti (`___PS_DONE___`)**: bir sunumun notlarında bu satır varsa köprü kayabilir (yalnızca bozuk durum, yetki yok; telefondan tetiklenemez).
- Bilerek böyle: udev kuralı (`TAG+="uaccess"`) oturumdaki her uygulamaya sanal klavye verir; ürünün işi bu, belgelendi, paket kaldırılınca kural gider.

---

## 3. Linux'ta denenecekler (CachyOS/KDE makinesi)

### Lazer ve mürekkep katmanı

- [ ] İki monitör: katman gösterinin olduğu monitörde mi açılıyor?
- [ ] GNOME (Mutter). %125 ölçek KDE'de doğru (2026-10-21).

### Ekran görüntüsüyle slayt resmi

- [ ] Oynayan video resimde görünüyor mu, 2 saniyelik yoklama yalnızca resim değişince mi gönderiyor? Linux'ta denenemedi: LibreOffice burada yerel Wayland'de (ekran resmi yok), WPS 11.1'de video hiç oynamıyor.

### `caps`/`front` ve mürekkep

- [ ] LibreOffice pencere sınıfları (`libreoffice-impress`, `libreoffice-draw`) X11'de doğru mu, telefon araçları doğru soluklaştırıyor mu? Bu makinede LibreOffice yerel Wayland'de, X sınıfı okunamıyor.
- [ ] İki telefon: biri "mürekkep kalsın", diğeri "temizle"; slaytı değiştirenin ayarı mı geçerli? (İkinci telefon yok; sunucu testi iki gerçek bağlantıyla kapsıyor.)

### PC: tepsi ve güncelleme

- [ ] "Oturum açılınca başlat": oturumu kapatıp açınca küçültülmüş başlıyor mu? (`--minimized` elle doğru.)
- [ ] Güncelleme denetimi: ilk GitHub release'inden sonra "Yeni sürüm" satırı çıkıyor mu?

### PDF görüntüleyiciler ve tarayıcılar

- [ ] Okular (Ctrl+Shift+P) ile Başlat/Bitir. Okular kurulu değil.
- [ ] Chrome'da PDF'te Sonraki/Önceki (Firefox'ta denendi).
- [ ] **KDE Wayland'de yerel tarayıcılar** (`kwin_active_window.dart`, KWin betiği): Plasma 6 Wayland'de Chrome → F11, Firefox → Ctrl+Alt+P olmalı. Gerçek KDE oturumunda denenmedi.
- [ ] KDE'de yerel Wayland penceresinin ekran resmi yok (KWin `ScreenShot2`, aşağıda "Bilerek sonraya").

### WPS

- [ ] PC'deki "Devral" düğmesine gerçek tıklama (telefondaki denendi; Wayland'de yapay tıklama yok).

### Destek tablosu

- [ ] Telefondaki "Neler yapılabilir?" tablosunda "Denenmedi" etiketli hücreler (`capability_table.dart`, `_untried`) ve eski `destek-tablosu.md`'deki **†** hücreler: kod okunarak yazıldı, özellikle Impress satırları tek tek doğrulanmadı. Fırsat oldukça birer birer denenip tablo güncellenmeli.

---

## 4. Telefonda denenecekler (Galaxy S23 FE)

Önce telefon uygulamasını **release** olarak derleyip kur; debug yavaşlatıyor.

**Kurulum engeli (2026-10-21):** telefondaki uygulama başka bir anahtarla imzalıydı; bu makinede derlenen release APK üstüne kurulamadı (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Ya imzalayan makineden kurulur ya da uygulama kaldırılıp kurulur (kayıtlı PC'ler ve ayarlar gider). versionCode o zamankinden büyük olmalı (`--build-number`).

- [ ] **Son PC'ye bağlanma**: PC'nin IP'si değişince mDNS'te adıyla bulunuyor mu? (Kayıtlı PIN'le bağlanma ve yanlış PIN'de PIN sorma çalışıyor; IP değiştirmek yönetici parolası istedi.)
- [ ] **Pil izni kaldırıldı**: kilitli telefonla, ekran kapalı, yarım saatten uzun oturumda Doze bağlantıyı koparıyor mu? Koparırsa geri alma `store/izinler.md` bölüm 4.
- [ ] **Bildirim izni reddi**: Android 13+'ta reddedince kumandada bir kez "Bildirim izni kapalı" notu ve "Ayarları aç" çıkıyor mu, ikinci kez çıkmıyor mu (`NotificationDeniedHost`)? Yalnızca widget testinden geçti.
- [ ] **48 dp hedefler ve kontrast**: küçük tuşlar bitişik mi, soluk metinler okunuyor mu (göz ile). Kontrast testi gradyanlı kartlarda yanlış alarm verdiği için gerçek ekranlar bir kez taranmalı. TalkBack elle denenmedi.
- [ ] **`usesCleartextTraffic="false"`**: birleştirilmiş manifest okunmadı; derleyip bir bağlantı denemesi.
- [ ] **Sunucu görünümünde dokunulan yere giden lazer** (`LASER_ABS`): PowerPoint/WPS'te imleç, kaplama ve Impress; 16:9 olmayan ekranda kayma.
- [ ] **PowerPoint gösterisinde** kart, Sunucu görünümü ve "Slayta git" ızgarası telefon ekranında (PC tarafı Windows'ta doğrulandı).
- Bilerek böyle: zamanlayıcı rakamları ve PC üst çubuk hapı büyük yazıda 1.3 ölçekte sınırlı (yer yok). PC'de 48 dp kuralı uygulanmadı (fare arayüzü).

---

## 5. Saatte denenecekler (Galaxy Watch 6)

APK'yı yalnızca `adb -s <saatin seri numarası>` ile kur (bir kez telefona kurulup telefon uygulamasının yerine geçmişti).

- [ ] Saat bölümü PowerPoint ile Windows'ta (aşağıdaki "Yeni arayüzün tam denemesi").
- [ ] Soluk metin renkleri telefonla eşitlendi (`Theme.kt`: `paperTextMuted` 8087A9, `inkTextMuted` 686E91, yüksek karşıtlık kenarlığı 3A3A3A): saati derleyip `WearProtocolTest`'i çalıştır ve ekranda bak.
- [ ] Bağlantı sertleştirmesi (2026-10-24, `49d92a6`: `DirectLink` `SecurityException` yakalıyor, kapanan oturum soket almıyor, yazıcı iş parçacığı oturum başına, `PresentingService` reddedilen `startForeground`'u atlatıyor): saatte bir oturum boyunca, izin oturum ortasında geri alınarak.

---

## 6. Windows'ta denenecekler (bu makine)

### Yeni arayüzün tam denemesi, telefonla

Eski deneme listesi `~/Masaüstü/QuickRemote-tasarim-ornekleri/WINDOWS-DENEME.md` (Linux makinesinde, 16 bölüm). Telefonsuz denemede (2026-10-22, deneme istemcisiyle) yapılanlar YAPILANLAR.md'de. Telefonla kalanlar:

- [ ] PC penceresinin geniş düzeni (760 px ve üstü).
- [ ] Ortak ağ uyarısı, Görünüm ve Dil ayarları.
- [ ] Güvenlik kodu penceresi.
- [ ] Touchpad: kalem renkleri ve silgi.
- [ ] Medya ve "şu an çalan" (SMTC hiç denenmedi).
- [ ] QR ile bağlanma ve telefonu çıkarma.
- [ ] Saat bölümü (WIN-UI 15).

### Diğerleri

- [ ] **Slayt resmi**: WPS 12.2'de `Slides(n).Export` (12.1'de çalışıyor).
- [ ] **Kaplama**: DPI %150 ve iki monitör (%125'te doğru).
- [ ] **Tepsi simgesine tıklama** (sol tık pencere, sağ tık menü). Tek örnek, `--minimized` ve HKCU Run çalışıyor.
- [ ] **"Sorun bildir" tarayıcıda açılıyor mu** (`url_launcher`'a geçildi, sonrası görülmedi). Günlüğü dışa aktarma çalışıyor.
- [ ] **Edge'de tam ekran PDF** (Edge kullanıcı profilinde PDF yerine eklenti sayfaları açtığı için denenmedi; Chrome'da doğrulandı).
- [ ] **WPS 12'nin PDF sekmesi**: başlığında dosya adı görünüyor mu (`PdfViewers.windowsProgram`)? WPS 12.2 test PDF'ini açarken çöktü.
- [ ] **Tarayıcıda PowerPoint ve Google Slaytlar**: [PPT_WEB_PLAN.md](PPT_WEB_PLAN.md), 6. bölüm.

---

## 7. GitHub, CI ve paketler

- [ ] **Pardus**: bir sanal makinede .deb kurulumu (ilk release'ten önce bir kez; CI'da Debian 12 ve Ubuntu 22.04 kapsayıcılarında kuruluyor).
- [ ] **AUR**: hesap aç, `quickremote-pc-bin` deposunu oluştur, release'in `aur-pkgbuild` çıktısını ilk kez it.
- [ ] Release'teki telefon ve saat APK'ları Play kararına bağlı (PLAY, 1. bölüm).
- [ ] **CI raporunun (2026-10-22) gerçek GitHub koşusu isteyenleri** (bu makinede `gh` yok, son koşuların durumu buradan görülemedi):
  - Sabitlenen SHA'ların Actions'ta çözülmesi (`setup-java` 4.9.1, `setup-python` 5.6.0 girdileri).
  - Gradle sarmalayıcı sağlaması (`distributionSha256Sum`): ilk `./gradlew` kabul ediyor mu. Değer indirilen zip'ten hesaplandı; resmî `gradle-9.3.1-all.zip.sha256` ile bir kez elle karşılaştır.
  - `choco install innosetup --version=6.7.3` Chocolatey'de var mı (yalnız runner'da Inno yoksa önemli; yoksa son 6.x'e çek).
  - AAB: `flutter build appbundle` ve `:app:bundleRelease` imzayla çıkıyor mu, `keytool` imzacıyı gösteriyor mu, Play Console kabul ediyor mu (etiketli `v1.0.0` koşusu gerekir; `-test` sürümleri AAB üretmez).
- [ ] `quick_remote_wear/gradle/wrapper/gradle-wrapper.jar`'ı resmî jar'la karşılaştırmak; `SHA256SUMS.txt` imzası; `actions/attest-build-provenance`.
- [ ] Windows kod imzalama: ilk sürüm imzasız (SmartScreen uyarısı README'de). İmzalı yol sonra Microsoft Store'da MSIX; Azure Trusted Signing'in Türkiye'de bireylere açık olup olmadığı bakılmadı.

---

## 8. Web sitesi

- [ ] **Play rozeti**: uygulama Play'e çıkınca (gizlilik politikası sayfaları hazır).
- [ ] **Gizlilik politikası**: `store/privacy-policy.*.md`'de yayıncının adı ve e-postası boş.
- [ ] **Alan adı belli olunca**: `site/tools/site.url`'e yaz (canonical, hreflang, `og:url`, mutlak `og:image`, sitemap o zaman yazılır); gerçek indirme bağlantıları.
- [ ] `node site/tools/verify.mjs`'i 2026-10-26'daki iki satırlık değişiklikten sonra çalıştır (bu makinede Playwright kurulu değil).

---

## 9. Bilerek sonraya bırakılanlar

- **Telefon ana ekran widget'ı**: RemoteViews ya da Glance gerekir.
- **Uzak çökme raporu (Sentry)**: yapılmadı (karar). Kullanıcı sayısı artıp günlükler yetmezse, varsayılan kapalı ve açık onayla düşünülür; Play'in Veri güvenliği formu da değişir.
- **KDE'de yerel Wayland pencerelerinin ekran resmi**: KWin `org.kde.KWin.ScreenShot2` (`.desktop`'a `X-KDE-DBUS-Restricted-Interfaces`). GNOME'da portal kullanılmayacak (her oturum izin sorar).
- **Linux'ta büyüteç**: yapılmayacak (Wayland ekranın resmini yalnızca portalla verir; dışa aktarılan slaytı büyütmek ekrandakinden farklı bir şey gösterir).
- **Saatte ayrı tema seçici**: gerek görülmedi; telefondan eşitleme yeterli.
- **Linux paketleri**: AppImage ve .rpm sonra; Flatpak yok (uinput, pkexec, UNO borusu ve ana sistemin Python'u kum havuzunda çalışmaz).
- **Windows**: Microsoft Store/MSIX ve winget sonra.
- **Telefonda uygulama içi güncelleme** (`in_app_update`): acil değil.
- **WPS'i katmana geçirmek**: gerekirse, tek tek durumlarla.
- `quick_remote_pc/tool_tmp/` (kaplama deneme düzeneği) hiç commit edilmeyecek.
