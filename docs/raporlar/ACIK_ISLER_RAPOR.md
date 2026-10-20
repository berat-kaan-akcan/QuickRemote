# Beş açık iş: inceleme raporu

Tarih: 2026-10-20. Durum: yalnızca inceleme ve bir deneme. Uygulamanın koduna dokunulmadı.
Kaplama (lazer ve kalem katmanı) için ayrı rapor: [OVERLAY_RAPOR.md](OVERLAY_RAPOR.md). Aşağıdaki işlerin ikisi ona bağlanıyor.

## Özet

| İş | Yapılabilir mi | Büyüklük | Öneri |
|---|---|---|---|
| 1. Ekran görüntüsüyle slayt resmi | Evet. Linux'ta XWayland penceresi için bu makinede denendi. | 4-6 gün | Yap; "o anki slayt" için, dışa aktarmanın yanında |
| 2. Windows için BtHidRepair | Belki. Windows'ta denenmeden bilinmiyor. | 2-4 gün + Windows'ta deneme | Önce yarım günlük bir Windows denemesi |
| 3. PC'nin `caps`/`front` göndermesi | Evet; Linux Wayland'de native pencerelerde sınırlı | 3-4 gün | Yap; kaplamadan önce |
| 4. Saatte tema seçimi | Evet | 1-2 gün | Tasarımda kararlaştırılan "Saatte de kullan" anahtarı |
| 5. "Mürekkep kalsın" ayarı telefon başına | Evet, küçük | Yarım gün | Yap; en ucuz iş |

Önerilen sıra: 5 → 3 → 1 → 4 → 2. Neden:

- 5 küçük.
- 3, telefonun PDF'i tanımasını sağlıyor. 1 ve kaplama da bu bilgiye dayanıyor.
- 2, Windows'ta denenmeden planlanamaz.

---

## 1. Ekran görüntüsüyle slayt resmi

