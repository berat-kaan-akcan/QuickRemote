# QuickRemote: yapılmayanlar

Son güncelleme: 2026-10-28. Bütün açık işler bu dosyada: denenmemiş özellikler, yazılmamış kod, bekleyen kararlar ve bilerek sonraya bırakılanlar. Bitenler [YAPILANLAR.md](YAPILANLAR.md)'de.

Bir madde bitince buradan silinir ve YAPILANLAR.md'deki ilgili bölüme sonucuyla (tarih, sürüm, ne görüldü) yazılır.

Bu dosyanın dışında kalan iki liste:

- [PPT_WEB_PLAN.md](PPT_WEB_PLAN.md): tarayıcıda PowerPoint ve Google Slaytlar. Kodu yazıldı; deneme listesi (6. bölüm) orada.
- [../../PLAY_STORE_YAPILACAKLAR.md](../../PLAY_STORE_YAPILACAKLAR.md): Play Store'a çıkış.

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
- [ ] **Saat, gösteri dışında siyah/beyaz ekranı soluk gösteriyor**: kaplama orada çalıştığı hâlde. Saate ayrı bir bayrak gerekiyor (`laserAnywhere` gibi). 2026-10-28'de WPS PDF önündeyken saatte yine görüldü.
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

- [ ] Devral'dan sonra gösteri yokken telefon "LibreOffice Impress'i başlatın" diyor, öndeki WPS düzenleyicisi olduğu hâlde (program adı ilk programdan geliyor).
- [ ] PC'deki "Devral" düğmesine gerçek tıklama (telefondaki denendi; Wayland'de yapay tıklama yok).

### Destek tablosu

- [ ] Telefondaki "Neler yapılabilir?" tablosunda "Denenmedi" etiketli hücreler (`capability_table.dart`, `_untried`) ve eski `destek-tablosu.md`'deki **†** hücreler: kod okunarak yazıldı, özellikle Impress satırları tek tek doğrulanmadı. Fırsat oldukça birer birer denenip tablo güncellenmeli.

---

## 4. Telefonda denenecekler (Galaxy S23 FE)

Önce telefon uygulamasını **release** olarak derleyip kur; debug yavaşlatıyor.

