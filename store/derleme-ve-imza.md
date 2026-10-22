# Play gereksinimleri: teknik hazırlık, AAB akışı, imza

Tarih: 2026-10-22. **Bu makinede Android SDK kurulamadı** (`dl.google.com` ve Google Maven, ağ ilkesiyle 403; `storage.googleapis.com` açık, Flutter motoru indirilebildi). Bu yüzden `flutter build apk/appbundle` çalıştırılamadı; aşağıdakiler kaynak okuma, Flutter araç kaynağı ve motor dosyasının ELF incelemesiyle çıkarıldı. "Doğrulandı" yazanlar gerçekten denendi, "Denenmedi" yazanlar ilk derlemede kontrol edilecek.

## 1. Hedef API (targetSdk)

- Telefon: `targetSdk = flutter.targetSdkVersion` = **36** (Flutter 3.47.5, `FlutterExtension.kt`), `compileSdk = 37`, `minSdk = 24`. Doğrulandı.
- Saat: `targetSdk = 36`, `compileSdk = 37`, `minSdk = 30`. Doğrulandı.
- Play: 2026'da yeni uygulama ve güncellemeler API 36 hedeflemeli (2027 Ağustos'ta 37). **Kontrol et:** Console > Politika > "Hedef API düzeyi" sayfası. Bugün yeterli.
- Android 16 / API 36 davranışları: uygulama yön kilitlemiyor (`setPreferredOrientations` yok), manifestte `screenOrientation` yok; uçtan uca (edge-to-edge) zorunluluğunu Flutter 3.47 karşılıyor. Büyük ekran kısıtı yok sayılması etkilemez. Pil dostu (Doze) davranışı için izin notuna bak (`izinler.md`).

## 2. 16 KB sayfa boyutu

