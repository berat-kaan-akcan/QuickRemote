# Slayt önizlemesi ve Sunucu görünümü: oturum raporu

Tarih: 2026-10-20. Görev tanımı: [SLIDE_PREVIEW_PROMPT.md](SLIDE_PREVIEW_PROMPT.md).
Durum: 1-5. aşamalar ve CLAUDE.md tamam. Site (6. aşamanın diğer yarısı) bilerek ertelendi.
Hiçbir şey commit edilmedi.

## Özet

Wi-Fi modunda PC, o anki ve sıradaki slaydın resmini telefona gönderiyor:

- Telefonda slayt kartında küçük önizleme var.
- Önizlemeye dokununca "Sunucu görünümü" açılıyor.
- Ayarlar'da aç/kapa anahtarı var.
- "Slayta git" penceresi küçük resimli bir ızgara gösteriyor.

Resimler şu programlardan alınabiliyor:

| Program | Durum |
|---|---|
| Windows PowerPoint | Var; Windows'ta henüz denenmedi |
| Linux Impress | Var; gerçek LibreOffice'te doğrulandı |
| Linux WPS (uygulamanın açtığı) | Var; gerçek WPS'te doğrulandı |
| Windows WPS | Kapalı (doğrulanamadı) |
| Kullanıcının kendi açtığı WPS (Linux) | Yok |
| PDF görüntüleyiciler | Yok |

## Son test durumu

| Proje | Sonuç |
|---|---|
| Ortak paket (`dart test`) | 18/18 |
| PC (`flutter test`) | 178/178 |
| Telefon (`flutter test`) | 107/107, `l10n_test` dahil |
| Python köprüleri | 66/66 |
| `dart analyze` (PC, telefon) | sorun yok |

## Aşama aşama

### 1. Protokol ve PC sunucusu

**Ortak paket**
- Yeni komutlar `SLIDE_PREVIEW:0/1` ve `SLIDE_THUMB:n`. Üretici fonksiyonları `RemoteCommands.slidePreview()` ve `slideThumb()`; ikisi de `allowedPrefixes` listesinde.
- Yeni `SlideImageFrame` (`lib/src/slide_image_frame.dart`). Frame düzeni şu: `0x51` magic, kind (0 o anki, 1 sıradaki, 2 küçük resim), slayt numarası, deck, genişlik, yükseklik ve JPEG baytları; hepsi little-endian.
- Kısa ya da bozuk frame `null` döner.
- `deckId` 32 bitlik FNV-1a ile hesaplanıyor.

**PC sunucusu**
- `InputService.exportSlide(index, width)` eklendi.
- Komut ayrıştırma `CommandRouter.previewSwitch` ve `thumbSlide` içinde.
- Yeni `SlidePreviewer` (`services/server/slide_previewer.dart`):
  - Slayt değişince o anki slaydı (1280 px) ve sıradakini (640 px) gönderiyor; küçük resimler 320 px.
  - Aynı anda tek dışa aktarma çalışıyor ve 3 saniyede vazgeçiliyor.
  - Gösteri hızla ilerlerse yalnızca son slayt gönderiliyor.
  - Aynı resim aynı telefona iki kez gitmiyor.
  - Önbellek bellekte en fazla 30 MB; en az kullanılan çıkıyor, deck değişince boşalıyor.
- Önizlemeyi açmamış telefona hiçbir binary frame gitmiyor; eski telefonlar binary frame'i yazı sanıp çöküyor.
- `auth` cevabında `previews: true`, `SLIDE_STATE`'te `deck` var.

### 2. Windows PowerPoint, kart önizlemesi ve ayar

**Windows**
- Yeni `SlideExporter` (`input/windows/slide_exporter.dart`): COM `Slides(n).Export(..., "JPG", w, h)` ile çalışıyor.
- Komut PowerShell'ini değil yoklama PowerShell'ini kullanıyor; İleri/Geri onu beklemiyor.
- WPS gösterisinde resim vermiyor.
- Slayt durumu `deckKey` olarak dosya yolu ve son kayıt zamanını okuyor. Bu değer telefona gönderilmiyor.

