# QuickRemote Gizlilik Politikası

Son güncelleme: 22 Ekim 2026

> Yayın öncesi doldurulacak yerler: **[GELİŞTİRİCİ ADI]** ve **[DESTEK E-POSTASI]**. Bu sayfa Play Console'daki "Gizlilik politikası" adresinde herkese açık olmalıdır.

QuickRemote; Android telefonunuzu (ve isteğe bağlı olarak Wear OS saatinizi) bilgisayarınızdaki sunum için kumandaya çeviren bir uygulamadır. Bu politika, Android uygulamasının (telefon) ve saat uygulamasının verilerinizle ne yaptığını anlatır.

**Kısaca:** QuickRemote geliştiriciye hiçbir veri göndermez. Hesap, reklam, analiz ya da çökme raporlama yoktur. Telefonunuz yalnızca sizin kendi bilgisayarınızla, yerel ağda ya da Bluetooth ile konuşur.

## 1. Geliştirici

**[GELİŞTİRİCİ ADI]**, iletişim: **[DESTEK E-POSTASI]**. Kaynak kod ve sorun takibi: https://github.com/berat-kaan-akcan/QuickRemote

## 2. Hangi veriler nereye gider

### 2.1 Bilgisayarınıza (Wi-Fi modu)
Telefon, sizin kendi bilgisayarınızda çalışan QuickRemote PC uygulamasına yerel ağ üzerinden bağlanır. Bağlantı TLS ile şifrelidir; PC uygulaması ilk çalıştığında kendi sertifikasını üretir ve telefon bu sertifikanın parmak izini tanır (QR kodla eşleştirmede ya da güvenlik kodunu karşılaştırdığınızda). PC yalnızca yerel ağdaki adreslerden gelen bağlantıları kabul eder.

Telefondan PC'ye giden veriler:
- Eşleştirme için 6 haneli PIN.
- Cihazın adı: Android ayarlarındaki cihaz adınız ya da modeli. PC, bağlı telefonlar listesinde göstermek için kullanır.
- Kumanda komutları: sonraki/önceki slayt, başlat/bitir, siyah/beyaz ekran, lazer ve çizim hareketleri, ses ve medya komutları.

PC'den telefona gelen veriler: slayt numarası ve sayısı, konuşmacı notları, slayt görüntüleri (isteğe bağlı, Ayarlar'dan kapatılır), çalan medyanın adı ve ses düzeyi, hata durumları, PC'nin ana makine adı. Bu veriler yalnızca bellekte tutulur ve ekranda gösterilir.

Bu veriler geliştiriciye ya da üçüncü bir tarafa **gönderilmez**; yalnızca sizin kendi bilgisayarınıza gider.

### 2.2 Bilgisayarınıza (Bluetooth modu)
Bluetooth modunda telefon, bilgisayarınıza Bluetooth klavye ve fare olarak görünür. Bilgisayarınıza yalnızca tuş ve fare hareketleri gider; PC uygulaması gerekmez. Uygulama çevredeki Bluetooth cihazlarını taramaz; yalnızca eşleştirilmiş cihazlarınızı okuyarak bilgisayarı bulur. "Telefonu görünür yap" düğmesine basarsanız, Android sizden telefonu birkaç dakika bilgisayarların bulabileceği şekilde görünür yapmanızı ister.

### 2.3 Saat uygulaması
Saat, bilgisayarla doğrudan konuşmaz. Komutlarını (slayt ileri/geri, siyah/beyaz ekran, lazer hareketi) telefondaki QuickRemote'a Google'ın Wear OS Veri Katmanı (Wearable Data Layer) ile iletir; telefon bunları bilgisayara aktarır. Telefon da saate bağlantı durumunu, PC'nin adını, slayt numarasını ve sayısını, tema seçiminizi, konuşma süresi saatini ve uyarıları gönderir. Bu iletişim telefon ile saat arasında Google Play hizmetleri üzerinden olur; QuickRemote bunu bir sunucuya göndermez. Lazer için isteğe bağlı olarak saatle telefon arasında doğrudan bir Bluetooth bağlantısı kullanılır. Saat yalnızca tema seçimini ve ipucu gösterilip gösterilmediğini kendi üzerinde saklar.