Play: Android 15+ hedefleyen güncellemeler 16 KB uyumlu olmalı (1 Kasım 2025'ten beri yeni yüklemeler için zorunlu). Telefon uygulaması native kütüphane içerir, saat uygulaması içermez (saf Kotlin/Compose, `ndk` yok).

| Parça | Durum |
|---|---|
| Flutter motoru `libflutter.so` (3.47.5, arm64) | **Doğrulandı:** `storage.googleapis.com/.../android-arm64-release/artifacts.zip` açıldı, `readelf -lW` bütün LOAD segmentleri `0x10000` (64 KB) hizalı: 16 KB'ın katı. |
| `libapp.so` (Dart AOT) | Flutter araç zinciri üretir, motorla aynı bağlayıcı ayarı; denenmedi ama Flutter ≥3.32'den beri uyumlu. |
| NDK | `ndkVersion = flutter.ndkVersion` = 28.2.13676358: r28+ 16 KB hizalamasını varsayılan yapar. |
| AGP 9.1.0 | .so dosyalarını APK/AAB içinde 16 KB'a hizalı (sıkıştırılmamış) paketler (AGP ≥ 8.5.1). |
| `com.google.mlkit:barcode-scanning:17.3.0` (`libbarhopper_v3.so`) | **Denenmedi** (Google Maven kapalı). ML Kit'in 16 KB uyumlu sürümlerinden olduğu biliniyor; ilk derlemede doğrula. |
| CameraX 1.6.1 (`libimage_processing_util_jni.so`) | **Denenmedi**; CameraX 1.4.1'den beri uyumlu. |
| `play-services-wearable`, `permission_handler`, `nsd`, `flutter_background`, `share_plus`, `vibration` vb. | Native .so taşımıyor (yalnız Java/Kotlin). |

İlk derlemede doğrulama (Android SDK'lı makinede):
```sh
cd quick_remote_app && flutter build apk --release --target-platform android-arm64
# 1) zip hizası:
$ANDROID_HOME/build-tools/<son>/zipalign -c -P 16 -v 4 build/app/outputs/flutter-apk/app-release.apk | grep -i "lib/.*\.so"
# 2) ELF hizası (her .so için LOAD p_align >= 0x4000):
unzip -o -q build/app/outputs/flutter-apk/app-release.apk 'lib/*' -d /tmp/apk && for f in /tmp/apk/lib/*/*.so; do echo $f; readelf -lW $f | awk '/LOAD/{print $NF}' | sort -u | tr '\n' ' '; echo; done
```
Biri 0x1000 çıkarsa: `mobile_scanner` için ML Kit sürümünü yükselt (`dev.steenbakker.mobile_scanner.useUnbundled=true` gradle özelliği Play hizmetleri sürümüne geçirir; o zaman .so uygulamada olmaz). Play Console dahili test yüklemesi de aynı uyarıyı verir.

## 3. R8 (küçültme) ve kaynak daraltma

- Flutter 3.47 Gradle eklentisi, `release` türü için **`isMinifyEnabled = true` ve `isShrinkResources = true`** değerlerini kendiliğinden açar (`FlutterPlugin.kt`: `shouldShrinkResources` varsayılan true), `proguard-android-optimize.txt` ve Flutter'ın kendi kurallarını ekler, ayrıca `android/app/proguard-rules.pro` varsa onu da. Uygulamada bu dosya yok. Yani yayın derlemesi **zaten küçültülüyor**; `build.gradle.kts`'te açıkça yazılı değil.
- Riskli yerler, kaynakta incelendi:
  - Kotlin kodunda yansıma yok (`Class.forName`, `getDeclared*`, `getIdentifier` aranıp bulunmadı).
  - Servisler ve etkinlikler manifestte adlarıyla geçiyor, R8/aapt otomatik tutar (`QuickTileService`, `WearListenerService`, `ShortcutActivity`, `IsolateHolderService`).
  - `android_wear_capabilities` dizisi koddan değil Google Play hizmetlerinden okunuyor: `res/raw/keep.xml` ile kaynak daraltmadan korunuyor (var).
  - `mobile_scanner` kendi `proguard-rules.pro`'sunu getirir (ML Kit sınıflarını tutar).
  - `flutter_background` bildirim simgesini adıyla yükler (`mipmap/ic_launcher`); manifestte `android:icon` olarak geçtiği için daraltmadan korunur.
- Saat: `isMinifyEnabled = true`, `shrinkResources` yok (isteğe bağlı iyileştirme, sorunsuz), kural dosyası yok. CI `:app:assembleRelease` + `lintDebug` ile derliyor.
- **Denenmedi:** küçültülmüş yayın APK'sının cihazda çalışması. İlk release APK ile şunları dene: QR tara, Wi-Fi bağlan, Bluetooth HID bağlan, kısayollar + Hızlı Ayarlar kutucuğu, saat bağlantısı (Data Layer), hata günlüğü paylaş. Bir sınıf bulunamazsa `android/app/proguard-rules.pro` açıp `-keep class ...` ekle.
- Kural dosyası şimdilik eklenmedi: derleyemeden tahmini kural yazmak yarar değil gürültü getirir.

## 4. AAB derleme akışı ve imza

### Yükleme anahtarı (bir kez, **[Sen]**)
```sh
keytool -genkeypair -v -keystore ~/quickremote-upload.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```
`quick_remote_app/android/key.properties` (gitignore'da, repoya girmez):
```properties
storeFile=/mutlak/yol/quickremote-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```
- `storeFile` hem mutlak yol hem `quick_remote_app/android/app/` göreli yol olabilir: telefon `file(...)` ile, saat `File.resolve(...)` ile okur ve ikisi de mutlak yolu olduğu gibi kabul eder. İki proje aynı `key.properties`'i okuduğu için tek anahtar yeter. (CI göreli ad kullanıyor: `upload-keystore.jks`.)
- Anahtarı ve parolaları iki ayrı yerde yedekle. Kaybedersen Play'den yükleme anahtarı sıfırlaması istenir (günler sürer).
- `key.properties` yoksa `bundleRelease` bilerek **hata verir** (debug anahtarıyla AAB çıkmasın diye); `assembleRelease` yalnız uyarır.

### Derleme
```sh
export JAVA_HOME=<JDK 17-25>          # 21 önerilir
# Telefon, ilk Play sürümü 1.0.0 -> versionCode 10000
cd quick_remote_app
flutter pub get
flutter build appbundle --release --build-name 1.0.0 --build-number 10000 --dart-define=APP_VERSION=1.0.0
#   -> build/app/outputs/bundle/release/app-release.aab

# Saat, aynı sürüm -> versionCode 1_000_000 + 10000
cd ../quick_remote_wear
sh ./gradlew :app:bundleRelease -PphoneVersionCode=10000 -PappVersionName=1.0.0
#   -> app/build/outputs/bundle/release/app-release.aab
```
`--build-number` verilmezse telefon `pubspec.yaml`'daki `0.1.0+1`'i, yani versionCode 1'i kullanır; saatin varsayılanı da 1_000_001 olur. Gerçek yüklemede her zaman bayrakları ver (ya da `pubspec.yaml`'ı `1.0.0+10000` yap).

### Native hata ayıklama simgeleri (isteğe bağlı)
Play, native çökme çözümlemesi için simge ister ve uyarı verir. `app/build.gradle.kts` `release` bloğuna `ndk { debugSymbolLevel = "SYMBOL_TABLE" }` eklenebilir. Derlenemediği için eklenmedi (yanlış DSL derlemeyi bozar); ilk derlemede dene.

### Play App Signing
Yeni uygulamalarda zorunlu. İlk AAB'yi yüklenen yükleme anahtarıyla imzalarsın, Google asıl dağıtım anahtarını üretir ve yeniden imzalar. Telefon ve saat AAB'si **aynı yükleme anahtarıyla** imzalı olmalı (Console aynı uygulama için tek anahtar tutar); Data Layer'ın çalışması için ikisinin kullanıcıya inen imzası aynı olmalı, aynı uygulama kaydı bunu sağlar.

## 5. versionCode düzeni (release.yml ile tutarlılık)

| | Formül | 1.0.0 | 1.2.3 |
|---|---|---|---|
| Telefon | `MAJOR*10000 + MINOR*100 + PATCH` (`release.yml`, "Version" işi; MINOR, PATCH < 100) | 10000 | 10203 |
| Saat | 1 000 000 + telefonunki (`quick_remote_wear/app/build.gradle.kts`, `-PphoneVersionCode`) | 1 010 000 | 1 010 203 |

- İkisi Play'de aynı kayıtta ama ayrı artefaktlar; her artefaktın versionCode'u kendi içinde hep artmalı. Düzen bunu sağlar.
- **Ön sürüm etiketleri** (`v1.0.0-rc1`) aynı versionCode üretir; Play ikinci yüklemede "bu sürüm kodu zaten kullanıldı" der. Play'e yalnız son etiketle (ya da PATCH'i artırarak) yükle.
- MAJOR ≥ 100 olursa telefonun kodu 1 000 000'u geçer ve saatinkiyle çakışmaz ama karışır; gerçekçi değil.
- Play üst sınırı 2 100 000 000: sorun yok.
- 0. bölümdeki karar: Play'e `1.0.0` ile çıkmak (önceki `0.1.0` GitHub'daki deneme sürümü). Etiket `v1.0.0`.

