# Play Store'da yayın: yapılacaklar

Tarih: 2026-10-20. Telefon uygulaması ve saat uygulaması **tek bir Play kaydıyla** yayınlanır (aynı `applicationId`, saat ayrı bir AAB olarak). PC uygulaması Play'de değil; GitHub release'inden iner.

Play kuralları sık değişir. "**Kontrol et**" yazan maddelerde Play Console'un o günkü metnine bak.

**Güncelleme 2026-10-22:** hazırlanan metinler, formlar ve kontrol listesi `store/` klasöründe: [store/README.md](store/README.md), sıralı liste [store/KONTROL_LISTESI.md](store/KONTROL_LISTESI.md). Bu dosyadaki işaretler aşağıda güncellendi. Bu makinede Android SDK indirilemedi, bu yüzden AAB derlemesi henüz **denenmedi** (`store/derleme-ve-imza.md`).

Etiketler: **[Sen]** yalnızca senin yapabileceğin işler (hesap, ödeme, cihaz, karar). **[Claude]** benim kodda ya da dosyada yapabileceğim işler; "yap" demen yeter.

---

## 0. Önce karar ver: ilk yüklemeden sonra geri alınamayanlar

- [ ] **[Sen] Paket adı (`applicationId`)**: Şu an `com.quickremote.quick_remote_app`. İlk yüklemeden sonra **asla değişmez**.
  - `quickremote.com` alan adı senin değilse ters alan adı kuralına uymaz. Bu bir yasak değil, ama sonradan bir şirketin itiraz riski var.
  - Öneri: `io.github.beratkaanakcan.quickremote`, ya da sahip olduğun bir alan adı.
  - Değişirse telefon ve saat birlikte değişir; Data Layer ancak ikisi aynı adı taşıyınca çalışır. **[Claude]** değişikliği her iki projede yaparım.
- [ ] **[Sen] Ücretsiz mi, ücretli mi?** Ücretsiz yayınlanan bir uygulama **sonradan ücretli yapılamaz**. Ücretliyse ya da uygulama içi satın alma olacaksa ödeme profili, vergi bilgisi ve herkese açık adres gerekir.
- [ ] **[Sen] Uygulamanın adı**: Play'de "QuickRemote" ya da "Quick Remote" adlı başka uygulamalar var mı, bak (TV kumandaları çok). Ad en fazla 30 karakter olabilir. Ayırt edici bir ek düşün, ör. "QuickRemote: Sunum Kumandası".
- [ ] **[Sen] Sürüm numarası düzeni**: Şu an `0.1.0+1`. Release akışı versionCode'u `MAJOR·10000 + MINOR·100 + PATCH` diye hesaplıyor; saatinki bunun 1 000 000 fazlası. İlk yüklemeden önce birini seç, sonra hep artarak git (versionCode hiç düşemez). Öneri: Play'e `1.0.0` ile çık.

---

## 1. Kodda yapılacaklar (yayından önce)

### Reddedilme riski olanlar

- [x] **[Claude] Pil optimizasyonu izni (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)**: *kaldırıldı (2026-10-22): manifestte `tools:node="remove"`, `BackgroundSession` eklentiye `shouldRequestBatteryOptimizationsOff: false` veriyor. Kilitli telefonla uzun oturum cihazda denenmedi; kopuyorsa geri alma yolu `store/izinler.md` bölüm 4.* Aşağıdaki eski not:
  - Play bu izni yalnızca belirli kullanım türlerine veriyor ve incelemede soruyor. Bugün `flutter_background` bu izni **zorunlu** istiyor (`background_session.dart`): kullanıcı reddederse arka planda bağlantı hiç kurulmuyor.
  - Öneri: izni kaldırmak ve yalnızca `connectedDevice` ön plan hizmetine güvenmek. Bunun için ya kendi küçük hizmetimizi yazarız, ya da eklentinin bu izni istemeyen bir yolunu buluruz.
  - Olmazsa Console'da gerekçe yazılır. **Kontrol et:** izin verilen kullanım türleri listesi.
- [ ] **[Claude] GitHub release'indeki telefon ve saat APK'ları**: Play, uygulamayı **kendi anahtarıyla** yeniden imzalar (Play App Signing). Senin anahtarınla imzalı GitHub APK'sı bu yüzden:
  - Play'den kurulan sürümün üstüne kurulamaz.
  - Play'den kurulan saatle de konuşamaz (Data Layer aynı imzayı ister).
  - Öneri: release akışından APK'ları çıkarmak, Play tek kaynak olsun.
  - Alternatif: Play Console'da "kendi uygulama imzalama anahtarını yükle" seçeneği. Daha karmaşık; önermiyorum.