**Durum (2026-10-20): kodu yazıldı, birim testlerinden geçti; gerçek gösteride denenmedi.** `SlideImageFrame`'e `kind 3 = screen` eklendi (slayt ve deck 0; eski telefonlar bilinmeyen tür olarak atlıyor, testli). PC: `InputService.captureScreen()`; Linux'ta XCB `GetImage` (`X11Windows.capture`), Windows'ta `PrintWindow(PW_RENDERFULLCONTENT)` (yalnızca analizden geçti). Resim yalnızca gösteri penceresinden ya da tam ekrandaki PDF görüntüleyici/tarayıcıdan alınıyor; siyah/beyaz ekranda alınmıyor; kaplamanın mürekkebi PC'de resmin üstüne çiziliyor; JPEG `image` paketiyle ayrı isolate'te, 1280 px. `SlidePreviewer`: slayt komutundan 400 ms sonra (gösteride komuttan sonraki slayt durumunu da bekleyerek), sonra iki saniyede bir; yalnızca küçük kopyanın özeti değiştiyse gönderiliyor. Gösteride `current` olarak dışa aktarılan resmin yerine geçiyor; PDF'te ve slaytı okunamayan gösteride (kullanıcının açtığı WPS) `kind 3`. Telefon: slayt kartı ve sunucu görünümü PDF açıkken canlı resmi gösteriyor. Bu makinede yalnızca kendi açtığım küçük bir GTK penceresinin resmi alındı (17 ms, renkler doğru). KWin `ScreenShot2` sonraki adım; GNOME'da portal yok.
Bekleyen canlı denemeler: gerçek WPS gösterisi (XWayland, `wpp` tam ekran); Impress gösterisi OpenGL/Skia ile çizerken `GetImage` boş mu dönüyor, ve LibreOffice'in X11 penceresi mi native Wayland mı olduğu; videolu slaytta videonun resimde görünüp görünmediği ve iki saniyelik yoklama; tam ekran Firefox/Chrome PDF'i (XWayland'de) ve pencereli tarayıcıda resim gitmediği; kaplama mürekkebinin resimde doğru yerde olması; Windows'ta PowerPoint ve WPS gösterisi, Edge/Chrome tam ekran PDF (`PrintWindow` siyah dönüyor mu, derleniyor mu).

### Ne kazanılır

Bugün resim programın dışa aktarmasından geliyor (`InputService.exportSlide`). Bu yüzden şunlar resimde yok: PDF'ler, kullanıcının kendi açtığı WPS, animasyonun o anki adımı, mürekkep ve oynayan video. Gösteri penceresinin görüntüsü bunların hepsini verir. Çünkü resim, projeksiyonda ne görünüyorsa odur.

Ama ekran görüntüsü yalnızca **o anki** slaytı verir. Sıradaki slayt ve küçük resimler yine dışa aktarmadan gelmek zorunda. Yani bu yöntem dışa aktarmanın yerine geçmez, yanına gelir.

### Deneme (bu makinede, KDE Wayland)

- XWayland'de tam ekran bir pencere açtım; WPS'in gösterisi de böyle bir pencere.
- Üstüne native Wayland'de tam ekran başka bir pencere koydum. Ekranda yalnızca üstteki görünüyordu.
- Alttaki pencereyi XID'siyle `GetImage` üzerinden aldım (ImageMagick `import -window`): içerik eksiksiz ve doğru geldi.
- Yani pencere başka bir pencerenin altında kalsa da resmi alınabiliyor.
- 103 ms sürdü. Bu süreye ImageMagick'in açılışı ve PNG kodlama dahil; `GetImage` tek başına bundan çok daha kısa.

### Platformlar

| Ortam | Yöntem | Durum |
|---|---|---|
| Linux, XWayland ya da X11 penceresi (WPS'in iki türü, X11 oturumu) | XCB `GetImage` (`x11_windows.dart` zaten XCB kullanıyor) | Denendi (yalnızca bir GTK penceresinde). Gerçek WPS gösterisinde **DOĞRULANACAK**. |
| Linux, native Wayland penceresi (Wayland'deki Okular, Firefox; GNOME'da LibreOffice) | XWayland'den görünmez. Seçenek 1: KDE'de `org.kde.KWin.ScreenShot2` D-Bus arayüzü; `.desktop` dosyasına `X-KDE-DBUS-Restricted-Interfaces` yazılınca izin penceresi çıkmaz (`DesktopEntry` bu dosyayı zaten kuruyor). Seçenek 2: portal (her oturumda izin penceresi). | **DOĞRULANACAK**. GNOME'da yalnızca portal var. |
| Windows | `PrintWindow(hwnd, PW_RENDERFULLCONTENT)`: pencere arkada kalsa da DirectX içeriğini alır. Olmazsa `Windows.Graphics.Capture` (Windows 10'da sarı çerçeve çizer). | **DOĞRULANACAK** |

Impress'in kendi dışa aktarması zaten var. Orada ekran görüntüsü yalnızca animasyon adımı, mürekkep ve video için ek kazanç sağlar.

### Nasıl çalışır

- **Ne zaman çekilir**:
  - NEXT, PREV ve START_AT'ten sonra, geçiş bitsin diye kısa bir beklemeyle (ör. 400 ms).
  - Animasyon adımında slayt numarası değişmez, yani NEXT her seferinde yeni bir çekim ister.
  - Video oynarken iki saniyede bir yoklamayla çekilir; yalnızca resim değiştiyse gönderilir. Küçültülmüş bir kopyanın özetiyle karşılaştırılır.
- **Ne zaman çekilmez**:
  - Siyah ya da beyaz ekran açıkken.
  - Pencere bulunamazsa.
  - PDF görüntüleyici tam ekranda değilse. Böylece tarayıcının diğer sekmeleri ya da masaüstü telefona gitmez; yalnızca projeksiyonda görünen gider.
- **Kaplamayla birlikte**: Kaplamanın mürekkebi ayrı bir pencerede, gösteri penceresinin görüntüsünde yok. PC kendi çizgilerini resmin üstüne kendisi çizer.
- **JPEG**: PC'de bugün JPEG kodlayıcı yok; resimler programlardan JPEG olarak geliyor. Pure Dart `image` paketiyle ayrı bir isolate'te kodlanabilir: önce 1280 px'e küçültülür, 50-150 ms tahmin.
- **Protokol**:
  - PDF'te slayt numarası ve deck yok. `SlideImageFrame`'e yeni bir tür eklenir: `kind 3 = screen`, slayt 0.
  - Eski telefonlar bilinmeyen türü `null` sayıp atlıyor (`SlideImageFrame.decode`), yani güvenli.
  - Gösteride ekran görüntüsü, aynı slaytın dışa aktarılan resminin yerine `current` olarak gider.
- **Telefon**: PDF açıkken slayt kartı canlı resmi gösterir. Bunun için 3. iş gerekir: telefonun PDF'in açık olduğunu bilmesi.
- **Bilinen sınır kısmen kalkar**: CLAUDE.md'deki "the picture is the slide as saved" notu, ekran görüntüsü alınabilen yerlerde artık geçerli olmaz. Sıradaki slayt için hâlâ geçerli.

### Riskler

- LibreOffice gösterisi OpenGL ya da Skia ile çiziyorsa XWayland'de `GetImage` boş dönebilir. Gerçek gösteride **DOĞRULANACAK**.
- Videoyu ayrı bir alt pencerede ya da donanım katmanında çizen oynatıcılar resimde siyah çıkabilir.
- Gönderilen veri artar. Ama yalnızca önizlemeyi açmış telefonlara, o anki slayt için ve değişince gidiyor.

---

## 2. Windows için BtHidRepair

### Sorun

Windows, telefonun SDP kayıtlarını eşleştirirken bir kez okuyor. Telefon QuickRemote'un klavye kaydı yokken eşleştiyse Windows onu klavye olarak kabul etmiyor. Bugün kullanıcıdan cihazı kaldırıp yeniden eşleştirmesi isteniyor.

Linux'ta PC, BlueZ'e kayıtları yeniden okutuyor (`bluez_hid_repair.dart`).

### Windows'ta olası yol

1. **Hizmeti açmak**: PC, `BtHidRepair.serviceUuid` ile bir RFCOMM hizmeti açar: Winsock `AF_BTH` soketi, `bind`, `listen`, ardından `WSASetService` ile SDP kaydı.
   - `win32` paketinde `WSASetService` yok; kendi FFI bağlamasını yazmak gerekir. Birkaç fonksiyon, zor değil.
   - Telefon tarafı değişmez: aynı UUID'ye bağlanıyor.
2. **Telefon bağlanınca**: PC, telefonun adresi için HID hizmetini kapatıp açar: `BluetoothSetServiceState(..., HumanInterfaceDeviceServiceClass_UUID, DISABLE)`, ardından `ENABLE`.
   - Beklenti: Windows hizmeti açarken telefonun HID kaydını yeniden okur ve HidBth sürücüsünü kurar.
   - `BluetoothSetServiceState` `win32` paketinde var.
3. **Olmazsa yedek**: PC penceresinde "Telefonu yeniden eşleştir" tuşu.
   - `BluetoothRemoveDevice` ile telefon kaldırılır, ardından `BluetoothAuthenticateDeviceEx` ile eşleştirme başlatılır.
   - Bu da kullanıcının bugün elle yaptığı işi tek tuşa indirir. Yine de iki tarafta onay penceresi çıkar.

### Bilinmeyenler, hepsi Windows'ta DOĞRULANACAK

- `ENABLE`, Windows'un önbellekteki kaydıyla mı çalışıyor, yoksa SDP'yi yeniden mi okuyor? Bütün iş buna bağlı.
- `BluetoothSetServiceState` yönetici izni istiyor mu? İstiyorsa bir UAC onayı çıkar.
- Windows 11'in yeni Bluetooth yığını eski API'lerle aynı davranıyor mu?

Öneri: Önce yarım günlük bir deneme. Küçük bir PowerShell ya da C betiğiyle 2. adım, sorunlu bir telefonla elle denenir. Sonuç olumluysa 1. adım yazılır; olumsuzsa 3. adıma geçilir. Deneme adımları `WINDOWS-DENEME.md`'ye eklenebilir.

**Durum (2026-10-20):** Deneme hazır, Windows'ta yapılmadı. Adımlar ve sonuç tablosu [WINDOWS-DENEME.md](../../WINDOWS-DENEME.md), "Bluetooth klavye onarımı"; betik `quick_remote_pc/tool/windows_bt_hid_trial.ps1` (Windows PowerShell 5.1, Add-Type P/Invoke): eşleşmiş cihazları listeler, seçilen telefon için kurulu hizmetleri, Aygıt Yöneticisi kayıtlarını ve HID SDP kaydını (Windows önbelleği ve `LUP_FLUSHCACHE` ile telefondan taze) okur, `BluetoothSetServiceState` ile HID'i kapatıp açar, hata kodlarını (yönetici izni dahil) açıklar, sonra durumu yeniden okur; çıktıyı masaüstüne kaydeder. Betik bu makinede çalıştırılamadı (PowerShell yok); ilk koşuda küçük düzeltmeler gerekebilir. Uygulama kodu yazılmadı.

---

## 3. PC'nin `caps` ve `front` göndermesi (tasarım planının 8. aşaması)

**Durum (2026-10-20): PC tarafı yapıldı.** `InputService.capabilities()` Linux, Windows ve kaplamada dolduruldu; `SLIDE_STATE` (gösteri yokken boş olanı da) `front` ve `caps` taşıyor, öndeki pencere değişince yeniden gönderiliyor. Windows kodu yalnızca analizden geçti, gerçek Windows'ta denenmedi.

### Neden

Telefon bugün yalnızca "gösteri açık mı" bilgisine bakıyor. Şunları bilemiyor:

- PDF açık mı? "PDF açık · yalnız sayfa geçişi ve tam ekran" yazısı, Başlat yerine "Tam ekran", Slayta git'in gizlenmesi bu bilgiye bağlı.
- Hangi araç şu an gerçekten çalışıyor?

Programa göre farkların çoğu bugün telefonda tahminle çıkarılıyor: `presenter` ve `platform` alanlarından, ya da `current: 0` ile.

### Öneri

`SLIDE_STATE`'e iki alan eklenir:

- `front`: Öndeki pencerenin türü: `show` (bilinen bir programın gösterisi), `editor` (sunum programının düzenleyicisi), `pdf`, `browser`, `other`. Bilinmiyorsa alan gönderilmez.
- `caps`: Şu an çalışan araçların listesi. Örnek: `["laser","pen","highlighter","eraser","eraseAll","blank","media","goto","notes","colors","previews"]`.
  - Telefon listede olmayanı soluk gösterir.
  - Alan hiç yoksa (eski PC) telefon bugünkü gibi davranır.
  - Telefon bilmediği bir değeri yok sayar. Yeni araçlar (kaplamadaki spotlight gibi) listeye eklenebilir; protokolü bozmaz.

Neden `caps` liste ve neden PC'de üretiliyor:

- Kurallar program ve platforma göre değişiyor; hepsi zaten PC'de.
- Örnekler: köprü WPS'inde fosforlu kalemin rengi yalnızca odaktayken çalışıyor; Impress'te medya tetikleyicileri; kullanıcının açtığı WPS'te Slayta git yok.
- Telefonda tekrar tahmin etmek yerine PC söyler.
- Kaplama gelince PDF'te `laser` ve `pen` listeye kendiliğinden girer.

### Pencereyi tanıma

- **Windows**: `GetForegroundWindow` ve exe adı. PDF için bu yol zaten var (`pdf_viewers.dart`); her 2 saniyelik yoklamada çağırmak ucuz.
- **Linux X11 ve XWayland**: `_NET_ACTIVE_WINDOW` ve WM_CLASS; `x11_windows.dart` bunu zaten yapıyor.
- **Linux native Wayland**: Öndeki pencere XWayland'den görünmez (Wayland'deki Okular, Firefox).
  - KDE'de bir KWin betiği D-Bus üzerinden etkin pencereyi bildirebilir; GNOME'da yol yok.
  - Burada `front` gönderilmez ve telefon bugünkü gibi davranır.
  - Bu sınır bugün START ve END'in PDF'i tanımasında da var.

### Yapılacaklar

Sıra CLAUDE.md'ye göre: önce ortak paket, sonra PC, sonra telefon.

- **PC**: `InputService`'e `Future<PresenterCaps> capabilities()` gelir; iki platform da doldurur. `state_broadcaster` bunu `SLIDE_STATE`'e koyar ve `front` değişince durumu yeniden gönderir.
- **Telefon**: `PresentationState` iki alanı okur. `KARARLAR.md`'deki "Programa göre farklar" bölümü uygulanır.
- **Saat**: `/quickremote/state`'e `front: pdf` eklenirse saat de "yalnızca gösteri sırasında" uyarısını doğru verir. İsteğe bağlı.
- **Testler**: PC'de `linux_input_service_test` ve WebSocket sunucusu testlerine `caps`; telefonda araçların soluk görünmesi.

**Durum (telefon, 2026-10-20)**: Yapıldı, commit edilmedi. `PresentationState` `caps`/`front`'u `SLIDE_STATE`'ten ve "gösteri yok" `STATUS`'undan okur (ardından gelen boş `SLIDE_STATE` onları silmez); `ShowInfo` `caps` varken tahmin yerine onu kullanır. PDF/tarayıcı öndeyken bilgi yazısı "PDF açık · yalnız sayfa geçişi ve tam ekran" (tarayıcıda "Tarayıcı önde · ..."), Başlat yerine "Tam ekran" (START gönderir), Slayta git gizli; `caps`'te olmayan araçlar (lazer, kalem, vurgulayıcı, silgi, Temizle, siyah/beyaz, medya, başa sar, slayta git, renkler, notlar, önizleme, spotlight/büyüteç/geri al) soluk ya da gizli. `caps` yoksa (eski PC) her şey eskisi gibi. Saate `front` geçirilmedi (saatin `WearProtocol.kt` tarafı da değişmeli). PDF'te tam ekrandan çıkmak için ayrı tuş yok (PC tam ekranı bildirmiyor).

---

## 4. Saatte tema seçimi

### Bugün

- Saatte altı tema kodda hazır (`WearTheme`).
- `WearTheme.stored` ve `store` var, `theme` anahtarıyla saklanıyor.
- `MainActivity` saklanan temayı okuyor, ama onu seçecek bir yer yok. Saat hep Kobalt.

### Önerim

Tasarımda zaten kararlaştırılmış yol: telefonun Tema ekranında **"Saatte de kullan"** anahtarı (KARARLAR.md, Tema; UYGULAMA-PLANI.md, 5. aşama).

- Anahtar açıkken telefon, `/quickremote/state`'e `theme` alanını yazar (`cobalt`, `oled`, `contrast`, `mint`, `violet`).
- Saat bu alanı alınca kendi tercihine kaydeder (`WearTheme.store`) ve hemen uygular. Telefon uzaktayken de son tema kalır.
- **Gün Batımı** yalnızca açık bir tema; saatte açık tema yok. Saatte Kobalt'a düşer; telefonda anahtarın altında bunu söyleyen kısa bir not olur.
- Anahtar kapalıysa alan yazılmaz, saat kendi saklı temasında kalır.
- `WearProtocolTest` yeni alanı iki taraftan da okur, Kotlin ve Dart adlarının aynı olduğunu kontrol eder.

**Durum (2026-10-20):** Yapıldı ve uçtan uca kodda doğrulandı: Tema ekranında "Saatte de kullan" anahtarı ve Gün Batımı notu, `SettingsProvider.watchUsesTheme` (varsayılan açık), `WearBridge.watchThemeOf` (Gün Batımı → `cobalt`), alan yoksa saat kendi temasında kalır, `PhoneLink` yeni temayı `WearTheme.store` ile saklayıp hemen uygular. Telefon testleri (`wear_bridge_test`, `settings_provider_test`, `theme_screen_test`) ve saatte `WearProtocolTest` geçiyor. Gerçek saatte henüz denenmedi.

### Saatte ayrı bir seçici

İsteğe bağlı, sonra yapılabilir: Araçlar sayfasının altına bir "Tema" listesi (`ListItems.kt`'deki satırlar). Telefonla eşitleme açıksa telefonunki öncelikli olur. Tasarımda bunun görseli yok; ben şimdilik gerek görmüyorum.

---

## 5. "Mürekkep slayt değişince kalsın" ayarı telefon başına

**Durum (2026-10-20): yapıldı.** Sunucu `SET_KEEP_INK`'i soket başına saklıyor ve NEXT, PREV, START, START_AT'e o telefonun değerini `keepInk` parametresiyle geçiriyor; `PresenterSettings` kaldırıldı. Test: `websocket_server_test.dart`, iki (üç) telefon.

### Bugün

- `PresenterSettings.keepInkOnSlideChange`, PC için tek bir statik değer.
- Her telefon bağlanınca ve ayarı değiştirince `SET_KEEP_INK` gönderiyor; son gönderenin ayarı geçerli oluyor.
- Değeri okuyan iki yer var:
  - Linux: `linux_input_service.dart:275`, köprüye giden `clearInk`.
  - Windows: `ppt_controller.dart:43`, E tuşu ya da `EraseDrawing`.
- İkisi de yalnızca NEXT, PREV ve atlama sırasında okunuyor, yani yalnızca telefondan gelen komutlarda.

### Öneri

**Slaytı değiştiren telefonun ayarı geçerli olsun.**

- Sunucu `SET_KEEP_INK`'i soket başına saklar (`Map<WebSocket, bool>`).
- NEXT, PREV ve START_AT'i yönlendirmeden hemen önce `PresenterSettings.keepInkOnSlideChange`'i o telefonun değerine ayarlar.
  - Değer, servis metotlarının başında senkron okunuyor; bu yüzden aradaki `await`'ler sorun çıkarmaz. Yine de daha temizi değeri parametre olarak geçirmek.
- `SET_KEEP_INK` hiç göndermemiş eski telefon bugünkü varsayılanı (temizle) alır.
- Saatin komutları telefonun üzerinden geldiği için o telefonun ayarını kullanır; bu doğru.
- Klavyeden ya da tıklayıcıdan slayt değişince bugün de mürekkebe dokunulmuyor; değişen bir şey yok.

**Test**: `websocket_server_test.dart`'a iki telefon eklenir: A "kalsın", B "temizle". A NEXT gönderince sahte servis `keep` görür, B gönderince `clear`.

Kaplamada mürekkebi slayta göre saklama planlandığında ([OVERLAY_RAPOR.md](OVERLAY_RAPOR.md)) aynı kural kullanılır.

---

## Sorular ve önerilerim (2026-10-20)

1. **Ekran görüntüsü ve gizlilik**: PDF ve tarayıcıda yalnızca tam ekrandayken resim gitsin kuralı uygun mu?
   - **Önerim: Evet.** Resim yalnızca projeksiyonda görünen şeyden alınır: gösteri penceresinden ya da tam ekrandaki PDF görüntüleyiciden. Pencereli tarayıcıdan ve masaüstünden hiçbir zaman alınmaz.
   - Resim yalnızca önizlemeyi açmış telefonlara gider.
2. **KDE'de native Wayland pencereleri**: KWin ekran görüntüsü arayüzü için `.desktop` dosyasına izin satırı eklemeyi kabul ediyor musun? Bu yol yalnızca KDE'de çalışır.
   - **Önerim: Evet, ama ikinci adımda.** Önce XCB `GetImage` (WPS ve XWayland pencereleri, X11 oturumu). KWin yolu, native Wayland'deki PDF görüntüleyicileri için sonra eklenir.
   - GNOME'da portal kullanılmaz: her oturumda çıkan izin penceresi sunum sırasında kabul edilemez. GNOME'da bu pencereler için resim olmaz.
3. **Windows Bluetooth denemesi**: Sorunlu durumda bir telefonla (önce başka bir şey için eşleşmiş) Windows makinende deneme yapabilir misin?
   - **Önerim: Deneme yapılana kadar bu iş bekler.** Deneme adımları ve küçük bir betik hazırlanıp `WINDOWS-DENEME.md`'ye eklenir. Bunu Windows makinende senin yapman gerekiyor.
   - Deneme olumsuz çıkarsa "Telefonu yeniden eşleştir" tuşu (3. adım) yapılır.
   - O zamana kadar bugünkü yönlendirme kalır.
4. **Saat teması**: Yalnızca telefondan eşitleme yeterli mi, yoksa saatte de bir seçici olsun mu?
   - **Önerim: Yalnızca telefondan eşitleme** ("Saatte de kullan", varsayılan açık). Saatte ayrı bir seçici yapılmaz; küçük ekranda bir ayar listesi daha gereksiz.
