# Kalanlar: bütün denemeler ve açık noktalar

Son güncelleme: 2026-10-20. Bu liste [DURUM.md](DURUM.md)'nin "2. Ne kaldı" bölümünün aynısı; DURUM.md'de ayrıca neler yapıldığı da var. Bir madde bitince iki dosyada da işaretlenmeli.

**Commit durumu:** Son commit `911807b` (logo). Ondan sonra yapılan her şey commit edilmedi.

Kaynak kısaltmaları:

| Kısaltma | Dosya |
|---|---|
| OVERLAY | `docs/raporlar/OVERLAY_RAPOR.md` |
| ACIK | `docs/raporlar/ACIK_ISLER_RAPOR.md` |
| ALTYAPI | `docs/raporlar/ALTYAPI_RAPOR.md` |
| ONIZLEME | `docs/raporlar/SLIDE_PREVIEW_RAPOR.md` |
| WIN-BT | [WINDOWS-DENEME.md](WINDOWS-DENEME.md): Windows Bluetooth denemesi |
| WIN-UI | `~/Masaüstü/QuickRemote-tasarim-ornekleri/WINDOWS-DENEME.md`: yeni arayüzün PowerPoint ile Windows denemesi (16 bölüm) |
| SITE | `~/Masaüstü/QuickRemote-tasarim-ornekleri/SITE-NOTLARI.md`: sitede değişecek yerler |
| DESTEK | `~/Masaüstü/QuickRemote-tasarim-ornekleri/destek-tablosu.md`: hangi özellik hangi programda çalışıyor (**†** = doğrulanmamış) |
| PLAY | [PLAY_STORE_YAPILACAKLAR.md](PLAY_STORE_YAPILACAKLAR.md) |
| ESKI | Eski oturumların notları (denetim, WPS, saat, Bluetooth) |

Linux'taki ekran denemeleri tuşlara basar ve tam ekran açar. Başlamadan önce açık olan her şeyi kapat ya da küçült.

---

## 1. Linux (bu makine)

### Lazer ve mürekkep katmanı (OVERLAY, "Bekleyen denemeler" 1–7)
- [ ] Impress gösterisinde ve oynayan videonun üstünde lazer (`~/Masaüstü/LibreOffice Impress (gömülü video).odp`).
- [ ] Lazer ya da mürekkep açıkken tıklamanın katmandan geçip slaytı ilerletmesi.
- [ ] Chrome'da tam ekran PDF: gösteri olmadan lazer, kalem, silgi, spot ışığı ve siyah ekran.
- [ ] Kalem ve fosforlu kalem:
  - Çizgi akıcı mı?
  - Fosforlu kalem kendi üstünden geçince koyulaşmıyor mu?
  - Slayt değişince siliniyor mu?
  - "Mürekkebi koru" açıkken geri geliyor mu?
- [ ] Spot ışığının hızı ve görünüşü.
- [ ] İki monitör: katman, gösterinin olduğu monitörde mi açılıyor?
- [ ] Kesirli ölçek (%125) ve GNOME.

### Slayt önizlemesi (ONIZLEME, "Yapılacaklar" 2)
- [ ] Impress gösterisinde ve uygulamanın açtığı WPS gösterisinde:
  - Slayt kartındaki resim.
  - Sunucu görünümü.
  - "Slayta git" küçük resim ızgarası.

  Bugüne kadar yalnızca gösteri dışında denendi.

### Ekran görüntüsüyle slayt resmi (ACIK 1)
- [ ] Gerçek bir WPS gösterisinde (XWayland) resim geliyor mu?
- [ ] Impress: OpenGL/Skia ile çizen gösteride resim boş mu dönüyor? LibreOffice'in penceresi X11 mi, native Wayland mı? Native Wayland'de resim olmaz.
- [ ] Oynayan video resimde görünüyor mu? 2 saniyelik yoklama yalnızca resim değişince mi gönderiyor?
- [ ] Firefox/Chrome'da tam ekran PDF'te resim geliyor mu? Pencereli tarayıcıda hiçbir şey gitmiyor mu?
- [ ] Kaplamanın mürekkebi resimde doğru yere mi çiziliyor?

### PC: `caps`/`front` (ACIK 3) ve telefon başına mürekkep (ACIK 5)
- [ ] LibreOffice pencere sınıfları (`libreoffice-impress`, `libreoffice-draw`) doğru mu? Telefon araçları doğru mu gösteriyor, doğru mu soluklaştırıyor?
- [ ] PDF önde, gösteri yokken telefonda "PDF açık" metni ve "Tam ekran" tuşu çıkıyor mu?
- [ ] İki telefon: biri "mürekkep kalsın", diğeri "temizle". Slaytı değiştirenin ayarı mı geçerli oluyor?

