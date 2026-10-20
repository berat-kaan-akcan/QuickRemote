# Görev: Telefonda slayt önizlemesi ve "Sunucu görünümü"

QuickRemote'a, Wi‑Fi modunda o anki slaydın resmini telefona getiren özelliği ekle.
Önce CLAUDE.md'yi oku; protokol, renk/tasarım, l10n ve platform kuralları orada.
İşi aşağıdaki aşamalarla yap, her aşamadan sonra testleri çalıştır ve dur, sonucu raporla.
"DOĞRULANACAK" diye işaretli şeyleri gerçek programda dene; çalışmazsa uydurma,
yapamadığını söyle ve o programda özelliği kapalı bırak.

## Kapsam
- Sadece Wi‑Fi modu. Bluetooth HID modunda bilgisayar telefona veri gönderemez, kapsam dışı.
- Saat (quick_remote_wear) kapsam dışı; hiçbir dosyasına dokunma.
- Telefon tarafında: slayt kartında küçük önizleme, dokununca "Sunucu görünümü" ekranı
  (o anki + sıradaki slayt + notlar + Geri/İleri), Ayarlar'da aç/kapa, "Slayta git"
  listesinde küçük resimler.

## 1. Protokol (packages/quick_remote_shared)
- Komutlar (önce `remote_commands.dart`, `allowedPrefixes`'e ekle, builder yaz):
  - `SLIDE_PREVIEW:1` / `SLIDE_PREVIEW:0`: telefon önizlemeyi açar/kapatır. `SET_KEEP_INK` gibi
    her bağlanışta ve ayar değişince gönderilir. Varsayılan kapalı: PC, bunu göndermemiş bir
    telefona ASLA binary frame göndermez (eski telefonlar `data as String` ile çöker,
    `websocket_client.dart`).
  - `SLIDE_THUMB:n`: n. slaydın (1'den başlar) küçük resmini ister ("Slayta git" listesi için).
    30 komut/s sınırına takılmamak için telefon görünür olanları sırayla, en fazla birkaç tane
    aynı anda ister.
- PC'den telefona resim: binary frame, `SlideImageFrame` (ortak pakette encoder + decoder +
  testleri), little-endian:
  `uint8 magic (0x51)`, `uint8 kind` (0 = o anki, 1 = sıradaki, 2 = küçük resim),
  `uint16 slide`, `uint32 deck`, `uint16 width`, `uint16 height`, ardından JPEG baytları.
  Bozuk/kısa frame decoder'da null döner.
- `auth` ok cevabına `previews: true` (bu PC o an en az bir programdan resim alabiliyorsa
  değil, özelliği biliyorsa). Alan yoksa telefon özelliği gizler.
- `SLIDE_STATE`'e `deck`: sunumun kimliği (dosya yolu + slayt sayısı + son değişiklik
  zamanından üretilmiş uint32). Değişince telefon önbelleğini boşaltır.
- Hata gerekirse `RemoteError`'a ekle (legacyDetail ile), telefonun iki ARB'sine ve
  `failure_text.dart`'a da. Resim alınamaması kullanıcıya hata olarak gösterilmesin;
  kart resimsiz haliyle kalsın.

## 2. PC sunucusu (quick_remote_pc)
- `InputService`'e `Future<SlideImage?> exportSlide(int index, int width)` ekle, iki
  platformda da uygula (desteklenmeyen yerde null). `CommandRouter` `SLIDE_PREVIEW` ve
  `SLIDE_THUMB`'ı ayrıştırsın.
- `WebSocketServer` istemci başına önizleme açık/kapalı tutsun. `StateBroadcaster`, slayt
  değişince (veya `deck` değişince) açık istemcilere o anki (1280 px) ve sıradaki (640 px)
  slaydı göndersin; küçük resim 320 px. Aynı resmi iki kez gönderme.
- Önbellek: (deck, slide, width) → JPEG, bellekte LRU (~30 MB üst sınır), deck değişince boşalt.
  Geçici dosyaları uygulama destek dizinindeki kendi klasörüne yaz ve sil.
- Dışa aktarma komut kuyruğunu bekletmemeli: İleri/Geri her zaman önce gider. Windows'ta
  PowerShell'in yoklama (polling) sürecini kullan, komut sürecini değil; zaman aşımı koy
  (ör. 3 s). Slayt hızla değişirse yalnızca en son slaydı aktar (eskileri iptal/atla).
- Program başına:
  - Windows PowerPoint: COM `Slides(n).Export(yol, "JPG", w, h)`, `PresenterCom.lookup` ile.
  - Windows WPS: aynı COM çağrısı. DOĞRULANACAK (WPS 12.2): `Player` gibi sessizce hiçbir şey
    yapmayan çağrılar var; dosya gerçekten oluşuyor ve doğru slayt mı, kontrol et.
  - Linux Impress (`assets/linux/impress_bridge.py`): yeni `export` komutu,
    `com.sun.star.drawing.GraphicExportFilter` + `setSourceDocument(drawPage)`, FilterData
    `PixelWidth`/`PixelHeight`, JPEG. Her UNO çağrısı ana thread'de (`AsyncCallback`).
    Fosforlu kalem çizgisi (`strokes`) sürerken ve `settle` beklenirken dışa aktarma yapma.
    Köprünün kendi `quickremote-highlight`/`quickremote-media` şekillerini resme katma
    (ya geçici gizle ya da kabul edip not düş; hangisi olduğunu raporla).
    Python unittest'lerini ekle (LibreOffice olmadan, sahte nesnelerle).
  - Linux WPS köprüsü (`assets/linux/wps_bridge.py`): pywpsrpc ile `Slide.Export`.
    DOĞRULANACAK; çalışmazsa null.
  - Kullanıcının açtığı WPS (Linux), PDF görüntüleyiciler: şimdilik null. (Fikir, bu görevde
    YAPMA: Windows'ta gösteri penceresinin ekran görüntüsü; Linux'ta XWayland penceresi için
    `x11_windows.dart`'taki XCB ile `GetImage`. Wayland'ın kendi pencereleri portal izni
    istediği için pratik değil.)