- [ ] **[Claude] AAB derlemesi** (akış ve komutlar `store/derleme-ve-imza.md`'de yazıldı; `release.yml` değişikliği önerildi, yapılmadı): Play APK değil **AAB** ister. Release akışında telefon için `flutter build appbundle`, saat için `:app:bundleRelease` adımları eklenir. İstersen Play'e otomatik yükleme de olur (servis hesabı gerekir; sonra).
- [ ] **[Claude] 16 KB bellek sayfası uyumu** (`libflutter.so` doğrulandı, ML Kit/CameraX ilk derlemede bakılacak, bkz. `store/derleme-ve-imza.md`): Android 15+ hedefleyen yeni uygulamalarda zorunlu. Flutter 3.47 uyumlu. Eklentilerin native kütüphaneleri de (özellikle `mobile_scanner`'ın ML Kit'i) uyumlu olmalı. AAB derlenince kontrol edilir; Play Console da raporlar.

### Olması iyi olanlar

- [ ] **[Claude] Açık kaynak lisansları ekranı**: Ayarlar'a "Lisanslar" satırı (`showLicensePage`); fontların OFL lisansları zaten pakette.
- [ ] **[Claude] Gizlilik politikası bağlantısı**: Ayarlar'a bir bağlantı. Politikanın kendisi aşağıda, 3. bölümde.
- [x] **[Claude] Hedef API** (telefon 36, saat 36 doğrulandı): telefon Flutter'ı izliyor (36), saat 36. Bugün yeterli; Play her yıl bir üst sürümü zorunlu kılıyor (**kontrol et:** o günkü son tarih).

### Gerçek cihazda denenmeyi bekleyenler

Bu oturumda yazılan ama telefonda hiç çalışmamış özellikler:
- [ ] **[Sen + Claude]** Uygulama kısayolları, Hızlı Ayarlar kutucuğu, Android 14+ davranışı.
- [ ] **[Sen + Claude]** "Hata günlüğünü paylaş" ve "Sorun bildir".
- [ ] **[Sen + Claude]** Slayt önizleme ve ekran görüntüsü kartı.
- [ ] **[Sen + Claude]** `caps` ile soluk araçlar; PDF önde iken "Tam ekran".
- [ ] **[Sen + Claude]** Saat: tema eşitleme, gösterisiz lazer, ekran açılınca kumandanın dönmesi.
- [ ] **[Sen + Claude]** Kaplama denemelerinin tam listesi: `docs/raporlar/OVERLAY_RAPOR.md`, "Bekleyen denemeler".

---

## 2. Hesap ve imza

- [ ] **[Sen] Play Console geliştirici hesabı**: tek seferlik 25 $ ve kimlik doğrulaması.
  - Kişisel mi, kuruluş mu? Kuruluş için D-U-N-S numarası gerekir. Tek kişiysen kişisel hesap yeter.
  - Hesaptaki e-posta mağaza sayfasında herkese görünür; ayrı bir destek adresi açmayı düşün.
- [ ] **[Sen] Yükleme anahtarı (upload key)**: `keytool` ile bir `.jks` oluştur ve `quick_remote_app/android/key.properties` dosyasını yaz. Şu an bu dosya **yok**. Dosya `.gitignore`'da; repoya girmez.
  - Anahtarı ve şifresini **iki ayrı yere yedekle** (ör. parola yöneticisi + harici disk).
  - Kaybedersen Play'den yükleme anahtarı sıfırlaması istenebilir, ama günler sürer.
  - **[Claude]** komutu ve `key.properties` şablonunu hazırlarım; şifreyi sen yazarsın.
- [ ] **[Sen] Play App Signing**: yeni uygulamalarda zorunlu. İlk AAB'de Google'ın anahtarı seçili gelir; öyle bırak.

---

## 3. Gizlilik politikası ve veri güvenliği formu

- [ ] **[Claude] Gizlilik politikası sayfası** (metin hazır: `store/privacy-policy.tr.md`, `.en.md`; sayfa ayrı bir ajanda; adı ve e-postayı doldur): `landing-page/gizlilik.html` ve `landing-page/en/privacy.html`. Kamera, Bluetooth ve bildirim izinleri olduğu için **zorunlu**.
  - Herkese açık bir adreste olmalı: site yayında değilse GitHub Pages yeter.
  - İçerik:
    - Uygulama hiçbir veriyi geliştiriciye göndermez.
    - Bağlantı yalnızca kullanıcının kendi bilgisayarına, yerel ağda ve TLS ile şifreli kurulur. PC'ye cihazın adı gider.
    - Kamera yalnızca QR okur; görüntü kaydedilmez.
    - Hata günlüğü cihazda kalır; yalnızca kullanıcı paylaşırsa gider. PIN ve dosya yolları günlüğe yazılmaz.
    - "Sorun bildir" GitHub'ı tarayıcıda açar.
    - Google ML Kit'in kullanım ölçümleri (aşağıya bak).
- [ ] **[Sen] Veri güvenliği formu (Data safety)**:
  - Kullanıcının **kendi** PC'sine giden veri, geliştiriciye ya da üçüncü tarafa gitmediği için "toplanan veri" sayılmaz. Bu yüzden büyük ölçüde "Veri toplanmıyor" denebilir.
  - **Dikkat, ML Kit:** QR okuyan `mobile_scanner`, Google ML Kit kullanıyor. ML Kit, Google'a performans ve kullanım ölçümleri gönderebiliyor. Google'ın "ML Kit data disclosure" sayfasındaki değerleri forma yaz (genelde "Uygulama bilgisi ve performansı" ve "Cihaz kimlikleri", toplanır, paylaşılmaz). **Kontrol et:** o sayfanın güncel hâli.
  - "Aktarımda şifreli": Evet (TLS).
  - "Kullanıcı verisinin silinmesini isteyebilir": hesap yok; veriler uygulama silinince gider.
  - **[Hazır]** cevap listesi: `store/veri-guvenligi.md`.

---

## 4. Play Console beyanları

- [ ] **[Sen] Ön plan hizmeti beyanı (Foreground service)**: telefon (`connectedDevice`, PC bağlantısı ve Bluetooth klavye) ve saat (`PresentingService`) için ayrı ayrı.
  - Neden gerektiğini yaz ve **kısa bir video** bağlantısı ver (YouTube, liste dışı): telefon kilitliyken kumandanın çalıştığı gösterilir.
  - **[Hazır]** açıklama metni: `store/izinler.md` bölüm 3; videoyu sen çekersin.
- [ ] **[Sen] Uygulama erişimi (App access)**: İnceleyiciler uygulamayı PC olmadan deneyemez; bu en sık red nedenlerinden.
  - Buraya şunları yaz: "Ücretsiz PC uygulaması gerekir: <GitHub release bağlantısı>. Bluetooth modu PC uygulaması olmadan çalışır."
  - Bir demo videosu ekle. Bluetooth modu inceleyicinin kendi bilgisayarıyla denenebilir; bunu öne çıkar.
- [ ] **[Sen] İçerik derecelendirmesi (IARC anketi)**: Şiddet yok, kullanıcılar arası iletişim yok, konum yok. Sonuç "Herkes / 3+" olur.
- [ ] **[Sen] Hedef kitle**: "13 yaş ve üzeri" ya da "18+" seç. Çocukları (13 yaş altı) **seçme**: Aileler politikası ve ek şartlar gelir. Öğretmenler kullanacak olsa da uygulama çocuklara yönelik değil.
- [ ] **[Sen] Reklam**: Yok. **Haber uygulaması**: Hayır. **Sağlık, finans, devlet**: Hayır.
- [ ] **[Sen] İzin açıklamaları**: Console, Bluetooth ve kamera için soru sorarsa:
  - Bluetooth: telefonun bilgisayara klavye ve fare olması.
  - Kamera: eşleştirme QR'ı.

---

## 5. Mağaza sayfası (Türkçe ve İngilizce)

- [x] **[Hazır] Metinler** (`store/magaza-metinleri.md`): kısa açıklama (en fazla 80 karakter) ve uzun açıklama (en fazla 4000 karakter), iki dilde. Landing page'deki metinlerden çıkarırım.
  - PowerPoint, LibreOffice, WPS adları yalnızca "ile çalışır" anlamında geçer; logoları kullanılmaz (Play'in meta veri ve marka kuralları).
- [x] **[Hazır] Uygulama simgesi** 512×512 PNG (`store/graphics/app-icon-512.png`): `brand/tools/export_assets.sh` ile üretilir.
- [x] **[Hazır] Öne çıkan görsel** (feature graphic) 1024×500: `store/graphics/feature-graphic-1024x500.png` (sade logo; istersen zenginleştirilir).
- [ ] **[Sen + Claude] Telefon ekran görüntüleri**: 2–8 adet, gerçek cihazdan. Öneri: bağlanma, ana kumanda, sunucu görünümü, dokunmatik lazer, Bluetooth modu, tema. **[Claude]** başlık yazılı çerçeveleri yaparım.
- [ ] **[Sen + Claude] Saat ekran görüntüleri**: en az 1 adet, kare (en az 384×384), cihaz çerçevesi yok, yalnızca uygulama arayüzü. `adb exec-out screencap` ile saatten alınır.
- [ ] **[Sen] Kategori**: "Verimlilik" (Productivity). Etiketleri seç.
- [ ] **[Sen] İletişim**: e-posta (zorunlu), web sitesi (landing page), gizlilik politikası adresi.
- [ ] **[Claude] Landing page**: Play rozetini ve bağlantısını ekle, gizlilik sayfalarını bağla. Site güncellemeleri proje bitene kadar ertelenmişti (2026-10-16); bu iş o zaman yapılır.

---

## 6. Saat (Wear OS) için ayrıca

- [ ] **[Sen] Form faktörü**: Console'da "Gelişmiş ayarlar → Form faktörleri"nden **Wear OS'i ekle** ve saat AAB'sini aynı sürüme koy. Wear OS'in **ayrı bir kalite incelemesi** var; telefon onaylanıp saat reddedilebilir.
- [ ] **[Sen + Claude] Wear kalite kontrol listesi** (**kontrol et:** "Wear OS app quality" sayfası):
  - Yuvarlak ekranda kırpılma olmamalı.
  - Dönen çerçeve ya da taç ile kaydırma çalışmalı.
  - Ortam (ambient) modu davranışı doğru olmalı.
  - Telefon uygulaması yokken anlamlı bir ekran olmalı: var ("telefonda QuickRemote'u aç").
  - Saat uygulaması bağımsız değil (`standalone=false`); Play bunu "telefon gerekir" diye gösterir. Doğru.
- [ ] **[Sen]** Saatin açıklaması ve ekran görüntüleri, mağaza sayfasının Wear bölümüne.

---

## 7. Test süreci ve yayın sırası

1. [ ] **[Sen] Dahili test (Internal testing)**: en fazla 100 kişi, dakikalar içinde yayında. AAB'yi buraya yükle; Play'in ön yükleme raporunu (pre-launch report) ve 16 KB uyarılarını kontrol et.
2. [ ] **[Sen] Kapalı test, zorunlu**: Kasım 2023'ten sonra açılan **kişisel** hesaplarda, üretime çıkmadan önce **en az 12 test kullanıcısının 14 gün kesintisiz** katılması gerekiyor (**kontrol et:** güncel sayılar).
   - Bu takvimdeki en uzun iş, erkenden başla.
   - Test kullanıcıları: arkadaşlar, öğretmenler, sınıf. Gmail adresleriyle eklenir; katılım bağlantısına tıklayıp uygulamayı kurmaları gerekir.
   - Bu sürede geri bildirim topla; Console sonunda "test sırasında ne öğrendin?" diye soruyor.
3. [ ] **[Sen] Üretim erişimi başvurusu**: 14 gün dolunca Console'daki anketle başvurulur. Yanıt genelde birkaç gün sürer.
4. [ ] **[Sen] Üretim (Production)**: önce kademeli yayın (ör. %20), çökme yoksa %100.
   - Android vitals'ta çökme ve ANR oranlarını izle.
   - Uygulama içindeki "Sorun bildir" GitHub'a gider.

---

## 8. Yayından sonra

- [ ] **[Sen]** Her güncellemede telefon ve saat AAB'si birlikte yüklenir; saatin versionCode'u telefonunkinden hep 1 000 000 fazla.
- [ ] **[Sen]** Play'in yıllık hedef API zorunluluğu (genelde Ağustos sonu): Flutter güncellemesiyle `targetSdk` yükselir; saatinki elle.
- [ ] **[Sen]** Kullanıcı yorumlarına cevap ver; Türkçe ve İngilizce.
- [ ] **[Claude]** PC uygulaması, telefonun gönderdiği sürümle eski bir PC'yi tanıyıp "PC uygulamasını güncelleyin" diyebilir. Altyapı raporunda bir fikir olarak duruyor; istersen yaparım.
- [ ] **Not, Android geliştirici doğrulaması**: Google, Play dışından kurulan APK'lar için de doğrulanmış geliştirici şartı getiriyor; ülke ülke yürürlüğe giriyor. Play'de yayınlıyorsan hesabın zaten doğrulanmış olur; GitHub'dan APK dağıtmayı bırakırsan seni etkilemez.

---

## Önerilen sıra

1. 0. bölümdeki kararlar: paket adı, ücret, ad.
2. **[Claude]** 1. bölümdeki kod işleri: pil izni, AAB, GitHub APK'larının kaldırılması, lisanslar ekranı, gizlilik politikası bağlantısı.
3. **[Sen]** Play Console hesabı ve yükleme anahtarı.
4. **[Sen + Claude]** Cihazda denemeler; hataların düzeltilmesi.
5. **[Claude]** Gizlilik politikası, mağaza metinleri, görseller. **[Sen]** ekran görüntüleri.
6. **[Sen]** Dahili test, ardından hemen 12 kişilik kapalı test (14 gün). Bu sürede beyanlar ve formlar doldurulur.
7. **[Sen]** Üretim başvurusu ve kademeli yayın.
