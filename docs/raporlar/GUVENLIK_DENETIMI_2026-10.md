# Güvenlik denetimi, Ekim 2026

Kapsam: TLS/pinleme/PIN akışı, hız sınırları ve DoS, komut allowlist'i ve
önek doğrulaması, PowerShell/Python/kabuk enjeksiyonu, dosya yolları, günlük
temizleme (`AppLog.redact`), Android manifesti, imzalama, CI, bağımlılıklar,
udev kuralı ve Linux kurulumu. Taban: shared 39, app 172, pc 310, python 71
test; `dart analyze` temiz. Şimdi: shared 43, pc 320 (+10), app 268 (başka
ajanların yeni testleri dahil), python 71; hepsi yeşil, analiz temiz.
Hiçbir şey commit edilmedi.

## Özet

Çekirdek tasarım sağlam: TLS + parmak izi pini (ilk bağlantıda PIN gönderilmeden
önce durur), sabit zamanlı PIN karşılaştırması, IP başına/genel hız sınırları,
yerel ağ filtresi, handshake kapısı, ön-kimlik bayt bütçesi, Origin reddi,
compression kapalı. Telefonun gönderdiği hiçbir metin PowerShell/Python/kabuğa
girmiyor: parametreli komutlar `int`e çevrilip aralık denetiminden geçiyor,
slayt resim yolunu uygulama kendisi üretiyor (`slide-$index-$width.jpg`, ikisi
de int), `pkexec` betiği sabit. Yol gezinmesi (path traversal) ve komut
enjeksiyonu bulunmadı.

Bulunan ve düzeltilen gerçek sorunlar, hepsi yerel ağdaki bir saldırgan veya
eşleşmiş bir telefon için hizmet aksatma (DoS) ya da sertleştirme düzeyinde;
kritik/yüksek bir sızma yolu yok.

## Düzeltilenler

