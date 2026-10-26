# Windows'ta yapılacak denemeler

Bu dosyadaki denemeler yalnızca gerçek bir Windows bilgisayarda yapılabilir. Her bölüm adım adım yazıldı; sonuçları bölümün sonundaki tabloya yazın.

---

## Bluetooth klavye onarımı (BtHidRepair)

Arka plan: [docs/raporlar/ACIK_ISLER_RAPOR.md](docs/raporlar/ACIK_ISLER_RAPOR.md), 2. iş.

### Neyi deniyoruz?

Telefon, QuickRemote'un Bluetooth kumandası açık değilken bilgisayarla eşleştiyse (ör. daha önce müzik için), Windows telefonu klavye olarak tanımıyor. Bugün çözüm, telefonu Windows'tan kaldırıp yeniden eşleştirmek.

Linux'ta bilgisayar bunu kendisi düzeltiyor. Windows'ta da aynısını yapmanın bir yolu olabilir: telefonun "klavye/fare" (HID) hizmetini Windows'ta kapatıp yeniden açmak. Belki Windows, hizmeti açarken telefonun kayıtlarını yeniden okur ve telefonu klavye olarak kabul eder.

Bu deneme şu sorulara cevap verecek:

1. **Hizmeti kapatıp açmak (`BluetoothSetServiceState` DISABLE, sonra ENABLE) Windows'a telefonun kayıtlarını yeniden okutuyor mu?** Okutuyorsa telefon klavye olarak çalışmaya başlar. Bütün iş buna bağlı.
2. **Bunun için yönetici izni gerekiyor mu?** Gerekiyorsa uygulamada her seferinde bir UAC onay penceresi ("Bu uygulamanın cihazınızda değişiklik yapmasına izin vermek istiyor musunuz?") çıkacak.
3. **Windows 11'in Bluetooth'u eski Windows API'leriyle aynı davranıyor mu?** Betik Windows sürümünü kaydediyor; mümkünse Windows 10'da da denenir.
4. Ek bilgi: Windows'un önbelleğinde telefonun klavye kaydı var mı, telefon o anda bu kaydı gerçekten sunuyor mu (betik ikisini ayrı ayrı okur).

Olumlu çıkarsa PC uygulaması bunu kendisi yapacak (telefon bağlanınca otomatik). Olumsuz çıkarsa PC penceresine "Telefonu yeniden eşleştir" tuşu konacak.

### Gerekenler

- Bluetooth'lu Windows 10 ya da 11 bilgisayar.
- QuickRemote kurulu bir Android telefon.
- Telefonun bu bilgisayarla **QuickRemote'un Bluetooth ekranı kapalıyken** eşleşmiş olması: sorunlu durum bu. Hazırlık adımında nasıl yapılacağı yazıyor.
- Depodaki betik: `quick_remote_pc\tool\windows_bt_hid_trial.ps1`.

### Hazırlık: sorunlu durumu oluşturmak

Telefon zaten "klavye olarak tanınmıyor" durumundaysa bu bölümü atlayın.

1. Windows'ta **Ayarlar → Bluetooth ve cihazlar** sayfasını açın. Telefon listede varsa üstüne tıklayıp **Cihazı kaldır** deyin.
2. Telefonda QuickRemote **kapalıyken** telefonun Bluetooth ayarlarını açın (telefon böylece görünür olur).
3. Windows'ta **Cihaz ekle → Bluetooth** deyin, telefonu seçin, iki ekranda da kodu onaylayın.
4. Telefonda QuickRemote'u açın, **Bluetooth kumanda** ekranına girin ve bilgisayarı seçin.
5. Bağlantı kurulamamalı ya da hemen kopmalı; uygulama "bilgisayarı yeniden eşleştirin" gibi bir uyarı göstermeli. Bu, denenecek durum. Telefonda **Bluetooth kumanda ekranını açık bırakın**.

### Deneme

1. Depoyu bilgisayara indirin (ya da yalnızca `windows_bt_hid_trial.ps1` dosyasını bir klasöre kopyalayın).
2. Başlat menüsünde **PowerShell** yazın, **Windows PowerShell**'i açın (önce yönetici olmadan, normal açın).
3. Betiğin klasörüne geçin. Örneğin dosya `İndirilenler` içindeyse:

   ```powershell
   cd $HOME\Downloads
   ```

