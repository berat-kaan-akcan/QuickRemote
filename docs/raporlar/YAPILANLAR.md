# QuickRemote: yapılanlar

Son güncelleme: 2026-10-26. Bitmiş işler, denemelerin sonuçları ve verilen kararlar bu dosyada. Açık işler [YAPILMAYANLAR.md](YAPILMAYANLAR.md)'de; tarayıcıda PowerPoint ve Google Slaytlar için ayrı plan [PPT_WEB_PLAN.md](PPT_WEB_PLAN.md).

Bu dosya şunlardan toplandı (2026-10-26, eskileri silindi, geçmişi git'te): `DURUM.md`, `KALANLAR.md`, `WINDOWS-DENEME.md`, `docs/raporlar/` içindeki ACIK_ISLER, ALTYAPI, OVERLAY, SLIDE_PREVIEW (rapor ve görev), SITE_YENILEME, CI_RAPOR, GUVENLIK_DENETIMI ve KULLANICI_DENETIMI raporları. Kodun nasıl çalıştığının ayrıntısı CLAUDE.md'de; burada ne yapıldığı, neyin nerede denendiği ve neden öyle karar verildiği var.

"Denendi" yalnızca gerçek programda, cihazda ya da ekranda görülen şey için yazıldı. "Kodu yazıldı" birim testlerinden geçti ama gerçek ortamda görülmedi demek.

---

## 1. Test durumu

| Proje | Sonuç | Tarih |
|---|---|---|
| Ortak paket | 69 test geçti | 2026-10-26 |
| PC | 408 test geçti | 2026-10-26 |
| Telefon | 371 test geçti | 2026-10-26 |
| Python köprüleri | 71 test geçti | 2026-10-22 |
| Saat | 37 test geçti | 2026-10-20 |
| `dart analyze` (üç Dart projesi) | sorun yok | 2026-10-26 |

---

## 2. Özellikler

### Slayt önizlemesi ve Sunucu görünümü (2026-10-20)

- **Protokol**: `SLIDE_PREVIEW:0/1`, `SLIDE_THUMB:n`; PC'den telefona `SlideImageFrame` (`0x51`, tür, slayt, deck, en, boy, JPEG; küçük ya da bozuk çerçeve `null`); `auth`'ta `previews: true`, `SLIDE_STATE`'te `deck` (32 bit FNV-1a). Önizlemeyi açmamış telefona hiçbir ikili çerçeve gitmiyor (eski telefonlar çöküyordu).
- **PC**: `SlidePreviewer`: o anki 1280 px, sıradaki 640 px, küçük resimler 320 px; aynı anda tek dışa aktarma, 3 sn'de vazgeçme, hızlı NEXT'lerde yalnızca son slayt, aynı resim aynı telefona iki kez gitmiyor, 30 MB LRU önbellek, deck değişince boşalıyor.
- **Programlar**: Windows PowerPoint ve WPS (COM `Slides(n).Export`, yoklama PowerShell'inde; WPS koşulu 2026-10-22'de kalktı), Linux Impress (köprünün `export`'u, `GraphicExportFilter`; iki dışa aktarmanın birbirini sonsuza dek beklettiği bir kilitlenme bulunup düzeltildi), Linux'ta uygulamanın açtığı WPS (pywpsrpc `Slide.Export`).
- **Telefon**: slayt kartında 16:9 resim, siyah/beyaz ekranda üstü o renk; Sunucu görünümü (dikey: büyük slayt, sıradaki, notlar, Önceki/Sonraki; yatay: slayt solda); "Slayta git" ızgarası (`ThumbnailRequests`: dörder istek, ekrandan çıkan hücrenin isteği geri alınır, 4 sn'de cevapsız hücre boş kalır); Ayarlar'da aç/kapa (varsayılan açık).
- **Ölçümler**: LibreOffice 26.8.1 (başsız) 2-12 ms/slayt; WPS 11.1 penceresiz sunumda dosyalar doğru; PowerPoint 365 ve WPS 12.1 (Windows) ~20 ms/slayt, ilki ~430 ms.
- **Bilinen sınır** (kullanıcıya söylenir): dışa aktarılan resim slaytın kaydedilmiş hâli (animasyon adımı, mürekkep, oynayan video yok); küçük resimler yalnızca gösteri açıkken; kaydedilmemiş sunumun resimleri yalnızca slayt sayısıyla ayırt edilir.
- **Denendi**: Linux Impress gösterisinde ve Devral ile alınan WPS gösterisinde kart, Sunucu görünümü (dikey ve yatay) ve ızgara (2026-10-21, ızgaradan 3. slayta atlandı). Windows'ta PC tarafı (2026-10-22). Telefon ekranında PowerPoint ile bakılmadı.

### Ekran görüntüsüyle slayt resmi (2026-10-20)

- `SlideImageFrame`'e tür 3 (ekran; slayt ve deck 0). Resim yalnızca projeksiyonda görünenden alınıyor: gösteri penceresi ya da **tam ekrandaki** PDF görüntüleyici/tarayıcı; pencereli tarayıcıdan ve masaüstünden hiçbir zaman. Siyah/beyaz ekranda alınmıyor. Kaplamanın mürekkebi resmin üstüne PC'de çiziliyor; JPEG ayrı isolate'te, 1280 px.
- Linux: XCB `GetImage` (`X11Windows.capture`; alttaki pencere bile eksiksiz alınıyor, kendi GTK penceremizde 17 ms). Windows: `PrintWindow(PW_RENDERFULLCONTENT)`.
- Zamanlama: slayt komutundan 400 ms sonra (gösteride yeni slayt durumunu bekleyerek), sonra 2 sn'de bir, yalnızca 32×18 gri kopyanın özeti değişince.
- **Denendi**: Linux'ta kullanıcının açtığı WPS gösterisinde resim slaytla değişiyor; XWayland Firefox'ta tam ekran PDF'te geliyor, pencereliyken gelmiyor; mürekkep resimde doğru yerde (2026-10-21). Windows'ta PowerPoint 365, WPS 12.1 ve tam ekran Chrome'da siyah çıkmıyor, Chrome'da kaplama mürekkebi de resimde (2026-10-22). Telefonda kartta PDF ve WPS resmi, Sunucu görünümünde büyük resim ve yalnız Önceki/Sonraki; Sonraki'den sonra resim 3 sn'de yeni sayfada (2026-10-21).
- **Sınır**: LibreOffice yerel Wayland'de çalışınca (KDE/Qt6) X penceresi yok, resim alınmıyor; telefon dışa aktarılan slaytı gösteriyor.

### Lazer ve mürekkep katmanı (2026-10-20)

- **Katman**: ekranın üstünde, tıklamaları geçiren, odak almayan şeffaf pencere. Linux: ayrı süreç `quickremote_overlay` (GTK3 + cairo, XWayland, override-redirect). Windows: runner'da üç katmanlı pencere (mürekkep, gölge, nokta; GDI+, `UpdateLayeredWindowIndirect`).
- **Araçlar**: lazer, kalem, saydam fosforlu kalem (kendi üstünden geçince koyulaşmıyor), çizgi çizgi silgi, Temizle, geri al (`UNDO_INK`), spot ışığı (`MODE_SPOTLIGHT`), büyüteç (`MODE_ZOOM`, yalnızca Windows, Magnification API), gösteri dışında siyah/beyaz ekran. "Mürekkebi koru" açıksa mürekkep slayta göre saklanıyor ve dönünce geri geliyor.
- **Kim çizer**: PC'de Ayarlar → Lazer: Otomatik (önerilen) / Her zaman QuickRemote / Programın kendi lazeri. Otomatik'te PowerPoint ve WPS kendi araçlarını kullanır; Impress, PDF, tarayıcı ve gösteri dışı katmanla. Ayar değişince telefona `OVERLAY` mesajı.
- **Telefon**: gösteri olmadan da dokunmatik alan ve araçlar; lazer tuşuna ikinci dokunuş tür seçimini açar (lazer, spot ışığı, büyüteç); Temizle'yi basılı tutmak geri alır. **Saat**: gösteri olmadan da lazer (`laserAnywhere`).
- **Bulunan hatalar**: `gtk_init` kullanıcının dilini yüklüyor, Türkçe'de `sscanf` "0.5"i 0 okuyordu (`g_ascii_strtod`). Linux katmanının giriş alanı bütün ekrandı, çizgi kaldıkça masaüstüne tıklanamıyordu; düzeltildi `a95c067` (2026-10-21), son telefon ayrılınca katman da temizleniyor.
- **Denendi, Linux (2026-10-21)**: Impress gösterisinde oynayan videonun da üstünde; tıklamalar katmandan geçiyor (gerçek fareyle); XWayland Firefox'ta tam ekran PDF'te lazer, kalem, silgi, spot ışığı, siyah ekran; kalem akıcı, fosforlu kalem koyulaşmıyor, slayt değişince siliniyor, "koru" açıkken geri geliyor; spot ışığı; %125 ölçekte doğru yerde. Yan bulgu: %125'te LibreOffice 26.8 videoyu kendisi kaydırıyor (QuickRemote'tan bağımsız).
- **Denendi, Windows 11 (2026-10-22, %125, tek monitör)**: masaüstünde, tam ekran Chrome PDF'te ve "QuickRemote" modunda PowerPoint gösterisinde lazer, kalem, fosforlu kalem, geri al, spot ışığı, yuvarlak 2× büyüteç, boş ekran; katman hiç odak almadı (NEXT gösteriye gitti), mürekkebin üstüne fare tıklaması alttaki pencereye geçti.
- **Telefon (2026-10-21)**: gösterisiz dokunmatik lazer, tür seçimi, basılı tutunca geri al. **Saat (2026-10-21)**: gösterisiz lazer düğmesi açık, nokta PC'de görünüyor.

### Öndeki pencere ve çalışan araçlar: `front`/`caps` (2026-10-20)

- PC her `SLIDE_STATE`'te (boş olanında da) öndeki pencerenin türünü (`show`, `editor`, `pdf`, `browser`, `other`) ve şu an çalışan araçları gönderiyor; pencere değişince durumu yeniden gönderiyor. Kurallar PC'de, telefon tahmin etmiyor. Eski PC'de telefon eskisi gibi.
- Telefon (`ShowInfo`): `caps`'te olmayan araç soluk; PDF/tarayıcı önde ve gösteri yokken kırmızı uyarı yerine bilgi satırı, Başlat yerine "Tam ekran", Slayta git gizli. Gösteri yokken öndeki programın adı (`presenter`, 2026-10-22).
- Ayarlar → Yardım → **"Neler yapılabilir?"** ekranı (2026-10-21): bağlantı, bilgisayar ve program seçilir, her özellik çalışır / kısmen / çalışmaz ve not; karşılaştırma görünümü; gerçek cihazda denenmemiş hücrelerde "Denenmedi" (2026-10-23).
- **Denendi**: telefonda soluk araçlar, PDF önde iken "Tam ekran" ve gizli Slayta git (2026-10-21, XWayland Firefox'ta "Tarayıcı önde"); Windows'ta `front` show/editor/browser/other doğru, WPS'te `previews` (2026-10-22).

### "Mürekkep kalsın" telefon başına (2026-10-20)

- Sunucu `SET_KEEP_INK`'i soket başına saklıyor, NEXT, PREV, START, START_AT'e o telefonun değerini `keepInk` olarak geçiriyor; slaytı değiştiren telefonun ayarı geçerli. `PresenterSettings` kaldırıldı. Hiç göndermemiş eski telefon "temizle" alır. Test: `websocket_server_test.dart` (iki ve üç telefon). Tek telefonla "koru" açık/kapalı canlı denendi (2026-10-21).

### Saat

- **Tema eşitleme** (2026-10-20): telefonun Tema ekranında "Saatte de kullan" (varsayılan açık); Gün Batımı saatte Kobalt. **Denendi** (2026-10-21): tema değişince saat değişiyor, Gün Batımı Kobalt, anahtar kapalıyken saat kendi temasında. Yan bulgu: Araçlar sayfasında "Gösteri kapalı" kesiliyordu, düzeltildi `30241cf`.
- **Gösterisiz lazer** (yukarıda). **Start "Tam ekran"** (2026-10-25, `c3f81b8`): PDF görüntüleyici ya da tarayıcı önde ve gösteri yokken (`viewer`), basınca slayt düğmelerine geçiyor; Edge'de denendi.
- **Tek konuşma saati** (2026-10-25, `eec79db`): telefon ve saat aynı süreyi gösteriyor; Bluetooth kumandası da kendi saatini tutuyor (`c404f61`).
- **Soluk metin renkleri** telefonla eşitlendi (`495a119`, 2026-10-22) ve **bağlantı sertleştirmesi** (`49d92a6`, 2026-10-24): kodda; cihazda bakılacaklar YAPILMAYANLAR.md'de.

### WPS: Devral (2026-10-21)

Köprü, kullanıcının kendi açtığı WPS'e bağlanamıyor. PC'deki WPS satırındaki ve telefondaki "Devral" o WPS'in dosyalarını `/proc/<pid>/fd`'den bulur, pencerelerini kapatır ve dosyaları köprünün WPS'inde açar; gösteri sürüyorsa ekran resmini 64 px'lik slayt resimleriyle karşılaştırıp aynı slayttan başlatır (bulamazsa 1. slayt).

- **Denendi**: gösteri yokken iki sekmeli WPS kapandı, iki dosya köprünün WPS'inde açıldı, etkin sekme korundu. Gösteri sürerken 119 slaytlık sunumda animasyonu yarıda kalmış 4. slayt bulundu, 3 sn, telefon "4 / 119" ve bütün araçları aldı. Telefondaki düğme gerçek dokunuşla.
- **Bulunup düzeltilenler**: köprü, pencereleri kapatılmış eski WPS'ine açmaya çalışıyordu (artık yanıt vermeyeni kapatıp yenisini başlatıyor, açamazsa dosyalar kullanıcının WPS'inde yeniden açılıyor). Notunda boş metin kutusu olan slaytta köprünün durumu çöküyordu (`aea0996`). Kaydetme sorusu açıkken ikinci Devral sorunun penceresine "kapat" gönderiyordu, WPS bunu "kaydetme" sayıyordu; artık diyaloglara hiç kapat gönderilmiyor (`7ea6356`). 60 sn'de yanıtlanmayan soru `WPS_TAKEOVER_NOT_CLOSED`.
- Devral'dan sonra gösteri yokken telefon "LibreOffice Impress'i başlatın" diyordu; öndeki programın adı artık gidiyor (2026-10-23, kodla ve testle; gerçek WPS ile bakılmadı).
- WPS 11.1'de (Linux) video hiç oynamıyor (`Player.Play()` bir şey yapmıyor, `State` hep "oynuyor"); köprünün WPS gösterisinde slayt medyası düğmeleri soluk (`1565922`).

### PDF görüntüleyiciler ve tarayıcılar

- Başlat her programın kendi tuşuyla (Firefox Ctrl+Alt+P, Acrobat Ctrl+L, Okular Ctrl+Shift+P, WPS PDF ve Chromium tarayıcıları F11, SumatraPDF F5). Tarayıcılarda ve WPS PDF'te Sonraki/Önceki ok tuşları (PageDown bir ekran kaydırıp sayfalar arasında takılıyordu). Windows'ta Edge, Chrome, Firefox, Acrobat ve SumatraPDF doğrulandı.
- **Linux (2026-10-21)**: WPS PDF (`libtiff5` kurulunca) "PDF açık", F11 ile tam ekran, ekran resmi; ok tuşlarıyla sayfa sayfa (`463d0a5`). Firefox'un sunum kipinde PageDown takılmıyor.
- **KDE Wayland'de yerel tarayıcılar** (2026-10-23, `6e7d7dc`): Plasma'da Chrome ve Firefox yerel Wayland'de açılınca PC onları X11'den göremiyordu (F5 basıp sayfayı yeniliyordu). Öndeki pencere KWin betiğiyle okunuyor (`kwin_active_window.dart`), Wayland app_id'leri ve Edge'in Linux adı eklendi. Gerçek KDE oturumunda denenmedi.
- **WPS 12'nin PDF sekmesi** (Windows): başlığında `.pdf` olan `wps.exe` penceresi PDF sayılıyor ve ok tuşlarını alıyor.
- **Tarayıcıda PowerPoint ve Google Slaytlar** (2026-10-26): başlıktan tanıma, Ctrl+F5/Esc/oklar, Google Slaytlar'da slayta git, telefonda ve Bluetooth'ta iki program. Ayrıntı ve deneme listesi [PPT_WEB_PLAN.md](PPT_WEB_PLAN.md).

### Sunucu görünümünde dokunulan yere giden lazer (2026-10-23, `0849894`)

Mutlak konum: `LASER_ABS` (ikili çerçeve türü 2, gösterinin kesirleri), yalnızca `auth`'unda `absLaser` olan PC'ye. Kaplama ve Impress kesirleri doğrudan alıyor; PowerPoint ve WPS'in lazeri imleci izlediği için imleç gösteri penceresinin o noktasına götürülüyor. Kodu yazıldı, cihazda denenmedi.

### Bluetooth kumanda

- Bağlanınca program soruluyor (`BtProgramSheet`), Wi-Fi'nin medya paneli paylaşılıyor (2026-10-21, `494c333`).
- PowerPoint'te lazerden sonra araç çubuğu gizleniyor: MODE_ARROW Ctrl+A sonra Ctrl+U (2026-10-25, PowerPoint 365'te doğrulandı).
- Tarayıcıdaki PowerPoint ve Google Slaytlar hedefleri (2026-10-26, PPT_WEB_PLAN.md).

### Telefon: kısayollar, kutucuk, ana ekran

- **Uygulama kısayolları** ("Bluetooth kumanda", "QR tara", "Bağlan: <son PC>") ve **Hızlı Ayarlar kutucuğu** (2026-10-20). Son PC'ye kayıtlı PIN ve sabitlenmiş parmak iziyle bağlanıyor; adres yanıt vermezse mDNS'te adıyla 6 sn arıyor. Bağlantılar yalnızca açık niyetle (dışa kapalı `ShortcutActivity`).
- **Denendi (2026-10-21, Android 16)**: üç kısayol çıkıyor ve çalışıyor, başlatıcı dışa kapalı etkinliği açabiliyor; kutucuğun görünüşü, alt yazıda PC adı, bağlıyken "açık", dokununca panel kapanıp uygulama açılıyor. "QR tara" ve "Bluetooth kumanda" açık kumandayı kapatıyordu, düzeltildi `8c4ceb7`.
- **Ana ekran** (2026-10-21): son bağlantılar listesi kalktı, yalnızca mDNS'te bulunan PC'ler; altta sabit bağlanma alanı (QR, Bluetooth, elle). Kayıtlı PIN'i olan PC'de "Kayıtlı" işareti; uzun telefonlarda daha büyük tuşlar (2026-10-23).
- PIN akışı: yeniden bağlanma reddedilince yeni PIN soruluyor, PIN penceresi nedenini söylüyor (2026-10-21).

### PC masaüstü (2026-10-20)

- **Tek örnek**: Linux GtkApplication tekil; Windows `Local\QuickRemotePC` mutex'i, ikinci kopya ilkini öne getirip kapanıyor.
- **Tepsi** (`tray_manager` 0.8, appindicator gerekmiyor): Göster, sunucuyu başlat/durdur, telefon sayısı, yeni sürüm, Çıkış; simgede durum noktası. "Kapatınca tepsiye küçült" (ilk seferde bilgi penceresi).
- **Oturum açılınca başlat** (Linux `~/.config/autostart`, Windows HKCU Run, `--minimized`) ve **açılınca sunucuyu başlat** (ortak ağda kendiliğinden başlamıyor, sarı satır).
- **Güncelleme denetimi**: açılışta ve 24 saatte bir GitHub `releases/latest`; yalnızca bildiriyor, indirmiyor; Ayarlar'da kapatılabilir, AUR paketi `UPDATE_CHECK=false` ile derleniyor.
- Durmuş sunucu yalnızca güç tuşunu gösteriyor (2026-10-21).
- **Denendi, Linux KDE (2026-10-21)**: tepsi menüsü panele hiç bildirilmiyordu, düzeltildi `83004f7`; sol tık pencereyi açıyor, menüden Başlat/Durdur, nokta açıkken yeşil, kapalıyken gri. Pencere kapanınca tepsiye iniyor, bilgi penceresi çıkıyor, Çıkış tam kapatıyor (yan bulgu: tepsiden durdurulan sunucunun "ortak ağ" uyarısı kalıyordu, `46e53b9`). İkinci kopya hemen çıkıyor. Ortak ağda sunucu başlamıyor, sarı satır ve tepsi ipucu var.
- **Denendi, Windows (2026-10-22)**: tek örnek, gizli pencereyi öne getirme, `--minimized`, "Oturum açılınca başlat"ın HKCU Run'a yazıp silmesi.

### Yerel hata günlüğü ve sorun bildirme (2026-10-20)

- `AppLog` ortak pakette: dosya, 1 MB'ta döndürme, 3 dosya, arabellekli yazma; `debugPrint`, yakalanmayan hatalar ve Linux köprülerinin stderr'i ona gidiyor. `AppLog.redact` PIN, QR, parmak izi, güvenlik kodu, not/başlık, dosya yolları ve parolaları gizliyor (testli). Uzak çökme raporu yok (karar).
- PC: Ayarlar → Sorun giderme ("Günlüğü dışa aktar", "Sorun bildir"). Telefon: Ayarlar → Yardım ("Hata günlüğünü paylaş", "Sorun bildir").
- **Denendi**: Linux'ta günlük yazılıyor, yol `<path>`, PIN yok; dışa aktarma kaydetme penceresini açıyor; "Sorun bildir" tarayıcıyı arkada açıyordu, GTK üzerinden açılıyor ve öne geliyor `70fb0ef` (2026-10-21). Telefonda paylaşım menüsü günlükle açılıyor, "Sorun bildir" dolu bir issue sayfası açıyor (2026-10-21). Windows'ta dışa aktarma çalışıyor, dosyada PIN, kullanıcı adı, dosya adı yok (2026-10-22).

### CI, release ve paketler

- **CI** (2026-10-20, `.github/workflows/ci.yml`): altı iş (shared, pc-linux, pc-windows, python ubuntu+windows, app, wear), yalnızca değişen klasörler; `v*` etiketi, pazartesi ve elle koşu hepsini çalıştırır. Flutter sabit, JDK 21, `platforms;android-37`.
- **Release** (`release.yml`): sürüm etiketten; Windows Inno Setup kurulumu (kullanıcı başına, imzasız, VC++ DLL'leri içinde); Linux tar.gz, AUR için `-noupdate` tar.gz, .deb (ubuntu-22.04'te derlenir; `debian:12` ve `ubuntu:22.04`'te kurulup Xvfb'de açılıyor); sırlar varsa APK'lar ve AAB; taslak GitHub release, `SHA256SUMS.txt`; AUR PKGBUILD'i doldurulmuş artifact.
- **Denendi (2026-10-21)**: ilk push'ta CI; telefon ve saat işleri Android paket adı yüzünden düşüyordu, düzeltildi `a030f31`, hepsi yeşil. Release elle koşusu (`0.0.1-test`): .deb kontrolü yanlış alarm veriyordu `c13ff49`; .deb EGL/GLES bağımlılığı olmadan temiz Debian/Ubuntu'da açılışta çöküyordu `60555de`. AUR PKGBUILD'i Linux makinesinde `makepkg` ile paket oluşturdu (kurulmadı).
- **Windows kurulumu gerçek Windows'ta** (2026-10-25, Windows 11 26300, Inno Setup 6.7.3, VC++ 14.50): sessiz kurulum kullanıcı klasörüne, Başlat menüsü kısayolu ve kaldırma kaydı doğru, uygulama açılıp sunucuyu eski sertifika ve ayarlarla başlattı, telefon 8090'a ulaştı. Açılışta başlatma `--minimized` kaydını yazıyor, kaldırıcı onu ve uygulama klasörünü siliyor; ayarlar ve sertifika AppData\Roaming'de kalıyor.
- **CI sertleştirme (2026-10-22, `254df09`)**: birinci taraf eylemler commit SHA'sına sabitlendi (`checkout` 4.4.0, `upload-artifact` 4.6.2, `download-artifact` 4.3.0, `setup-java` 4.9.1, `setup-python` 5.6.0; her satırda `# vX.Y.Z`); iki Gradle sarmalayıcısına `distributionSha256Sum` (gradle-9.3.1-all.zip, `17f27786…6e43`, indirilen zip'ten hesaplandı); release'e AAB adımı (yalnız ön sürüm olmayan etiketlerde, telefon/saat imzacı karşılaştırması); Inno Setup 6.7.3'e sabitlendi. `actionlint` temiz. Checkout'larda `persist-credentials: false` (paths-filter işi hariç), `GH_TOKEN` yalnızca "Draft release" adımında.
- README'de "Hazır paketler" bölümü.