| # | Önem | Sorun | Düzeltme |
|---|------|-------|----------|
| 1 | Orta | TLS handshake'i bitip HTTP isteği hiç gelmeyen bağlantılar sınırsız tutulabiliyordu. `HttpServer`ın boşta zaman aşımı 120 s ve handshake kotası handshake bitince serbest kalıyor; yerel ağdaki biri dosya tanıtıcılarını (fd) tüketip telefonun bağlanmasını engelleyebilirdi. İstek başı bitmeden sonsuz akan başlık da ~1 MB'a kadar bellek tutuyordu. | `tls_handshake_gate.dart`: handshake sonrası bağlantı 10 s içinde istek başını (boş satır) bitirmeli (`requestTimeout`), en çok 16 KB (`maxHeaderBytes`); istek bekleyen bağlantı IP başına 16, toplam 128 (`maxAwaitingPerClient/Total`, `awaitingRequest`). Boş satır parça sınırlarında da bulunuyor; istek başı tamamlanınca denetim kalkar, WebSocket etkilenmez. Satırlar: `_awaitRequest` (~111), `_RawSocketAdapter._withinHead`. Test: `tls_handshake_gate_test.dart` "after the handshake" grubu (4 test). |
| 2 | Orta | Eşleşmiş bir istemci `LEFT_UP`/`MODE_ARROW`/`LASER_OFF` komutlarını hız sınırına tabi olmadan sınırsız gönderebiliyordu (`_releaseCommands` sınırı tamamen atlıyordu). Her biri programa ulaşır (Windows'ta PowerShell kuyruğu). Ayrıca allowlist dışı komutlar hiç sayılmıyordu: saniyede sınırsız 1 KB'lık mesaj + günlük satırı. | `websocket_server.dart` `_countCommand` (~796): bırakma komutlarının kendi 30/sn bütçesi var (düğmeyi bırakma yine başka komutların bütçesinden etkilenmiyor); reddedilen komutlar da sayılıyor; saniyede 300'den fazla mesaj = taşkın, 4008 ile bağlantı kesilir. Testler: "the button releases have a budget of their own", "a release is not dropped because...", "commands refused by the allowlist count too...". |
| 3 | Düşük | Önekli komutların değeri gevşek doğrulanıyordu: `SLIDE_PREVIEW:` + 900 karakter olduğu gibi `ack` olarak geri yankılanıyor, `lastCommand` ile arayüze ve günlüğe gidiyordu; `START_AT:0x10` ve `START_AT:+5` `int.tryParse` yüzünden çalışıyordu. Günlüğe telefonun uydurduğu metin (satır sonu dahil) giriyordu. | `quick_remote_shared/remote_commands.dart` `RemoteCommands.isValid`: tam allowlist ya da bilinen önek + 1-9 ASCII rakam. Sunucu bunu kullanıyor; reddedilen komutun metni günlüğe yazılmıyor, yalnızca uzunluğu. Testler: shared `isValid` grubu (3 test) + sunucu "a prefix command with anything but a short number...". |
| 4 | Düşük | `AppLog.redact` `password`, `secret`, `token`, `QR_CERT_PASSWORD=...`, `Bearer ...` biçimlerini temizlemiyordu (şu an günlüğe girmiyorlar, ama kural eksikti ve CLAUDE.md "yeni özel veri türü = kural + test" diyor). | `app_log.dart` `_secretWord`, `_bearer`. İlk denemede öne `\w*` koymak uzun sözcüklerde karesel süre yapıyordu (1000 karakterlik satırlarda test 90 sn'ye çıktı); `\w*` öne konmadan yazıldı, 100 KB'lık adversarial girdiler <70 ms. Test: "hides passwords, secrets and tokens...". |
| 5 | Düşük | `AuthManager._failedAttempts` yalnızca engel süresi dolunca/başarıda temizleniyordu; farklı /64'lerden (ULA `fd..`) denemelerle tablo sunucu açık kaldıkça büyüyebilirdi. | `auth_manager.dart`: 1024 adresi aşınca 60 sn'dir başarısız olmayan ve engelli olmayan kayıtlar unutulur (`maxTrackedAddresses`). Hız sınırı davranışı değişmedi. Testler: "memory" grubu (2 test). |
| 6 | Düşük | Manifestte düz metin trafik açıkça kapatılmamıştı (targetSdk 36'da varsayılan kapalı, ama açık yazmak sertleştirme). | `AndroidManifest.xml`: `android:usesCleartextTraffic="false"`. Gerçek cihazda doğrulanmadı (bkz. aşağıda). |
| 7 | Düşük | CI: `actions/checkout` token'ı `.git/config`'te bırakıyordu; sürüm işinde `GH_TOKEN` tüm işe açıktı. | `ci.yml`/`release.yml`: checkout'lara `persist-credentials: false` (yalnızca `changes` işi hariç: `dorny/paths-filter` push'ta git ile base'i çekiyor, kırılmasın diye bırakıldı, yorumla belirtildi); `GH_TOKEN` yalnızca "Draft release" adımının `env:`'ine taşındı. YAML ayrıştırması doğrulandı; gerçek Actions çalıştırması yapılamadı. |

## Doğrulanıp sorun çıkmayanlar

- **Enjeksiyon:** Windows betiklerine giren değerler yalnızca `int` (START_AT 1..9999, renk 0..0xFFFFFF, ses 0..100, `SLIDE_THUMB`); `SlideExporter.script` yolu uygulamanın kendi ürettiği, tek tırnakta kaçışlı; sertifika parolası/yolu ortam değişkeniyle geçiyor. Python köprüleri JSON satırı alıyor, telefon metni içermiyor. `pkexec sh -c` betiği sabit (`_udevRule` sabit), telefon girdisi yok.
- **Dosya yolları:** `slide-previews/` altındaki ad yalnızca int'lerden; kullanıcı dosyası okunmuyor/yazılmıyor. Günlük dışa aktarma kullanıcının seçtiği yere yazıyor.
- **TLS/pin:** İstemcide güvenilen kök yok, parmak izi `badCertificateCallback`'te karşılaştırılıyor, sabitleme yalnızca PIN kabulünden sonra kalıcı; QR'daki parmak izi uyuşmazlığında geçersiz kılma yok; yeniden bağlanmada `certMismatch/unverified/certRejected` döngüyü keser.
- **PIN:** 6 hane, `Random.secure`, sabit zamanlı; IP başı 5 hata/60 s engel, genel 20/dk duraklatma + PIN yenileme (beklenen tahmin süresi pratikte sonsuz).
- **Ön kimlik:** 4 KB bütçe, parçalı mesaj toplamı çerçeve başlıklarından sayılıyor, permessage-deflate kapalı, Origin'li istek reddi, 5 s auth zaman aşımı.
- **Impress köprüsü:** UNO borusu soket, sahibi `uid` değilse reddediliyor; eski localhost:2002 dinleyicisi için güncelleme düğmesi var.
- **pywpsrpc:** tek sürüm, 8 tekerlek için `--hash`, `--require-hashes --only-binary :all:` (sdist `setup.py` çalışamaz).
- **Dağıtım paketleri:** deb `--root-owner-group`, postinst/postrm kuralı kaldırıyor, PKGBUILD kaynağı sürüm etiketli sha256'lı (release iş akışı dolduruyor).
- **İmzalama:** `key.properties` ve keystore `.gitignore`'da; anahtar yoksa `bundleRelease` hata veriyor; CI'da anahtar adım env'inde, iş sonunda `rm -f`, telefon/saat APK imza özeti karşılaştırılıyor; üçüncü taraf eylemler SHA'ya sabit.
- **Manifest:** `allowBackup=false`; `MainActivity` dışında dışa açık bileşenler: `QuickTileService` (`BIND_QUICK_SETTINGS_TILE` izni şart), `WearListenerService` (gms bağlayıcısı arayanın Google Play hizmetleri olduğunu doğrular), `ShortcutActivity` `exported=false`. `taskAffinity=""`.
- **Günlük:** `redact` PIN, QR, parmak izi (hex/iki nokta/base64url), güvenlik kodu, not/başlık, yollar için kapsamlı; bir dizi saldırgan girdi elle denendi.

## Yapılmayanlar ve nedenleri

1. **`MainActivity` dışarıdan `quickremote://connect/last|scan|bluetooth` ile açılabilir (düşük).** Aktivite zorunlu olarak `exported` ve kod yorumu "dışarıdan açılamaz" diyor; oysa başka bir uygulama açık (explicit) intent ile bu bağlantıları gönderip son bilgisayara bağlanmayı ya da kamerayı açtırabilir. Etkisi küçük (kendi bilgisayarına bağlanır). Çözüm önerisi: `ShortcutActivity`/`QuickTileService` intent'ine süreç ömürlü rastgele bir jeton ekleyip `LaunchLink.linkOf`'ta denetlemek. Kotlin değişikliği ve cihaz testi gerektirdiği, kapsamım manifest/gradle olduğu için yapılmadı. Yorumdaki "web sayfası açamaz" doğru (tarayıcı yalnızca `host=watch` filtresini görür).
2. **Gradle sarmalayıcısında `distributionSha256Sum` yok** (iki proje). Hash'i doğrulayamadım (ağ erişimi yok, uydurmadım). `services.gradle.org/distributions/gradle-9.3.1-all.zip.sha256` değerini her iki `gradle-wrapper.properties`'e eklemek önerilir; `quick_remote_wear/gradle/wrapper/gradle-wrapper.jar` repoda ikili dosya olarak duruyor, resmî jar ile karşılaştırılmalı.
3. **Birinci taraf Actions sürüm etiketine bağlı** (`checkout@v4`, `upload/download-artifact@v4`, `setup-java@v4`, `setup-python@v5`). SHA'larını çözemedim (GitHub erişimi kapalı), tahmin etmedim. Ayrıca `choco install innosetup` sürümsüz; yayın için `actions/attest-build-provenance` (SHA'lı) ve `SHA256SUMS.txt` imzası önerilir.
4. **Windows sertifika parolası `cert_pwd.txt` olarak `.pfx`in yanında** (aynı kullanıcı profili): koruma dosya izinlerine bağlı, parola ek güvenlik sağlamıyor. DPAPI ile korumak mümkün ama Windows'ta çalıştırıp doğrulanamaz.
5. **Mesaj hızı yalnızca metin için sınırlı;** 9 baytlık ikili hareket çerçeveleri (kimliği doğrulanmış istemci) sınırsız işleniyor (birleştirici ucuz). Gerçek bir dokunmatik/lazer akışı 250 Hz'e çıkabileceğinden kesme eşiği cihazda ölçülmeden konmadı.
6. **TLS bağlantı sıklığı:** sınırlı eşzamanlı handshake var, saniyedeki yeni bağlantı sayısı için hız sınırı yok; yerel ağdaki biri RSA el sıkışmalarıyla CPU harcatabilir. Eşzamanlılık sınırı bunu sınırlıyor; ek sınır gerçek ağda ölçülmeli.
7. **PowerShell çıktı sentineli (`___PS_DONE___`):** belge notlarına yazılmış bu satır köprüyü kaydırabilir (yalnızca bozuk durum, yetki yok); not metni PC tarafından geldiği için telefondan tetiklenemez.
8. **Saat (Wear) hareket mesajı:** `WearBridge._onMove` sonlu ama çok büyük (1e300) değerlerde Bluetooth modunda neredeyse sonsuz döngü kurabilir. Kaynak aynı imzalı saat uygulaması olduğu ve dosya kapsamım dışında olduğu için bildirildi; `dx/dy` için `abs() > 1e4` ise yok saymak yeterli.
9. **udev kuralı** (`TAG+="uaccess"`) oturumdaki her uygulamaya sanal klavye verir; bu ürün işlevi gereği ve belgelenmiş (paket kaldırınca kural gidiyor).
10. **Otomatik güncelleme kontrolü** yalnızca bildirir; URL `github.com/berat-kaan-akcan/QuickRemote/` ile sınırlı ve yalnızca https açılır (doğrulandı).

## Gerçek cihaz/ortam gerektirenler

- `usesCleartextTraffic="false"` ile birleştirilmiş manifest (Android derlemesi bu ortamda yapılmadı); uygulama yalnızca `wss://` ve mDNS kullandığı için etki beklenmiyor, ama bir `flutter build apk` ve telefonda bağlantı denemesi gerekir.
- `TlsHandshakeGate` sınırları: gerçek Windows/Linux sunucuda telefonun bağlanması (istek başı birkaç ms içinde geliyor; 10 s / 16 KB / 16 bağlantı sınırları bunun çok üstünde) ve yavaş Wi-Fi'de. Birim testleri loopback'te geçiyor.
- CI iş akışı değişiklikleri GitHub'da bir kez çalıştırılmalı (`persist-credentials: false` ile adımlar).
- Windows tarafı (PrintWindow, lazer katmanı) CLAUDE.md'de zaten "hiç çalıştırılmadı" diye işaretli; güvenlik açısından ayrıca denetlenemedi.

## CLAUDE.md için öneri (lead ekleyebilir)

Protokol bölümüne: "Komutlar `RemoteCommands.isValid` ile doğrulanır (önek değeri 1-9 rakam); her metin mesajı (reddedilen dahil) saniyede 30 komut bütçesine sayılır, bırakma komutlarının ayrı 30/sn bütçesi vardır, 300'ü aşan mesaj bağlantıyı 4008 ile keser. `TlsHandshakeGate` handshake sonrası da 10 s / 16 KB içinde istek başı bekler (IP başına 16, toplam 128)."