### PC: tepsi, tek örnek, otomatik başlama, güncelleme (ALTYAPI 2, 4)
- [ ] Tepsi simgesi görünüyor mu? Menü çalışıyor mu? Simgenin rengi duruma göre değişiyor mu?
- [ ] Pencere kapanınca tepsiye iniyor mu? İlk seferki bilgi penceresi çıkıyor mu? Çıkış tam kapatıyor mu?
- [ ] İkinci açılış yeni kopya açmadan ilk pencereyi gösteriyor mu?
- [ ] "Oturum açılınca başlat": oturumu kapatıp açınca uygulama küçültülmüş başlıyor mu?
- [ ] Ortak (public) ağda sunucu kendiliğinden başlamıyor mu? Sarı satır çıkıyor mu?
- [ ] Güncelleme denetimi: ilk GitHub release'inden sonra "Yeni sürüm" satırı çıkıyor mu?

### PC: hata günlüğü (ALTYAPI 6)
- [ ] Günlük dosyası gerçekten yazılıyor mu? PIN ve dosya yolları gizleniyor mu?
- [ ] "Günlüğü dışa aktar" kaydetme penceresini açıyor mu?
- [ ] "Sorun bildir" tarayıcıda dolu bir issue sayfası açıyor mu?

### PDF görüntüleyiciler (ESKI, CLAUDE.md)
- [ ] Okular (Ctrl+Shift+P) ve WPS PDF (F11) ile Başlat/Bitir. Diğer görüntüleyiciler Windows'ta doğrulandı, bu ikisi hiç denenmedi.
- [ ] Linux'ta tarayıcıların PDF'inde Sonraki/Önceki hâlâ PageDown/PageUp gönderiyor. Windows'ta bu yüzden sağ/sol oka geçilmişti; Linux'ta da sayfalar arasında takılıyor mu?

### Programa göre destek tablosu (DESTEK)
- [ ] **†** işaretli hücreler kodu okuyarak yazıldı, gerçek programda denenmedi. Özellikle Impress satırlarında tek tek doğrulama yok. Fırsat oldukça birer birer denenip tablo güncellenmeli.

---

## 2. Telefon (S23 FE)

Önce telefon uygulamasını **release** olarak derleyip kur. Debug sürümü yavaşlatıyor.

- [ ] **Kısayollar** (ALTYAPI 5): simgeye basılı tutunca "Bluetooth kumanda", "QR tara" ve "Bağlan: <PC>" çıkıyor ve çalışıyor mu?
  - Başlatıcı, dışa kapalı (`exported=false`) olan `ShortcutActivity`'yi açamazsa manifest'te bu değer `true` yapılır.
  - Kısayol, açık bir kumanda ekranını kapatmıyor mu?
- [ ] **Hızlı Ayarlar kutucuğu** (ALTYAPI 5): görünüşü, alt yazıda PC adı, bağlıyken "açık" görünmesi, Android 14+'ta dokununca panelin kapanıp uygulamanın açılması.
- [ ] **Son PC'ye bağlanma** (ALTYAPI 5): PC'nin IP'si değişince mDNS'te adıyla bulunuyor mu?
- [ ] **`caps`** (ACIK 3): çalışmayan araçlar soluk mu? PDF önde iken "Tam ekran" çıkıyor ve Slayta git gizleniyor mu?
- [ ] **Slayt önizlemesi** (ONIZLEME): kart, Sunucu görünümü (dikey ve yatay), "Slayta git" ızgarası. Bunlar yalnızca widget testlerinden geçti.
- [ ] **Ekran görüntüsü kartı** (ACIK 1): PDF'te "Bilgisayarın ekranı" resmi; Sunucu görünümünde büyük resim ve Önceki/Sonraki.
- [ ] **Hata günlüğü** (ALTYAPI 6): "Hata günlüğünü paylaş" Android paylaşım menüsünü açıyor mu? "Sorun bildir" tarayıcıyı açıyor mu?
- [ ] **Kaplama** (OVERLAY 8): gösterisiz dokunmatik lazer, lazer türü seçimi, Temizle'yi basılı tutunca geri alma.

## 3. Saat (Galaxy Watch 6)

APK'yı yalnızca `adb -s <saatin seri numarası>` ile kur. Bir kez telefona kurulup telefon uygulamasının yerine geçmişti.

