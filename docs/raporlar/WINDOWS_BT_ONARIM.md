# Windows'ta Bluetooth klavye onarımı: yolların karşılaştırması

Tarih: 2026-11-17. Durum: araştırma bitti; (a1) yolu yazıldı ve birim testlerinden geçti, (a2) için deneme betiği yazıldı. **Hiçbiri Windows'ta derlenmedi ya da çalıştırılmadı.** "Denenmedi" yazan her satır belgeden ya da başkasının kodundan çıkarılmıştır. Ölçülmüş olan tek şey 2026-10-25 denemesidir (YAPILANLAR.md, "Windows Bluetooth denemesi"). Deneme listesi 7. bölümde.

## 1. Sorun ve bilinenler

Telefon, QuickRemote'un Bluetooth ekranı kapalıyken (HID kaydı yokken) Windows'la eşleştiyse Windows onu klavye olarak kabul etmiyor; telefonun günlüğünde bağlantı ~1 sn içinde düşüyor ("refused the HID link") ve uygulama `host_unaware` ekranını gösteriyor. Linux'ta PC uygulaması bunu kendisi çözüyor (`BluezHidRepair`); Windows'ta karşılığı yok.

2026-10-25'te ölçülenler (Windows 11 Home 26300, Intel adaptör, Galaxy S23 FE):

- `BluetoothSetServiceState` ile HID'i açmak hata vermedi ama kalıcı olmadı; "Bluetooth HID Aygıtı" hayalet kaldı (`CM_PROB_PHANTOM`), telefon yine reddedildi. Yönetici izni gerekmedi.
- Windows'un önbelleğinde QuickRemote'un HID kaydı vardı. Yani eksik olan kayıt değil, kurulmayan sürücü.
- Telefonu Windows'tan elle kaldırıp, telefonda Bluetooth ekranı açıkken "Cihaz ekle" ile eşleştirmek tek seferde çalıştı. **Çalıştığı görülen tek yol bu.**
- `BluetoothAuthenticateDeviceEx` 1244 verdi. O çağrının parametreleri depoda yok (betiğin bugünkü hâlinde bu çağrı bulunmuyor), bu yüzden aşağıdaki açıklama bir varsayımdır.

## 2. Özet

| | (a1) Kaldır + Windows'un "Cihaz ekle"si | (a2) Kaldır + programla eşleştir | (b) Hayalet HID aygıtını sil | (c) BLE klavye (HID over GATT) |
|---|---|---|---|---|
| Yönetici izni | Belgede yok; denenmedi (HID aç/kapa istemedi) | Aynı | **Evet** (UAC) | Hayır |
| Kullanıcının adımı | ~7 (tuş, telefonu seç, açılan pencerede Bluetooth, telefonu seç, PC'de onay, telefonda onay; telefonda "görünür yap" da gerekebilir) | 3-4 (tuş, telefonu seç, PC'de kodu onayla, telefonda onayla) | 1 tuş + UAC; sonucu belirsiz | Bugünkü ilk eşleştirme kadar (~5); onarım adımı hiç olmaz |
| Çalıştığına dair kanıt | Elle yapılanı çalıştı (2026-10-25); tuşun kendisi denenmedi | Yok; 1244 alındı, nedeni varsayım | Yok; denemedeki bulgu aleyhine | Yok; Android + Windows için güvenilir bir örnek bulunamadı |
| Windows 10 / 11 | API ikisinde aynı; ayar sayfasının adı ve adresi farklı | Win32: ikisinde; WinRT: Windows 10 1511+ | `pnputil /remove-device` Windows 10 2004+; SetupAPI ikisinde | Windows 11 görünüm (Appearance) alanı olmayan BLE cihazlarını listelemiyor olabilir |
| İş | Küçük (yazıldı, 6. bölüm) | Orta; yerel (C++) kod ve deneme gerekir | Küçük ama UAC'li yardımcı süreç | Büyük; telefonda ikinci bir Bluetooth yığını |
| Risk | Düşük | Orta | Yüksek (işe yaramama) | Yüksek (cihaz uyumu) |

**Öneri (uygulandı):** (a1) uygulamada, (a2) önce bir deneme betiğiyle Windows makinesinde sınanacak, ancak çalışırsa uygulamaya alınacak. (b) ve (c) yapılmadı. Gerekçe 6. bölümde.