**Kurulum engeli (2026-10-21):** telefondaki uygulama başka bir anahtarla imzalıydı; bu makinede derlenen release APK üstüne kurulamadı (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Ya imzalayan makineden kurulur ya da uygulama kaldırılıp kurulur (kayıtlı PC'ler ve ayarlar gider). versionCode o zamankinden büyük olmalı (`--build-number`).

- [ ] **Son PC'ye bağlanma**: PC'nin IP'si değişince mDNS'te adıyla bulunuyor mu? (Kayıtlı PIN'le bağlanma ve yanlış PIN'de PIN sorma çalışıyor; IP değiştirmek yönetici parolası istedi.)
- [ ] **Sunucu görünümünde dokunulan yere giden lazer** (`LASER_ABS`): PowerPoint'te denendi (2026-10-28, YAPILANLAR); WPS'te imleç, kaplama ve Impress, 16:9 olmayan ekranda kayma kaldı.

---

## 5. Saatte denenecekler (Galaxy Watch 6)

APK'yı yalnızca `adb -s <saatin seri numarası>` ile kur (bir kez telefona kurulup telefon uygulamasının yerine geçmişti).

- [ ] Saat bölümü PowerPoint ile Windows'ta. WPS PDF ile denendi (2026-10-28: Tam ekran, İleri/Geri, lazer, Bitir).
- [ ] Bağlantı sertleştirmesi (2026-10-24, `49d92a6`: `DirectLink` `SecurityException` yakalıyor, kapanan oturum soket almıyor, yazıcı iş parçacığı oturum başına, `PresentingService` reddedilen `startForeground`'u atlatıyor): saatte bir oturum boyunca, izin oturum ortasında geri alınarak.

---

## 6. Windows'ta denenecekler (bu makine)

### Yeni arayüzün tam denemesi, telefonla

Eski deneme listesi `~/Masaüstü/QuickRemote-tasarim-ornekleri/WINDOWS-DENEME.md` (Linux makinesinde, 16 bölüm). Telefonsuz denemede (2026-10-22, deneme istemcisiyle) yapılanlar YAPILANLAR.md'de. Telefonla kalanlar:

- [ ] Ortak ağ uyarısı (ağ profilini değiştirmek gerekir). Görünüm ve Dil denendi (2026-10-28).
- [ ] Güvenlik kodu penceresi (telefonda kayıtlı parmak izi olmayan bir bağlantı gerekir; uygulama verisini silmeden çıkmıyor).
- [ ] Touchpad: kalem renkleri ve silgi, telefonun kendi düğmeleriyle (katmanda komutlarla denendi, 2026-10-28).
- [ ] QR ile bağlanma (kamera PC ekranına tutulmalı). Telefonu çıkarma denendi (2026-10-28).

### Diğerleri

- [ ] **Slayt resmi**: WPS 12.2'de `Slides(n).Export` (12.1'de çalışıyor). Bu makinede şu an WPS 12.1.0.29162 kurulu; 12.2 klasörü boş.
- [ ] **Kaplama**: DPI %150 ve iki monitör (%125'te doğru).
- [ ] **WPS PDF öndeyken Başlat bir kez arkadaki PowerPoint gösterisini açtı** (2026-10-27): WPS 12.1'in PDF sekmesi öndeydi (`fg` doğru okundu), arkada PowerPoint'te Korumalı Görünüm'de bir sunu vardı. F11 yerine `_startPresenter` çalıştı, ~15 sn sonra PowerPoint gösterisi açıldı. Hemen ardından aynı durumda tekrarlanınca F11 doğru basıldı; neden bulunamadı. Kullanıcı o sırada bilgisayarı kullanıyordu, odak bir an başka pencereye geçmiş olabilir. `_startViewer` artık öndeki pencerenin adını günlüğe yazıyor (2026-11-04): tekrar görülürse günlüğe bak. 2026-10-28'de aynı durumda üç kez denendi (Shift+F5 sürümüyle), PowerPoint açılmadı.
- [ ] **WPS PDF'te QuickRemote'tan ikinci Başlat Oynat yerine araç çubuklu tam ekranı açtı** (2026-10-28): Başlat → Bitir → Başlat sırasında ikinci ve üçüncü Başlat'ta üstte WPS araç çubuğu olan tam ekran görüldü. Tuşlarla doğrudan (Shift+F5, Esc, tekrar Shift+F5; araya Alt da kondu) her seferinde doğru Oynat geldi. Bitir'in Esc'inden sonra kalan bir durum olabilir; Bitir'den sonra öndeki pencerenin hâline bakılmalı. 2026-11-04: Bitir odağı görünüme verip Başlat vermiyordu, Başlat da artık veriyor (`_focusViewerContent`); bu farkın neden olduğu bir varsayım, Windows'ta denenmedi.
- [ ] **Katmanda Hepsini sil bir kez çizgileri silmedi** (2026-10-28): kırmızı/mavi/yeşil kalem, sarı fosforlu, silgi, geri al, hemen ardından ERASE_ALL; sunucu `ack` verdi ve günlükte çalıştı, ama 1,5 sn sonra kırmızı ve mavi çizgi ekrandaydı. Aynı sırayla iki kez daha denendi, silindi.
- [ ] **Chrome ve Edge'de PDF tam ekranda bir sayfaya sığmıyor** (2026-10-27): F11 pencereyi büyütür ama yakınlaştırma pencere küçükkenki gibi kalır, araç çubuğu (Chrome'da sayfa resimleri paneli de) durur; ekranda bir sayfa ve bir sonrakinin yarısı görünür. Denenenler:
  - Edge'in PDF araç çubuğundaki "PDF'yi tam ekrana girin" düğmesi tam istenen şey (tek sayfa ekranı doldurur, oklar ve Page Down sayfa çevirir, Esc çıkar), ama kısayolu yok; UI Automation'da yalnızca tarayıcının kendi düğmeleri görünüyor, PDF görüntüleyicinin düğmeleri görünmüyor.
  - Chrome'un PDF menüsündeki "Sunum" araç çubuklarını gizler ama yakınlaştırmayı değiştirmez; kısayolu bulunamadı.
  - "Sayfaya sığdır" (Ctrl+\): Türkçe Q klavyede sanal tuş koduyla gitmiyor (Chrome tuşun karakterine bakıyor), Ctrl basılıyken Unicode `\` (SendInput `KEYEVENTF_UNICODE`) gidiyor. Ama aç/kapa: durumu bilmeden basmak ters çevirebilir.
  - Geçici Edge profili Windows hesabıyla kendiliğinden oturum açıp uzantıları eşitliyor (sekmeyi bir uzantı sayfası alıyor); denemeler `--inprivate` ile ya da Chrome'la yapılmalı.
  - Şimdilik telefonda uyarı var (2026-10-28, `viewerInFront`, tarayıcı öndeyken): "PDF ekrana tam sığmıyorsa bilgisayarda yakınlaştırmayı “Sayfaya sığdır” olarak ayarlayın." Telefonda henüz görülmedi. Kendiliğinden düzeltme zorlanmayacak (kullanıcının kararı).
- [ ] **Tarayıcıda PowerPoint ve Google Slaytlar**: Chrome'da denendi (2026-10-28, YAPILANLAR); Firefox ve Google'ın Sunucu görünümü Linux'ta denendi (2026-11-04, YAPILANLAR); Edge, Windows'ta Firefox ve Sunucu görünümü, Bluetooth modu kaldı: [PPT_WEB_PLAN.md](PPT_WEB_PLAN.md), 6. bölüm.

---

## 7. GitHub, CI ve paketler

- [ ] **Pardus**: bir sanal makinede .deb kurulumu (ilk release'ten önce bir kez; CI'da Debian 12 ve Ubuntu 22.04 kapsayıcılarında kuruluyor).
- [ ] **AUR**: hesap aç, `quickremote-pc-bin` deposunu oluştur, release'in `aur-pkgbuild` çıktısını ilk kez it.
- [ ] Release'teki telefon ve saat APK'ları Play kararına bağlı (PLAY, 1. bölüm).
- [ ] Windows kod imzalama: ilk sürüm imzasız (SmartScreen uyarısı README'de). İmzalı yol sonra Microsoft Store'da MSIX; Azure Trusted Signing'in Türkiye'de bireylere açık olup olmadığı bakılmadı.

---

## 8. Web sitesi

- [ ] **Play rozeti** ve gizlilik politikası sayfaları.
- [ ] **Alan adı belli olunca**: og:image ve hreflang için tam adresler, gerçek indirme bağlantıları.
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
