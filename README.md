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

- Flutter SDK (^3.10.3)
- Python 3.x
- Firebase projesi (Realtime Database aktif)
- WearOS destekli akıllı saat veya emülatör

### 1. Firebase Kurulumu

1. [Firebase Console](https://console.firebase.google.com/)'dan yeni bir proje oluşturun
2. **Realtime Database** oluşturun
3. **Authentication** bölümünden **Anonymous sign-in** metodunu aktif edin
4. Servis hesabı anahtarını indirip proje kök dizinine `serviceAccountKey.json` olarak kaydedin
5. `google-services.json` dosyasını `quick_remote_watch/android/app/` dizinine koyun

### 2. Watch App (Flutter)

```bash
cd quick_remote_watch
flutter pub get
flutter run
```

> ⚠️ WearOS emülatörü veya fiziksel saat bağlı olmalıdır.

### 3. PC Listener (Python)

```bash
pip install firebase-admin pyautogui
python listener.py
```

Listener çalışmaya başladığında terminalde şu mesajı göreceksiniz:

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