**Telefon**
- `WebSocketClient` binary frame'leri çözüyor.
- `PresentationState` resimleri tutuyor: büyük ve orta boydan 6'şar, küçük resimden 200.
- İleri basınca önceden gelen "sıradaki" resmi hemen gösteriliyor.
- `SettingsProvider.slidePreview` varsayılan açık. Ayarlar'da "Slayt Önizlemesi" anahtarı var.
- Ayar her bağlanışta ve değiştiğinde gönderiliyor; önizleme bilmeyen eski bir PC'ye hiç gönderilmiyor.
- Kart, slayt numarasının sağında 120 px genişliğinde 16:9 resim gösteriyor (`widgets/slide_image.dart`).
- Siyah/beyaz ekran açıkken resmin üstü o renge bürünüyor.
- Bu sunumdan hiç resim gelmediyse kart eskisi gibi kalıyor.

### 3. Sunucu görünümü

- Yeni ekran `screens/remote/presenter_view_screen.dart`.
- **Dikey:** üstte geri tuşu, `7 / 24` ve süre. Altında büyük slayt, "Sıradaki", kaydırılabilir notlar ve Geri/İleri.
- **Yatay:** slayt solda; sıradaki, notlar ve tuşlar sağda.
- **Nasıl açılıyor:** Önizlemeye dokununca, ya da önizleme varken not önizlemesine dokununca. Önizleme yoksa not önizlemesi eskisi gibi not penceresini açıyor.
- **Ses tuşları ve süre:** Ekran uzaktan kumandanın üstünde açıldığı için ses tuşları, arka plan oturumu ve süre çalışmaya devam ediyor.
- **Bağlantı koparsa** son durum soluk kalıyor.

### 4. "Slayta git" küçük resimleri

- Gösteri açıkken ve bu sunumdan resim gelmişken numara klavyesinin yerine ızgara çıkıyor: 2 ya da 3 sütun, pencere o anki slayta kaydırılmış açılıyor.
- Yeni `ThumbnailRequests` (`services/websocket/thumbnail_requests.dart`):
  - İstekler dörder dörder ve sırayla gidiyor.
  - Ekrandan çıkan hücrenin henüz gönderilmemiş isteği geri alınıyor.
  - 4 saniyede cevap gelmeyen hücre boş çerçeve gösteriyor ve o sunum için bir daha istenmiyor.
- Resim gelene kadar hücrede `Skeleton` duruyor.

### 5. Linux: Impress ve WPS

**Impress köprüsü (`export`)**
- `GraphicExportFilter` ile JPEG yazıyor. Slaytı gösteri denetleyicisinden alıyor, böylece gizli slaytlar ve özel gösterilerde numaralar uygulamayla aynı kalıyor.
- Dışa aktarma yalnızca sırada başka istek yokken çalışıyor; birden fazla birikirse en yenisi yapılıyor, eskiler `SKIPPED` cevabı alıyor.
- Önce slaytın yeniden çizilmesi bitiyor (`settle`); fosforlu kalem çizgisi sürerken istek `BUSY` ile reddediliyor.
- Fosforlu kalem çizgileri resimde görünüyor (ekrandaki gibi). Medya tetikleyicileri animasyon olduğu için iz bırakmıyor.
- Çalışırken bir kilitlenme bulundu ve düzeltildi: iki dışa aktarma isteği birbirini sonsuza dek bekletiyordu. Düzeltme gerçek köprü süreciyle doğrulandı.

**WPS köprüsü (`export`)**
- pywpsrpc `Slide.Export` ile çalışıyor.
- "Çağrı başarılı ama dosya yok" durumunu `NOT_EXPORTED` olarak bildiriyor.
- WPS köprüsü tek iş parçacıklı; bir dışa aktarma sürerken gelen İleri onu bekleyebilir. Ölçülen süre 1-10 ms.

**Ortak**
- Geçici dosyalar `input/slide_files.dart` üzerinden uygulama destek dizinindeki `slide-previews/` klasörüne yazılıyor ve okununca siliniyor.
- Linux servisi resmi, gösteriyi çalıştıran programdan istiyor.