### Web sitesi (2026-10-20, `site-yenileme` dalı)

- Sayfalar `site/tools/parts/`'tan `build_pages.py` ile; her cümle `{{tr||en}}`. Logo 59A (favicon, uygulama simgesi, og:image, sprite). Uygulama ekranlarının kopyaları yeni tasarıma göre (Wi-Fi ve Bluetooth kumanda, ana ekran ve Ayarlar, tema, PC penceresi, saat).
- Yeni bölümler ve canlı demolar: saat ⇄ telefon ⇄ PC bağlantı animasyonu, katman (lazer, spot ışığı, büyüteç, mürekkep), altı tema (telefon ve saat birlikte), slayt önizlemesi ve Sunucu görünümü, kurulum sekmeleri ve kopyalanabilir komutlar, SSS, güvenlik, programlar, "Neyi denedik, neyi henüz denemedik".
- 2026-10-22 (`22d35b1`): gizlilik politikası sayfaları (TR/EN), 404, robots, SEO kancaları, denenme durumunun dürüst gösterilmesi, daha sıkı `verify.mjs`. 2026-10-23: Windows 11 deneme sonuçları ve yeni lazer ayarı metinleri.
- `verify.mjs` tam matrisi (tr/en × 1440/390 × açık/koyu × hareket azaltma) temizdi (2026-10-20); ekranlar `docs/raporlar/site-ekranlar/`. Düzeltilenler: telefon kuralının `.rig` dışına sızması, 390 px'te SSS'de 20 px taşma, Sunucu görünümünde boşluk, ayarlar kartında kırpılma.
- Dürüstlük kuralı: gerçek cihazda denenmemiş özellikler gizlenmiyor, işaretleniyor; ana vaatler yalnızca doğrulanmış özellikler. Sürüm numarası ("0.2.0") yalnızca örnek.

