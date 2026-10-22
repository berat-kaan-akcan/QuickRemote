# Play'e çıkış kontrol listesi (2026-10-22)

Sıra: önce **yüklemeyi engelleyenler** (bunlar olmadan Console AAB'yi kabul etmez ya da uygulamayı yayınlatmaz), sonra **yayını engelleyenler** (inceleme/üretim), sonra engellemeyenler. **[Sen]** = yalnızca hesap sahibi yapabilir. **[Hazır]** = repoda yapıldı. **[Claude]** = istersen yaparım.

## A. AAB'yi yüklemeden önce (engelleyen)

1. [ ] **[Sen] Paket adı kararı.** `com.quickremote.quick_remote_app` ilk yüklemeden sonra değişmez. Kalacaksa bırak; değişecekse söyle, telefon (`build.gradle.kts`, namespace, Kotlin paketleri) ve saat birlikte değişir. Yeni ad `quickremote.com` sahibi değilsen ters alan adı kuralına uymaz (yasak değil). Öneri: `io.github.berat_kaan_akcan...` ya da kendi alan adın.
2. [ ] **[Sen] Play Console geliştirici hesabı** (25 $, kimlik doğrulaması, kişisel ya da kuruluş). Doğrulama günler sürebilir: **en erken başla.**
3. [ ] **[Sen] Yükleme anahtarı + `key.properties`** (`store/derleme-ve-imza.md` bölüm 4). Anahtar olmadan `bundleRelease` hata verir (bilerek).
4. [ ] **[Sen] Android SDK'lı makinede ilk derleme** (bu makinede SDK indirilemedi): telefon ve saat AAB'si, `zipalign -P 16`, birleşik manifest kontrolü (aşağıda D). Derleme hata verirse bana yaz.
5. [ ] **[Sen] Sürüm:** `1.0.0` ile çık; telefon versionCode 10000, saat 1 010 000 (`--build-number`/`-PphoneVersionCode` bayrakları şart).
6. [ ] **[Hazır] targetSdk 36**, R8 küçültme (Flutter varsayılanı), `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` kaldırıldı, `AD_ID` izni birleşik manifestten atılacak şekilde işaretlendi.

## B. Üretime çıkmadan önce Console beyanları (engelleyen)

7. [ ] **[Sen] Gizlilik politikası adresi.** Metin hazır: `store/privacy-policy.tr.md` ve `.en.md`. Başka bir ajanın hazırladığı site sayfası yayına çıkınca adresi Console'a gir; içinde **[GELİŞTİRİCİ ADI]** ve **[DESTEK E-POSTASI]** doldurulmalı. Adres herkese açık, giriş istemeyen bir sayfa olmalı (PDF olmaz). Aynı adresi mağaza sayfasına da yaz.
8. [ ] **[Sen] Veri güvenliği formu**: `store/veri-guvenligi.md` bölüm 1 (ML Kit yüzünden "Evet, teşhis + cihaz kimliği, paylaşılmıyor"). Gönderim günü Google'ın ML Kit sayfasıyla eşle.
9. [ ] **[Sen] Ön plan hizmeti beyanı** (telefon ve saat, tür `connectedDevice`): metinler `store/izinler.md` bölüm 3. **Video gerekli:** kilitli telefonla kumandanın çalıştığını, bildirimi ve çıkınca bildirimin kaybolmasını göster (YouTube, liste dışı). En çok zaman alan beyan; videoyu önceden çek.
10. [ ] **[Sen] Uygulama erişimi**: `store/magaza-metinleri.md` "App access" metni, PC uygulaması bağlantısı ve demo videosu. İnceleyici PC'siz deneyemez: bu en sık red nedeni. Bluetooth modunu öne çıkar.
11. [ ] **[Sen] İçerik derecelendirmesi** ve **hedef kitle** (`veri-guvenligi.md` bölüm 2–3): çocukları seçme.
12. [ ] **[Sen] Reklam kimliği: Hayır; reklam yok; haber/COVID/devlet/finans/sağlık: Hayır.**
13. [ ] **[Sen] Mağaza sayfası**: ad, kısa/tam açıklama TR ve EN (`magaza-metinleri.md`), 512 simge, öne çıkan görsel 1024×500 (`store/graphics/` hazır), **en az 2 telefon ekran görüntüsü** (gerçek cihazdan; plan `magaza-metinleri.md`'de), kategori Verimlilik, iletişim e-postası (zorunlu), site adresi.
14. [ ] **[Sen] Ücretsiz mi?** Ücretsiz yayınlanan uygulama sonradan ücretli yapılamaz. Ücretliyse ödeme profili gerekir.
15. [ ] **[Sen] Kapalı test: en az 12 test kullanıcısı, 14 gün kesintisiz.** Yalnız 13 Kasım 2023'ten sonra açılmış **kişisel** hesaplar için geçerli (kuruluş hesaplarında yok; **kontrol et:** Console'un o günkü sayıları). Üretim erişimi bu 14 günden sonra istenir. Takvimdeki en uzun iş: hesabı açar açmaz dahili test, hemen ardından kapalı test başlat. Test kullanıcıları Gmail adresiyle eklenir ve bağlantıdan kurar; sınıf, arkadaş, öğretmen.
16. [ ] **[Sen] Wear OS**: Console > Gelişmiş ayarlar > Form faktörleri > Wear OS ekle, saat AAB'sini aynı sürüme yükle; saat için ekran görüntüsü (1:1, ≥384, çerçevesiz) ve açıklama. Wear'in ayrı kalite incelemesi var: telefon onaylanıp saat reddedilebilir. Saati ilk sürümden **çıkarıp sonra eklemek** de mümkündür (telefon onayı beklemeden). Karar sende.

## C. Yayını engellemeyen, ama yapılmalı

17. [ ] **[Sen + Claude] Gerçek cihaz denemesi** (özellikle yayın APK'sı): R8 sonrası QR, Bluetooth HID, saat bağlantısı, kısayollar, Hızlı Ayarlar. Yeni: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` olmadan kilitli telefon, 30+ dakika; bağlantı kopuyorsa izni geri koyma yolu `izinler.md` bölüm 4'te.
18. [ ] **[Claude] Ayarlar'a gizlilik politikası bağlantısı** ve **Lisanslar** satırı (ARB/ekran işi, bu görevde yasaktı). Adres belli olunca yaparım.
19. [ ] **[Claude] `release.yml`**: APK yerine AAB (`derleme-ve-imza.md` bölüm 6). GitHub release'ten telefon/saat APK'sını kaldırmak ya da bırakmak sende.
20. [ ] **[Claude] Site**: Play rozeti ve gizlilik sayfası bağlantısı (site ajanı bitirince).
21. [ ] **[Sen]** Play Console "Uygulama bütünlüğü", "Veri silme" sayfaları: boş geçilebilir.
22. [ ] **[Sen]** Dahili test yükleme sonrası Pre-launch raporu: kilit ekranı, izin ve 16 KB uyarılarına bak.
23. [ ] **[Sen]** Kademeli yayın (%20 → %100), Android vitals (çökme, ANR) izlemesi.
24. [ ] **[Sen]** Marka: Play'de "QuickRemote" adlı başka uygulama var mı bak; başlık `QuickRemote: Sunum Kumandası` ayırt edici ek taşıyor.

## D. İlk AAB geldikten sonra bakılacaklar (Console > Uygulama paketi gezgini ya da birleşik manifest)

- İzinlerin `izinler.md` bölüm 1'dekiyle aynı olduğunu doğrula; listede olmayan bir izin çıkarsa hangi kitaplıktan geldiğine bak (`tools:node="remove"` ile atılabilir). Özellikle `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `AD_ID`, `ACCESS_FINE_LOCATION`, `READ_PHONE_STATE` **olmamalı**.
- Hizmet listesinde yalnız `IsolateHolderService` (`connectedDevice`), `QuickTileService`, `WearListenerService`, GMS/CameraX bileşenleri.
- `minSdk` 24, `targetSdk` 36, 16 KB uyarısı yok.