- [ ] **Tema eşitleme** (ACIK 4):
  - Telefonda tema değişince saat de değişiyor mu?
  - Gün Batımı saatte Kobalt mı oluyor?
  - Anahtar kapalıyken saat kendi temasında mı kalıyor?
- [ ] **Gösterisiz lazer** (OVERLAY 9): kaplama açıkken lazer düğmesi açık mı, lazer çalışıyor mu?
- [ ] Saat bölümü PowerPoint ile Windows'ta da denenecek (WIN-UI 15).

---

## 4. Windows (senin makinen)

Windows için yazılan kodların çoğu **hiç derlenmedi ya da hiç çalıştırılmadı**. En verimlisi, aşağıdakileri tek bir oturumda sırayla yapmak.

### Önce derleme
- [ ] `flutter build windows` derleniyor mu? Yeni C++ dosyaları (`laser_overlay.cpp`, mutex'li `main.cpp`), `gdiplus.lib`, `magnification.lib`.

### Yeni arayüzün tam denemesi (WIN-UI, 16 bölüm)
- [ ] Sırasıyla:
  - PC penceresi (dar, geniş) ve sunucuyu başlatma.
  - Ortak ağ uyarısı, Görünüm ve Dil ayarları.
  - Güvenlik kodu penceresi.
  - PowerPoint kontrolleri: Başlat, Sonraki/Önceki, not, siyah/beyaz ekran, Slayta git, odak koruması.
  - Touchpad: lazer, kalem, renkler, silgi, Temizle.
  - Medya ve şu an çalan.
  - QR ile bağlanma ve telefonu çıkarma.
  - WPS, Bitir ("mürekkep saklansın mı?" sorusunun geçilmesi) ve saat.

  Adımlar ve beklenen görüntüler dosyada.
- [ ] Not: WIN-UI'nin 13. bölümü WPS'te lazer yerine "Ok" bekliyor, ama kod artık WPS'in kendi lazerini (Ctrl+A ardından Ctrl+R) kullanıyor. Denemede WPS'te gerçek lazer görülmeli; dosyadaki o adım eskidi.

### Eski denetimden kalan Windows değişiklikleri (ESKI)
- [ ] Odak koruması, COM ile Slayta git (START_AT), SMTC önbelleği, IP yoklaması, `nsd` 5.x, sertifika ortam değişkenleri. Hepsi Linux'ta yazıldı. WIN-UI denemesi bunların çoğunu kapsar.
- [ ] PowerPoint'in Korumalı Görünüm'de açtığı bir sunumda Başlat.
- [ ] WPS'in COM yolları (`PresenterCom`): Windows WPS'te bütün komutlar.

### Slayt önizlemesi (ONIZLEME 1, 3)
- [ ] PowerPoint gösterisinde kart, Sunucu görünümü ve "Slayta git" ızgarası.
- [ ] WPS 12.2'de `Slides(n).Export`. Çalışıyorsa `slide_exporter.dart`'taki yalnızca-PowerPoint koşulu kaldırılacak.

### Kaplama (OVERLAY 10–13)
- [ ] Tarayıcıdaki PDF'te ve gösteri dışında lazer. Ayarlar'da QuickRemote seçiliyken PowerPoint'te lazer.
- [ ] Mürekkep, spot ışığı, büyüteç:
  - Pencereler odak almıyor mu, yani tuşlar gösteriye gitmeye devam ediyor mu?
  - Tıklamalar katmandan geçiyor mu?
- [ ] DPI %125/150 ve iki monitör.

### 2026-10-20 işleri (ACIK, ALTYAPI)
- [ ] `caps`/`front`: PowerPoint ve WPS'te öndeki pencere ve araçlar doğru mu? NEXT/PREV'de mürekkep telefon başına mı siliniyor?
- [ ] Ekran görüntüsü: PowerPoint ve WPS gösterisinde, Edge/Chrome'da tam ekran PDF'te. `PrintWindow` siyah mı dönüyor?
- [ ] Tepsi (sol tık pencere, sağ tık menü), tek örnek (ikinci kopyanın ilkini öne getirmesi), `--minimized`, kayıt defterine (HKCU Run) yazma.
- [ ] Günlüğü dışa aktarma ve "Sorun bildir".

### Bluetooth denemesi (WIN-BT, ACIK 2)
- [ ] `quick_remote_pc/tool/windows_bt_hid_trial.ps1`, adım adım WINDOWS-DENEME.md'de.
  - Betik hiç çalıştırılmadı; ilk çalıştırmada küçük düzeltmeler gerekebilir.
  - Sonuca göre ya asıl BtHidRepair kodu ya da "Telefonu yeniden eşleştir" tuşu yazılacak.

---

## 5. GitHub, CI ve paketler (ALTYAPI 1, 3)

- [ ] İlk push'ta CI koşusu. Windows'ta Linux'a bağlı testler kırılabilir; atlanır ya da düzeltilir.
- [ ] Release akışını ilk etiketten önce bir kez elle çalıştır.
- [ ] Gerçek Flutter derlemeleri, Inno Setup kurulumu, gerçek `dpkg-deb` ile .deb paketi. Hiçbiri yerelde denenmedi.
- [ ] Pardus'ta bir sanal makinede .deb kurulumu (ilk release'ten önce bir kez).
- [ ] AUR: hesap aç, `quickremote-pc-bin` paketini ilk kez yükle.
- [ ] Play kararına bağlı: release akışındaki telefon ve saat APK'ları (PLAY, 1. bölüm).