### Play Store hazırlığı (2026-10-22, `6c524a5`)

`store/` klasöründe metinler, Veri güvenliği formu, izin denetimi (`izinler.md`), gizlilik politikası metinleri, `derleme-ve-imza.md` (targetSdk, 16 KB, R8, AAB, imza), grafikler ve sıralı kontrol listesi. Pil optimizasyonu izni kaldırıldı (`tools:node="remove"`, `shouldRequestBatteryOptimizationsOff: false`). Kalanlar PLAY_STORE_YAPILACAKLAR.md'de.

### Güvenlik denetimi (2026-10, `1c9437e`)

Çekirdek tasarım sağlam bulundu (TLS + parmak izi pini, sabit zamanlı PIN, hız sınırları, yerel ağ filtresi, handshake kapısı, ön-kimlik bayt bütçesi, Origin reddi, sıkıştırma kapalı); telefonun gönderdiği hiçbir metin PowerShell/Python/kabuğa girmiyor, yol gezinmesi ve komut enjeksiyonu yok. Düzeltilenler:

| # | Önem | Sorun | Düzeltme |
|---|---|---|---|
| 1 | Orta | TLS bitip HTTP isteği gelmeyen bağlantılar sınırsız tutulabiliyordu; sonsuz başlık ~1 MB bellek | `TlsHandshakeGate`: istek başı 10 sn ve 16 KB içinde; bekleyen bağlantı IP başına 16, toplam 128 |
| 2 | Orta | `LEFT_UP`/`MODE_ARROW`/`LASER_OFF` hız sınırsızdı; allowlist dışı komutlar sayılmıyordu | Bırakma komutlarına ayrı 30/sn bütçe; reddedilenler de sayılıyor; 300/sn üstü 4008 ile kesilir |
| 3 | Düşük | Önekli komut değerleri gevşekti (900 karakter yankı, `START_AT:0x10`, `+5`) | `RemoteCommands.isValid`: tam allowlist ya da önek + 1-9 rakam; reddedilen metin günlüğe yazılmıyor |
| 4 | Düşük | `redact` parola, sır, token, `Bearer` biçimlerini temizlemiyordu | `_secretWord`, `_bearer` (öne `\w*` konmadan; 100 KB girdiler <70 ms) |
| 5 | Düşük | `_failedAttempts` tablosu farklı /64'lerden büyüyebiliyordu | 1024 adresi aşınca eski kayıtlar unutulur |
| 6 | Düşük | Manifestte düz metin trafik açıkça kapalı değildi | `usesCleartextTraffic="false"` |
| 7 | Düşük | CI: checkout token'ı `.git/config`'te, `GH_TOKEN` bütün işe açık | `persist-credentials: false`, `GH_TOKEN` adım düzeyinde |

