# QuickRemote marka rehberi

QuickRemote'un logosu, renkleri, yazı tipleri ve arayüz dili. Telefon (`quick_remote_app`) ve PC (`quick_remote_pc`) uygulamaları bu rehbere göre çalışır. Koddaki karşılıkları her bölümde belirtiliyor.

## Konsept: "Signal & Laser"

QuickRemote ile sunum telefondan yönetilir. Kimliğin iki öğesi var:

- **Kobalt mavisi**: bağlantıyı ve kontrolü, yani güveni temsil eder. Arayüzün ana rengidir.
- **Lazer turuncusu**: işaretçiyi ve aksiyonu temsil eder. Tek sıcak vurgu rengidir; az ve bilinçli kullanılır.

## Logo

İşaret, yumuşak köşeli bir **"Q" halkasıdır**. Halka aynı zamanda bir slaydı ya da ekranı andırır. Q'nun kuyruğu halkanın sağ alt köşesinden çıkar ve bir **lazer noktasında** biter. Okunuşu: "Quick" (Q), "Remote" (işaretçi), sunum (çerçeve).

| Dosya (`brand/logo/`) | Kullanım |
|---|---|
| `app-icon.svg` | Uygulama ikonu: kobalt gradyan karo, beyaz işaret |
| `app-icon-square.svg` | Köşesiz karo (Android adaptive arka plan kaynağı) |
| `mark-color.svg` | Açık zemin: kobalt halka, turuncu nokta |
| `mark-white.svg` | Koyu zemin ya da kobalt üzeri: beyaz halka, turuncu nokta |
| `mark-mono.svg` | Tek renk (Android 13 temalı ikon, baskı) |
| `lockup-light-bg.svg` / `lockup-dark-bg.svg` | İşaret ve yazı yan yana |
| `wordmark-light-bg.svg` / `wordmark-dark-bg.svg` | Yalnızca yazı |
| `favicon.svg` | 16–48 px için kalın çizgili, parıltısız sürüm |

- **Wordmark**: Space Grotesk ile "**Quick**" Bold, "Remote" Medium ve birincil renkte yazılır. Ad her zaman bitişik ve büyük harflerle "QuickRemote" olarak yazılır. PC uygulamasında yanına gri renkte "PC" eklenir.
- **Boşluk**: İşaretin çevresinde en az lazer noktasının çapı kadar boşluk bırakılır.
- **En küçük boyut**: İşaret 16 px. 24 px'in altında `favicon.svg` kullanılır.
- **Yapılmaması gerekenler**: İşareti döndürmek, gerdirmek, gölge eklemek; lazer noktasını turuncu dışında bir renge boyamak (tek renk sürüm hariç); halkayı çembere çevirmek.

Uygulamalarda logo görsel dosyası yerine kodla çizilir. Böylece her boyutta keskin kalır, iki temaya uyar ve animasyonlu açılabilir. Koddaki karşılıkları: `lib/widgets/brand/brand_mark.dart` içinde `BrandMark`, `BrandTile`, `BrandWordmark` ve `BrandLockup`.

### Varlıkları yeniden üretmek

```bash
brand/tools/export_assets.sh   # rsvg-convert, ImageMagick 7 ve python3 gerekir
```

