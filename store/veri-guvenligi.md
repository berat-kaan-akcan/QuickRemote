# Veri güvenliği formu ve derecelendirme cevapları

Play Console > Uygulama içeriği. Cevaplar kodla doğrulandı (gizlilik politikasındaki iddialarla aynı kaynak). İşaret: **[Sen]** Console'da son kontrolü yapacaksın. Google formları sık değiştirir; bir soru buradaki listede yoksa mantığı: "geliştiriciye ya da üçüncü bir tarafa cihazdan veri çıkıyor mu?"

## 1. Veri güvenliği (Data safety) / Data safety form

### Gerekçe (neden "neredeyse hiçbir şey toplanmıyor")
Play'e göre "toplama", verinin cihazdan geliştiriciye ya da bir üçüncü tarafa aktarılmasıdır. QuickRemote'un verileri (PIN, cihaz adı, komutlar) yalnızca kullanıcının **kendi** bilgisayarına gider; geliştirici sunucusu yoktur. Tek istisna: uygulamaya gömülü **Google ML Kit** (QR okuma) Google'a kullanım/performans ölçümü gönderebilir. Bunu dürüstçe beyan ediyoruz. (Kontrol edilen: `mobile_scanner` 7.4.2 gömülü modeli `com.google.mlkit:barcode-scanning:17.3.0` kullanır, `useUnbundled` kapalı.)

Eğer sonradan QR okuyucu ML Kit'siz bir çözümle değişirse (ör. saf Dart ya da başka bir kütüphane), tüm form "Veri toplanmıyor / paylaşılmıyor" olur.

### Form cevapları

| Soru | Cevap |
|---|---|
| Uygulama kullanıcı verisi topluyor ya da paylaşıyor mu? | **Evet** (yalnız ML Kit'in teşhis verisi yüzünden, aşağıya bak) |
| Toplanan tüm veri aktarımda şifreli mi? | **Evet** (yerel ağ bağlantısı TLS; ML Kit Google'a HTTPS ile gönderir) |
| Kullanıcı verisinin silinmesini isteme yolu sağlıyor musunuz? | **Hayır**: geliştirici hesabı ya da sunucu verisi yok. (Politika: telefondaki veriler uygulama silinince gider.) Console "bir yol sağlamıyorum" seçeneğini kabul eder. |
| Hesap oluşturma | Yok |
| Play Aile Politikası / çocuklara yönelik | Hayır |

### Veri türleri

| Kategori / tür | Toplanıyor mu | Paylaşılıyor mu | Zorunlu mu | Amaç |
|---|---|---|---|---|
| Uygulama bilgisi ve performansı > **Teşhis** (Diagnostics) | Evet (ML Kit) | Hayır (Google, hizmet sağlayıcı olarak) | Zorunlu (kapatılamaz) | Analitik / uygulama işlevi |
| Uygulama bilgisi ve performansı > Çökme günlükleri | **Hayır**. Uygulamanın kendi günlüğü cihazda kalır, yüklenmez. | | | |
| Cihaz veya diğer kimlikler | **Evet** (ML Kit örnek kimliği, Google ML Kit veri açıklamasına göre) | Hayır | Zorunlu | Analitik / uygulama işlevi |
| Konum, kişiler, mesajlar, fotoğraf/video, ses, dosyalar, takvim, sağlık, finans, web geçmişi | **Hayır** | | | |
| Kişisel bilgiler (ad, e-posta, adres) | **Hayır** | | | |
| Uygulama etkinliği (sayfa görüntülemeleri, arama geçmişi, yüklü uygulamalar) | **Hayır**. Sunum geçmişi yalnız cihazda. | | | |

**[Sen]** Google'ın "ML Kit data disclosure" sayfasını (https://developers.google.com/ml-kit/android-data-disclosure) gönderim günü aç ve yukarıdaki iki satırı oradaki tabloyla eşle. Sayfa "Barcode scanning" için hangi türleri listeliyorsa onları işaretle. Genelde: "App info and performance (crash logs, diagnostics)" ve "Device or other IDs".

### Sorulursa: PC'ye giden veri
PIN, cihaz adı ve komutlar kullanıcının kendi bilgisayarına, yerel ağda TLS ile ya da Bluetooth ile gider. Geliştiriciye ya da üçüncü tarafa ulaşmaz. Bu nedenle "toplama" sayılmaz; yine de inceleyici sorarsa cevap bu.

## 2. İçerik derecelendirmesi (IARC anketi)

Kategori: **Yardımcı programlar, üretkenlik, iletişim veya diğer** (Utility, Productivity, Communication, or Other).

| Soru | Cevap |
|---|---|
| Şiddet, kan, korku | Hayır |
| Cinsel içerik, çıplaklık | Hayır |
| Küfür, kaba dil | Hayır |
| Uyuşturucu, alkol, tütün | Hayır |
| Kumar (gerçek ya da simüle) | Hayır |
| Kullanıcılar arası iletişim / kullanıcı içeriği paylaşımı | Hayır |
| Kullanıcı konumunu paylaşır mı | Hayır |
| Dijital satın alma / uygulama içi ürün | Hayır |
| Kontrolsüz internet erişimi (tarayıcı, sosyal ağ) | Hayır (yalnız kullanıcının kendi PC'si; "Sorun bildir" harici tarayıcıyı açar) |
| Kullanıcıya yönelik gerçek zamanlı sohbet | Hayır |

Beklenen sonuç: IARC 3+, PEGI 3, ESRB Everyone, USK 0. **[Sen]** anketi doldurup e-postanı gir.

## 3. Hedef kitle ve içerik (Target audience)

- Hedef yaş grupları: **16–17 ve 18+** seç (13–15 de eklenebilir). **5 yaş altı, 6–8 ve 9–12'yi seçme**: seçersen "Aileler için" programı ve ek şartlar gelir. Öğretmenler ve öğrenciler kullanacak olsa da uygulama çocuklara yönelik değil.
- "Uygulama çocukları çekebilir mi" sorusu: **Hayır** (görünüm sade, çizgi film dili, mascot ya da oyun yok).
- Reklam: **Yok**. Haber uygulaması: **Hayır**. COVID-19 temaslı takibi: **Hayır**. Devlet uygulaması: **Hayır**. Finansal özellikler: **Hayır**. Sağlık: **Hayır**. Sosyal/oyun/kumar: **Hayır**.
- Reklam kimliği: **Hayır** (manifestte `AD_ID` kaldırıldı).
- Uygulama erişimi: giriş gerekmiyor; ama işlevi için PC uygulaması gerek. Metin `store/magaza-metinleri.md` içinde ("Uygulama erişimi" bölümü).

## 4. English summary

- Data safety: answer **Yes, collects data** only because bundled Google ML Kit (QR scanner) sends diagnostics and an instance ID to Google as a service provider. Mark: Diagnostics + Device/other IDs; collected, **not shared**, required, purposes analytics/app functionality, encrypted in transit; no deletion mechanism (no developer-held data). Everything else: not collected. Compare with Google's ML Kit data-disclosure page on the day of submission.
- Content rating: Utility category, all "No"; result 3+/Everyone.
- Target audience: 16+ (do not select under-13 groups); not a Families app; no ads; Advertising ID: No.
