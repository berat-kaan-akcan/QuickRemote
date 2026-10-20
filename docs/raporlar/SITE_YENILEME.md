# Site yenileme (site/)

## Durum
DEVAM EDİYOR (oturum 1, 2026-10-20): içerik, demolar, görseller ve doğrulama bitti; PR açılacak

Dal: `site-yenileme` (main'den açıldı). Sınırlar: yalnızca `site/`, bu dosya, `docs/raporlar/site-ekranlar/` ve CLAUDE.md'nin site paragrafı.

## Envanter (projede bugün ne var)
Kaynaklar: CLAUDE.md, brand/BRAND.md, iki uygulamanın ARB dosyaları, saatin `res/values*`. Site 2026-10-14'te kuruldu (`00b5631`); sonrası:

**Marka (10-18, 10-20):** yeni logo 59A (kobalt Sonraki tuşu + küçük Önceki tuşu + köşede lazer noktası; eski "Q" işareti kalktı). Üretilmiş SVG'ler `brand/logo/`, PNG'ler `brand/export/`.

**Telefon:** yeniden tasarlanan ekranlar (Wi-Fi kumanda, Bluetooth kumanda, ana ekran, ayarlar); kumanda başlığı PC adı + program adı; Slayt kartı (SLAYT etiketi, canlı nokta, sayaç, büyük numara, segmentli iz, not önizlemesi, Siyah/Beyaz ekran + "Slayta git" tuşları), tam genişlik Başlat/Bitir tuşu, geniş Sonraki + dar Önceki; medya sırası: ses, çalan, slayt medyası; 6 renk teması (Kobalt, OLED, Yüksek kontrast, Nane, Mor, Gün Batımı) + açık/koyu; dil seçimi (Sistem/TR/EN); slayt önizlemesi (resim kartta), sunucu görünümü (büyük slayt, sıradaki, notlar), slayta git ızgarası (küçük resimler); `caps` ile solan araçlar; Lazer türü seçici (lazer, spot ışığı, büyüteç); Temizle'ye basılı tut = son çizgiyi geri al; uygulama kısayolları (Bluetooth kumanda, QR tara, "Bağlan: son PC") ve Hızlı Ayarlar kutucuğu; Ayarlar → Yardım (hata günlüğünü paylaş, sorun bildir); Bluetooth: kapalıyken aç, görünür yap, "bilgisayar klavyeyi tanımıyor" kılavuzu; "çizimleri koru" ayarı; sayfa/PDF görüntüleyici önde iken "Tam ekran".

**PC:** yeniden tasarlanan tek pencere (durum kartı, eşleştirme kartı QR + IP + PIN + güvenlik kodu, bağlı telefonlar, Linux kurulum satırları); Görünüm (Sistem/Açık/Koyu); Lazer ayarı (Otomatik/QuickRemote/Program); lazer ve mürekkep **overlay**'i (lazer, spot ışığı, büyüteç [yalnız Windows], son çizgiyi geri al, ekran dışında siyah/beyaz ekran); tepsi (Göster, sunucuyu başlat/durdur, telefon sayısı, yeni sürüm, Çıkış), kapatınca tepsiye küçült, oturum açılınca başlat, açılınca sunucuyu başlat, güncelleme denetimi; Sorun giderme (günlüğü dışa aktar, sorun bildir); WPS'in lazer kalemi (Windows); PDF görüntüleyiciler; ekran görüntüsü (tam ekran gösteri/PDF'in resmi telefona).

**Saat:** yeniden tasarım (Başlat sayfası + konuşma süresi seçimi; Araçlar sayfası: Lazer, Beyaz, Siyah, Bitir [1 sn basılı tut]; Kumanda sayfası: büyük Sonraki, küçük Önceki ve lazer, slayt noktaları, süre sayacı; Sonraki'ne basılı tut = lazer); 6 renk teması (telefondaki "Saatte de kullan"); Ongoing Activity; titreşimli süre uyarıları; telefon Bluetooth klavyesi iken saat tuşları klavye olarak gider; saat doğrudan bilgisayara bağlanmaz (telefon üzerinden).

**Paketler:** Windows kurulum (Inno Setup, kullanıcı başına, imzasız), Linux tarball, .deb (Debian 12, Ubuntu 22.04 denendi), AUR PKGBUILD (elle yayınlanır), telefon+saat APK'sı (anahtar varsa).

**Dürüstlük notları (CLAUDE.md/DURUM.md):** Windows'ta hiç derlenmemiş/çalıştırılmamış: Windows overlay (lazer/mürekkep), büyüteç, Windows ekran görüntüsü, Windows slayt önizleme dışa aktarma (PowerPoint COM `Export`; WPS 12.2 doğrulanmadı), Windows installer. Linux: ekran görüntüsü yalnız X11/XWayland pencerelerinde, native Wayland penceresinde yok; GNOME'da portal yok. Slayt resmi kaydedilmiş slayttır (animasyon adımı, çizim, video görünmez). Büyüteç Linux'ta yok.

## Fark listesi
(Aşağıda sıralı; [x] = kapandı)

### Marka ve ortak
- [x] Logo: sprite'taki `#mark` eski Q; 59A ile değiştir (ayrı, parıltısız favicon ve uygulama ikonu varlıkları `brand/export/`'tan)
- [x] `assets/favicon.svg`, `favicon-32.png`, `apple-touch-icon.png`, `app-icon.png` yenile
- [x] Başlık/altlık logosu ve wordmark: BRAND.md (Quick Bold, Remote Medium)

### Telefon parçası (hero)
- [x] Başlık: PC adı + "PowerPoint" (landing-page `b73b012`)
- [x] Slayt kartı: yeni yapı; Başlat/Bitir tek tuş; siyah/beyaz kartın içinde + "Slayta git"; geniş Sonraki/dar Önceki
- [x] Slayt resmi kartta (önizleme) ve sunucu görünümü
- [x] Medya sırası: Sistem sesi → Şu an çalan → Slayt medyası (landing-page `b73b012`)

### Saat
- [x] Yeni saat tasarımı (Başlat/Araçlar/Kumanda sayfaları, süre sayacı, noktalar, basılı tut = lazer, 1 sn basılı tut = Bitir)
- [x] Saat "telefon üzerinden" metni (landing-page `fd71d83`; kontrol)
- [x] Saat temaları

### Yeni özellikler (sitede hiç yok)
- [x] Lazer/mürekkep overlay'i: lazer, spot ışığı, büyüteç, geri al; gösteri dışında da
- [x] Slayt önizleme, sunucu görünümü, slayta git ızgarası
- [x] Renk temaları (telefon + saat) ve PC Görünüm
- [x] Araçlar programa göre solar (caps)
- [x] Kısayollar ve Hızlı Ayarlar kutucuğu
- [x] Tepsi, oturum açılınca başlat, güncelleme denetimi, sorun bildir/günlük
- [x] Diller (TR/EN, sistem dili)
- [x] PC penceresi yeni tasarım (durum kartı, eşleştirme kartı, telefon listesi)
- [x] Kurulum/indirme: Windows yükleyici, .deb, tarball, AUR, APK
- [x] Güvenlik bölümü: yerel ağ sınırı, deneme sınırları; (kontrol: 5 hata/60 sn doğru, 6 hane PIN)
- [x] Programlar: WPS Linux/Windows, PDF ayrıntıları, Okular/WPS PDF doğrulanmadı
- [x] SSS: dil, tepsi, güncelleme, gizlilik/günlük, önizleme sınırı, saat Bluetooth
- [x] Bluetooth: kapalıyken aç, görünür yap, tuş tablosu hedef programa göre

### İki dil
- [x] TR/EN eşitliği (bölüm sayısı, id'ler, sayılar)

## Ekstralar (fikir listesi)
- [x] Bağlantı animasyonu: saat ⇄ telefon ⇄ PC (veri akışı)
- [x] Canlı overlay demosu: lazer / spot ışığı / büyüteç / mürekkep, gösteri dışında da
- [x] Tema değiştirici: 6 tema, telefon + saat birlikte değişir
- [x] Slayt önizleme + sunucu görünümü demosu
- [x] Kaydırmaya bağlı girişler (transform/opacity), reduced-motion'da sade
- [x] Kurulum sekmeleri (Windows / Linux / Android / Saat) + kopyalanabilir komutlar
- [x] SSS genişletme + arama olmadan hızlı bağlantılar

## Kararlar
- Sayfalar `site/tools/parts/` parçalarından `build_pages.py` ile üretilir (görev "build adımı yok" der: site kendisi yine düz HTML/CSS/JS ve bir derleme gerektirmez; betik yalnızca iki sayfanın aynı yapıda kalmasını sağlar). Her cümle `{{tr||en}}` çifti.
- Logo: `brand/logo/favicon.svg`'den koyu karo olarak satır içi sprite'a alındı; "Q'nun kuyruğu" hikâyesi "bağlantı çizgisi" oldu (çizgi ve duraklar aynı).
- Telefon kopyası dinamik temalı (`--p*` değişkenleri = AppPalette); hero telefonu varsayılan Kobalt koyu. Saat Gün Batımı'nı Kobalt gösterir (uygulamadaki gibi).
- Dürüstlük: Windows'ta hiç derlenmeyen/çalıştırılmayan şeyler (katman, büyüteç, ekran resmi, PowerPoint slayt resmi, yükleyici), tepsi/oturumda başlat/güncelleme denetimi, telefon kısayolları ve sunucu görünümü gizlenmedi; "Neyi denedik, neyi henüz denemedik" bölümü, katman bölümündeki "Yeni · deneme aşamasında" etiketi ve ilgili kartlardaki notlarla açıkça işaretlendi. "Gerçek cihazda denendi" sütunu yalnızca CLAUDE.md'de "verified" diye geçenlere dayanır.
- Gösterilen sürüm numarası ("Yeni sürüm: 0.2.0") yalnızca örnektir. İndirme bağlantıları `releases/latest`; henüz yayın yok, Play Store'da yok diye yazıldı.
- Uygulamadan not (düzeltilmedi): `DURUM.md` "Site güncellemesi proje bitince" der; bu görevle kalktı. `README` "kişisel kullanım", lisans kararı bekliyor, sitede "Kişisel kullanım amaçlıdır" korundu.
- Oturumun atanmış dalı `claude/…`, görevin dalı `site-yenileme`; görevdeki talimata uyuldu.
- Dal `site-yenileme` (görev metni); oturumun atanmış dalı `claude/…` ise kullanılmadı, çünkü görev yalnızca `site-yenileme`'ye push edilmesini ister.
- Windows'ta doğrulanmamış özellikler sitede "Windows'ta denenmedi" diye işaretlenir (gizlenmez); ana vaatler yalnızca doğrulanmış özelliklerdir.

## Doğrulama sonuçları
`node site/tools/verify.mjs` (tam matris: tr/en × 1440/390 × açık/koyu × hareket azaltma açık/kapalı): konsol hatası yok, kırık `#` bağlantısı/ikon yok, yatay kaydırma yok, TR/EN kimlik, bölüm ve eleman sayıları eşit, tüm demo adımları geçti (hero, saat, tema, katman, goto, medya, anahtar tablosu, PC penceresi, tepsi, görünüm, kopyalama). Ekran görüntüleri `docs/raporlar/site-ekranlar/`.
Düzeltilen sorunlar: telefon kuralının `.rig` dışına sızması (mini telefon), 390 px'te SSS'de nbsp kaynaklı 20 px taşma, sunucu görünümünde boşluk, ayarlar kartında kırpılma.
Uygulamadaki tuhaflık notu: yok.

## Sıradaki adım
CLAUDE.md paragrafı ve araç README'si yazıldı; ekran görüntüleri commit edilecek, sonra durum TAMAMLANDI yapılıp draft PR açılacak.