Bu betik SVG'lerden şunları üretir: `brand/export/` (PNG'ler, favicon), telefon uygulamasının ikonları (`assets/images/logo.png`, Android mipmap'leri, adaptive ön plan/arka plan/monokrom katmanlar, Android 7–11 için `splash_logo.png`), PC uygulamasının `assets/images/logo.png` dosyası ve Windows `app_icon.ico`.

## Renkler

Ham değerler `lib/theme/app_colors.dart` (`AppColors`) dosyasındadır. Ekranlar renkleri `context.palette` (`AppPalette`) üzerinden okur; o anki temaya göre doğru tonu palet seçer.

### Marka

| Ad | Hex | Kullanım |
|---|---|---|
| Cobalt | `#2F4BE0` | Birincil dolgu; açık temada birincil metin |
| Cobalt Bright | `#3E63F5` | Birincil gradyanın ucu |
| Cobalt Light | `#8EA1FF` | Koyu temada birincil metin ve ikon |
| Cobalt Deep | `#1B28A3` | Logo karosunun gradyan ucu |
| Laser | `#FF6A3D` | Vurgu: lazer noktası, aktif slayt, parıltı |
| Laser Deep | `#C8401C` | Açık temada vurgu metni |

### Nötrler

| Rol | Açık ("Paper") | Koyu ("Ink") |
|---|---|---|
| Arka plan | `#F4F5FA` | `#0A0D18` |
| Yüzey | `#FFFFFF` | `#121628` |
| Yükseltilmiş yüzey | `#FFFFFF` | `#1A1F36` |
| Çukur yüzey (input, iz) | `#ECEEF5` | `#0E1222` |
| Kenar | `#E1E4EE` | `#252B47` |
| Metin | `#0E1224` | `#EEF0FA` |
| İkincil metin | `#4A5172` | `#A9AFCB` |
| Soluk metin | `#6B7194` | `#7D84A6` |

### Durum renkleri

Durum renklerinin koyu temada parlak, açık temada derin tonları vardır. Her ikisi de kendi zemininde WCAG AA kontrastını (4.5:1) sağlar.

| Rol | Koyu tema | Açık tema |
|---|---|---|
| Başarı | `#3DDC97` | `#12804F` |
| Uyarı | `#FFB547` | `#A35F00` |
| Hata | `#FF5C77` | `#CC2240` |
| Bilgi (ve Bluetooth modu) | `#5CC8FF` | `#0A6FAD` |

Kurallar:

- Renkli bir dolgu üzerindeki metnin rengini elle seçmeyin; `readableOn(renk)` kontrastı daha yüksek olanı (mürekkep ya da beyaz) seçer.
- Lazer turuncusu bir ekranda bir iki yerde kullanılır: aktif öğe, parıltı, en önemli vurgu.
- Çizim araçları (lazer, kalem, vurgulayıcı, silgi) ve mürekkep örnekleri slaytta görünen gerçek renklerdir; bunlar yalnızca telefondaki `AppColors` içinde bulunur.
- Kamera ekranı ve QR karosu her iki temada da sabit renklidir. QR her zaman beyaz zemin üzerinde koyu modüllerle çizilir; böylece tüm tarayıcılar okur.

## Tipografi

| Stil (`AppType`) | Yazı tipi | Boyut / ağırlık | Kullanım |
|---|---|---|---|
| `numeric` | Space Grotesk | 40 / 700, tabular | Slayt numarası, sayaç, PIN, ses yüzdesi |
| `displayLarge` | Space Grotesk | 32 / 700 | Büyük başlık |
| `headline` | Space Grotesk | 24 / 700 | Ekran başlığı, hero |
| `title` | Space Grotesk | 19 / 600 | Kart ve diyalog başlığı |
| `titleSmall` | Inter | 15.5 / 600 | Liste satırı başlığı |
| `body` | Inter | 15 / 400 | Gövde metni |
| `bodySmall` | Inter | 13 / 400 | Açıklama, alt metin |
| `label` / `labelSmall` | Inter | 15, 12.5 / 600 | Buton, sekme, çip |
| `overline` | Inter | 12 / 700, +0.6 aralık | Bölüm başlıkları |
| `mono` | Inter | 12.5 / 500, tabular | IP, port, güvenlik kodu |

İki yazı tipi de SIL OFL 1.1 lisanslıdır ve uygulamaya gömülüdür (`assets/fonts/`); çalışırken indirilmez. Space Grotesk değişken fonttan alınmış 500/600/700 statik kesimlerle gelir ve Türkçe karakterlerin tamamını destekler. Büyük harfe çevirme (`toUpperCase`) kullanılmaz, çünkü Türkçe "i/İ" dönüşümünü bozar.

## İkonlar

- Material ikonlarının **Rounded** setini kullanın (`Icons.*_rounded`); seçili gezinme öğesinde dolu, diğerlerinde `_outlined` varyantı kullanılır.
- Varsayılan boyut 22 px, liste ve kart başlıklarında 20–24 px.
- Bir ikon bir satırı ya da kartı başlatıyorsa **`IconBadge`** kullanın: tonlu, yuvarlak köşeli bir kare.

## Biçim, boşluk, gölge

- **Boşluk** (`AppSpace`): 4 px ızgara (4, 8, 12, 16, 20, 24, 32, 48). Sayfa kenar boşluğu 20 px.
- **Köşe yarıçapı** (`AppRadius`): 8, 12, 16 (buton, input), 20 (kart), 28 (hero kart, sayfa, diyalog), hap (999).
- **Gölge** (`AppShadows`): Material elevation yerine yumuşak, tonlu gölgeler kullanılır: kart için `soft`, sayfa ve diyalog için `raised`, birincil buton ve aktif öğe için renkli `glow`.
- **Cam efekti**: Gerçek bulanıklık yalnızca alt sayfalarda (bottom sheet) kullanılır. Kartlarda ucuz bir cam görünümü elde edilir: yarı saydam renk tonu ve ince kenar. Kumanda ekranında bulanıklık yoktur, çünkü dokunmatik yüzey animasyonu sırasında her karede yeniden hesaplanırdı.
- **Dokunma alanı**: En az 48×48 px (`AppSpace.minTouch`).

## Hareket

| Token (`AppMotion`) | Süre | Kullanım |
|---|---|---|
| `fast` | 120 ms | Basma geri bildirimi, hover |
| `base` | 220 ms | Geçişler, renk ve boyut değişimi |
| `slow` | 380 ms | Giriş animasyonları, sayfa içeriği |
| `page` | 320 ms | Sayfa geçişi (soluklaşarak %3 yukarı kayar) |
| `stagger` | 45 ms | Liste öğeleri arasındaki gecikme |

Eğriler: `standard` (Material 3 emphasized), `enter` (easeOutCubic), `exit`.

- Basılan her öğe hafifçe küçülür (`Pressable`); masaüstünde fare üzerine geldiğinde hafifçe büyür.
- Liste ve kartlar kademeli olarak belirir (`FadeSlideIn`). Bu animasyon zamanlayıcı kullanmaz; gecikme, animasyon aralığının başlangıcıdır.
- Android'deki "Animasyonları kaldır" ayarı açıksa (`AppMotion.reduced`) tüm süreler sıfırlanır, döngüsel animasyonlar (radar, nabız, tarama çizgisi, ekolayzer) durur ve açılış animasyonu atlanır.
- Animasyonlar yalnızca `transform` ve `opacity` değiştirir ve `RepaintBoundary` ile yalıtılır. Dokunmatik yüzeydeki parmak parıltısı widget yeniden kurmadan, yalnızca kendi katmanını boyar.

## Bileşenler

Bileşenler `lib/widgets/ui/` altındadır ve tek bir import ile gelir: `import '…/widgets/ui/ui.dart';`

| Bileşen | Görev |
|---|---|
| `Pressable` | Basma, hover ve klavye odak halkası; erişilebilirlik etiketi |
| `AppButton`, `AppIconButton` | Butonlar: `primary` (gradyan), `solid`, `tonal`, `outline`, `ghost` × `AppTone` |
| `AppCard`, `IconBadge` | Kart (renk tonlu, isteğe bağlı cam) ve ikon rozeti |
| `StatusPill`, `PulseDot` | Canlı durum çipi |
| `InlineAlert` | Ekran içi uyarı satırı |
| `EmptyState` | Boş, hata ve desteklenmeyen durum ekranı |
| `Skeleton` | Yüklenirken parlayan yer tutucu |
| `Reveal`, `FadeSlideIn` | Görünür/gizli geçişi, giriş animasyonu |
| `AmbientBackground` | Sabit ışık havuzlu sayfa zemini |
| `AppSegmented`, `AppListTile`, `AppSwitchTile`, `SectionHeader`, `ContentWidth` | Telefon uygulaması: segment kontrol, liste satırları, bölüm başlığı, tablet genişlik sınırı |
| `AppDialog`, `AppBottomSheet`, `AppSnackbar` | Telefon uygulaması: diyalog, alt sayfa ve bildirim (`lib/utils/ui/`) |

## Tema

İki uygulama da sistemin açık/koyu ayarını izler (`ThemeMode.system`). `AppTheme.light` ve `AppTheme.dark` tüm Material bileşenlerini (buton, input, diyalog, switch, slider, tooltip, sayfa geçişi) bu rehbere bağlar. Android 12 ve üstündeki sistem açılış ekranı temaya göre Paper ya da Ink zeminde uygulama ikonunu gösterir; ardından Flutter'daki `BrandSplash` logoyu çizerek bu ekranı devralır.
