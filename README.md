# ⌚ QuickRemote

**WearOS akıllı saatinizden bilgisayarınızı kontrol edin.**

QuickRemote, WearOS tabanlı bir akıllı saatten bilgisayarınıza komut göndermenizi sağlayan bir uzaktan kumanda sistemidir. Firebase Realtime Database üzerinden gerçek zamanlı iletişim kurar.

---

## 🎯 Özellikler

| Komut | Açıklama | İkon |
|-------|----------|------|
| **İleri** | Sunum slaytını ilerletir | ➡️ |
| **Geri** | Sunum slaytını geri alır | ⬅️ |
| **Kilitle** | Bilgisayarı kilitler | 🔒 |

---

## 🏗️ Mimari

```
┌──────────────────┐        ┌──────────────────┐        ┌──────────────────┐
│   WearOS Watch   │──────▶│     Firebase      │──────▶│    PC Listener   │
│   (Flutter App)  │  push  │  Realtime Database│  listen │    (Python)      │
└──────────────────┘        └──────────────────┘        └──────────────────┘
```

1. **Watch App** → Kullanıcı saatteki butona basar, komut Firebase'e yazılır
2. **Firebase** → Komut bulutta saklanır ve değişiklik tetiklenir
3. **PC Listener** → Python scripti değişikliği algılar ve komutu çalıştırır

---

## 📁 Proje Yapısı

```
QuickRemote/
├── quick_remote_watch/      # Flutter WearOS uygulaması
│   ├── lib/
│   │   └── main.dart        # Ana uygulama kodu
│   ├── android/             # Android/WearOS yapılandırması
│   └── pubspec.yaml         # Flutter bağımlılıkları
├── listener.py              # PC tarafı dinleyici script
├── setup_env.ps1            # Ortam değişkenlerini ayarlayan script
└── serviceAccountKey.json   # Firebase servis hesabı (git'e dahil değil)
```

---

## 🛠️ Teknolojiler

- **Watch App:** Flutter, Dart
- **Backend:** Firebase Realtime Database, Firebase Auth (Anonim)
- **PC Listener:** Python, pyautogui, firebase-admin
- **Platform:** WearOS (Wear OS by Google)

---

## 🚀 Kurulum

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.10.3)
- [Python 3.x](https://www.python.org/downloads/)
- Google hesabı (Firebase için)
- WearOS destekli akıllı saat veya [Android Studio WearOS Emülatörü](https://developer.android.com/training/wearables/get-started/creating#virtual-device)

---

### 1. Repoyu Klonlayın

```bash
git clone https://github.com/berat-kaan-akcan/QuickRemote.git
cd QuickRemote
```

---

### 2. Firebase Projesi Oluşturun

1. [Firebase Console](https://console.firebase.google.com/)'a gidin ve **Proje Ekle**'ye tıklayın
2. Proje adı olarak istediğiniz bir isim verin (örn: `MyQuickRemote`)
3. Google Analytics'i isteğe bağlı olarak kapatıp projeyi oluşturun

---

### 3. Realtime Database Kurulumu

1. Firebase Console'da **Build → Realtime Database** sekmesine gidin
2. **Veritabanı Oluştur** butonuna tıklayın
3. Konum olarak size yakın bir bölge seçin (örn: `europe-west1`)
4. **Test modunda başla** seçeneğini seçin (sonra güvenlik kurallarını değiştireceğiz)
5. Veritabanı oluşturulduktan sonra **Kurallar** sekmesine gidin ve şu kuralları yapıştırın:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

6. **Yayınla** butonuna tıklayın

> ⚠️ Bu kurallar sayesinde yalnızca giriş yapmış kullanıcılar veritabanına erişebilir.

---

### 4. Firebase Authentication Kurulumu

1. Firebase Console'da **Build → Authentication** sekmesine gidin
2. **Başlayın** butonuna tıklayın
3. **Oturum açma yöntemi** sekmesinde **Anonim (Anonymous)** sağlayıcısını bulun
4. **Etkinleştir** toggle'ını açıp **Kaydet**'e tıklayın

---

### 5. Kimlik Dosyalarını İndirin

#### 📱 Watch App için: `google-services.json`

1. Firebase Console'da **Proje Ayarları** (⚙️ ikonu) → **Genel** sekmesine gidin
2. **Uygulamalarınız** bölümünde **Android** ikonuna tıklayarak yeni bir Android uygulaması ekleyin
3. Paket adı olarak `com.example.quick_remote_watch` yazın
4. **Uygulamayı kaydet** butonuna tıklayın
5. **google-services.json** dosyasını indirin
6. İndirdiğiniz dosyayı şu dizine koyun:
   ```
   QuickRemote/quick_remote_watch/android/app/google-services.json
   ```
7. Kalan adımları atlayıp Firebase Console'daki kurulumu tamamlayın

#### 🖥️ PC Listener için: `serviceAccountKey.json`

1. Firebase Console'da **Proje Ayarları** (⚙️ ikonu) → **Hizmet hesapları** sekmesine gidin
2. **Yeni özel anahtar oluştur** butonuna tıklayın
3. İndirilen JSON dosyasını proje kök dizinine `serviceAccountKey.json` olarak yeniden adlandırıp koyun:
   ```
   QuickRemote/serviceAccountKey.json
   ```

---

### 6. `listener.py`'daki Database URL'sini Güncelleyin

`listener.py` dosyasını açın ve 14. satırdaki URL'yi **kendi** Firebase Realtime Database URL'niz ile değiştirin:

```python
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://SIZIN-PROJE-ID.firebasedatabase.app/'
})
```

> 💡 Bu URL'yi Firebase Console → Realtime Database sayfasının üst kısmında bulabilirsiniz.

---

### 7. Watch App'i Çalıştırın (Flutter)

```bash
cd quick_remote_watch
flutter pub get
flutter run
```

> ⚠️ WearOS emülatörü veya fiziksel saat bağlı ve eşleştirilmiş olmalıdır.

---

### 8. PC Listener'ı Çalıştırın (Python)

```bash
pip install firebase-admin pyautogui
python listener.py
```

Başarılı bir şekilde çalıştığında şu mesajı göreceksiniz:

```
PC Dinlemeye Başladı... (Çıkmak için pencereyi kapat)
```

---

## 📖 Kullanım

1. **PC'de** `listener.py` scriptini çalıştırın
2. **Saatte** QuickRemote uygulamasını açın
3. Butonlara basarak PC'nizi kontrol edin:
   - 🟠 **Sol ok** → Slayt geri
   - 🟢 **Sağ ok** → Slayt ileri
   - 🔴 **Kilit** → Bilgisayarı kilitle

---

## ⚠️ Önemli Notlar

- `serviceAccountKey.json` dosyası gizli bilgiler içerir, **asla GitHub'a yüklemeyin**
- PC Listener yalnızca **Windows** üzerinde çalışır (ekran kilitleme için `ctypes.windll` kullanır)
- Saat ve PC'nin internet bağlantısı olmalıdır

---

## 📄 Lisans

Bu proje kişisel kullanım amaçlıdır.
