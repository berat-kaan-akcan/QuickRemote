# CI ve yayın hattı raporu (2026-10-22)

Kapsam: `GUVENLIK_DENETIMI_2026-10.md` "düzeltilmedi" listesindeki 2. ve 3. maddeler ile `store/derleme-ve-imza.md` 6. bölüm. **GitHub Actions burada çalıştırılamadı**; aşağıdaki her şey statik doğrulandı (YAML ayrıştırma, `actionlint` v1.7.7: hata yok).

## Ne değişti

1. **Birinci taraf Actions SHA'ya sabitlendi** (`ci.yml`, `release.yml`). SHA'lar `git ls-remote --tags https://github.com/<repo>` ile çözüldü (gh API bu oturumda kapalıydı, uydurma yok; hepsi hafif etiket, yani doğrudan commit SHA'sı):
   - `actions/checkout` v4.4.0 `11d5960a326750d5838078e36cf38b85af677262`
   - `actions/upload-artifact` v4.6.2 `ea165f8d65b6e75b540449e92b4886f43607fa02`
   - `actions/download-artifact` v4.3.0 `d3f86a106a0bac45b974a628896c90dbdf5c8093`
   - `actions/setup-java` v4.9.1 `cf277c60eb25467037889841efdb72551f06f6c3`
   - `actions/setup-python` v5.6.0 `a26af69be951a213d495a4c3e4e4022e16d87065`
   Her `uses:` satırında `# vX.Y.Z` yorumu var; artık etiketle yazılı `uses:` kalmadı. Eskiden `@v4` kayan etiketti; v4.4.0 o etiketin gösterdiği commit.
2. **`distributionSha256Sum`** iki `gradle-wrapper.properties`'e eklendi: `17f277867f6914d61b1aa02efab1ba7bb439ad652ca485cd8ca6842fccec6e43` (gradle-9.3.1-all.zip). **Sınır:** yayımlanmış `.sha256` dosyası indirilemedi (`services.gradle.org` `downloads.gradle.org`'a yönlendiriyor, proxy engelliyor). Değer, `services.gradle.org`'dan indirdiğim zip'in kendi hesapladığım SHA-256'sı (zip bütünlüğü `unzip -t` ile sağlam). Yani resmî sayfayla çapraz doğrulanmadı; ilk güvenle alındı. Bir kez elle karşılaştır: `https://services.gradle.org/distributions/gradle-9.3.1-all.zip.sha256`.
3. **Release: AAB.** `android` işine `Phone and watch AAB` adımı ve `android-aab` artefaktı eklendi (imza sırları varsa, yalnız ön sürüm olmayan etiketlerde, versionCode etiket formülünden, telefon/saat imzacı karşılaştırması `keytool` ile). APK'lar duruyor. AAB GitHub sürümüne girmiyor (`release` işi toplamıyor). Ayrıntı: `store/derleme-ve-imza.md` 6. bölüm.
4. **Inno Setup sabitlendi:** `choco install innosetup --version=$env:INNO_SETUP_VERSION` (`6.7.3`, iş düzeyinde env; betik Inno 6 içindir, 7.x var). Kurulu sürüm günlüğe yazılıyor. Runner'da Inno zaten kuruluysa (`ProgramFiles(x86)\Inno Setup 6`) choco çalışmaz.
5. `store/derleme-ve-imza.md` 6. bölüm "yapılmadı"dan "yapıldı" olarak yeniden yazıldı.

## Doğrulama

- YAML iki dosyada ayrışıyor; işler: ci `changes shared pc-linux pc-windows python app wear`, release `version windows linux deb-test android release`.
- `actionlint` v1.7.7 (Go ile derlendi): ikisinde de uyarı yok.
- `needs`/`if` mantığı: `release` hâlâ `[version, windows, linux, deb-test, android]` ister ve yalnız `push`ta çalışır; yeni AAB adımı `android` içinde olduğu için sırasız bağımlılık yok. Sırlar yalnız adım düzeyinde `env:` içinde (`Signing key` ve `key` adımları); AAB adımı sır okumaz, yalnız o an diskte olan `key.properties`'i kullanır, anahtar `if: always()` adımıyla AAB'den sonra siliniyor.

## Gerçek bir GitHub çalıştırması gerektirenler

- Her SHA'nın Actions'ta çözülmesi (özellikle `setup-java` 4.9.1 ve `setup-python` 5.6.0 girdileri aynı kaldı mı).
- Gradle sarmalayıcı sağlaması: ilk `./gradlew` hash'i kabul ediyor mu (iki proje, CI `app` ve `wear` işleri). Hash yanlışsa derleme "checksum mismatch" ile durur, sessiz geçmez.
- `choco install innosetup --version=6.7.3`: sürümün Chocolatey'de var olduğunu doğrulayamadım (topluluk deposuna erişim yok; 6.7.3 yalnız `jrsoftware/issrc` etiketinden doğrulandı). Yoksa `windows` işi o adımda düşer; bu yalnız runner'da Inno yoksa olur. Düşerse sürümü Chocolatey'deki son 6.x'e çek.
- AAB: `flutter build appbundle` ve `:app:bundleRelease` imzayla gerçekten çıkıyor mu, `keytool -printcert -jarfile` AAB'de imzacıyı gösteriyor mu (gösterme biçimi `SHA256:` satırına dayanıyor), Play Console'un yüklemeyi kabul etmesi. Etiketli bir `v1.0.0` (ya da elle `1.0.0`) çalıştırması gerekir; `-test` sürümleri AAB üretmez.
- Hâlâ açık (bu işin dışı): `quick_remote_wear/gradle/wrapper/gradle-wrapper.jar`'ın resmî jar'la karşılaştırılması, `SHA256SUMS.txt` imzası ve `actions/attest-build-provenance`.