Raporun "yapılmadı" listesinden sonradan yapılanlar: Gradle sağlaması ve SHA sabitlemesi (2026-10-22, yukarıda), saatin hareketini ±2000'e sınırlama (`WearBridge.maxMove`, `495a119`). Kalanlar YAPILMAYANLAR.md'de.

### Kullanıcı denetimi (Play öncesi, 2026-10, `1c29419`)

- **Erişilebilirlik**: dokunma hedefleri 48 dp (`Pressable.minTarget`; `AppButton`, `AppSegmented`); TalkBack'in etiketleri iki kez okuması (`ExcludeSemantics`); zamanlayıcı düğmelerinin adları; `textMuted` kontrastı 4.5:1 (`inkTextMuted 686E91`, `paperTextMuted 8087A9`, `sunsetTextMuted 846B5C`) ve bunu bütün paletlerde denetleyen `palette_contrast_test.dart`; çizim aracı etiketleri.
- **Büyük yazı, küçük ekran, yatay, tablet taşmaları**: telefonda kontroller ve medya sekmesi, "PC bulunamadı" kutusu; PC'de durmuş panel, PIN kutuları, Ayarlar diyaloğu.
- **İlk çalıştırma ve hatalar**: kamera izni reddinde siyah ekran yerine `ScanErrorView`; "QuickRemote PC'yi indir" düğmesi; ham istisna metinleri yerine eylem öneren metinler; PC'de port hatası "8090-8099 portları kullanımda".
- **Hakkında**: telefonda ve PC'de sürüm, gizlilik notu, açık kaynak lisansları.
- Raporun "düzeltilmedi" listesinden sonradan yapılanlar: bildirim izni reddi notu (`NotificationDeniedHost`, 2026-10-22), saatin soluk metin renkleri (2026-10-22).

