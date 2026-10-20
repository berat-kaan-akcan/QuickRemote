# Bütün programlarda lazer ve kalem katmanı: inceleme raporu

Tarih: 2026-10-20. Durum: inceleme, deneme ve Aşama 1'in büyük kısmı yapıldı (aşağıda "Yapılanlar").

**Karar (2026-10-20):** Çalışan eski yollar kalır, katman yalnızca eksik olan yerlere gelir. PowerPoint ve WPS kendi lazerini kullanır; Impress, PDF, tarayıcı ve gösteri dışı pencereler katmanı kullanır. WPS gerekirse sonra katmana geçer.

## Özet

Fikir yapılabilir ve projeye iyi oturuyor. Önerim: yapalım, ama önce lazerle başlayalım, mürekkep ikinci adımda gelsin.

- **Linux (KDE Wayland)**: Bu makinede denedim. Şeffaf bir pencere bütün pencerelerin, panelin ve tam ekran bir pencerenin üstünde çizilebiliyor. Ekran görüntüsüne de giriyor (aşağıda "Deneme").
- **Windows**: Bilinen, yaygın bir yöntem var (katmanlı, tıklama geçiren, hep üstte duran pencere). Denenmedi.
- **Sunucu tarafında kancalar zaten var**: `InputService.handlesLaserPointer` / `laserPointerMoved` ve `handlesDrawPointer` / `drawPointerMoved`, Impress için yazılmıştı. Bunlar, imleci oynatmadan konumu bir çiziciye vermek için yapılmış. Kaplama aynı yere takılır; sunucunun hareket yolu neredeyse hiç değişmez.
- **Telefon için protokol değişikliği gerekmiyor**: Lazer, kalem, fosforlu kalem, silgi ve renkler bugünkü komutlarla çalışır. Yeni olanlar (spotlight, geri al, kalem kalınlığı) birkaç yeni komut ister.

## Deneme (bu makinede, KDE Plasma 6.8, Wayland, 1920×1080)

Dosya: `/tmp/claude-1000/-home-berat-Masa-st--QuickRemote/b56fb9e7-6563-486b-ad18-997cb02b08e8/scratchpad/overlay_probe.py`. Python + GTK3, XWayland üzerinden şu özelliklere sahip bir pencere açıyor:

- override-redirect: pencere yöneticisi pencereyi yönetmiyor, odak almıyor,
- ARGB görsel: şeffaf,
- boş giriş şekli (`input_shape_combine_region`): tıklamalar alttaki pencereye geçmeli,
- dönen bir lazer noktası; bir de spotlight modu var (ekran %60 kararıyor, bir daire açık kalıyor).

| Denenen | Sonuç |
|---|---|
| Normal pencerelerin ve panelin üstünde | Çalıştı |
| Tam ekran native Wayland penceresinin üstünde (sunum yerine) | Çalıştı |
| Şeffaflık, spotlight karartması | Çalıştı |
| Ekran görüntüsünde (spectacle) görünmesi | Görünüyor, yani ekran paylaşımına da girer |
| Hız (Python, her karede 1080p tam yeniden çizim) | 54-56 fps |
| Tıklamaların gerçekten geçmesi | **DOĞRULANACAK** (elle tıklanmadı) |
| Gerçek Impress gösterisi ve oynayan video üstünde | **DOĞRULANACAK** |
| GNOME (Mutter), wlroots, X11 oturumu | **DOĞRULANACAK** |
| Kesirli ölçekleme (%125 gibi) | **DOĞRULANACAK** (XWayland burada bulanık ya da yanlış boyutlu olabilir) |
| Windows | **DOĞRULANACAK** |

## Ne kazanırız

Fikirdeki maddeler, kodla karşılaştırarak:

| Fikir | Durum | Bugünkü kod |
|---|---|---|
| PDF görüntüleyicide ve tarayıcıda lazer ve kalem | Doğru. Bugün `_slideshowOnlyCommands` bunları gösteri dışında engelliyor. Kaplama tuşa basmadığı için bu engel kaplamada kalkabilir. | `websocket_server.dart` |
| Impress'te video üstüne çizim | Doğru. Video, gösterinin içinde ayrı bir pencerede oynuyor. Kaplama ise en üstte duran ayrı bir pencere. | CLAUDE.md'deki "A video plays in a native window above the slide" geçici çözümü (imleci video üstünde gerçek imleçle göstermek) gereksiz kalır |
| Impress'in kısayolu olmaması | Doğru. Bluetooth modunda ise değişen bir şey yok (orada PC uygulaması yok). | `bt_key_mapping.dart` |
| WPS'in Ctrl+A / Ctrl+R hileleri | Doğru, ikisi de kalkar. Bunlara bağlı odak koşulları da kalkar (`PptController.wpsLaser`, "unfocused bridge WPS gets the visible arrow"). | |
| Spotlight, büyüteç | Spotlight kolay, denemede çalıştı. Büyüteç zor (aşağıda). | |

Fikirde olmayan ama gelen kazançlar:

- **Gerçek saydam fosforlu kalem her yerde.** Impress'teki `PolyLineShape` çözümü ve LibreOffice 26.8 şartı gereksiz kalır. O çözüm slaydı yeniden çizdiriyor, animasyonları baştan başlatıyor ve `settle` beklemeleri istiyor.
- **Siyah/beyaz ekran her programda**: Kaplama tam ekranı boyar. Bugün PDF'te ve tarayıcıda yok.
- **Mürekkep slayta bağlı saklanabilir.** (deck, slayt) başına çizgi listesi tutulur. "Mürekkebi koru" açıksa slayta dönünce mürekkep geri gelir; bugün bu programdan programa değişiyor.
- **Geri al ve çizgi çizgi silgi**: Kendi çizgilerimizi tuttuğumuz için kolay.
- **Daha akıcı lazer.** Bugün Windows'ta lazer gerçek imleci 125 Hz'te oynatıyor. Kaplama araya ara konum ekleyip (interpolasyon) ekranın yenileme hızında çizebilir; bir de iz efekti olabilir.
- **Her yerde aynı görünüm**: Lazer rengi, boyutu ve kalem kalınlığı PowerPoint, Impress, WPS ve PDF'te aynı olur.
- **Gösteri dışında lazer**: Excel, kod demosu, web sitesi. Kaplama hiçbir tuşa basmadığı için güvenli.
- **Çoklu telefon**: Her telefona ayrı renkli bir lazer verilebilir. Bugün imleç tek olduğu için `_gestureOwner` ile tek telefona veriliyor; bu kural kaplamada lazer için gevşeyebilir.

## Neyi kaybederiz, riskler

1. **Mürekkep sunuma kaydedilmez.** PowerPoint'in "mürekkebi sakla" sorusu çıkmaz. Bugün de END bu soruya "At" diyor, yani pratikte kayıp yok.
2. **Mürekkep ekrana bağlıdır, içeriğe değil.** Slayt değişirse, PDF kayarsa ya da pencere kayarsa mürekkep yerinde kalır.
   - NEXT, PREV ve START_AT'te kaplamayı biz temizleriz.
   - Sunumcu slaytı klavyeyle değiştirirse yoklama (`state_broadcaster`) değişikliği görür ve temizleriz. Bu, yoklama süresi kadar gecikir.
   - PDF'te ve tarayıcıda slayt durumu yok; orada yalnızca telefonun NEXT/PREV'i temizler. Fareyle kaydırma mürekkebi kaydırmaz.
3. **Animasyonun bir adımı ya da bir geçiş** mürekkebi silmez. Bu çoğu zaman istenen davranış; programın kendi mürekkebi de böyle.
4. **Pencere paylaşımı**: Zoom ya da Teams'te yalnızca sunum penceresi paylaşılırsa kaplama görünmez. Tüm ekran paylaşılırsa görünür. Kullanıcıya söylenmeli; program kendi lazerine dönecek bir ayar da kalmalı.
5. **Çoklu monitör.** Kaplama, gösterinin olduğu monitöre açılmalı. Sunucu görünümünde gösteri ikinci ekrandadır.
   - Windows: `PptController._findShowWindow` gösteri penceresini zaten buluyor; `MonitorFromWindow` ile monitörü bulunur.
   - Linux: Impress köprüsü gösteri penceresinin X konumunu zaten veriyor. WPS gösterisi XWayland'de tam ekran bir pencere (`x11_windows.dart` görür).
   - PDF ve native Wayland pencerelerinin konumu XWayland'den görünmez; o durumda birincil monitöre ya da kullanıcının seçtiği monitöre açılır.
   - Bugün `LinuxMouseController` boyutu birincil ekrandan alıyor; bu da değişmeli.