### 2.4 Kamera
Kamera yalnızca PC ekranındaki eşleştirme QR kodunu okumak için, siz taramayı açtığınızda kullanılır. Görüntü kaydedilmez, saklanmaz, hiçbir yere gönderilmez. QR kodunu okumak için uygulamaya gömülü Google ML Kit barkod modeli cihazda çalışır. Google ML Kit, kendi veri açıklamasında belirtildiği şekilde Google'a kullanım ve performans ölçümleri (uygulama sürümü, cihaz bilgisi, hata ve süre ölçümleri gibi) gönderebilir; ayrıntılar: https://developers.google.com/ml-kit/android-data-disclosure . Kameranız ya da taranan görüntü bu ölçümlerin parçası değildir. QR yerine IP adresini ve PIN'i elle yazarak da bağlanabilirsiniz; bu durumda kamera hiç açılmaz.

## 3. Telefonda saklananlar

Aşağıdakiler yalnızca telefonunuzda, uygulamanın özel depolama alanında durur. Android yedeklemesi kapalıdır (`allowBackup=false`), bulut yedeğine girmez. Uygulamayı silince ya da verilerini temizleyince gider.
- Ayarlar: dil, tema, zamanlayıcı ve titreşim tercihleri, seçili program, vb.
- Son bağlanılan bilgisayarlar (en fazla beş): ad, adres, port ve PIN'i. Kısayol ve hızlı ayar kutucuğu bunları kullanır. Her PC açılışında yeni PIN ürettiği için eski kayıtlar geçersiz kalır.
- Bilgisayarların sertifika parmak izleri (bağlantının doğru bilgisayara gittiğini doğrulamak için).
- Son 20 sunumun geçmişi: tarih, süre ve slayt başına geçen süreler. Yalnızca sizin görüntülemeniz içindir. "Raporu kopyala" dediğinizde panoya metin olarak kopyalanır.
- Hata günlüğü: telefonun özel klasöründe `quickremote.log` (en fazla 1 MB'lık üç dosya). PIN'ler, sertifika parmak izleri, `quickremote://` bağlantıları, dosya yolları, not ve medya başlıkları kaydedilmeden önce silinir. Günlük hiçbir yere gönderilmez.

## 4. Sizin başlattığınız paylaşımlar

- **Hata günlüğünü paylaş:** Günlüğü geçici bir dosyaya yazar ve Android'in paylaşma menüsünü açar. Nereye göndereceğinize siz karar verirsiniz.
- **Sorun bildir:** Tarayıcınızda GitHub'ın yeni sorun sayfasını açar; uygulama sürümü, Android sürümü ve PC'deki program adları forma önceden yazılır. Siz göndermedikçe hiçbir şey gönderilmez. GitHub'ın kendi gizlilik politikası geçerlidir.

## 5. Yapmadıklarımız

- Reklam yok, reklam kimliği kullanılmaz.
- Kullanım analitiği, izleme ya da uzaktan çökme raporlama yok.
- Hesap, kayıt ya da oturum açma yok.
- Konum bilgisi istenmez ve kullanılmaz. Kişileriniz, dosyalarınız, fotoğraflarınız, mikrofonunuz erişilmez.
- Veri satılmaz, kiralanmaz, üçüncü taraflarla paylaşılmaz.

## 6. İzinler ve nedenleri

| İzin | Neden |
|---|---|
| Kamera | Eşleştirme QR kodunu okumak. |
| Bluetooth (bağlanma, görünür olma; Android 12 öncesinde eski Bluetooth izinleri) | Telefonu bilgisayara klavye/fare yapmak; eşleşmiş bilgisayarı bulmak; saatin lazer bağlantısı. |
| Bildirimler | Kumanda açıkken çalışan ön plan hizmetinin bildirimi. |
| Ön plan hizmeti (bağlı cihaz) ve uyanık kalma | Telefon kilitlenirken bağlantıyı sürdürmek. |
| Ağ erişimi, Wi-Fi çok noktaya yayın | Bilgisayarı yerel ağda bulmak ve bağlanmak. |
| Titreşim | Zamanlayıcı uyarıları. |

## 7. Çocuklar

QuickRemote çocuklara yönelik değildir ve çocuklardan bilerek veri toplamaz; zaten kimseden veri toplamaz.

## 8. Haklarınız ve silme

Geliştirici sizin hakkınızda hiçbir veri tutmadığı için silinecek bir hesap ya da sunucu verisi yoktur. Telefonda saklananları uygulamayı silerek ya da Android Ayarlar > Uygulamalar > QuickRemote > Depolama > Verileri temizle ile silebilirsiniz. Bilgisayarınızdaki bağlı telefonlar listesinden bir telefonu kaldırabilirsiniz.

## 9. Değişiklikler

Bu politika değişirse bu sayfa güncellenir ve üstteki tarih değişir. Önemli değişiklikler uygulamanın yeni sürümünün notlarında belirtilir.

## 10. İletişim

**[DESTEK E-POSTASI]** ya da https://github.com/berat-kaan-akcan/QuickRemote/issues