- Bilinen sınır, kullanıcıya açıklanmalı (CLAUDE.md'ye yaz): dışa aktarılan resim slaydın
  son halidir; animasyonun o anki adımı, mürekkep ve oynayan video görünmez.
- Testler: `test/websocket_server_test.dart`'ta `fakes.dart`'taki sahte InputService ile:
  önizlemeyi açmamış istemciye binary gitmiyor; açınca slayt değişiminde iki frame geliyor;
  `SLIDE_THUMB` doğru frame'i döndürüyor; hızlı slayt değişiminde sadece sonuncusu gidiyor.
  Linux için `test/linux_input_service_test.dart`.

## 3. Telefon (quick_remote_app)
- `websocket_client.dart`: gelen binary frame'i `SlideImageFrame` ile çöz, yazı mesajlarını
  bugünkü gibi işle. `presentation_state.dart`: resimleri tut (deck + slide + kind),
  bellekte sınırlı önbellek; `WebSocketService` `currentSlideImage`, `nextSlideImage`,
  `thumbnail(n)` ve `previewsAvailable` (auth'taki `previews` && ayar açık) versin.
- `SettingsProvider`: `slidePreview` (varsayılan açık), Ayarlar ekranında anahtar; değişince
  ve her bağlanışta `SLIDE_PREVIEW:0/1` gönder (`keepInkOnSlideChange` nasıl yapıldıysa öyle).
- `SlideCard` (`screens/remote/views/main_controls_view.dart`): büyük slayt numarasının
  sağına 16:9 önizleme (yuvarlatılmış köşe, `AppRadius`, ince kenarlık). Slayt değişince
  numara gibi geçişli değişsin (`AppMotion.of`). Siyah/beyaz ekran açıkken üstüne o rengin
  örtüsü (resim bunu göstermez). Resim yoksa kart bugünkü haliyle kalsın.
  DİKKAT: bu ağaç `SliverFillRemaining(hasScrollBody: false)` altında; `LayoutBuilder`
  KULLANMA, `AspectRatio` + sabit/esnek genişlik kullan.
- Yeni ekran `screens/remote/presenter_view_screen.dart` ("Sunucu görünümü"): üstte geri
  tuşu, `7 / 24` ve süre; büyük o anki slayt; altında "Sıradaki" küçük resmi ve notlar
  (kaydırılabilir); en altta Geri/İleri (`BigSlideButton`). Yatayda o anki solda büyük,
  sağda sıradaki + notlar + tuşlar. Önizlemeye veya not önizlemesine dokununca açılır
  (önizleme yoksa not önizlemesi bugünkü not penceresini açmaya devam eder). Ses tuşları
  (`hardware_key_handler.dart`) bu ekranda da çalışsın. Bağlantı koparsa son durum soluk kalsın.
- "Slayta git" (`utils/go_to_slide_sheet.dart`): önizleme varsa numara listesi yerine küçük
  resimli ızgara; görünür hücreler `SLIDE_THUMB` ister, gelene kadar `Skeleton`.
- Renkler `context.palette`, ölçüler `app_tokens.dart`, bileşenler `widgets/ui/`.
  Bütün yeni metinler `app_tr.arb` + `app_en.arb` (ICU yer tutucularıyla), koda Türkçe yazı yok.
- Testler: frame çözme, önbellek/deck değişimi, ayarın komutu göndermesi, `SlideCard`
  resimli/resimsiz/siyah ekran, Sunucu görünümü dikey/yatay, `l10n_test`.

## 4. Belgeler ve site
- CLAUDE.md: Wire protocol bölümüne komutlar, binary frame düzeni, `previews`/`deck`,
  eski telefon kuralı; PC bölümüne program başına dışa aktarma ve sınırları; telefon
  bölümüne yeni ekran.
- `landing-page/`: telefon parçası uygulamanın ekranlarını kopyalıyor; kart değiştiyse
  `index.html` ve `en/index.html`'e aynı değişikliği yap.

## Aşamalar
1. Ortak paket + PC sunucusu (sahte InputService ile testler).
2. Windows PowerPoint dışa aktarma + telefonda kart önizlemesi + ayar. (Burada dur, cihazda
   denenebilir hale getir.)
3. Sunucu görünümü ekranı.
4. Slayta git küçük resimleri.
5. Impress (Linux), sonra iki WPS (doğrulamayla).
6. Belgeler ve site.

Komutlar: `dart test` (shared), `flutter test` (app ve pc), `dart analyze` (`flutter analyze`
bu yolda çöker), `python -m unittest discover -s quick_remote_pc/test/python`.