6. **Hız, yüksek çözünürlükte.** Spotlight her karede tüm ekranı boyar. 4K'da yazılımla çizip XWayland'e ya da `UpdateLayeredWindow`'a yollamak kare başına ~33 MB eder; bu ağır.
   - Lazer ve mürekkepte yalnızca değişen bölge çizilir; sorun olmaz.
   - Spotlight için Windows'ta GPU yolu (DirectComposition + Direct2D) gerekir. Linux'ta önce ölçülmeli; spotlight 30 fps'e düşürülebilir.
7. **Hep üstte olma yarışı (Windows).** Başka bir "hep üstte" pencere (bildirim, ekran klavyesi) araya girebilir. Gösteri sürerken `SetWindowPos(HWND_TOPMOST)` arada bir yeniden çağrılmalı. Oyun gibi özel (exclusive) tam ekran uygulamaların üstüne çizilemez; sunum programları böyle çalışmıyor.
8. **GNOME.** Mutter, override-redirect X pencerelerini en üst katmanda tutar. Bu yüzden çalışması beklenir, ama denenmedi. GNOME layer-shell desteklemiyor; XWayland yolu orada tek yol.
9. **Büyüteç** ekranın görüntüsünü ister:
   - Windows'ta Magnification API (`MagSetWindowSource`) bunu verir; yapılabilir.
   - Linux Wayland'de ekran görüntüsü portal izni (xdg-desktop-portal ScreenCast) ister; her oturumda bir izin penceresi çıkar. XWayland'den native Wayland pencereleri görünmez.
   - Linux için yarım bir çözüm: Impress ve WPS'te zaten dışa aktardığımız slayt resmini (`exportSlide`) büyütmek. Bu resimde animasyon adımı ve video yok.
   - Büyüteci en sona bırakmayı öneriyorum.

## Platformlara göre teknik yol

### Windows

- Pencere, Flutter runner'ında (C++, `windows/runner/`) ayrı bir Win32 penceresi olarak açılır ve bir MethodChannel ile yönetilir. Uygulama zaten aynı süreçte; yardımcı bir sürece gerek yok.
- Pencere stilleri: `WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW`. Bunlar sırasıyla şeffaflık, tıklamanın geçmesi, hep üstte olma, odak almama ve görev çubuğunda görünmeme içindir.
- Odak almaması önemli: `pressInSlideShow` tuşları odaktaki gösteriye basıyor; kaplama odağı çalarsa bu bozulur.
- Çizim için iki yol:
  - İlk sürüm: `UpdateLayeredWindow` ile piksel başına alfa.
  - Spotlight için: `WS_EX_NOREDIRECTIONBITMAP` + DirectComposition + Direct2D (GPU).
- DPI: Kaplama, gösterinin monitörünün fiziksel piksellerinde çizer. Runner'ın manifest'inde per-monitor v2 olduğu kontrol edilmeli.
- PowerPoint'te video zaten slayt penceresinde çiziliyor. Video sorunu orada yoktu; kazanç PDF, tarayıcı ve WPS'te.

### Linux

- **Önerilen**: Ayrı küçük bir yardımcı süreç; `GDK_BACKEND=x11` ile XWayland'de override-redirect bir pencere açar. Denemedeki yöntem budur.
  - Neden ayrı süreç: Flutter'ın penceresi Wayland'de açılıyor. Aynı GTK süreci hem Wayland hem X11 arka ucu kullanamaz.
  - Tek bir kod yolu X11 oturumunu, KDE Wayland'i, GNOME Wayland'i ve wlroots'u (XWayland varsa) kapsar.