4. Betiği çalıştırın:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows_bt_hid_trial.ps1
   ```

   `-ExecutionPolicy Bypass` yalnızca bu çalıştırma için geçerlidir; Windows'un ayarını değiştirmez.

5. Betik eşleşmiş Bluetooth cihazlarını numaralı listeler. Telefonunuzun numarasını yazıp **Enter**'a basın.
6. Betik sırayla şunları yapar ve ekrana yazar:
   - **ÖNCE**: Windows'un telefon için kurduğu hizmetler (HID var mı), Aygıt Yöneticisi'ndeki kayıtlar, telefonun klavye (HID) kaydı Windows önbelleğinde ve telefonun kendisinde.
   - HID hizmetini **kapatır**, 3 saniye bekler, yeniden **açar**.
   - 10 saniye bekler, **SONRA** durumunu yeniden okur ve bir özet yazar.
7. Telefona bakın: Bluetooth kumanda bağlandı mı? Bir slayt gösterisi ya da Not Defteri açıp telefondaki tuşlara basın; bilgisayar tepki veriyor mu?
8. Özette **ERROR_ACCESS_DENIED** (yönetici izni gerekiyor) yazıyorsa:
   - Başlat menüsünde **PowerShell**'e sağ tıklayın, **Yönetici olarak çalıştır** deyin.
   - 3-7. adımları tekrarlayın.
   - Normal PowerShell'de reddedilip yöneticide çalıştığını da not edin; bu 2. sorunun cevabı.
9. İlk deneme olumsuzsa bir kez daha deneyin, bu sefer telefonda Bluetooth kumanda ekranının açık ve "bağlanıyor" durumunda olduğundan emin olun.

Betik tüm çıktıyı geçici klasöre (`%TEMP%`) `quickremote-bt-deneme-<tarih>.txt` adıyla da kaydeder ve dosyanın yolunu en sonda yazar. Sonucu değerlendirirken gerekecek, Windows geçici klasörü temizlemeden önce bir yere kopyalayın.

Başka seçenekler:

- `-ListOnly`: yalnızca eşleşmiş cihazları listeler, hiçbir şeyi değiştirmez.
- `-NoToggle`: yalnızca ÖNCE bölümünü okur, hizmeti kapatıp açmaz.
- `-Address AA:BB:CC:DD:EE:FF`: listeden seçmek yerine telefonun adresini verir.

### Bir şey ters giderse

- Telefon Windows'ta bozuk görünürse (ör. "Sürücü hatası"): **Ayarlar → Bluetooth ve cihazlar**'da telefonu kaldırıp yeniden eşleştirin. Bugünkü çözüm zaten bu; deneme kalıcı bir şey bozmaz.
- "Bluetooth adaptörü bulunamadı": Bluetooth'u açın ve yeniden deneyin.
- Kırmızı Add-Type hatası çıkarsa ekranın görüntüsünü alın ve deneme dosyasıyla birlikte saklayın.

### Sonuçlar

| Soru | Sonuç |
|---|---|
| Windows sürümü ve derlemesi (betik yazar) | Windows 11 Home 10.0.26300 (2026-10-25) |
| Bluetooth adaptörü (betik yazar) | Intel(R) Wireless Bluetooth(R) |
| ÖNCE: HID hizmeti kurulu mu? | Hayır; Aygıt Yöneticisi'nde "Bluetooth HID Aygıtı" var ama durumu Unknown (`CM_PROB_PHANTOM`) |
| ÖNCE: önbellekteki HID kaydı / telefondan taze okunan | 1 (QuickRemote) / 1 (telefonda Bluetooth ekranı açıkken) |
| DISABLE sonucu, normal PowerShell | `ERROR_NOT_FOUND` (hizmet kurulu olmadığı için) |
| ENABLE sonucu, normal PowerShell | tamam (erişim hatası yok) |
| DISABLE / ENABLE sonucu, yönetici PowerShell (gerekirse) | Gerekmedi (erişim reddi yok) |
| SONRA: HID hizmeti kurulu mu? Aygıt Yöneticisi'nde HID kaydı çıktı mı? | Betik hemen sonra "kurulu" okudu, ama ikinci çalıştırmada "önce: kurulu değil" çıktı: kalıcı olmadı. HID aygıtı hayalet kaldı |
| SONRA: önbellekteki HID kaydı | 1 |
| **Telefon klavye olarak çalıştı mı?** | **Hayır.** İki denemede de telefonun günlüğünde "DESKTOP-BRP8AUC refused the HID link" (bağlantı ~1 s sonra düşüyor); uygulama "Bilgisayar telefonu klavye olarak kabul etmiyor" ekranını gösteriyor |
| Aynı deneme Windows 10'da (yapılabildiyse) | |
| Notlar | Galaxy S23 FE, QuickRemote 1000012. Önbellekte QuickRemote kaydı zaten olduğu hâlde Windows reddediyor; sorun eksik kayıt değil, kurulmayan HID sürücüsü. Çıktılar masaüstünde `quickremote-bt-deneme-20261025-143456.txt` ve `-143616.txt`. Kaldırıp yeniden eşleştirme (aynı gün): telefonu Windows'tan kaldırıp QuickRemote'un Bluetooth ekranı açıkken Ayarlar → Cihaz ekle ile eşleştirince HID aygıtı "OK" oldu ve telefon klavye olarak bağlandı ("HID connected to DESKTOP-BRP8AUC"). Programla eşleştirme (`BluetoothAuthenticateDeviceEx`) 1244 verdi ve iki cihazın onayı aynı süreye denk gelmedi; elle eşleştirme tek seferde çalıştı |

Değerlendirme:

- **Telefon çalıştıysa**: 1. sorunun cevabı evet. PC uygulaması telefon `BtHidRepair` hizmetine bağlanınca aynısını kendisi yapacak. Yönetici izni gerekiyorsa bu bir UAC onayıyla olacak.
- **Hizmet açıldı ama telefon çalışmadıysa** (önbellekte HID kaydı yok, telefondan taze okunan var): Windows önbellekteki kayıtla çalışıyor. "Telefonu yeniden eşleştir" tuşu yapılacak.
- **ENABLE `ERROR_SERVICE_DOES_NOT_EXIST` verdiyse**: Windows kayıtlarında HID olmayan bir hizmeti açmıyor; sonuç yine "yeniden eşleştir" tuşu.
- **Telefondan taze okunan kayıt da 0 ise**: telefon o anda klavye kaydını sunmuyor (Bluetooth kumanda ekranı kapalı ya da arka planda). Ekranı açıp yeniden deneyin.