## 3. (a) Kaldırıp yeniden eşleştirmek

### Kaldırma

`BluetoothRemoveDevice` "cihazla bilgisayar arasındaki kimlik doğrulamayı kaldırır ve cihazın önbelleğe alınmış hizmet bilgisini siler" [1]. Bu, Windows'a kayıtları yeniden okutmanın belgelenmiş tek yolu. Belge yetki şartı yazmıyor; yönetici gerekip gerekmediği **denenmedi**. Cihaz "hatırlanan" değilse `ERROR_NOT_FOUND` döner.

Telefonun tarafında eski eşleşme kalır; yeni eşleştirmede Android onay penceresini yeniden gösterir. Elle yapılan denemede de yalnızca Windows tarafı kaldırılmıştı ve çalıştı.

Bedel: telefonun o bilgisayardaki ses bağlantısı da düşer, eşleşince geri gelir (elle yapılan yolda da aynı).

### (a1) Eşleştirmeyi Windows'a bırakmak

Kaldırdıktan sonra Windows'un kendi penceresi açılır, kullanıcı telefonu orada ekler.

- Hangi pencere: `ms-settings:bluetooth` iki sürümde de Bluetooth ayar sayfasını açar (Windows 10: "Bluetooth ve diğer cihazlar → Bluetooth ya da başka cihaz ekle"; Windows 11: "Bluetooth ve cihazlar → Cihaz ekle"). Taslağın ilk denediği `ms-settings-connectabledevices:devicediscovery` listelerde "Cihaz bulma", "Kablosuz ekrana bağlan" ve "Cast" diye geçiyor [8]; "Cihaz ekle" penceresini açtığı **doğrulanmadı**. `DevicePairingWizard.exe` (eski "Cihaz ekle" sihirbazı) için kaynak bulunamadı. Hangisinin doğru pencereyi açtığı iki sürümde de denenmeli; emin olunan tek adres `ms-settings:bluetooth`.
- Telefon aramada görünmeli: Android yalnızca Bluetooth ayarları açıkken ya da `BtMakeVisibleButton`'dan sonra görünür. Bu, (a1)'e bir adım ekler.
- Windows 11'de "Bluetooth cihazlarını bulma: Varsayılan / Gelişmiş" ayarı var; telefonun Varsayılan'da listelenip listelenmediği **denenmedi** (2026-10-25'te hangi ayarda olduğu not edilmemiş).

### (a2) Programla eşleştirmek

**1244 neden oldu (varsayım).** `BluetoothAuthenticateDeviceEx` belgesi 1244'ü (`ERROR_NOT_AUTHENTICATED`) dönüş kodları arasında saymıyor [2]. Eski `BluetoothAuthenticateDevice` belgesinde bu kod "Bluetooth kimlik doğrulaması başarısız" (`BTH_ERROR_AUTHENTICATION_FAILURE`) anlamında; Windows CE belgesinde "istenen güvenlik düzeyine ulaşılamadı ya da karşı cihaz eşleştirmeyi kesti" [3]. Aynı belge şunu söylüyor [2]:

- `pbtOobData` NULL ise "kimlik doğrulamayı sürdürmek için bir arayüz gösterilir".
- Bant dışı veri dışındaki bütün yöntemlerde (telefonla olan sayı karşılaştırması da öyle) "çağıran `BluetoothRegisterForAuthenticationEx` ile bir geri çağrı kaydetmeli ve `BluetoothSendAuthenticationResponseEx` ile yanıtlamalıdır"; "geri çağrı kayıtlıysa arayüz gösterilmez".

Denemede geri çağrı kaydedilmediyse Windows kendi bildirimini göstermiş, kullanıcının ona tıklayıp onaylaması telefonun onay süresine yetişmemiş olabilir ("iki cihazın onayı aynı ana denk gelmedi" gözlemiyle uyumlu). Bu doğruysa geri çağrıyla PC tarafı anında yanıtlanır ve yalnızca telefondaki onay kalır. **Doğrulanmadı.**

İki API var:

**Win32** (`bluetoothapis.h`; Windows Vista SP2'den beri, 10 ve 11'de aynı): `BluetoothRegisterForAuthenticationEx` → `BluetoothAuthenticateDeviceEx` → geri çağrıda `BluetoothSendAuthenticationResponseEx` → `BluetoothSetServiceState(HID, ENABLE)`.

- Son adım gerekli olabilir: bu API yalnızca eşleştirir; "bir hizmeti etkinleştirmek karşılık gelen sürücüyü kurar" [4]. Eski eşleşmede bu çağrı kalıcı olmadı; taze eşleşmede tutup tutmayacağı **denenmedi**.
- Adresle çalışır, telefonun aramada görünmesi gerekmez (beklenen; denenmedi).
- Dart FFI'a uymuyor: geri çağrı Windows'un kendi iş parçacığından gelir ve `BOOL` döndürmek zorundadır. Dart'ın başka iş parçacığından çağrılabilen geri çağrısı (`NativeCallable.listener`) değer döndüremez; ayrıca `BluetoothAuthenticateDeviceEx` onay gelene kadar çağıranı bekletir. Bu yüzden kod Windows çalıştırıcısında (C++, `laser_overlay.cpp` gibi bir MethodChannel arkasında, kendi iş parçacığında) durmalı.

**WinRT** (`Windows.Devices.Enumeration`, Windows 10 1511+): `BluetoothDevice.FromBluetoothAddressAsync(adres)` → `DeviceInformation.Pairing.Custom.PairAsync(ConfirmOnly | ConfirmPinMatch)` → `PairingRequested` olayında `Accept()` [5].

- Paketlenmemiş masaüstü programında çalıştığının örneği var: `BluetoothDevicePairing` (MIT, konsol programı, Windows 10 1809+) klasik Bluetooth cihazını MAC adresiyle, aramadan, tam bu çağrılarla eşleştiriyor; kaynağındaki not: "`Pairing.PairAsync` UWP olmayan programlarda çalışmıyor, bu yüzden `Pairing.Custom.PairAsync` kullanılıyor" [6]. Telefonla ve HID'le denendiğine dair bilgi yok.
- Ayarlar uygulamasının kullandığı yol bu olduğu için HID sürücüsünü kendisi kurması beklenir. **Doğrulanmadı**; kurmazsa yine `BluetoothSetServiceState` gerekir.
- Yine C++ çalıştırıcısında (C++/WinRT) yazılır; `win32` Dart paketinde WinRT yok.

Güvenlik: PC tarafındaki onayı program verdiği için 6 haneli kod QuickRemote PC penceresinde gösterilmeli ve kullanıcı orada onaylamalı; kodu göstermeden kabul etmek, eşleştirmeyi araya giren birine karşı korumasız bırakır (eşleşen cihaz bir klavye).

Yönetici izni: iki API'nin belgesi de şart yazmıyor; **denenmedi**.

### İsteğe bağlı ek: PC'nin sorunu kendiliğinden fark etmesi

Linux'ta telefon reddedilince PC'nin `BtHidRepair` RFCOMM hizmetine bağlanıyor. Windows PC uygulaması aynı hizmeti sunarsa (Winsock `AF_BTH` + `WSASetService`), hangi telefonun reddedildiğini öğrenir ve "Telefon klavye olarak kabul edilmiyor. Yeniden eşleştir?" diye kendisi sorar; kullanıcı ayarlarda tuş aramaz. Sessizce yapılamaz (eşleştirme iki tarafta onay ister). Telefon bugün isteği teslim edince 15 sn "QuickRemote PC bağlantıyı hazırlıyor" gösterip sonra `host_unaware`'e düşüyor; Windows'ta "bilgisayarın ekranına bakın" demesi için küçük bir protokol eki gerekir. Ayrı bir aşama; **denenmedi**.

## 4. (b) Hayalet HID aygıtını silmek

- Yönetici izni: **gerekir.** `DiUninstallDevice`: "Windows varsayılan olarak aygıt kaldırmak için yönetici yetkisi ister" (`ERROR_ACCESS_DENIED`) [7]. `pnputil /remove-device` ve `/scan-devices` Windows 10 2004'ten beri var ve yönetici komut satırında çalıştırılır [9]. PC uygulaması yönetici olarak çalışmadığı için UAC onayı isteyen ayrı bir süreç gerekir.
- İşe yarayacağına dair kanıt yok, aleyhine bulgu var: denemede `BluetoothSetServiceState(ENABLE)` başarı döndü, hizmet bir an "kurulu" göründü, sonra yine kayboldu. Yani Windows aygıtı kurmayı deniyor ve tutmuyor; hayalet kayıt sonuç gibi görünüyor, neden değil. Kaydı silip yeniden taramak aynı noktaya dönebilir. **Denenmedi.**
- Olumlu yanı: eşleşme ve ses bağlantısı bozulmaz, telefonda onay gerekmez.
- Ucuz bir ön deneme mümkün (yönetici PowerShell: `pnputil /remove-device "<HID örnek kimliği>"`, `pnputil /scan-devices`, ardından HID'i yeniden etkinleştirmek), ama başarısızlık olasılığı yüksek olduğu için öncelik değil.

## 5. (c) Telefonda HID over GATT (BLE klavye)

Windows BLE klavyeyi ayrı bir yığınla (HOGP) ve ayrı bir cihaz olarak eşleştirir; ilk eşleştirmede HID hizmeti hep orada olacağı için bu sorun hiç doğmaz. Bedeli:

- Android'in `BluetoothHidDevice` API'si yalnızca klasik Bluetooth içindir. BLE'de her şey elle yazılır: `BluetoothGattServer` üstünde HID (0x1812), pil ve cihaz bilgisi hizmetleri, rapor haritası, bildirimler, şifreli erişim, `BluetoothLeAdvertiser` ile yayın. `BluetoothHidService.kt`'nin yanında ikinci bir yığın; reddedilme/onarım akışı, saat köprüsü ve fare raporları onun için de yazılır.
- Bulunan açık kaynak örnekler eski; biri yalnızca Android ve macOS ile denenmiş [10]. Android telefonun Windows'a BLE klavye olduğu güvenilir bir örnek **bulunamadı**.
- Windows 11'in Eylül 2023'ten beri yayınında Appearance alanı olmayan BLE cihazlarını listelemediği bildiriliyor (Windows 10 istemiyor) [11]. Android'in `AdvertiseData` API'sinde bu alanı koymanın yolu görünmüyor. İkisi de **doğrulanmadı**; doğruysa Windows 11'de telefon "Cihaz ekle"de hiç görünmez.
- Android BLE yayınında değişen özel adres kullanır; Windows'ta gizlilik açık cihazlarla eşleşip yeniden bağlanamama bildirimleri var [12].
- Kullanıcı yine Windows'ta bir eşleştirme yapar; telefon listede iki kez görünür (ses için klasik, klavye için BLE). Windows'un aynı telefonun iki kaydını nasıl ele aldığı **denenmedi**.
- Yönetici izni gerekmez. PC uygulaması gerekmez (tek gerçek üstünlüğü). Linux'ta da ayrıca denenmesi gerekir.

Haftalar süren, cihazdan cihaza değişen bir iş; bugünkü sorunu çözmek için orantısız.

## 6. Öneri

1. **(a1) uygulamada**: elle çalıştığı görülen yolun aynısı; yeni olan yalnızca `BluetoothRemoveDevice` çağrısı.
2. **(a2) önce betikle denenir**: çalışan değişken olursa uygulamaya C++ çalıştırıcısında eklenir ve adım sayısı ~7'den 3-4'e iner; (a1) yedek kalır. Denenmemiş C++ kodunu, hangi API'nin çalıştığı bilinmeden Windows derlemesine koymamak için uygulamaya yazılmadı.
3. (b) ve (c) yapılmaz.

### Yazılanlar (2026-11-17)

- PC: `services/desktop/bluetooth_pairing.dart` (`BluetoothPairing` arayüzü, saf Dart `BtRepair`: telefonlar önce listelenir, seçilen kaldırılır, ayarlar açılır; üç sonuç: kaldırıldı, kaldırıldı ama ayarlar açılamadı, kaldırılamadı), `windows_bluetooth.dart` (`WindowsBluetooth`, win32 FFI; ayarlar `ms-settings:bluetooth`, ShellExecute ile), Ayarlar → Bluetooth kumanda → "Telefonu yeniden eşleştir" (`bt_repair_section.dart`, yalnızca Windows'ta görünür), iki dilde metinler. Testler: `test/bt_repair_section_test.dart` (sahte `BluetoothPairing` ile).
- Telefon: "bilgisayar telefonu klavye olarak kabul etmiyor" ekranının Windows sekmesinde elle yapılan talimatın altında PC'deki tuşu anlatan not (`btHostUnawareWindowsPc`). Linux sekmesi değişmedi.
- Betik: `quick_remote_pc/tool/windows_bt_pair_trial.ps1`.
- Site: değişiklik gerekmedi (yalnızca "uygulama ne yapacağını adım adım gösterir" diyor). README'nin Bluetooth satırı güncellendi.

## 7. Deneme listesi (Windows makinesinde)

Hazırlık, her bölümden önce telefonu "bozuk" duruma getirmek için: telefonu Windows'tan kaldır; telefonda QuickRemote **kapalıyken** (Bluetooth ekranı hiç açılmamışken; emin olmak için uygulamayı son uygulamalardan at) Windows'un "Cihaz ekle"siyle eşleştir. Sonra telefonda Bluetooth ekranını aç: "Bilgisayar telefonu klavye olarak kabul etmiyor" ekranı gelmeli. Gelmiyorsa bozuk durum oluşmamıştır; bunu da not et.

### 1. Uygulamadaki tuş (a1)

1. `flutter build windows` (ya da `flutter run -d windows`). Derleme hatası olursa çıktısını sakla: `windows_bluetooth.dart` Windows'ta hiç derlenmedi.
2. PC: Ayarlar → "Bluetooth kumanda" bölümü görünüyor mu? "Telefonu yeniden eşleştir"e bas. Listede telefon en üstte ve telefon simgesiyle mi, kulaklık vb. altta mı?
3. Telefonu seç. Beklenen: yeşil "… kaldırıldı" bildirimi ve Windows'un Bluetooth ayar sayfası açılır. Not et: telefon listeden gitti mi, UAC ya da hata çıktı mı, ayarlar öne geldi mi.
4. Telefonda Bluetooth ekranı açıkken (gerekirse "Görünür yap") Windows'ta "Cihaz ekle → Bluetooth" ile telefonu ekle, iki tarafta kodu onayla.
5. Telefonda kumanda kendiliğinden açılmalı; Sonraki/Önceki bir sunumda slayt değiştirmeli. Telefonun sesi geri geldi mi?
6. Telefonun reddedilme ekranında Windows sekmesindeki yeni not okunuyor mu, taşma var mı (iki dilde).
7. Olursa Windows 10'lu bir makinede 2-5'i tekrarla ("Bluetooth ya da başka cihaz ekle").

### 2. Programla eşleştirme betiği (a2)

Normal (yönetici olmayan) PowerShell'de, `quick_remote_pc\tool` klasöründe. Her çalıştırma `%TEMP%\quickremote-bt-eslestirme-<tarih>.txt` yazar; hepsini sakla.

1. `powershell -ExecutionPolicy Bypass -File .\windows_bt_pair_trial.ps1 -Mode List` : telefonun adresini al. Betik C# derleme hatası verirse çıktıyı gönder, devam etme.
2. Telefon bozuk durumdayken: `... -Mode Win32 -Address <adres>`. Betik kaldırır, Enter bekler; telefonda Bluetooth ekranını aç (görünür yapma), Enter'a bas. Ekrandaki KOD ile telefondakini karşılaştır, telefonda onayla.
3. Not et: "geri çağrı" satırı çıktı mı; Windows kendi bildirimini de gösterdi mi; sonuç 0 mı 1244 mü; kaç saniye sürdü; HID "eşleştirdikten sonra" kendiliğinden kuruldu mu yoksa ENABLE'dan sonra mı; 15 sn sonra Aygıt Yöneticisi'nde HID "OK" mi; telefonda kumanda açıldı mı; bir dakika sonra `-Mode Status` ile hâlâ kurulu mu (2026-10-25'te kalıcı olmamıştı).
4. 1244 çıkarsa `-AuthRequirement 5`, sonra `1` ile yinele (`-NoRemove` ekle; telefon zaten kaldırılmış olur).
5. Telefonu yeniden bozuk duruma getir, sonra `... -Mode WinRT -Address <adres>`. "WinRT: derleme" hata verirse bu da bir sonuç (başvurular Windows sürümüne göre değişebilir); o zaman aynı çağrıları yapan hazır araçla denenebilir: [BluetoothDevicePairing](https://github.com/PolarGoose/BluetoothDevicePairing) `pair-by-mac --mac <adres> --type Bluetooth` (üçüncü taraf bir program; indirip indirmemek sana kalmış).
6. Not et: "PairingRequested" satırındaki tür (ConfirmOnly / ConfirmPinMatch) ve kod; durum `Paired` mi; HID kendiliğinden kuruldu mu; telefonda kumanda açıldı mı.
7. `ERROR_ACCESS_DENIED (5)` görülen her adımı yönetici PowerShell'inde yinele ve hangisinin yönetici istediğini yaz.

### Sonuç tablosu (doldurulacak)

| Soru | (a1) tuş | (a2) Win32 | (a2) WinRT |
|---|---|---|---|
| Windows sürümü | | | |
| Derlendi / çalıştı mı | | | |
| Kaldırma sonucu, yönetici gerekti mi | | | |
| Eşleştirme sonucu (kod, süre) | | | |
| Telefonun "görünür" olması gerekti mi | | | |
| Kaç onay (PC / telefon), Windows bildirimi çıktı mı | | | |
| HID kendiliğinden kuruldu mu, kalıcı mı | | | |
| Telefon klavye olarak çalıştı mı | | | |
| Ses geri geldi mi | | | |

## Kaynaklar

1. [BluetoothRemoveDevice](https://learn.microsoft.com/en-us/windows/win32/api/bluetoothapis/nf-bluetoothapis-bluetoothremovedevice)
2. [BluetoothAuthenticateDeviceEx](https://learn.microsoft.com/en-us/windows/win32/api/bluetoothapis/nf-bluetoothapis-bluetoothauthenticatedeviceex), [BluetoothRegisterForAuthenticationEx](https://learn.microsoft.com/en-us/windows/win32/api/bluetoothapis/nf-bluetoothapis-bluetoothregisterforauthenticationex)
3. [BluetoothAuthenticateDevice](https://learn.microsoft.com/en-us/windows/win32/api/bluetoothapis/nf-bluetoothapis-bluetoothauthenticatedevice), [BthAuthenticateEx (Windows Embedded Compact)](https://learn.microsoft.com/en-us/previous-versions/windows/embedded/gg155622(v=winembedded.80))
4. [BluetoothSetServiceState](https://learn.microsoft.com/en-us/windows/win32/api/bluetoothapis/nf-bluetoothapis-bluetoothsetservicestate)
5. [DeviceInformationCustomPairing](https://learn.microsoft.com/en-us/uwp/api/windows.devices.enumeration.deviceinformationcustompairing), [Pairing a set (örnek)](https://learn.microsoft.com/en-us/windows/uwp/devices-sensors/pairing-a-set)
6. [PolarGoose/BluetoothDevicePairing](https://github.com/PolarGoose/BluetoothDevicePairing) (`src/Bluetooth/Devices/DevicePairer.cs`)
7. [DiUninstallDevice](https://learn.microsoft.com/en-us/windows/win32/api/newdev/nf-newdev-diuninstalldevice), [CM_Uninstall_DevNode](https://learn.microsoft.com/en-us/windows/win32/api/cfgmgr32/nf-cfgmgr32-cm_uninstall_devnode)
8. [ms-settings adres listesi (winaero)](https://winaero.com/ms-settings-commands-in-windows-10), [Windows 11 ayar kısayolları (elevenforum)](https://www.elevenforum.com/t/create-shortcuts-to-open-pages-in-settings-in-windows-11.522/latest)
9. [PnPUtil komut sözdizimi](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax)
10. [BLE HID Peripheral for Android](https://www.github.com/rdady/BLE-HID-Peripheral-for-Android)
11. [Espruino: Bluetooth LE HID Keyboards](https://www.espruino.com/BLE%20Keyboard)
12. [Microsoft Q&A: gizliliği açık BLE cihazına bağlanamama](https://learn.microsoft.com/en-us/answers/questions/390918/unable-to-connect-ble-device-with-ble-privacy-enab)