- Yardımcı süreci **C ile (GTK3 + cairo)** yazıp Linux runner'ının CMake'iyle derlemeyi ve uygulamanın yanına koymayı öneriyorum.
  - Flutter Linux zaten GTK3 istiyor; yeni bir bağımlılık gelmez.
  - Python + GTK (`python3-gi`) prototip için iyi, ama her dağıtımda kurulu değil.
- Konuşma yolu, köprülerdeki gibi stdin/stdout üzerinden JSON satırları. `ScriptBridge` yeniden kullanılır. Hareketler sık geldiği için `pointer` güncellemelerinde Impress köprüsündeki gibi yalnızca en yenisi uygulanır.
- **İleride**: KWin ve wlroots'ta `zwlr_layer_shell_v1` (bu makinede var) "overlay" katmanı. Kesirli ölçeklemede keskin görüntü verir. XWayland yolu %125 gibi ölçeklerde bulanık kalırsa buna geçilir. GNOME'da bu yol yok.

## Sunucuya nasıl takılır

- Yeni bir `OverlayInputService`, platformun `InputService`'ini sarar (dekoratör):
  - `modeLaser`, `modePen`, `modeHighlighter`, `modeEraser`, `eraseAll`, `laserOff`, renk komutları, siyah/beyaz ekran kaplamaya gider.
  - Geri kalan komutlar (NEXT, START, ses, medya) olduğu gibi alttaki servise gider.
  - `handlesLaserPointer` ve `handlesDrawPointer` her zaman `true` olur. Böylece `_applyMove` imleci oynatmaz, yalnızca konumu izler (`trackDelta`); bu yol Impress için zaten var.
  - LEFT_DOWN / LEFT_UP çizgi başı ve sonu olur; işletim sistemine fare tuşu basılmaz. Böylece kalem modunda yanlışlıkla bir şeye tıklama riski de kalkar.
- NEXT, PREV ve START_AT'te ve `SLIDE_STATE`'te slayt ya da deck değişince mürekkep temizlenir (ya da "mürekkebi koru" açıksa saklanır).
- `_slideshowOnlyCommands` kuralı kaplama açıkken yalnızca lazer, kalem ve spotlight için gevşer. Bunlar tuş basmadığı için güvenli. ERASE_ALL'u ve siyah/beyazı kaplama yaptığı sürece onlar da gevşeyebilir.
- PC ayarı (Ayarlar penceresi), üç seçenek:
  - "Lazer ve kalemi QuickRemote çizsin": Her zaman / Programın kendi aracını kullan / Otomatik.
  - Otomatik: Impress, PDF, tarayıcı ve gösteri dışında kaplama; PowerPoint ve WPS'te kendi aracı (2026-10-20 kararı).
  - Bu sayede kaplama bozuk çıkan bir ortamda kapatılabilir.

## Protokol ve telefon

- `auth` cevabına `overlay: true` eklenir.
  - Telefon bunu görünce araçları gösteri dışında da açık tutar. Bugün gösteri yokken soluklaştırıyor; saat de öyle.
  - Telefon yeni araçları da yalnızca bu bayrak gelince gösterir.
  - Eski telefonlar bir şey fark etmez.