---

## 3. Denemeler

### Windows 11, telefonsuz (2026-10-22)

Windows 11 Home 26300, %125, tek monitör, PowerPoint 365 16.0.20430, WPS 12.1.0.29162, Chrome ve Edge 155. Telefonun yerine sunucuya bağlanan bir deneme istemcisi (TLS + PIN, komutlar, lazer kareleri, slayt resimleri), ekran görüntüleriyle bakıldı.

- `flutter build windows` ilk derlemede geçti (`laser_overlay.cpp`, mutex'li `main.cpp`, gdiplus, magnification).
- PowerPoint: Başlat, Sonraki/Önceki, not, siyah/beyaz ekran, Slayta git (COM `GotoSlide`), odak koruması; kalem, fosforlu kalem, Hepsini sil. Korumalı Görünüm'deki sunumda Başlat düzenlemeye geçip gösteriyi açtı (~4 sn).
- WPS 12.1 (`PresenterCom`): Başlat, Sonraki/Önceki, Slayta git, siyah ekran, kalem, NEXT/PREV'de mürekkep silme, lazer (Ctrl+A, Ctrl+R ile WPS'in kendi lazeri), Bitir.
- Mürekkep varken Bitir: "mürekkep saklansın mı?" sorusu "Kaydetme" ile geçildi, slaytta mürekkep kalmadı (iki programda).
- Dar pencere, güç tuşu, sunucu açık kartı, QR ve PIN düzgün. IP yoklaması, mDNS kaydı, sertifika yükleme çalışıyor.
- **Bulunup düzeltilenler** (`9b7a381`):
  - COM `Slide.Export` gösteri sırasında PowerPoint'in klavye odağını sıfırlıyordu; önizleme açıkken kumanda çalışmazdı. `PptController.restoreShowFocus`.
  - `Get-NetIPConfiguration` ~6 sn sürüyordu (sınır 5); START'tan sonraki durum 3-6 sn gecikiyordu. Varsayılan rotadan okunuyor (~50 ms), sunucu ~4-5 sn'de açılıyor.
  - Gösterinin siyah/beyaz ekranı bildirilmiyordu (telefona siyah resim gidiyordu). COM `View.State`; B/W'den sonraki 1,5 sn resim alınmıyor.
  - WPS'te Export Windows'ta da çalışıyor; yalnızca-PowerPoint koşulu kalktı.
  - Hiç sunum yokken START, WPS'in ana sayfasına F5 basıyordu; artık `START_FAILED`.
  - "Sorun bildir" tarayıcı yerine Belgeler klasörünü açıyordu (`explorer <uzun URL>`); `url_launcher`.
  - `wps_take_over_test.dart` (7 test) ve 3 Python köprü testi Windows'ta düşüyordu (Linux'a özgü); Windows'ta atlanıyor.
