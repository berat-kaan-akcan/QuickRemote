# PowerPoint for the web (tarayıcıda PowerPoint) desteği: plan

Tarih: 2026-10-26. Durum: Aşama 1, 2, 3 ve 5 yazıldı ve birim testlerinden geçti (Google Slaytlar da); Aşama 0'ın gerçek tarayıcıdaki denemesi ve Aşama 4 kaldı. Hiçbir şey gerçek bir PowerPoint/Google Slaytlar sayfasında denenmedi.

## Yapılanlar (2026-10-26)

- Paylaşılan paket: `WebPresenters` (`powerpointWeb`, `googleSlides`), `PresenterCaps.site` (SLIDE_STATE'te `site`; eski telefonlar yok sayar).
- PC: `PdfViewers.webPresenterOf` başlığın sayfa kısmının son parçasına bakar (tarayıcı adı, Edge'in profil adı, "ve diğer N sayfa" ve görünmez U+200B atılır; ilk parça asla sayılmaz). Chrome ve Edge'in başlık eki bu makinede ölçüldü: `Sayfa - Google Chrome`, `Sayfa ve diğer 1 sayfa - Kişisel - Microsoft Edge`. PowerPoint'in kendi sayfa başlığı ("Sunu1.pptx - PowerPoint" varsayıldı) görülmedi. İki site de Ctrl+F5 / Esc / oklar; Google Slaytlar'da START_AT tam ekran beklenip numara + Enter (Windows `PptController._jumpInViewer`, Linux `LinuxInputService._jumpInViewer`). Lazer, mürekkep, siyah/beyaz ekran QuickRemote'un katmanından (değişiklik gerekmedi).
- Telefon: `ShowInfo.site` / `startsFullScreen`; başlıkta site adı, "Tam ekran" yerine "Başlat", bilgi satırı `siteInFront`, Google Slaytlar'da "Slayta git". "Neler yapılabilir?" tablosunda iki program (karşılaştırma görünümünde yer olmadığı için yok, hepsi "denenmedi").
- Bluetooth: `BtTarget.powerpointWeb` (Ctrl+F5, Esc, PageDown/PageUp; lazer imleç, siyah ekran ve mürekkep yok) ve `BtTarget.googleSlides` (Ctrl+F5, Esc, oklar, B/W, lazer L ile aç/kapa).
- CLAUDE.md, site (`programs.html`, `status.html`).

Gerçek denemeler: aşağıdaki **6. Deneme listesi**. En önemli iki soru: PowerPoint'in sayfa başlığı ne, ve programın bastığı Ctrl+F5 sayfayı yenilemeden sunuyu açıyor mu.

Ücretsiz Microsoft hesabıyla PowerPoint, tarayıcıda (powerpoint.cloud.microsoft / office.com) açılıyor; masaüstü PowerPoint'i olmayan biri sunumu oradan yapabilir. Bugün QuickRemote bu pencereyi yalnızca "tarayıcı" sanıyor ve PDF gibi davranıyor: START F11 basıyor (tam ekran olur ama gösteri başlamaz), NEXT/PREV oklar (bu çalışır), END yalnızca F11'i geri alır, Esc basmaz.

## 1. Araştırma: PowerPoint for the web'in sunum kısayolları

Microsoft'un resmî tablosu ("Use keyboard shortcuts to deliver PowerPoint presentations", PowerPoint for the web sekmesi, Windows):

| İş | Tuş |
|---|---|
| Baştan başlat | **Ctrl+F5** (düz F5 tarayıcıda sayfayı yeniler) |
| Geçerli slayttan başlat | **Ctrl+Shift+F5** |
| Sonraki animasyon/slayt | N, Enter, PageDown, Sağ ok, Aşağı ok, Boşluk |
| Önceki animasyon/slayt | P, PageUp, Sol ok, Yukarı ok, Backspace |
| Gösteriyi bitir | Esc |

Tabloda **olmayanlar**: slayt numarası + Enter ile atlama, B/W (siyah/beyaz ekran), lazer, kalem, silgi, sunucu görünümü kısayolu. Bir bağımsız test (DEV Community, 2025) numara+Enter ile B/W'nin tarayıcıda hiçbir şey yapmadığını yazıyor. Lazer ve mürekkep için web'de güvenilir bir kaynak bulunamadı (blogların bir kısmı "tam ekranda lazer var" diyor, adım vermiyor; Ctrl+L/Ctrl+P masaüstü kısayolları, web'de doğrulanmadı). Sunucu görünümü web'de var gibi görünüyor (Slayt Gösterisi sekmesinde, yeni bir tarayıcı penceresi açıyor; bir üniversite yardım sayfasına göre), ama kaynaklar çelişkili.

Gösteri, tarayıcının Fullscreen API'siyle aynı sekmede tam ekrana geçer (F11 tam ekranı değil); Esc hem gösteriyi hem tam ekranı kapatır.

Kaynaklar: [Microsoft: deliver presentations](https://support.microsoft.com/en-us/accessibility/powerpoint/use-keyboard-shortcuts-to-deliver-powerpoint-presentations), [DEV: shortcuts that actually work](https://dev.to/hodadak_official/powerpoint-for-the-web-slideshow-shortcuts-that-actually-work-2mcg), [Microsoft: Play a slide show](https://support.microsoft.com/en-us/powerpoint/present-your-slide-show), [Presenter View in PowerPoint Web](https://help.usa.edu/hc/en-us/articles/30570772495511-Presenter-View-in-PowerPoint-Web).

## 2. Ne yapılabilir, ne yapılamaz

- **Klavyeyle olur:** başlat (Ctrl+F5 / Ctrl+Shift+F5), ileri/geri, bitir.
- **Overlay ile olur (zaten var):** lazer, spot ışığı, büyüteç (Windows), kalem, vurgulayıcı, geri al, siyah/beyaz ekran. Ayar Otomatik'teyken tarayıcıda zaten overlay çiziyor; QuickRemote bu gösteriyi "gösteri" olarak bilmediği için siyah/beyaz da overlay'den gelir. Yani bu kısım bedava.
- **Ekran görüntüsü önizlemesi (zaten var):** tam ekran tarayıcı penceresi `captureScreen` ile alınıyor, telefona kind 3 gider.
- **Olmaz (şimdilik):** slayt numarası, toplam, notlar, sonraki slayt resmi, küçük resimler, "slayta git". COM yok; sayfanın içini okumanın tek yolu UI Automation (aşağıda Aşama 4) ya da bir tarayıcı eklentisi.
- **Risk:** Ctrl+F5, PowerPoint sayfası yakalamazsa (odak adres çubuğundaysa, sekme başka bir sayfaysa) tarayıcıda **önbelleksiz yeniden yükleme**dir. PowerPoint web kendini otomatik kaydeder ama kullanıcı sayfanın yenilendiğini görür. Bu yüzden tuş yalnızca ön penceredeki sekme kesin PowerPoint ise basılmalı.

## 3. Aşamalar

### Aşama 0: ölçüm (Windows 11, Edge ve Chrome; sonra Firefox)

Kod yazıldıktan sonra da geçerli; adım adım hâli **6. Deneme listesi**'nde. Bakılacaklar:

1. Pencere başlığı: düzenleyicide ve gösteride ne yazıyor? (Tahmin: `Sunu1.pptx - PowerPoint - Microsoft Edge` gibi; Türkçe arayüzde ve kişisel/iş hesabında farklı olabilir. Gösteride başlık değişiyor mu?)
2. Ctrl+F5 ve Ctrl+Shift+F5 `SendInput` ile basılınca gösteri başlıyor mu, yoksa sayfa mı yenileniyor? Odak slayt panelindeyken, notlar kutusundayken, şeritteyken ayrı ayrı.
3. Gösteride oklar, PageDown, Esc. Esc bir kerede çıkıyor mu?
4. B, W, `.`, `,`, numara+Enter, Home/End: bir şey yapıyor mu?
5. Gösteride lazer/kalem için araç çubuğu var mı, kısayolu var mı (Ctrl+L, Ctrl+P, Ctrl+I, E, Ctrl+A)?
6. Gösteri penceresi tam ekranı kaplıyor mu (`captureScreen` alır mı), overlay tarayıcının tam ekranının üstünde kalıyor mu?
7. Sunucu görünümü: yeni pencere mi açıyor, başlığı ne, hangi pencereye tuş gitmeli?
8. Linux'ta (Firefox/Chrome, X11 ve XWayland) aynı başlık `_NET_WM_NAME` ile okunuyor mu.

### Aşama 1: PC, tanıma ve tuşlar (asıl iş, küçük)

- `pdf_viewers.dart`: `windowsProgram` WPS PDF'i başlıktan ayırdığı gibi, başlığında PowerPoint işareti olan bir tarayıcı penceresini `pptweb` (ad tartışılır) olarak adlandırır. Linux'ta `linux_input_service.dart` tarayıcının başlığını `X11Windows`'un başlık okuyucusundan alıp aynı işlevden geçirir. Başlık kalıbı Aşama 0'dan gelir; Türkçe/İngilizce iki kalıp da test edilir.
- Yeni `ViewerKeys pptWeb`: `start: [Ctrl, F5]`, `end: [Esc]` (F11 değil), `next: [Right]`, `prev: [Left]`. END'de `_toggled` kuralı burada da geçerli: Esc yalnızca START'ın basıldığı pencereye.
- START'ın geçerli slayttan başlaması istenirse Ctrl+Shift+F5 (masaüstü PowerPoint F5 ile baştan başlıyor; tutarlılık için baştan önerilir).
- `kindOf`: `FrontWindow.browser` kalır, ama yeni bir `presenter` değeri `powerpointWeb` (shared package) önde gösterilir; yeni telefonlar ad olarak "PowerPoint (web)" yazar, eski telefonlar bilinmeyen değeri yok sayar (kontrol edilecek: `PresentationState`'in bilinmeyen `presenter`'a tepkisi).
- `capabilities()`: `caps` içinde gösteri araçları programdan değil overlay'den (OverlayInputService zaten ekliyor); `canJump`, notlar, önizleme dışı.
- Testler: `pdf_viewers` için başlık eşleme testleri (Edge, Chrome, Firefox, Türkçe/İngilizce, PDF başlığı karışmasın, `PowerPoint` geçen ama PowerPoint olmayan bir sayfa, örneğin bir blog yazısı başlığı, yanlış eşleşmesin: kalıp başlığın sonuna bağlanmalı).

### Aşama 2: telefon ve saat

- `ShowInfo`: `front: browser` + `presenter: powerpointWeb` iken "Tam ekran" yerine "Sunuyu başlat" yazısı, kırmızı uyarı yerine bilgi satırı ("Tarayıcıda PowerPoint: slayt numarası görünmez").
- `capability_table.dart` ("Neler yapılabilir?"): yeni satır, PowerPoint (web): ileri/geri/başlat/bitir çalışır; lazer ve mürekkep QuickRemote'un overlay'iyle; slayta git, notlar, önizleme yok.
- ARB: yeni metinler `app_tr.arb` ve `app_en.arb`'ye.
- Saat: değişiklik yok (`viewer` alanı zaten var; başlat düğmesi slayt düğmelerine geçer).

### Aşama 3: Bluetooth HID modu

PC uygulaması olmadan da yapılabilir: `BtTarget`'a `powerpointWeb` eklenir (`bt_key_mapping.dart`): START Ctrl+F5, END Esc, oklar; lazer/kalem/siyah ekran yok (BT'de overlay yok), araç çubuğu bunları gizler. `BtProgramSheet`'e dördüncü seçenek. Bugün BT'de "PowerPoint" seçen biri tarayıcıda F5 basar ve sayfayı yeniler: bu aşama tek başına bile değerli.

### Aşama 4 (isteğe bağlı, sonra): slayt numarası

- Windows: UI Automation ile tarayıcının erişilebilirlik ağacından gösterinin "Slayt 3 / 12" benzeri metnini okumak (Edge ve Chrome ağacı UIA'ya açıyor). Mümkünse `SLIDE_STATE`'e `current/total` ve "slayta git" gelir; olmazsa vazgeçilir. Önce Aşama 0'da Accessibility Insights/Inspect ile ağaçta böyle bir metin var mı bakılır.
- Alternatif: bir tarayıcı eklentisi (yerel WebSocket). Kurulum yükü ve mağaza süreci yüzünden önerilmez.

### Aşama 5: site ve belgeler

- `CLAUDE.md` PDF paragrafına PowerPoint web eklenir (ölçülen sürümler ve başlık kalıbıyla).
- Site: `site/tools/parts/` içinde desteklenen programlar listesine "PowerPoint (web)", "Neyi denedik" bölümüne denenen tarayıcılar; `build_pages.py` ile üret.

## 4. Bonus: Google Slides

Google Slides da tarayıcıda Ctrl+F5 ile sunar (kaynaklara göre Ctrl+F5 geçerli slayttan, Ctrl+Shift+F5 baştan; doğrulanmadı), oklar ve Esc aynı. Başlığı "… - Google Slaytlar". Aşama 1'deki başlık eşleme bir kalıp listesi olursa aynı iş Google Slides'ı da kapsar; Aşama 0'a bir satır eklenebilir.

## 5. Önerilen sıra

Aşama 0 (yarım saat, bu makinede) → Aşama 3 (BT, en riskli mevcut hata) → Aşama 1 → Aşama 2 → Aşama 5. Aşama 4 yalnızca Aşama 0'da UIA ağacında slayt numarası görülürse.

## 6. Deneme listesi

Her denemenin "Sonuç" sütununa ✅ / ❌ / ⚠️ ve kısa bir not yazılır. Bir deneme ❌ çıkarsa "Yanlışsa" sütunu düzeltmenin nereye gideceğini söyler. Denemeler bitince CLAUDE.md'deki "not tried" sözleri, `capability_table.dart`'taki "Denenmedi" işaretleri ve sitedeki "henüz denenmedi" satırları sonuca göre güncellenir.

### Hazırlık

- Windows 11 bilgisayar: QuickRemote PC'nin bu daldan bir derlemesi (`flutter run -d windows` ya da kurulum paketi), sunucu açık.
- Telefon: bu daldan derlenmiş uygulama, PC'ye Wi-Fi ile bağlı. Bluetooth denemeleri için Bluetooth uzaktan kumanda modu.
- Tarayıcılar: **Edge** (ilk), **Chrome**, mümkünse **Firefox**.
- Hesaplar: ücretsiz bir Microsoft hesabıyla OneDrive'da açılmış, **en az 12 slaytlı** bir sunu (PowerPoint web); bir Google hesabıyla en az 12 slaytlı bir Google Slaytlar sunusu. Slaytların üstünde büyük numara olması sonuçları okumayı kolaylaştırır.
- Pencere başlıklarını okumak için (PowerShell):

  ```powershell
  Get-Process msedge,chrome,firefox -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle } |
    ForEach-Object { "$($_.ProcessName): $($_.MainWindowTitle)" }
  ```

- PC günlüğü: Ayarlar → Sorun giderme → Günlüğü dışa aktar (START_AT'in "the show did not come up in full screen" satırı oraya düşer).
- Telefon güvenliği: denemede bankacılık vb. bildirimler kapalı olsun (bildirim, dokunuşun üstüne düşebiliyor).

### A. Tanıma (Windows)

| # | Adım | Beklenen | Sonuç | Yanlışsa |
|---|---|---|---|---|
| A1 | Edge'de PowerPoint web düzenleyicisini aç, yukarıdaki PowerShell ile başlığı oku. Başlığı buraya **olduğu gibi** yaz. | Sayfa kısmı "PowerPoint" ile bitiyor, ör. `Sunu1.pptx - PowerPoint - Kişisel - Microsoft Edge` | | `PdfViewers._siteNames` / `webPresenterOf`, `pdf_viewers_test.dart`'a gerçek başlığı ekle |
| A2 | Aynı sunuda gösteriyi elle başlat (Ctrl+F5), başlığı tekrar oku. | Başlık aynı ya da yine "PowerPoint" ile bitiyor | | Aynı yer |
| A3 | A1-A2'yi Chrome'da yap. | Sonu `- PowerPoint - Google Chrome` | | Aynı yer |
| A4 | Google Slaytlar düzenleyicisi ve sunusu, Edge ve Chrome'da başlıklar. | Sayfa kısmı "Google Slaytlar" (Türkçe arayüz) ya da "Google Slides" ile bitiyor | | Aynı yer |
| A5 | PowerPoint web açıkken telefondaki kumandaya bak. | Üst satır "PowerPoint (web)", bilgi satırı "PowerPoint (web) açık · Başlat sunuyu açar, slayt numarası görünmez", düğme "Başlat" (Tam ekran değil) | | A1'e dön; o doğruysa `ShowInfo.site`, `capabilities()` |
| A6 | Google Slaytlar açıkken aynı bakış. | "Google Slides" adı, "Başlat" düğmesi, **Slayta git** düğmesi görünüyor | | Aynı |
| A7 | Tarayıcıda sunu olmayan bir sekmeye geç (ör. "PowerPoint - Vikipedi", YouTube, Google'da "powerpoint" araması). | Telefon "Tarayıcı" der, düğme "Tam ekran"; site adı **görünmez** | | `webPresenterOf` fazla geniş: kalıbı daralt, teste ekle |
| A8 | Sekmeyi değiştir (sunu ↔ başka sayfa) ve telefona bak. | Telefon 2-4 saniye içinde yeni duruma geçiyor | | `StateBroadcaster` atlama turları |

### B. PowerPoint web, Wi-Fi (Windows, Edge sonra Chrome)

| # | Adım | Beklenen | Sonuç | Yanlışsa |
|---|---|---|---|---|
| B1 | Düzenleyici önde, odak slayt panelindeyken telefondan **Başlat**. | Gösteri 1. slayttan tam ekranda açılır; sayfa **yenilenmez** | | Yenileniyorsa: Ctrl+F5 sayfaya ulaşmıyor. Ctrl+Shift+F5'i ya da önce sayfaya odak vermeyi dene |
| B2 | B1'i odak **notlar kutusunda** ve **şeritte** (bir sekmeye tıklanmış) iken tekrarla. | Yine gösteri açılır | | Aynı |
| B3 | Odak **adres çubuğundayken** Başlat. | Bilinen risk: sayfa yenilenebilir. Ne olduğunu yaz | | Gerekirse Başlat'tan önce Esc / F6 ile odağı sayfaya ver |
| B4 | Gösteride **Sonraki** ×3, **Önceki** ×1. | 1→2→3→4, sonra 3 | | `ViewerKeys.next/prev` (oklar yerine PageDown dene) |
| B5 | Animasyonlu bir slaytta Sonraki. | Önce animasyon adımı, sonra slayt (masaüstündeki gibi) | | Bilgi için yaz |
| B6 | **Bitir**. | Gösteri kapanır, düzenleyiciye dönülür; tek Esc yeter | | `PptController.slideEnd` |
| B7 | Gösteride Bitir'e iki kez bas. | İkinci Esc düzenleyicide zararsız | | |
| B8 | Telefonda Slayta git düğmesi. | PowerPoint web'de **görünmez** | | `ShowInfo.canJump`, `main_controls_view.dart` |
| B9 | Masaüstü PowerPoint de açıkken (gösterisiz) tarayıcı önde, Başlat. | Tarayıcıdaki sunu başlar, masaüstü PowerPoint öne **gelmez** | | `slideStart`'ın sırası |

### C. Google Slaytlar, Wi-Fi (Windows, Edge sonra Chrome)

| # | Adım | Beklenen | Sonuç | Yanlışsa |
|---|---|---|---|---|
| C1 | Düzenleyici önde, 3. slayt seçili, telefondan **Başlat**. | Sunu tam ekranda **3. slayttan** açılır (Google'da Ctrl+F5 geçerli slayttan sunar); sayfa yenilenmez | | Yenileniyorsa B1'deki gibi |
| C2 | Sunuda Sonraki ×2, Önceki ×1. | 3→4→5→4 | | `PdfViewers.googleSlides` |
| C3 | Sunu açıkken **Slayta git → 9**. | 9. slayta atlar | | `_jumpInViewer`: rakamlar gidiyor mu, Enter gerekiyor mu |
| C4 | Slayta git → **12** (iki haneli). | 12. slayta atlar | | Rakamlar arası bekleme gerekebilir |
| C5 | Sunu **kapalıyken** (düzenleyici önde) Slayta git → 7. | Sunu açılır, yarım saniye sonra 7. slayta atlar; düzenleyicide hiçbir metin kutusuna **"7" yazılmaz** | | Bekleme süreleri (`30 × 100 ms`, `500 ms`) |
| C6 | Düzenleyicide bir metin kutusunun içine tıkla (yazma imleci orada), sonra Slayta git → 5. | Kutuya **rakam yazılmaz**; ya sunu açılıp 5'e gider ya da hiçbir şey olmaz | | En riskli durum: tam ekran denetimini sıkılaştır |
| C7 | Bitir. | Sunu kapanır | | |
| C8 | Sunucu görünümüyle sunma (Google'ın "Sunucu görünümü"). Ön pencere hangisi, tuşlar nereye gidiyor? | Yaz | | Gerekirse sunucu penceresinin başlığını da tanı |

### D. QuickRemote katmanının araçları (tarayıcı sunusunun üstünde)

PowerPoint web ve Google Slaytlar için ayrı ayrı, gösteri tam ekrandayken:

| # | Adım | Beklenen | Sonuç | Yanlışsa |
|---|---|---|---|---|
| D1 | Dokunmatik yüzeyde lazer. | Kırmızı nokta sununun **üstünde** görünür, takılmadan hareket eder | | Katman tarayıcının tam ekranının altında kalıyorsa `laser_overlay.cpp` yeniden en üste alma |
| D2 | Spot ışığı ve büyüteç (lazer tuşunu basılı tut). | İkisi de çalışır | | |
| D3 | Kalem ve vurgulayıcıyla çiz, Temizle'ye basılı tut (geri al). | Çizim görünür, tıklamalar sunuya **geçmez** (slayt ilerlemez) | | |
| D4 | Çizim varken Sonraki. | Çizim silinir, slayt ilerler | | |
| D5 | Siyah ekran, sonra Beyaz ekran, sonra tekrar. | Katman ekranı kapatır ve açar | | |
| D6 | Telefonda slayt resmi kartı. | "Bilgisayarın ekranı" resmi gelir, slayt değişince yenilenir | | `captureScreen`: pencere monitörü kaplıyor mu |
| D7 | Sunucu görünümü (telefonda karta dokun). | Ekran resmi büyük, yalnız Önceki/Sonraki | | |

### E. Bluetooth modu (PC uygulaması kapalı)

Telefonda Bluetooth uzaktan kumanda, programı seçerken yeni seçenekler:

| # | Adım | Beklenen | Sonuç | Yanlışsa |
|---|---|---|---|---|
| E1 | Program listesi. | "PowerPoint (web)" ve "Google Slides" görünüyor, durum satırları doğru | | `bt_program_sheet.dart` |
| E2 | PowerPoint (web) seçili: Başlat, Sonraki ×2, Önceki, Bitir. | Gösteri açılır (sayfa yenilenmez), slaytlar döner, kapanır | | `_powerpointWebOverrides` |
| E3 | PowerPoint (web): dokunmatik yüzeyde lazer. | Fare imleci hareket eder (lazer yok); tıklamalar yanlışlıkla slayt ilerletmez | | |
| E4 | Google Slides seçili: Başlat, Sonraki, Önceki, Bitir. | Çalışır | | `_googleSlidesOverrides` |
| E5 | Google Slides: Siyah ekran, Beyaz ekran. | Google'ın kendi siyah/beyaz ekranı açılır; aynı tuş ya da başka tuş kapatır | | |
| E6 | Google Slides: dokunmatik yüzeyde parmağı bas, gezdir, kaldır; birkaç kez. | Parmak basılıyken Google'ın lazeri açık, kalkınca kapanıyor; açık/kapalı **kaymıyor** | | L aç/kapa olduğu için kayarsa: yalnız MODE_LASER'da L, kapatmayı Esc'siz bir yolla dene |
| E7 | Saatten Başlat / Sonraki / lazer (Bluetooth'tayken). | Telefonun gönderdiği tuşlarla aynı | | `wear_bridge.dart` |
| E8 | Eski davranış: "PowerPoint" (masaüstü) seçiliyken tarayıcıda Başlat. | F5 basar, sayfa yenilenir (beklenen; kullanıcı "PowerPoint (web)" seçmeli) | | Bilgi |

### F. Linux (sonra)

| # | Adım | Beklenen | Sonuç | Yanlışsa |
|---|---|---|---|---|
| F1 | Firefox ve Chrome XWayland/X11'de, iki sitenin başlıkları (`xprop _NET_WM_NAME`, pencereye tıkla). | Windows'takiyle aynı biçim, sonu `— Mozilla Firefox` / `- Google Chrome` | | `webPresenterOf` |
| F2 | B1, B4, B6 ve C1, C3, C5 Linux'ta. | Windows'takiyle aynı | | `LinuxInputService._start` / `_jumpInViewer` |
| F3 | KDE Wayland'de yerel çalışan Chrome/Firefox. | Site **tanınmaz**, düz tarayıcı (bilinen sınır) | | Sonraki adım: KWin betiğine pencere başlığı eklemek |

### G. Eski sürümlerle uyum (isteğe bağlı)

| # | Adım | Beklenen | Sonuç |
|---|---|---|---|
| G1 | Eski telefon uygulaması + yeni PC, PowerPoint web önde. | Eski davranış: "Tarayıcı", "Tam ekran"; çökme yok | |
| G2 | Yeni telefon + eski PC. | Site adı gelmez, eski davranış | |

### Sonuçlar

Denemelerin tarihi, tarayıcı sürümleri ve görülen başlıklar buraya yazılır:

- Tarih:
- Edge sürümü / Chrome sürümü / Firefox sürümü:
- PowerPoint web başlığı (düzenleyici / gösteri):
- Google Slaytlar başlığı (düzenleyici / gösteri):