## 6. Play Store

Ayrı dosyada: [PLAY_STORE_YAPILACAKLAR.md](PLAY_STORE_YAPILACAKLAR.md).

## 7. Web sitesi (SITE, ONIZLEME 4)

Site güncellemesi, proje bitince tek seferde yapılacak (karar 2026-10-16). Toplanan değişiklikler:
- [ ] **Logo 59A:** favicon, uygulama simgesi, og:image ve sayfalardaki sprite (SITE, aşama 1).
- [ ] **Uygulama ekranlarının kopyaları** yeni tasarıma göre: Wi-Fi kumanda, Bluetooth, ana sayfa ve Ayarlar, tema, PC penceresi, saat (SITE, aşama 2–7).
- [ ] **Slayt önizlemesi:** karttaki resim, istenirse Sunucu görünümü demosu, "Hangi slayttasın" kutusu, SSS (ONIZLEME 4).
- [ ] **2026-10-20 özellikleri:** kaplama (gösterisiz lazer, spot ışığı, büyüteç), PDF'te canlı ekran, telefon kısayolları ve Hızlı Ayarlar kutucuğu, PC tepsisi, hazır paketler ve indirme bölümü.
- [ ] **Play rozeti** ve gizlilik politikası sayfaları (PLAY).
- [ ] **Alan adı belli olunca:** og:image ve hreflang için tam adresler, gerçek indirme bağlantıları (ESKI).

## 8. Senin kararını bekleyenler

- [ ] **Lisans**: repoda LICENSE yok. Site "Açık kaynak", README "kişisel kullanım" diyor; AUR paketi yer tutucu lisans kullanıyor.
- [ ] **Paket adı (`applicationId`)**: Play'e ilk yüklemeden önce son hâli verilmeli (PLAY, 0. bölüm).
- [ ] **Uygulamanın adı**: şimdilik QuickRemote (boşta olan aday SlideMando'ydu). Play'deki benzer adlara bakılmalı.

## 9. Bilerek sonraya bırakılanlar

- **Telefon ana ekran widget'ı**: RemoteViews ya da Glance gerekir (ALTYAPI 5).
- **Uzak çökme raporu (Sentry)**: varsayılan kapalı, açık onayla; kullanıcı sayısı artarsa düşünülür (ALTYAPI 6).
- **KDE'de native Wayland pencerelerinin ekran görüntüsü**: KWin `ScreenShot2` arayüzü. GNOME'da portal kullanılmayacak (ACIK 1).
- **Saate `front` bilgisi**: saat, PDF'te "yalnızca gösteri sırasında" uyarısını doğru verebilsin diye (ACIK 3).
- **Telefonda PDF tam ekranından çıkış tuşu**: PC tam ekran olup olmadığını bildirmiyor.
- **Küçük uç durum**: PC kalemi listeleyip lazeri listelemezse dokunmatik alandaki tek dokunuş başarısız olur.
- **Saat, gösteri dışında siyah/beyaz ekranı soluk gösteriyor**: ayrı bir bayrak gerekiyor (OVERLAY).
- **Siyah ekran açıkken kaplamanın mürekkebi görünmüyor**: programın siyah ekranından dönünce yoklama süresi kadar gecikmeyle yeniden çiziliyor (OVERLAY).
- **PC'nin sürümünü `auth` cevabında göndermesi**: telefon eski PC'ye "PC uygulamasını güncelleyin" diyebilsin diye (ALTYAPI 4).
- **Commit**: değişiklikler konulara göre ayrı commit'lere bölünecek. Logo değişiklikleri ayrı tutulacak; `quick_remote_pc/tool_tmp/` (kaplama deneme düzeneği) hiç commit edilmeyecek.