- Yeni komutlar (önce `remote_commands.dart`, sonra yönlendirici ve `InputService`, CLAUDE.md'deki sırayla):

| Komut | Ne yapar |
|---|---|
| `MODE_SPOTLIGHT` | Spotlight; hareket LASER frame'leriyle gelir |
| `UNDO_INK` | Son çizgiyi geri alır |
| `SET_PEN_WIDTH:n` (prefix) | Kalem kalınlığı |
| `SET_LASER_STYLE:...` (prefix, isteğe bağlı) | Lazer rengi, boyutu, izi |
| `MODE_ZOOM` (son aşama) | Büyüteç |

- Saat: Lazer zaten telefon üzerinden gidiyor; değişmeden kaplamayı kullanır. Saatteki "yalnızca gösteri sırasında" uyarısı, telefon `overlay` bayrağını saate geçirirse kalkar (`/quickremote/state`'e bir alan).
- Bluetooth HID modu: Değişmez. PC'de uygulama yok, kaplama da yok.
- Site: Lazer ve kalem bölümü "her programda" diye güncellenmeli (site işleri şimdilik ertelendi).

## Aşamalı plan

Süreler kaba tahmin, tek kişi.

| Aşama | İçerik | Tahmin |
|---|---|---|
| 1 | Linux yardımcı süreci (C), yalnızca lazer. `OverlayInputService`, PC ayarı, gösterinin monitörünü bulma. Gerçek Impress ve PDF'te deneme; video üstü, tıklama geçişi ve kesirli ölçek dahil. WPS denemesi yok, WPS eski yolda. | 2-3 gün |
| 2 | Windows penceresi (runner C++), lazer. Yalnızca tarayıcı PDF'inde ve gösteri dışında; PowerPoint ve WPS eski yolda. | 2-3 gün |
| 3 | Kalem, fosforlu kalem, silgi, ERASE_ALL, slayta göre saklama, geri al: Impress, PDF ve tarayıcıda. Telefonda araçlar gösteri dışında açık. | 4-5 gün |
| 4 | Spotlight (Windows'ta GPU yolu), siyah/beyaz ekranın PDF ve tarayıcıda kaplamaya taşınması, lazer stili. | 3 gün |
| 5 | Büyüteç: Windows'ta Magnification API; Linux'ta yok. | 3+ gün |
| Sonra, gerekirse | WPS'i katmana geçirmek (Linux'ta odakta olmayan köprü WPS'i gibi tek tek durumlarla başlanabilir). | |

Aşama 1'den sonra kaplamanın hissini (gecikme, akıcılık) gerçek bir sunumda görüp devam kararı vermek mantıklı.

## Sorular ve önerilerim (2026-10-20)

1. **Varsayılan**: Kaplama "Otomatik" mi başlasın, yoksa ilk sürümde isteğe bağlı mı olsun?
   - **Karar: Otomatik.** Impress, PDF, tarayıcı ve gösteri dışında kaplama çizer. PowerPoint ve WPS'te kendi aracı kalır; ikisinde de lazer çalışıyor.
   - Ayarlar'da "Her zaman" ve "Programın kendi aracı" seçenekleri de olur.
2. **Mürekkep ve "mürekkebi koru" ayarı**: Kaplamada slayta göre saklama, bugünkü ayarın yerine mi geçsin?
   - **Önerim: Evet, aynı ayar.** Kaplamada anlamı şu olur: mürekkep slayta göre saklanır ve slayta dönünce geri gelir. Ayar kapalıysa slayt değişince silinir.
3. **Linux yardımcı dili**: C (yeni bağımlılık yok) mu, Python (hızlı yazılır, `python3-gi` gerekir) mu?
   - **Önerim: C (GTK3 + cairo).** Python yalnızca deneme ve prototip için kalır.
4. **Büyüteç**: Linux'ta düzgün yapılamıyor. Yalnızca Windows'ta olsun mu, yoksa hiç olmasın mı?
   - **Önerim: Yalnızca Windows'ta ve en son aşamada.** Linux'ta yapılmaz. Dışa aktarılan slayt resmini büyütmek ekranda olandan farklı bir şey gösterir; kafa karıştırır.

## Yapılanlar (2026-10-20)

Bütün aşamaların kodu yazıldı. Ekran gerektiren denemeler yapılmadı; aşağıdaki listede bekliyor.

| Aşama | Yapılan | Durum |
|---|---|---|
| 1 | Linux katmanı (`linux/overlay/laser_overlay.cc`, GTK3 + cairo, ayrı süreç), `OverlayInputService`, PC'de Ayarlar → Lazer (Otomatik / QuickRemote / Program), gösterinin monitörü (Impress'in bildirdiği pencere, yoksa odaktaki X11 penceresi), ayar değişince telefona `OVERLAY` mesajı, saatte `laserAnywhere` | Birim testleri geçiyor; yardımcı bu makinede ekranda denendi (nokta görünüyor, iz bırakmıyor) |
| 2 | Windows katmanı (`windows/runner/laser_overlay.cpp`): nokta boyunda, lazerle taşınan katmanlı pencere; Dart'tan kanal | **Windows'ta hiç derlenmedi**; yalnızca clang ve sahte başlıklarla söz dizimi kontrol edildi |
| 3 | Kalem, fosforlu kalem, silgi (dokunduğu çizgiyi siler), ERASE_ALL, "mürekkebi koru" açıksa slayta göre saklama, PDF'te NEXT/PREV ile silme. Çizgiler Dart'ta tutuluyor. Windows'ta GDI+ ile monitör boyunda bir pencere. | Birim testleri geçiyor; Windows aynı durumda |
| 4 | `MODE_SPOTLIGHT` (spot ışığı), `UNDO_INK` (geri al), gösteri dışında siyah/beyaz ekranın katmanla yapılması. Telefonda lazer tuşuna ikinci dokunuş tür seçimini açıyor; Temizle'yi basılı tutmak geri alıyor. | Birim testleri geçiyor |
| 5 | `MODE_ZOOM` (büyüteç), yalnızca Windows (Magnification API); auth'ta `zoom`; telefonda üçüncü lazer türü | Windows'ta derlenmedi |

Kararlar:
- Otomatik'te PowerPoint ve WPS kendi lazerini ve kalemini kullanır. Spot ışığı ve büyüteç hiçbir programda yok; onları her yerde katman çizer.
- `overlay: true`, "lazer ve mürekkep gösteri dışında da çalışır" anlamına geliyor. Siyah/beyaz ekran gösteri içindeyken programın kendisinde kalıyor.
- Bulunan hata: `gtk_init` kullanıcının dilini yüklüyor; Türkçe'de `sscanf` "0.5"i 0 okuyordu. Yardımcı artık `g_ascii_strtod` kullanıyor.

### Bekleyen denemeler (ekran ve cihaz gerekiyor)

Linux (bu makine; başlamadan ekranın boş olduğundan emin olunmalı):
1. Impress gösterisi: lazer slaytın ve oynayan videonun üstünde görünüyor mu (`~/Masaüstü/LibreOffice Impress (gömülü video).odp`).
2. Tıklama geçişi: lazer ya da mürekkep açıkken yapılan bir tık slaytı ilerletiyor mu.
3. Chrome'da tam ekran PDF: lazer, kalem, silgi, spot ışığı ve siyah ekran gösteri olmadan çalışıyor mu.
4. Kalem ve fosforlu kalem: çizgi akıcı mı, fosforlu kalem kendi üstünden geçince koyulaşmıyor mu, slayt değişince siliniyor mu, "mürekkebi koru" açıkken geri geliyor mu.
5. Spot ışığı: hız (1080p'de yalnızca değişen bölge çiziliyor) ve görünüş.
6. İki monitör: katman gösterinin olduğu monitörde açılıyor mu.
7. Kesirli ölçek (%125) ve GNOME.

Telefon ve saat:
8. Telefon uygulamasını yeniden derleyip kurmak (`WearRelay.kt` değişti, henüz derlenmedi). Dokunmatik alan gösteri olmadan da çalışıyor mu; lazer türü seçimi; Temizle'yi basılı tutunca geri alma.
9. Saat: gösteri yokken lazer düğmesi açık mı, lazer çalışıyor mu.

Windows (senin makinen):
10. `flutter build windows`: yeni C++ dosyası, `gdiplus.lib` ve `magnification.lib` ile derleniyor mu.
11. Tarayıcıda PDF'te ve gösteri dışında lazer; Ayarlar'da QuickRemote seçiliyken PowerPoint'te lazer.
12. Mürekkep, spot ışığı, büyüteç; pencereler odak almıyor mu (gösteriye tuşlar gitmeye devam ediyor mu), tıklamalar geçiyor mu.
13. DPI %125/150 ve iki monitör.

Diğer açık noktalar:
- Saat, gösteri dışında siyah/beyaz ekranı hâlâ soluk gösteriyor (saat siyah/beyaz için ayrı bir bayrak almıyor).
- Siyah ekran açıkken katmanın mürekkebi görünmüyor: katmanın kendi siyah ekranı mürekkebin üstünde; programın siyah ekranında ise mürekkep, slayt durumu bunu bildirince gizleniyor ve ekran geri gelince yeniden çiziliyor (yoklama süresi kadar gecikmeyle).
