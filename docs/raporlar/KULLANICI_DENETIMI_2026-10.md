# Son kullanıcı hazırlık denetimi (Play Store öncesi) - 2026-10

Kapsam: telefon uygulaması (`quick_remote_app/lib`) ve PC uygulaması (`quick_remote_pc/lib` ekranlar, diyaloglar).
Yöntem: kod okuma, her bulgu için widget testi (taşma, 48 dp hedef, etiket/kontrast kuralları, metin ölçeği 2.0, küçük/yatay/tablet boyutlar), düzeltme, testleri yeşil tutma.
Sonuç: telefon 172 -> 309 test, PC 310 -> 379 test, iki projede `dart analyze` temiz.
Dokunulmayanlar (başka ajanlar): `packages/quick_remote_shared`, sunucu/auth kodu, Android manifest, `site/`.

## Düzeltilenler

### Erişilebilirlik (TalkBack, dokunma hedefi, kontrast)

1. Dokunma hedefleri 48 dp altındaydı: üst çubuk geri/eylem tuşu 44, ana ekran ayar tuşu 44, QR ekranı kapat 44, ses kısma/açma 44, siyah/beyaz ekran tuşu 40, "Slayta git" 40, not önizlemesi 42, `AppButton` yükseklik 34-46, `AppSegmented` 44 (Wi-Fi/Bluetooth, Windows/Linux seçicileri 36), zamanlayıcı küçük tuşları 28.
   Düzeltme: `Pressable.minTarget` (varsayılan 48; çizilen boyut aynı kalır, dokunma alanı büyür) - `quick_remote_app/lib/widgets/ui/pressable.dart:24,53,110`; `AppButton`/`AppIconButton` 48 (`app_button.dart`), `AppSegmented` varsayılan yükseklik 56 (`app_segmented.dart:24`); araç balonundaki sabit 40 kaldırıldı (`tool_popover.dart:250`). PC'de aynı üç dosya kopyalandı (CLAUDE.md "kopyalar aynı"), PC başlık tuşları fare için `minTarget: 0` (`home_screen.dart`, `_HeaderKey`).
