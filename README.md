# ⌚ QuickRemote

**WearOS akıllı saatinizden ve telefonunuzdan bilgisayarınızı kontrol edin.**

QuickRemote, WearOS tabanlı bir akıllı saat veya akıllı telefondan bilgisayarınıza komut göndermenizi sağlayan bir uzaktan kumanda sistemidir. Cihazlar aynı ağ (Wi-Fi) üzerinde düşük gecikmeli WebSocket ile haberleşir.

---

## 🎯 Özellikler

| Komut | Açıklama | İkon |
|-------|----------|------|
| **İleri** | Sunum slaytını ilerletir | ➡️ |
| **Geri** | Sunum slaytını geri alır | ⬅️ |
| **Kilitle** | Bilgisayarı kilitler (Windows) | 🔒 |
| **Fare/Lazer Kontrolü** | Cihaz hareketleriyle/dokunmatikle fareyi yönlendirme | 🖱️ |

---

## 🏗️ Mimari

```text
┌──────────────────┐        Wi-Fi (WebSocket)        ┌──────────────────┐
│Watch/Phone Client│────────────────────────────────▶│  PC Server App   │
│   (Flutter App)  │           (Local IP)            │  (Flutter Windows) │
└──────────────────┘                                 └──────────────────┘
```

1. **PC Server App (`quick_remote_pc`)** → Bilgisayarda bir WebSocket sunucusu başlatır. Eşleşme için bir PIN oluşturur.
2. **Client Apps (`quick_remote_watch`, `quick_remote_app`)** → Aynı ağdaki bilgisayarın IP ve Portuna (PIN koduyla) bağlanır.
3. İletişim, eski Firebase modelinin aksine yerel ağ üzerinden çok daha hızlı ve güvenli gerçekleşir.

---

## 📁 Proje Yapısı

```text
QuickRemote/
├── quick_remote_app/        # Flutter Mobil Uygulaması (Telefon)
├── quick_remote_pc/         # Flutter Masaüstü Uygulaması (Windows Sunucusu)
└── quick_remote_watch/      # Flutter WearOS uygulaması (Akıllı Saat)
```

---

## 🛠️ Teknolojiler

- **Client:** Flutter, Dart (Android, WearOS, iOS)
- **Server:** Flutter, Dart, win32 (Windows Masaüstü)
- **Bağlantı:** WebSocket (Yerel Ağ)

---

## 🚀 Kurulum

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Aynı Wi-Fi ağına bağlı cihazlar (PC ve Saat/Telefon)

---

### 1. Repoyu Klonlayın

```bash
git clone https://github.com/berat-kaan-akcan/QuickRemote.git
cd QuickRemote
```

---

### 2. PC Uygulamasını Çalıştırın

Windows işletim sistemine sahip bilgisayarınızda sunucuyu başlatın:

```bash
cd quick_remote_pc
flutter run -d windows
```

> **Not:** Uygulama açıldığında ekranda cihazınızın yerel IP adresini ve 4 haneli güvenlik PIN kodunu göreceksiniz. Bu bilgileri istemci cihaza gireceksiniz.

---

### 3. Saat veya Mobil Uygulamayı Çalıştırın

Telefonunuzda veya saatinizde istemci uygulamayı çalıştırın:

```bash
# Telefon için:
cd quick_remote_app
flutter run

# Saat için (Emülatör veya gerçek saat):
cd quick_remote_watch
flutter run
```

Uygulama açıldığında PC ekranındaki IP adresini ve PIN kodunu girerek doğrudan kontrol sağlamaya başlayabilirsiniz!

---

## 📄 Lisans

Bu proje kişisel kullanım amaçlıdır.
