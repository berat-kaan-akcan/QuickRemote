# Kalanlar: bütün denemeler ve açık noktalar

Son güncelleme: 2026-10-21. Bu liste [DURUM.md](DURUM.md)'nin "2. Ne kaldı" bölümünün aynısı; DURUM.md'de ayrıca neler yapıldığı da var. Bir madde bitince iki dosyada da işaretlenmeli.

**Commit durumu:** her şey commit edildi ve GitHub'a gönderildi (2026-10-21).

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
- [x] Impress gösterisinde ve oynayan videonun üstünde lazer (`~/Masaüstü/LibreOffice Impress (gömülü video).odp`). (2026-10-21: nokta oynayan videonun da üstünde. Yan bulgu: %125 ölçekte LibreOffice 26.8 videoyu kendisi kaydırıyor; doğru yerde siyah kutu, video sağ altta yarım. QuickRemote'tan bağımsız, slayt ilk açıldığında da öyle.)
- [x] Lazer ya da mürekkep açıkken tıklamanın katmandan geçip slaytı ilerletmesi. (2026-10-21: **geçmiyordu**: katmanın giriş alanı bütün ekrandı, ekranda çizgi kaldıkça hiçbir yere tıklanamıyordu (masaüstü donmuş gibi kaldı, PC yeniden başlatıldı). Düzeltildi `a95c067`, X'ten okunan giriş alanı artık boş ve gerçek fareyle denendi. Son telefon ayrılınca katman da temizleniyor.)
- [x] Chrome'da tam ekran PDF: gösteri olmadan lazer, kalem, silgi, spot ışığı ve siyah ekran. (2026-10-21: Firefox'u XWayland'de açarak denendi, hepsi çalışıyor. Chrome bu makinede yerel Wayland'de, aşağıdaki yeni maddeye bak.)
- [x] Kalem ve fosforlu kalem: (2026-10-21: dördü de evet.)
  - Çizgi akıcı mı?
  - Fosforlu kalem kendi üstünden geçince koyulaşmıyor mu?
  - Slayt değişince siliniyor mu?
  - "Mürekkebi koru" açıkken geri geliyor mu?
- [x] Spot ışığının hızı ve görünüşü. (2026-10-21: ekran kararıyor, parmağın altı aydınlık; hız telefonla elle bakıldı.)
- [ ] İki monitör: katman, gösterinin olduğu monitörde mi açılıyor?
- [ ] Kesirli ölçek (%125) ve GNOME. (2026-10-21: bu makine %125; katman doğru yerde çiziyor. GNOME denenmedi.)

### Slayt önizlemesi (ONIZLEME, "Yapılacaklar" 2)
- [x] Impress gösterisinde ve uygulamanın açtığı WPS gösterisinde: (2026-10-21: Impress'te üçü de çalışıyor, Sunucu görünümü dikey ve yatay, notlar geliyor. Uygulamanın açtığı (Devral ile alınan) WPS gösterisinde kart resmi, not ve "Slayta git" küçük resim ızgarası çalışıyor; ızgaradan 3. slayta atlandı.)
  - Slayt kartındaki resim.
  - Sunucu görünümü.
  - "Slayta git" küçük resim ızgarası.

  Bugüne kadar yalnızca gösteri dışında denendi.

### Ekran görüntüsüyle slayt resmi (ACIK 1)
- [x] Gerçek bir WPS gösterisinde (XWayland) resim geliyor mu? (2026-10-21: evet, kullanıcının açtığı WPS'te resim slaytla birlikte değişiyor.)
- [x] Impress: OpenGL/Skia ile çizen gösteride resim boş mu dönüyor? LibreOffice'in penceresi X11 mi, native Wayland mı? Native Wayland'de resim olmaz. (2026-10-21: LibreOffice burada yerel Wayland'de (KDE/Qt6 eklentisi), X penceresi yok; ekran resmi alınmıyor, telefon dışa aktarılan slaytı gösteriyor.)
- [ ] Oynayan video resimde görünüyor mu? 2 saniyelik yoklama yalnızca resim değişince mi gönderiyor? (2026-10-21: denenemedi. LibreOffice burada yerel Wayland'de, ekran resmi yok. WPS 11.1'de video hiç oynamıyor: köprünün `Player.Play()` çağrısı bir şey yapmıyor, `State` hep "oynuyor" diyor. Bu yüzden köprünün WPS gösterisinde telefonun slayt medyası düğmeleri artık soluk, oynatma durumu "bilinmiyor".)
- [ ] Küçük bulgu: Devral'dan sonra gösteri yokken telefon "Sunum Açık Değil, LibreOffice Impress'i başlatın" diyor, öndeki WPS düzenleyicisi olduğu hâlde (program adı ilk programdan geliyor).
- [x] Firefox/Chrome'da tam ekran PDF'te resim geliyor mu? Pencereli tarayıcıda hiçbir şey gitmiyor mu? (2026-10-21: XWayland Firefox'ta tam ekranda geliyor, pencereliyken gelmiyor. Yerel Wayland Chrome'da hiç gelmiyor.)
- [x] Kaplamanın mürekkebi resimde doğru yere mi çiziliyor? (2026-10-21: evet.)

### PC: `caps`/`front` (ACIK 3) ve telefon başına mürekkep (ACIK 5)
- [ ] LibreOffice pencere sınıfları (`libreoffice-impress`, `libreoffice-draw`) doğru mu? Telefon araçları doğru mu gösteriyor, doğru mu soluklaştırıyor? (2026-10-21: LibreOffice burada yerel Wayland'de, X sınıfı okunamıyor; Impress gösterisinde araçlar doğru, WPS gösterisinde Slayta git soluk.)
- [x] PDF önde, gösteri yokken telefonda "PDF açık" metni ve "Tam ekran" tuşu çıkıyor mu? (2026-10-21: XWayland Firefox'ta "Tarayıcı önde" ve "Tam ekran" çıkıyor, Slayta git gizli.)
- [ ] İki telefon: biri "mürekkep kalsın", diğeri "temizle". Slaytı değiştirenin ayarı mı geçerli oluyor? (2026-10-21: ikinci telefon yok. Sunucu testi iki gerçek bağlantıyla kapsıyor; tek telefonla "koru" açık/kapalı canlı denendi, doğru.)

### PC: tepsi, tek örnek, otomatik başlama, güncelleme (ALTYAPI 2, 4)
- [x] Tepsi simgesi görünüyor mu? Menü çalışıyor mu? Simgenin rengi duruma göre değişiyor mu? (2026-10-21, KDE, release derlemesi, D-Bus üzerinden: menü panele hiç bildirilmiyordu, düzeltildi `83004f7`; sol tık pencereyi açıyor, menüden Başlat/Durdur çalışıyor, nokta açıkken yeşil, kapalıyken gri.)
- [x] Pencere kapanınca tepsiye iniyor mu? İlk seferki bilgi penceresi çıkıyor mu? Çıkış tam kapatıyor mu? (2026-10-21: üçü de evet. Yan bulgu: tepsiden durdurulan sunucunun "ortak ağ" uyarısı ekranda kalıyordu, düzeltildi `46e53b9`.)
- [x] İkinci açılış yeni kopya açmadan ilk pencereyi gösteriyor mu? (2026-10-21: ikinci kopya hemen çıkıyor, tek süreç kalıyor.)
- [ ] "Oturum açılınca başlat": oturumu kapatıp açınca uygulama küçültülmüş başlıyor mu? (`--minimized` ile elle başlatınca pencere gizli, yalnızca tepsi simgesi çıkıyor; oturum kapatıp açma denenmedi.)
- [x] Ortak (public) ağda sunucu kendiliğinden başlamıyor mu? Sarı satır çıkıyor mu? (2026-10-21: başlamıyor, sarı satır ve tepsi ipucu çıkıyor.)
- [ ] Güncelleme denetimi: ilk GitHub release'inden sonra "Yeni sürüm" satırı çıkıyor mu?

### PC: hata günlüğü (ALTYAPI 6)
- [x] Günlük dosyası gerçekten yazılıyor mu? PIN ve dosya yolları gizleniyor mu? (2026-10-21: yazılıyor, yol `<path>` olarak gizli, PIN yok. Günlükte 20 Ekim'deki bir debug çalıştırmasından "RenderFlex overflowed by 17 pixels" hatası var; hangi ekran olduğu günlükten anlaşılmıyor.)
- [x] "Günlüğü dışa aktar" kaydetme penceresini açıyor mu? (2026-10-21: evet.)
- [x] "Sorun bildir" tarayıcıda dolu bir issue sayfası açıyor mu? (2026-10-21: açıyordu ama tarayıcı arkada kalıyordu; GTK üzerinden açılacak şekilde düzeltildi `70fb0ef`, artık öne geliyor.)

### PDF görüntüleyiciler (ESKI, CLAUDE.md)
- [ ] Okular (Ctrl+Shift+P) ve WPS PDF (F11) ile Başlat/Bitir. Diğer görüntüleyiciler Windows'ta doğrulandı, bu ikisi hiç denenmedi. (2026-10-21: Okular kurulu değil. WPS PDF `libtiff5` kurulunca açıldı: telefon "PDF açık" diyor, Tam ekran F11 ile çalışıyor, ekran resmi geliyor. PageDown bir ekran kaydırıyordu, sağ/sol ok sayfa başına atlıyor; Linux artık görüntüleyicinin ok tuşlarını kullanıyor; telefondan Sonraki/Önceki sayfa sayfa geçiyor.)
- [x] Linux'ta tarayıcıların PDF'inde Sonraki/Önceki hâlâ PageDown/PageUp gönderiyor. Windows'ta bu yüzden sağ/sol oka geçilmişti; Linux'ta da sayfalar arasında takılıyor mu? (2026-10-21: Firefox'un sunum kipinde PageDown sayfa sayfa geçiyor, takılmıyor. Chrome'da denenmedi.)

### WPS: Devral (2026-10-21)
Kullanıcının kendi açtığı WPS'e köprü bağlanamıyor. PC'deki WPS satırında ve telefonda çıkan "Devral" o WPS'i kapatıp sunumu QuickRemote'un WPS'inde açıyor. Gösteri sürüyorsa ekran resmini slaytların küçük resimleriyle karşılaştırıp aynı slayttan başlatıyor, bulamazsa 1. slayttan.
- [x] Gösteri yokken: iki sekmeli WPS kapandı, iki dosya da köprünün WPS'inde açıldı, etkin sekme korundu. (2026-10-21, sunucuya bağlanan bir test istemcisiyle.)
- [x] Gösteri sürerken aynı slayttan devam ediyor mu? (2026-10-21: evet. 119 slaytlık sunumda, animasyonu yarıda kalmış 4. slayt doğru bulundu, devralma 3 saniye sürdü, telefon "4 / 119" ve bütün araçları aldı. İlk denemede köprü, pencereleri daha önce kapatılmış eski WPS'ine açmaya çalışıp hata vermişti; köprü artık yanıt vermeyen WPS'i kapatıp yenisini başlatıyor, yine açamazsa dosyalar kullanıcının kendi WPS'inde yeniden açılıyor.)
- [x] Yan bulgu: uygulamanın açtığı WPS gösterisinde, notunda boş bir metin kutusu olan slaytta köprünün durumu çöküyordu (telefon slayt numarasını göremiyordu). Düzeltildi.
- [x] Kaydedilmemiş değişiklik varken: (2026-10-21: WPS kaydetme sorusunu soruyor. 60 saniyede yanıtlanmazsa telefona `WPS_TAKEOVER_NOT_CLOSED` gidiyor ve değişiklik duruyor; "Yes" denince dosya kaydedilip devralma kaydedilen hâliyle sürüyor. Bulunan hata: soru açıkken ikinci bir Devral sorunun penceresine de "kapat" gönderiyordu, WPS bunu "kaydetme" sayıp değişikliği siliyordu. Düzeltildi: diyaloglara hiç kapat gönderilmiyor, soru açıksa yalnızca yanıt bekleniyor.)
- [x] Telefondaki Devral düğmesi, gerçek dokunuşla (2026-10-21: gösteri telefondan başlatıldı, Devral'dan sonra kart "4 / 119", not ve resim geldi, Sonraki köprüden ilerletti). PC'deki düğmeye gerçek tıklama denenmedi (Wayland'de yapay tıklama yok).

### Yeni bulgu: yerel Wayland pencereleri (2026-10-21)
- [ ] KDE Plasma'da Chrome ve Firefox artık varsayılan olarak yerel Wayland'de açılıyor. PC öndeki pencereyi yalnızca X11'den (WM_CLASS) okuyabildiği için bunlarda "PDF önde" bilinmiyor: telefon "Sunum açık değil" diyor, Başlat tam ekran yerine Impress'i (açıksa) ya da F5'i (sayfayı yeniler) deniyor, ekran resmi gelmiyor. Firefox `MOZ_ENABLE_WAYLAND=0` ile XWayland'de açılınca hepsi çalışıyor. Öneri: KDE'de etkin pencerenin sınıfını KWin'den okumak (KWin betiği ya da D-Bus); GNOME'da karşılığı yok.

### Programa göre destek tablosu (DESTEK)
- [ ] **†** işaretli hücreler kodu okuyarak yazıldı, gerçek programda denenmedi. Özellikle Impress satırlarında tek tek doğrulama yok. Fırsat oldukça birer birer denenip tablo güncellenmeli.

---

## 2. Telefon (S23 FE)

Önce telefon uygulamasını **release** olarak derleyip kur. Debug sürümü yavaşlatıyor.

**Kurulum engeli (2026-10-21):** telefondaki uygulama (versionCode 1000002) başka bir anahtarla imzalı, bu makinede derlenen release APK üstüne kurulamıyor (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Ya imzalayan makineden kurulur ya da uygulama kaldırılıp kurulur (kayıtlı PC'ler ve ayarlar gider). Yeni kurulumun versionCode'u en az 1000003 olmalı (`--build-number 1000003`).

- [x] **Kısayollar** (ALTYAPI 5): simgeye basılı tutunca "Bluetooth kumanda", "QR tara" ve "Bağlan: <PC>" çıkıyor ve çalışıyor mu? (2026-10-21: üçü de çıkıyor ve çalışıyor, başlatıcı dışa kapalı etkinliği açabiliyor. "QR tara" ve "Bluetooth kumanda" açık kumandayı kapatıp bağlantıyı ekransız bırakıyordu, düzeltildi `8c4ceb7`.)
  - Başlatıcı, dışa kapalı (`exported=false`) olan `ShortcutActivity`'yi açamazsa manifest'te bu değer `true` yapılır.
  - Kısayol, açık bir kumanda ekranını kapatmıyor mu?
- [x] **Hızlı Ayarlar kutucuğu** (ALTYAPI 5): görünüşü, alt yazıda PC adı, bağlıyken "açık" görünmesi, Android 14+'ta dokununca panelin kapanıp uygulamanın açılması. (2026-10-21: dördü de evet, Android 16.)
- [ ] **Son PC'ye bağlanma** (ALTYAPI 5): PC'nin IP'si değişince mDNS'te adıyla bulunuyor mu? (2026-10-21: kayıtlı PIN'le bağlanma ve yanlış PIN'de PIN sorma çalışıyor. IP değişimi için ikinci IP eklemek yönetici parolası istiyor, denenmedi.)
- [x] **`caps`** (ACIK 3): çalışmayan araçlar soluk mu? PDF önde iken "Tam ekran" çıkıyor ve Slayta git gizleniyor mu? (2026-10-21: evet.)
- [x] **Slayt önizlemesi** (ONIZLEME): kart, Sunucu görünümü (dikey ve yatay), "Slayta git" ızgarası. Bunlar yalnızca widget testlerinden geçti. (2026-10-21: Impress'te üçü de çalışıyor.)
- [x] **Ekran görüntüsü kartı** (ACIK 1): PDF'te "Bilgisayarın ekranı" resmi; Sunucu görünümünde büyük resim ve Önceki/Sonraki. (2026-10-21: kartta PDF ve WPS ekran resmi çalışıyor; tam ekran WPS PDF'te Sunucu görünümü resmi büyük gösteriyor, yalnızca Önceki/Sonraki var, Sonraki'den sonra resim 3 saniyede yeni sayfaya geçiyor.)
- [x] **Hata günlüğü** (ALTYAPI 6): "Hata günlüğünü paylaş" Android paylaşım menüsünü açıyor mu? "Sorun bildir" tarayıcıyı açıyor mu? (2026-10-21: paylaşım menüsü günlük dosyasıyla açılıyor, "Sorun bildir" GitHub'da dolu bir issue sayfası açıyor.)
- [x] **Kaplama** (OVERLAY 8): gösterisiz dokunmatik lazer, lazer türü seçimi, Temizle'yi basılı tutunca geri alma. (2026-10-21: üçü de çalışıyor.)

## 3. Saat (Galaxy Watch 6)

APK'yı yalnızca `adb -s <saatin seri numarası>` ile kur. Bir kez telefona kurulup telefon uygulamasının yerine geçmişti.

- [x] **Tema eşitleme** (ACIK 4): (2026-10-21: üçü de evet. Yan bulgu: Araçlar sayfasında "Gösteri kapalı" kesiliyordu, düzeltildi `30241cf`.)
  - Telefonda tema değişince saat de değişiyor mu?
  - Gün Batımı saatte Kobalt mı oluyor?
  - Anahtar kapalıyken saat kendi temasında mı kalıyor?
- [x] **Gösterisiz lazer** (OVERLAY 9): kaplama açıkken lazer düğmesi açık mı, lazer çalışıyor mu? (2026-10-21: düğme açık, nokta PC'de görünüyor.)
- [ ] Saat bölümü PowerPoint ile Windows'ta da denenecek (WIN-UI 15).

---

## 4. Windows (senin makinen)

**2026-10-22 oturumu (telefonsuz):** Windows 11 Home 26300, %125 ölçek, tek monitör, PowerPoint 365 16.0.20430, WPS 12.1.0.29162 (12.2 değil), Chrome 155, Edge 155. Telefonun yerine sunucuya bağlanan bir deneme istemcisi kullanıldı (TLS + PIN, komutlar, lazer kareleri, slayt resimleri); ekran görüntüleriyle bakıldı. Bu oturumda bulunan ve düzeltilen hatalar (`9b7a381`):
- **PowerPoint gösterisi önizleme açıkken tuşlara tepki vermiyordu.** COM `Slide.Export` gösteri sırasında PowerPoint'in klavye odağını sıfırlıyor; pencere önde ama Sonraki/Önceki/B/W/kalem hiçbir şey yapmıyordu (telefonda slayt resmi açıkken kumanda çalışmazdı). `PptController.restoreShowFocus` odağı, ön planı değiştirmeden geri veriyor; dışa aktarmadan sonra ve her tuştan önce.
- **IP bulma her seferinde zaman aşımına düşüyordu.** `Get-NetIPConfiguration` sıcakken bile ~6 sn sürüyor (sınır 5 sn); Polling kuyruğunu tıkıyor, START'tan sonraki durum 3-6 sn gecikiyordu, sunucu açılışta 9-12 sn bekliyordu. Varsayılan rotadan okunuyor (~50 ms); yeni PowerShell sürecinin ilk işine 15 sn veriliyor. Sunucu artık ~4-5 sn'de açılıyor.
- **Gösterinin siyah/beyaz ekranı Windows'ta bildirilmiyordu**, telefona simsiyah slayt resmi gidiyordu. COM `View.State` (3, 4) okunuyor; B/W'den sonraki 1,5 sn resim alınmıyor.
- **WPS'te Export Windows'ta da çalışıyor** (gösteri içinde ve dışında); yalnızca-PowerPoint koşulu kaldırıldı, WPS gösterisinde de slayt resimleri ve küçük resimler geliyor.
- **Hiç sunum açık değilken START, WPS'in ana sayfasına F5 basıyordu** (WPS 12 ana sayfa ve belgeleri sunumla aynı pencere sınıfında). Artık `START_FAILED` dönüyor.
- **"Sorun bildir" Windows'ta tarayıcı yerine Belgeler klasörünü açıyordu** (`explorer <uzun URL>`). `url_launcher`'a geçildi; düzeltmeden sonra tarayıcıda açıldığı **henüz görülmedi**.
- Testler: `wps_take_over_test.dart` (7 test) ve 3 Python köprü testi Windows'ta düşüyordu (Linux'a özgü `/proc`, `waitpid`, Unix yolları); Windows'ta atlanıyor.

### Önce derleme
- [x] `flutter build windows` derleniyor mu? (2026-10-22: evet, `laser_overlay.cpp`, mutex'li `main.cpp`, gdiplus, magnification ilk derlemede geçti.)

### Yeni arayüzün tam denemesi (WIN-UI, 16 bölüm)
- [ ] Sırasıyla: (2026-10-22: telefon olmadan yapılabilenler aşağıda işaretlendi; telefon ekranıyla yapılacak tam deneme bekliyor. WIN-UI dosyası bu makinede yok.)
  - PC penceresi (dar, geniş) ve sunucuyu başlatma. (Dar pencere, güç tuşu, sunucu açık kartı, QR ve PIN düzgün; geniş düzen denenmedi.)
  - Ortak ağ uyarısı, Görünüm ve Dil ayarları.
  - Güvenlik kodu penceresi.
  - PowerPoint kontrolleri: Başlat, Sonraki/Önceki, not, siyah/beyaz ekran, Slayta git, odak koruması. (İstemciyle hepsi çalıştı; not durumda geliyor.)
  - Touchpad: lazer, kalem, renkler, silgi, Temizle. (Kalem, fosforlu kalem, Hepsini sil çalıştı; renk ve silgi denenmedi.)
  - Medya ve şu an çalan.
  - QR ile bağlanma ve telefonu çıkarma.
  - WPS, Bitir ("mürekkep saklansın mı?" sorusunun geçilmesi) ve saat. (WPS ve PowerPoint'te mürekkep varken Bitir: soru "Kaydetme" ile geçildi, slaytta mürekkep kalmadı.)
- [x] Not: WIN-UI'nin 13. bölümü WPS'te lazer yerine "Ok" bekliyor. (2026-10-22: WPS 12.1 gösterisinde Ctrl+A, Ctrl+R ile WPS'in kendi lazeri göründü.)

### Eski denetimden kalan Windows değişiklikleri (ESKI)
- [ ] Odak koruması, COM ile Slayta git (START_AT), SMTC önbelleği, IP yoklaması, `nsd` 5.x, sertifika ortam değişkenleri. (2026-10-22: odak koruması, START_AT, IP yoklaması (düzeltildi), mDNS kaydı ve sertifika yükleme çalışıyor; SMTC denenmedi.)
- [x] PowerPoint'in Korumalı Görünüm'de açtığı bir sunumda Başlat. (2026-10-22: düzenlemeye geçip gösteriyi açtı, ~4 sn.)
- [x] WPS'in COM yolları (`PresenterCom`): Windows WPS'te bütün komutlar. (2026-10-22, WPS 12.1: Başlat, Sonraki/Önceki, Slayta git, siyah ekran, kalem, NEXT/PREV'de mürekkep silme, lazer, Bitir. Yan bulgu: WPS gösterisi biterken telefon bir an "0 / 0" durumunu alıyor.)

### Slayt önizlemesi (ONIZLEME 1, 3)
- [ ] PowerPoint gösterisinde kart, Sunucu görünümü ve "Slayta git" ızgarası. (2026-10-22: PC tarafı çalışıyor: o anki 1280 px, sonraki 640 px, küçük resimler 320 px, ekran resmi dışa aktarmanın yerine geçiyor. Telefon ekranında bakılmadı.)
- [x] WPS 12.2'de `Slides(n).Export`. (2026-10-22: WPS 12.1'de çalışıyor, koşul kaldırıldı. 12.2'de denenmedi.)

### Kaplama (OVERLAY 10–13)
- [x] Tarayıcıdaki PDF'te ve gösteri dışında lazer. Ayarlar'da QuickRemote seçiliyken PowerPoint'te lazer. (2026-10-22: masaüstünde, tam ekran Chrome PDF'te ve "QuickRemote" modunda PowerPoint gösterisinde lazer, kalem, büyüteç.)
- [x] Mürekkep, spot ışığı, büyüteç: (2026-10-22: üçü de çiziliyor; büyüteç yuvarlak, 2×. Kaplama hiç odak almadı, NEXT gösteriye gitti. Mürekkebin üstüne gerçek fare tıklaması alttaki pencereye geçti.)
  - Pencereler odak almıyor mu, yani tuşlar gösteriye gitmeye devam ediyor mu?
  - Tıklamalar katmandan geçiyor mu?
- [ ] DPI %125/150 ve iki monitör. (2026-10-22: %125'te doğru yerde. %150 ve iki monitör denenmedi.)

### 2026-10-20 işleri (ACIK, ALTYAPI)
- [x] `caps`/`front`: PowerPoint ve WPS'te öndeki pencere ve araçlar doğru mu? NEXT/PREV'de mürekkep telefon başına mı siliniyor? (2026-10-22: `front` show/editor/browser/other doğru; WPS'te artık `previews` da var. Küçük kusur: WPS'in ana sayfası da "editor" sayılıyor.)
- [x] Ekran görüntüsü: PowerPoint ve WPS gösterisinde, Edge/Chrome'da tam ekran PDF'te. `PrintWindow` siyah mı dönüyor? (2026-10-22: siyah değil; Chrome tam ekranda kaplama mürekkebi de resimde. Edge, kullanıcı profilinde PDF yerine eklenti sayfaları açtığı için Edge'de PDF denenmedi.)
- [ ] Tepsi (sol tık pencere, sağ tık menü), tek örnek (ikinci kopyanın ilkini öne getirmesi), `--minimized`, kayıt defterine (HKCU Run) yazma. (2026-10-22: tek örnek, gizli pencereyi öne getirme, `--minimized` ve "Oturum açılınca başlat"ın HKCU Run'a yazıp silmesi çalışıyor. Tepsi simgesine tıklama denenmedi.)
- [ ] Günlüğü dışa aktarma ve "Sorun bildir". (2026-10-22: dışa aktarma kaydetme penceresini açıyor, dosyada PIN, kullanıcı adı, dosya adı yok. "Sorun bildir" düzeltildi, tarayıcıda açıldığı görülmedi.)
- [x] Küçük arayüz bulguları (2026-10-22, 440 px pencere): Ayarlar'da Lazer seçeneği "QuickRem…" diye kesiliyor; Ayarlar'ın "Kapat" düğmesi en altta durduğunda "Kapatınca tepsiye küçült" anahtarının üstüne biniyor. (2026-10-25: ikisi de artık yok; 440×760'ta gerçek fontlarla en üstte ve en altta çizilip bakıldı. Lazer bölümü 23 Ekim'de yeniden yazılmıştı, Kapat ayrı satırda.)

### Bluetooth denemesi (WIN-BT, ACIK 2)
- [ ] `quick_remote_pc/tool/windows_bt_hid_trial.ps1`, adım adım WINDOWS-DENEME.md'de. (2026-10-22: betik `-ListOnly` ile hatasız derlendi ve eşleşmiş Galaxy S23 FE, Watch6 ve kulaklığı listeledi; asıl deneme telefon gerektiriyor.)
  - 2026-10-25, Windows 11 26300: betik hatasız çalıştı (yönetici gerekmedi), ama hizmeti açmak telefonu klavye yapmadı: Windows bağlantıyı reddetmeye devam etti, HID aygıtı hayalet kaldı. Sonuçlar WINDOWS-DENEME.md tablosunda. Kaldırıp yeniden eşleştirme ise çalıştı (telefon klavye olarak bağlandı): uygulamanın Windows talimatı doğru. Kalıcı çözüm için seçenekler: PC uygulamasında tek tuşla onarım, hayalet HID aygıtını silmek, BLE klavye (HID over GATT).
  - Sonuca göre ya asıl BtHidRepair kodu ya da "Telefonu yeniden eşleştir" tuşu yazılacak.

---

## 5. GitHub, CI ve paketler (ALTYAPI 1, 3)

- [x] İlk push'ta CI koşusu. (2026-10-21: Windows testleri geçti; telefon ve saat işleri Android SDK paket adı yüzünden düşüyordu, düzeltildi `a030f31`. Şimdi bütün işler yeşil.)
- [x] Release akışını ilk etiketten önce bir kez elle çalıştır. (2026-10-21, `0.0.1-test`: iki düzeltmeden sonra yeşil. .deb kontrolü yanlış alarm veriyordu `c13ff49`; .deb EGL/GLES bağımlılığı olmadan temiz Debian/Ubuntu'da açılışta çöküyordu `60555de`, düzeltildi.)
- [x] Gerçek Flutter derlemeleri, Inno Setup kurulumu, gerçek `dpkg-deb` ile .deb paketi. (CI'da derleniyor; .deb, Debian 12 ve Ubuntu 22.04'te kurulup açılıyor. AUR PKGBUILD'i bu makinede `makepkg` ile paket oluşturdu, kurulmadı.)
- [x] Windows kurulum dosyasını (Inno Setup) gerçek Windows'ta kur ve aç. (2026-10-25, Windows 11 26300, Inno Setup 6.7.3, VC++ 14.50 DLL'leri: sessiz kurulum kullanıcı klasörüne, Başlat menüsü kısayolu ve kaldırma kaydı doğru, uygulama açılıp sunucuyu başlattı, eski sertifika ve ayarlarla; telefon 8090'a ulaştı. Açılışta başlatma seçeneği `--minimized` kaydını yazıyor, kaldırıcı onu ve uygulama klasörünü siliyor; ayarlar ve sertifika AppData\Roaming'de kalıyor.)
- [ ] Pardus'ta bir sanal makinede .deb kurulumu (ilk release'ten önce bir kez).
- [ ] AUR: hesap aç, `quickremote-pc-bin` paketini ilk kez yükle.
- [ ] Play kararına bağlı: release akışındaki telefon ve saat APK'ları (PLAY, 1. bölüm).

## 6. Play Store

Ayrı dosyada: [PLAY_STORE_YAPILACAKLAR.md](PLAY_STORE_YAPILACAKLAR.md).

## 7. Web sitesi (SITE, ONIZLEME 4)

Site 2026-10-20'de yenilendi (`docs/raporlar/SITE_YENILEME.md`). Kalanlar:
- [x] **Logo 59A:** favicon, uygulama simgesi, og:image ve sayfalardaki sprite (SITE, aşama 1).
- [x] **Uygulama ekranlarının kopyaları** yeni tasarıma göre: Wi-Fi kumanda, Bluetooth, ana sayfa ve Ayarlar, tema, PC penceresi, saat (SITE, aşama 2–7).
- [x] **Slayt önizlemesi:** karttaki resim, istenirse Sunucu görünümü demosu, "Hangi slayttasın" kutusu, SSS (ONIZLEME 4).
- [x] **2026-10-20 özellikleri:** kaplama (gösterisiz lazer, spot ışığı, büyüteç), PDF'te canlı ekran, telefon kısayolları ve Hızlı Ayarlar kutucuğu, PC tepsisi, hazır paketler ve indirme bölümü.
- [ ] **Play rozeti** ve gizlilik politikası sayfaları (PLAY).
- [ ] **Alan adı belli olunca:** og:image ve hreflang için tam adresler, gerçek indirme bağlantıları (ESKI).

## 8. Senin kararını bekleyenler

- [ ] **Lisans**: repoda LICENSE yok. Site "Açık kaynak", README "kişisel kullanım" diyor; AUR paketi yer tutucu lisans kullanıyor.
- [ ] **Paket adı (`applicationId`)**: Play'e ilk yüklemeden önce son hâli verilmeli (PLAY, 0. bölüm).
- [ ] **Uygulamanın adı**: şimdilik QuickRemote (boşta olan aday SlideMando'ydu). Play'deki benzer adlara bakılmalı.
- [x] **2026-10-21 listesinin soruları (2026-10-22, kullanıcı karar bırakınca kendimiz verdik):**
  - **Chrome/Firefox PDF'te F5:** Windows yolunda hata bulunmadı; Linux'ta sebep KDE Wayland'daki yerel tarayıcı penceresiydi. KWin betiğiyle öndeki pencere okunuyor (`kwin_active_window.dart`), eksik program adları eklendi. **Canlı deneme:** Plasma 6 Wayland'da Chrome → F11, Firefox → Ctrl+Alt+P.
  - **WPS PDF kaydırma:** Windows'ta WPS 12'nin PDF sekmesi düzenleyici sanılıyordu; başlığında `.pdf` olan `wps.exe` penceresi artık PDF sayılıyor ve ok tuşlarını alıyor. **Canlı deneme:** sekme başlığında dosya adı görünüyor mu.
  - **Sunucu görünümünde lazer:** mutlak konum seçildi (`LASER_ABS`, ikili kare türü 2, `auth`'ta `absLaser`). **Canlı deneme:** PowerPoint/WPS'te imleç, kaplama ve Impress, 16:9 olmayan ekranda kayma.
  - **"Neler yapılabilir" ekranında "Denenmedi":** konuldu.

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
- `quick_remote_pc/tool_tmp/` (kaplama deneme düzeneği) hiç commit edilmeyecek.