### 6. Belgeler

- CLAUDE.md'ye protokol, PC (program başına dışa aktarma ve sınırları) ve telefon bölümleri eklendi.
- **Site: Ertelendi.** Karar, siteyi proje bitince saatin kopyasıyla birlikte toplu güncellemek.

## Gerçek programlarda ne denendi

| Program | Denendi mi | Nasıl |
|---|---|---|
| LibreOffice 26.8.1 (Linux) | Evet, gösteri dışında | Başsız LibreOffice'te köprünün `export` komutu: 1280×720, 640×360, 320×180 JPEG çıktı, her biri 2-12 ms, doğru slaytlar. Gösteri denetleyicisi sahteydi, çünkü başsız LibreOffice'te gösteri başlatmak onu çökertiyor. |
| WPS 11.1.0.11723 (Linux) | Evet, gösteri dışında | Penceresiz açılmış bir sunumda `Slide.Export`: dosyalar oluştu, boyutlar ve slaytlar doğru. |
| PowerPoint (Windows) | Hayır | Bu makine Linux. |
| WPS 12.2 (Windows) | Hayır | Doğrulanamadığı için kapalı bırakıldı. |
| Telefon arayüzü | Yalnızca widget testleri | Gerçek cihazda bakılmadı; APK derlenmedi. |

## Bilinen sınırlar

Bunlar kullanıcıya da söylenmeli:

- Resim slaydın kaydedilmiş hâlidir. Animasyonun o anki adımı, mürekkep ve oynayan video görünmez.
- Küçük resimler yalnızca gösteri açıkken gelir, çünkü sunum kimliği ancak gösteri sırasında bilinir.
- Hiç kaydedilmemiş bir sunumun dosyası yoktur; resimleri yalnızca slayt sayısıyla ayırt edilir.

## Yapılacaklar

1. Windows'ta PowerPoint gösterisinde dene: kart, Sunucu görünümü, "Slayta git" ızgarası.
2. Linux'ta Impress gösterisinde ve uygulamanın açtığı WPS gösterisinde dene.
3. Windows WPS 12.2'de `Slides(n).Export`'u doğrula. Çalışıyorsa `slide_exporter.dart`'taki `$qrPresenter -eq 'powerpoint'` koşulunu kaldır.
4. Site: canlı demodaki telefon kartına önizleme, istenirse Sunucu görünümü demosu, "Hangi slayttasın" kutusunun metni, SSS. Sitedeki kart kopyası zaten uygulamanın bugünkü kartından farklı, birlikte eşitlenmeli. Proje bitince yapılacak.
5. İstersen commit.

## Dosyalar

**Yeni**
- `packages/quick_remote_shared/lib/src/slide_image_frame.dart` ve testi
- `quick_remote_pc/lib/services/server/slide_previewer.dart` ve testi
- `quick_remote_pc/lib/services/input/slide_files.dart`
- `quick_remote_pc/lib/services/input/windows/slide_exporter.dart` ve testi
- `quick_remote_app/lib/screens/remote/presenter_view_screen.dart` ve testi
- `quick_remote_app/lib/screens/remote/widgets/slide_image.dart`
- `quick_remote_app/lib/services/websocket/thumbnail_requests.dart`
- `quick_remote_app/test/slide_preview_test.dart`, `go_to_slide_grid_test.dart`

**Değişen**
- Ortak paket: `remote_commands.dart`
- PC: `websocket_server.dart`, `state_broadcaster.dart`, `command_router.dart`, `input_service.dart`, `input_simulator.dart`, Windows ve Linux input servisleri, `slide_state_controller.dart`, `impress_bridge.py`, `wps_bridge.py` ve testleri
- Telefon: `websocket_client.dart`, `presentation_state.dart`, `websocket_service.dart`, `settings_provider.dart`, `main.dart`, `main_controls_view.dart`, `go_to_slide_sheet.dart`, `settings_screen.dart`, iki ARB dosyası
- `CLAUDE.md`