## 6. `release.yml` için önerilen değişiklik (**yapılmadı**, `.github/` bu iş kapsamı dışındaydı)

Play, uygulamayı kendi anahtarıyla yeniden imzalar; GitHub'daki yükleme anahtarıyla imzalı APK ile Play'den kurulan sürüm birbirinin üstüne kurulamaz ve saat (Play'den) telefonla (APK'dan) konuşamaz. Öneri: `android` işinde APK yerine AAB üret, GitHub release'e **ekleme**, yalnız Actions artefaktı olarak sakla:
```yaml
      - name: Phone AAB
        working-directory: quick_remote_app
        run: |
          flutter config --jdk-dir "$JAVA_HOME"
          flutter pub get
          flutter build appbundle --release --build-name "$VERSION" --build-number "$CODE" \
            --dart-define=APP_VERSION="$VERSION"
      - name: Watch AAB
        working-directory: quick_remote_wear
        run: sh ./gradlew :app:bundleRelease -PphoneVersionCode="$CODE" -PappVersionName="$VERSION"
      # ... imza karşılaştırması için jarsigner -verify -verbose -certs kullanılır (apksigner AAB'yi okumaz)
      # artefakt yolu: quick_remote_app/build/app/outputs/bundle/release/app-release.aab
      #                quick_remote_wear/app/build/outputs/bundle/release/app-release.aab
```
GitHub release'ten telefon APK'sını da kaldırmak istemiyorsan yan yana yan kurulum uyarısını Readme'ye yaz. Karar sende (PLAY listesi 1. bölüm).

## 7. Bağımlılıklar ve lisans

- `pubspec.lock` Flutter eklentileri: reklam, analiz ya da çökme raporlama eklentisi yok (`firebase_*`, `google_mobile_ads`, `sentry` yok). Ağ kitaplığı yok; `dart:io` `HttpClient` yalnız PC'ye.
- Google bileşenleri: `play-services-wearable` 20.0.1 (Data Layer), ML Kit barkod (gömülü), CameraX.
- Lisanslar: yazı tipleri OFL (pakette). Açık kaynak lisans ekranı (`showLicensePage`) henüz yok; Play zorunlu kılmaz, Apache/BSD bildirimleri APK'da `META-INF`'te kalır. PLAY listesi 1. bölümde "olması iyi olanlar".