- PC Ayarlar'ının küçük bulguları (Lazer seçeneği "QuickRem…" diye kesiliyordu, "Kapat" düğmesi "Kapatınca tepsiye küçült"ün üstüne biniyordu): 2026-10-25'te ikisi de yok (440×760'ta gerçek fontlarla bakıldı).

### Windows Bluetooth denemesi (2026-10-25)

Soru: Telefon QuickRemote'un Bluetooth ekranı kapalıyken eşleştiyse Windows onu klavye olarak tanımıyor. HID hizmetini kapatıp açmak (`BluetoothSetServiceState`) Windows'a kayıtları yeniden okutur mu? Betik: `quick_remote_pc/tool/windows_bt_hid_trial.ps1` (`-ListOnly`, `-NoToggle`, `-Address` seçenekleri; çıktıyı `%TEMP%\quickremote-bt-deneme-<tarih>.txt`'e yazar).

| Soru | Sonuç |
|---|---|
| Windows sürümü | Windows 11 Home 10.0.26300 |
| Bluetooth adaptörü | Intel(R) Wireless Bluetooth(R) |
| ÖNCE: HID hizmeti kurulu mu? | Hayır; Aygıt Yöneticisi'nde "Bluetooth HID Aygıtı" var ama durumu Unknown (`CM_PROB_PHANTOM`) |
| ÖNCE: önbellekteki HID kaydı / telefondan taze okunan | 1 (QuickRemote) / 1 (telefonda Bluetooth ekranı açıkken) |
| DISABLE, normal PowerShell | `ERROR_NOT_FOUND` (hizmet kurulu olmadığı için) |
| ENABLE, normal PowerShell | tamam, erişim hatası yok |
| Yönetici PowerShell | gerekmedi |
| SONRA: HID hizmeti | betik hemen sonra "kurulu" okudu, ikinci çalıştırmada yine "kurulu değil": kalıcı olmadı, HID aygıtı hayalet kaldı |
| **Telefon klavye olarak çalıştı mı?** | **Hayır.** İki denemede de telefonun günlüğünde "refused the HID link" (~1 sn sonra düşüyor); uygulama "Bilgisayar telefonu klavye olarak kabul etmiyor" ekranını gösteriyor |

Galaxy S23 FE, QuickRemote 1000012. Önbellekte QuickRemote kaydı olduğu hâlde Windows reddediyor: sorun eksik kayıt değil, kurulmayan HID sürücüsü. **Kaldırıp yeniden eşleştirmek çalıştı**: telefonu Windows'tan kaldırıp QuickRemote'un Bluetooth ekranı açıkken Ayarlar → Cihaz ekle ile eşleştirince HID aygıtı "OK" oldu, telefon klavye olarak bağlandı. Programla eşleştirme (`BluetoothAuthenticateDeviceEx`) 1244 verdi; elle eşleştirme tek seferde çalıştı. Sonuç: uygulamanın bugünkü Windows talimatı doğru; yapılacak kod YAPILMAYANLAR.md'de. Betiğin günlüğü artık `%TEMP%`'e yazılıyor (`ad3566a`, 2026-10-26).

### Linux, telefon ve saat (2026-10-21)

Sonuçlar yukarıda özelliklerin altında ("Denendi" satırları). O gün bulunan ve düzeltilenler: katmanın tıklama almaması `a95c067`, tepsi menüsü `83004f7`, ortak ağ uyarısı `46e53b9`, tarayıcının arkada açılması `70fb0ef`, kısayolların kumandayı kapatması `8c4ceb7`, saatte metnin kesilmesi `30241cf`, WPS'in boş not kutusu `aea0996`, Devral'ın kaydetme sorusunu kapatması `7ea6356`, WPS PDF'te ok tuşları `463d0a5`.

---

## 4. Kararlar ve gerekçeler

### Katman (2026-10-20)

- Çalışan eski yollar kalır, katman eksik olan yerlere gelir: Otomatik'te PowerPoint ve WPS kendi lazerini kullanır. Spot ışığı ve büyüteç hiçbir programda yok, onları her yerde katman çizer. `overlay: true` "lazer ve mürekkep gösteri dışında da çalışır" demek; gösteri içinde siyah/beyaz ekran programın kendisinde.
- "Mürekkebi koru" ayarı katmanda da aynı ayar: mürekkep slayta göre saklanır.
- Linux yardımcısı C (GTK3 + cairo): Flutter Linux zaten GTK3 istiyor, Python (`python3-gi`) her dağıtımda yok. Ayrı süreç, çünkü aynı GTK süreci hem Wayland hem X11 arka ucu kullanamaz.
- Büyüteç yalnızca Windows'ta.
- Bilinen bedeller: mürekkep sunuma kaydedilmez (END zaten "At" diyordu); ekrana bağlıdır, içeriğe değil (slayt komutlarında ve yoklamada temizlenir); yalnızca sunum penceresi paylaşılırsa (Zoom, Teams) katman görünmez.
- İlk deneme (KDE Plasma 6.8, Wayland): şeffaf pencere panelin ve tam ekran pencerenin üstünde, spot ışığı karartması çalıştı, ekran görüntüsüne giriyor, Python ile tam yeniden çizimde 54-56 fps.

### Ekran resmi ve gizlilik (2026-10-20)

- Resim yalnızca projeksiyonda görünenden: gösteri penceresi ya da tam ekrandaki görüntüleyici; pencereli tarayıcı ve masaüstü asla; yalnızca önizlemeyi açmış telefonlara.
- KDE'de yerel Wayland pencereleri için KWin yolu ikinci adımda; GNOME'da portal kullanılmaz (her oturumda izin penceresi sunum sırasında kabul edilemez).

### `caps` neden PC'de (2026-10-20)

Kurallar program ve platforma göre değişiyor ve hepsi PC'de (köprü WPS'inde fosforlu kalemin odak şartı, Impress'in medya tetikleyicileri, kullanıcının WPS'inde Slayta git yok). Telefon tahmin etmez; bilinmeyen değeri yok sayar, yeni araçlar protokolü bozmadan eklenir.

### Saat teması (2026-10-20)

Yalnızca telefondan eşitleme ("Saatte de kullan", varsayılan açık ve öyle kalacak). Saatte ayrı seçici yok.

### Altyapı (2026-10-20)

- CI yalnızca değişen klasörlerde; `packages/` değişince ona bağlı her şey; etikette ve haftada bir hepsi.
- Windows: ilk sürüm imzasız (README'de SmartScreen "Ek bilgi → Yine de çalıştır"); ücretli sertifika alınmaz; imzalı yol sonra Microsoft Store'da MSIX.
- Linux: tar.gz + AUR + .deb ile başlandı (Pardus 23 Debian 12 tabanlı, CI'daki `debian:12` denemesi onu da büyük ölçüde kapsar). AppImage ve .rpm sonra. Flatpak yok: `/dev/uinput` için `--device=all`, `pkexec` ile udev kuralı yazılamaz, UNO borusu ana sistemin `/tmp`'sinde, ana sistemin `python3-uno`'su ve WPS içeride görünmez; hepsi `flatpak-spawn --host` ister, Flathub kabul etmez.
- Güncelleme denetimi varsayılan açık, yalnızca bildirir; kendi güncellemesi olan paketlerde derlemede kapalı. Kendiliğinden indirip kurma yok (önce imzalı paketler gerekir).
- Uzak çökme raporu yok; yerel günlük ve hazır GitHub issue bağlantısı yeterli.

### Windows Bluetooth (2026-10-20, sonucu 2026-10-25)

Önce yarım günlük bir deneme yapılacak, plan sonuca göre. Deneme olumsuz çıktı; "yeniden eşleştir" yolu kaldı (YAPILMAYANLAR.md).

### 2026-10-21 listesinin soruları (2026-10-22, karar bize bırakılınca)

- Chrome/Firefox PDF'te F5: Windows'ta hata yoktu; Linux'ta sebep KDE Wayland'deki yerel tarayıcıydı → KWin betiği.
- WPS PDF kaydırma: Windows'ta WPS 12'nin PDF sekmesi düzenleyici sanılıyordu → başlığında `.pdf` olan pencere PDF.
- Sunucu görünümünde lazer: mutlak konum (`LASER_ABS`).
- "Neler yapılabilir" ekranında "Denenmedi" etiketi konuldu.

### Slayt önizlemesinin görev tanımı (2026-10-20)

Yalnızca Wi-Fi modu (Bluetooth'ta bilgisayar telefona veri gönderemez), saat kapsam dışı. "DOĞRULANACAK" denen her şey gerçek programda denenecek, çalışmazsa o programda özellik kapalı kalacaktı (Windows WPS önce bu yüzden kapalıydı, 2026-10-22'de açıldı). Site güncellemesi proje sonuna bırakılmıştı, 2026-10-20'deki site yenilemesiyle yapıldı.