2. TalkBack her etiketi iki kez okuyordu ("Açık, Açık"): `Pressable` semanticLabel verildiğinde çocuğun metnini de anlamsal ağaca katıyordu (`Light\nLight`). Düzeltme: etiket varsa çocuk `ExcludeSemantics` içinde (`pressable.dart:103`), dokunma eylemi düğümde kalıyor. İçinde kendi düğmesi olan çocuk için `keepChildSemantics` (yalnızca zamanlayıcı çipi).
3. Zamanlayıcı: iki düğmenin ikisi de "00:00" diye okunuyordu, sıfırlama "Refresh". Yeni metinler `timerStartLabel/timerPauseLabel/timerResetLabel` (EN+TR), oynat/duraklat ikonu çipin tekrarı olduğundan anlamsal ağaçtan çıkarıldı (`presentation_timer.dart`).
4. Metin kontrastı (4.5:1): `textMuted` yalnızca 3.97-4.43 idi - Cobalt açık (arka plan), Cobalt koyu (yükseltilmiş yüzey), Sunset (tüm yüzeyler). Renkler `inkTextMuted 686E91`, `paperTextMuted 8087A9`, `sunsetTextMuted 846B5C` yapıldı (`app_colors.dart`; PC'de ortak iki renk aynı). Yeni test `test/palette_contrast_test.dart` tüm paletlerde (11 palet) dört metin rengini üç yüzeyde denetler.
5. Çizim aracı etiketleri ("Lazer" vb.) açık temada renkli yüzey üstünde 3.79:1 idi: etiket artık `textPrimary/textSecondary`, renk ikonda (`draw_tool_bar.dart`).

### Büyük yazı (2.0), küçük ekran, yatay, tablet taşmaları

6. Ana ekran kontroller sekmesi: "SLAYT" satırı + zamanlayıcı çipi, siyah/beyaz + "Slayta git" satırı, medya sekmesinde "Sesi kapat" 2.0'da taşıyordu (`main_controls_view.dart`, `volume_panel.dart`: Flexible + üç nokta, `Expanded/Align`). Zamanlayıcı çipi 2.0'da 276 dp'ydi: rakamlar en çok 1.3 ölçeğine kadar büyür, büyük yazıda gereksiz ikon/oynat tuşu gizlenir (`presentation_timer.dart:138,144`). Bu bilinçli bir sınırlama: çip komşularını ekrandan itiyordu.
7. "PC bulunamadı" boş durumu kısa kutuda ve büyük yazıda taşıyordu (140-422 px): kaydırılabilir, ortalı (`device_lists.dart:293`).
8. PC ana ekran: durdurulmuş panel 2.0'da alttan 41 px taşıyordu (`server_controls.dart`, kaydırılabilir); PIN kutuları 2.0'da 57-67 px taşıyordu (`pairing_card.dart:137,394,546`, FittedBox yalnızca çizilmiş rakamlar için, anlamsal etiket ayrı); "Kodu gizle" satırı; Ayarlar düğmeli durum kartı (`server_status_card.dart:200`); Linux kurulum satırı eylem düğmesi iki satıra sarıyor (`setup_status_row.dart:57`); başlıktaki durum hapı 1.3 ölçekle sınırlı (`home_screen.dart:363`) ve `StatusPill` metni Flexible (`feedback.dart`, iki projede).
9. PC Ayarlar diyaloğu 380 px / 2.0'da taşıyordu: başlık satırı ve dil açılır kutusu (`settings_dialog.dart`, Flexible + `isExpanded`).

### İlk çalıştırma, izin reddi, hata metinleri

10. QR tarama: kamera izni reddedilince veya kamera açılamayınca siyah ekran kalıyordu. Yeni `ScanErrorView` (`scan_screen.dart:180`): neden, "Ayarları aç" (`openAppSettings`), "Geri dön" (elle girişe yönlendirir). Metinler `scanPermission*`, `scanUnavailable*`, `scanOpenSettings`, `scanGoBack`.
11. Cihaz bulunamayınca sadece "tekrar tara" vardı; PC uygulamasını nereden alacağını bilmeyen yeni kullanıcı için "QuickRemote PC'yi indir" düğmesi eklendi (GitHub son sürüm sayfası, `device_lists.dart:342`, `homeGetPcApp`).
12. Ham istisna sızıntısı: `ConnectionError.serverNotFound` ("Sunucuya ulaşılamadı: Connection refused", işletim sistemi metni ve İngilizce) ve `unknown` ("Bağlantı hatası: SocketException...") kullanıcıya ham metin gösteriyordu. Artık ayrıntı gösterilmiyor (günlükte duruyor), eylem öneren metinler: aynı Wi-Fi, PC uygulaması açık, hata günlüğünü paylaş (`app_*.arb`: `connectionServerNotFound`, `connectionUnknown`). `connectionCertMismatch` "MITM" jargonundan arındırıldı. PC: sunucu başlatma `SocketException` artık ham OS metni yerine "8090-8099 portları kullanımda" (`start_error_text.dart`, `startErrorPortsInUse`). Test: `failure_text_test.dart`.
13. Her `ConnectionError` ve `RemoteError` kodunun TR+EN metni var: switch'ler kapsamlı (derleyici zorunlu kılıyor) ve `failure_text_test.dart` tüm değerleri iki dilde dolu doğruluyor; ek değişiklik gerekmedi.

### Hakkında, sürüm, lisans, gizlilik

14. Telefonda sürüm, lisans sayfası ve gizlilik notu yoktu (yazı tipi OFL lisansları `main.dart`'ta kayıtlıydı ama hiçbir yerden açılamıyordu). Ayarlar -> Hakkında: Sürüm, Gizlilik (iletişim kutusu), Açık kaynak lisansları (`showLicensePage`; Flutter + paketler + Inter + Space Grotesk) - `settings_screen.dart:178-215`. Gizlilik metni `privacyBody` (hesap/analiz/reklam yok, kamera/yakındaki cihazlar/bildirim ne için, günlük telefonda kalır).
15. PC Ayarlar diyaloğunda da Hakkında bölümü: sürüm + lisans sayfası (`settings_dialog.dart:183`, `settingsAbout/settingsVersion/settingsLicenses`). Yazı tipi lisansları PC'de de `main.dart:112` ile kayıtlı, `assets/fonts/OFL*.txt` var.

## Kontrol edilip sorun bulunmayanlar

- TR/EN ARB eşliği: telefon 438/438 ve PC anahtar sayısı eşit; Türkçe harfli Dart string testi (`l10n_test.dart`) yeşil. Sayı alan metinlerde ("Slayt {n}", süre kısaltmaları, "{count} Bağlı") çoğul biçimi gerektiren cümle yok.
- Hareketi azalt: tüm tekrarlayan animasyonlar (`scan_screen`, `bluetooth_connect_screen`, `glowing_dots`, `spinning_refresh_icon`, `feedback`) `AppMotion.reduced` ile duruyor.
- Android geri tuşu: uzaktan kumanda (Wi-Fi ve Bluetooth) `PopScope` ile çıkış onayı soruyor; diğer ekranlar normal.
- Bluetooth izin reddi yolu zaten var (`btPermissionSettings` -> `openAppSettings`).
- Ana ekran 320x568, 280x653 (katlanabilir kapak), yatay, tablet, metin 2.0 (`home_robustness_test.dart`), uzaktan kumanda üç sekmesi x iki dil x beş boyut (`remote_views_sweep_test.dart`), tüm ayar ekranları (`settings_screens_sweep_test.dart`), PC ana ekran 5 durum x 5 boyut x 2 dil (`home_sweep_test.dart`) ve PC ayarlar (`settings_sweep_test.dart`) taşmasız.
- "Neler yapılabilir?" tablosu (`capability_table.dart`) `bt_key_mapping.dart` (Impress'te lazer/fosforlu/silgi yok, kalem Ctrl+P, WPS Ctrl+A,Ctrl+R) ve CLAUDE.md'deki PC davranışıyla (WPS Windows önizleme/medya sınırları, wpsOwn odak şartı, Impress overlay) tutarlı bulundu; değişiklik gerekmedi.

## Düzeltilmeyenler ve nedenleri

- Bildirim izni reddi: `BackgroundSession` reddi sessizce geçiyor. Android 13+ ön plan servisi bildirimsiz de çalışır, bağlantı korunur; ayrı bir uyarı eklemek manifest/servis davranışına dokunurdu. Gerçek cihazda "ekran kapalıyken kopma" denenmeli.
- Konum/Wi-Fi izni: uygulama konum izni istemiyor (mDNS için çoklu yayın izni yeterli); eksik bir yol yok.
- Zamanlayıcı rakamları ve PC üst çubuk hapı 1.3 ölçekte kırpılıyor (yukarıda madde 6, 8). Tam çözüm düzeni iki satıra bölmek olurdu; ekran alanı kıtlığı nedeniyle bilinçli ödün.
- Kontrast: kontrast kuralı gerçek ekranlarda gradyanlı kartlarda ("SLAYT", "Bitir") 1.0x yanlış pozitif verdi (flutter_test gradyan örnekleme sınırı); bu yüzden gerçek doğrulama palet düzeyinde (madde 4). Tüm ekranların kontrastı gerçek cihazda göz ile bir kez taranmalı.
- Saat uygulaması (`quick_remote_wear`) `Theme.kt` içinde eski `inkTextMuted/paperTextMuted` değerleri (`6B7194`, `7D84A6`) duruyor; kapsam dışı. Saatte koyu tema ve büyük punto, 4.5:1'e çok yakın olduğundan acil değil; ayrı bir iş olarak aynı iki değeri güncellemek yeterli.
- Windows kaplaması (`laser_overlay.cpp`, ekran görüntüsü, spotlight) hâlâ gerçek Windows'ta çalıştırılmadı (CLAUDE.md); tablo bu özellikleri "var" gösteriyor, Windows denemesinden sonra doğrulanmalı.
- PC tarafında dokunma hedefi 48 uygulanmadı (fare arayüzü); yalnızca ortak widget kopyaları aynı tutuldu.
- Gerçek cihaz/TalkBack ile elle denenmedi (bu ortamda cihaz yok); doğrulama widget testleri ve anlamsal ağaç kurallarıyla yapıldı.
