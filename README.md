# 📱 QuickRemote

<div align="center">

**Akıllı telefonunuzdan bilgisayarınızı kontrol edin.**

*Sunum yönetimi, fare kontrolü ve çizim araçları — hepsi avucunuzun içinde.*

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20iOS-brightgreen)](#)
[![License](https://img.shields.io/badge/License-Personal_Use-blue)](#-lisans)

</div>

---

## ✨ Öne Çıkan Özellikler

### 🎯 Sunum Kontrolü
| Özellik | Açıklama |
|---------|----------|
| **Slayt İleri / Geri** | Sunumu tek dokunuşla ilerletin veya geri alın |
| **Sunumu Başlat / Bitir** | PowerPoint sunumunu uzaktan başlatın (F5) veya sonlandırın (ESC) |
| **Belirli Slayta Git** | İstediğiniz slayt numarasına doğrudan atlayın (`START_AT`) |
| **Slayt Durumu Senkronizasyonu** | Mevcut slayt numarası, toplam slayt sayısı ve konuşmacı notları gerçek zamanlı olarak telefonunuza aktarılır |
| **Sunum Zamanlayıcı** | Sunumunuzun ne kadar sürdüğünü takip edin |
| **Protected View Desteği** | PowerPoint Korumalı Görünüm otomatik olarak düzenleme moduna geçirilir |

### 🖱️ Fare & Touchpad
| Özellik | Açıklama |
|---------|----------|
| **Touchpad Modu** | Telefonunuzun ekranını trackpad gibi kullanarak fareyi kontrol edin |
| **Hassasiyet Ayarı** | Fare hassasiyetini ihtiyacınıza göre özelleştirin |
| **Sol / Sağ Tık** | Tam fare tıklama desteği |
| **Sürükle & Bırak** | Uzun basarak sürükleme işlemi yapın |

### 🎨 Çizim Araçları
| Araç | Açıklama |
|------|----------|
| **Lazer İşaretçi** | PowerPoint'in yerel lazer modunu uzaktan kontrol edin (Ctrl+L) |
| **Kalem** | Sunum üzerine serbest çizim yapın (Ctrl+P) |
| **Vurgulayıcı** | Önemli alanları fosforlu kalemle işaretleyin (Ctrl+I) |
| **Silgi** | Çizimleri temizleyin (Ctrl+E) |
| **Kalem Rengi Değiştirme** | COM otomasyonu ile kalem rengini dinamik olarak değiştirin |

### 🔗 Bağlantı & Keşif
| Özellik | Açıklama |
|---------|----------|
| **QR Kod ile Eşleşme** | PC uygulamasındaki QR kodu telefonunuzla tarayarak anında bağlanın |
| **mDNS Otomatik Keşif** | Aynı ağdaki PC'ler otomatik olarak listelenir (`_quickremote._tcp`) |
| **Manuel Bağlantı** | IP adresi ve port ile doğrudan bağlanın |
| **Son Cihazlar** | Daha önce bağlandığınız cihazlara hızla yeniden bağlanın (son 5 cihaz saklanır) |
| **Otomatik Yeniden Bağlanma** | Bağlantı koptuğunda otomatik olarak yeniden bağlanma desteği |

### 🔒 Güvenlik
| Özellik | Açıklama |
|---------|----------|
| **TLS/WSS Şifreleme** | Tüm iletişim otomatik oluşturulan self-signed sertifika ile şifrelenir |
| **4 Haneli PIN** | Her oturumda rastgele PIN oluşturulur; kimliksiz bağlantı engellenir |
| **Brute-Force Koruması** | 5 başarısız denemeden sonra IP adresi 60 saniyeliğine engellenir |
| **Sertifika Sabitleme** | İlk bağlantıda sertifika parmak izi kaydedilir; değişiklik tespit edilirse kullanıcıya sorulur |
| **Kimlik Doğrulama Zaman Aşımı** | Bağlanan istemci 10 saniye içinde doğrulanmazsa bağlantı kapatılır |
| **Bilgisayar Kilitleme** | `Win + L` ile bilgisayarı uzaktan kilitleyin |
| **Herkese Açık Ağ Uyarısı** | Public network algılandığında kullanıcı uyarılır |

---

## 🏗️ Mimari

```text
┌─────────────────────────┐                            ┌─────────────────────────┐
│     📱 Mobile Client    │      Wi-Fi (WSS/TLS)       │    🖥️ PC Server App     │
│     (Flutter App)       │◄──────────────────────────►│    (Flutter Windows)     │
│  Android / iOS          │       Local Network         │                         │
├─────────────────────────┤                            ├─────────────────────────┤
│ • QR Tarama             │      ◄── PIN Auth ──►      │ • WebSocket Server      │
│ • mDNS Keşfi            │      ◄── Commands ──►      │ • Win32 Input Simulator │
│ • Touchpad Girişi       │      ◄── SlideState ►      │ • PowerShell COM Bridge │
│ • Çizim Araçları        │      ◄── Mouse Data ►      │ • mDNS Advertisement    │
│ • Sunum Zamanlayıcı     │                            │ • QR Kod Oluşturucu     │
│ • Haptic Feedback       │                            │ • System Tray           │
└─────────────────────────┘                            └─────────────────────────┘
```

**İletişim Akışı:**
1. **PC Server App** → Windows üzerinde TLS destekli WebSocket sunucusu başlatır, mDNS ile kendini ağda duyurur ve ekranda QR kod gösterir.
2. **Mobile Client** → mDNS ile otomatik keşif yapar veya QR kodu tarayarak sunucunun IP, port ve PIN bilgilerini alır.
3. **Kimlik Doğrulama** → SHA-256 ile hashlenmiş PIN doğrulaması yapılır.
4. **Kontrol** → Tüm komutlar (`NEXT`, `PREV`, `START`, `LOCK`, `MODE_LASER` vb.) ve fare verileri düşük gecikmeli WebSocket kanalı üzerinden iletilir.

---

## 📁 Proje Yapısı

```text
QuickRemote/
├── quick_remote_app/              # 📱 Flutter Mobil Uygulaması (Android / iOS)
│   └── lib/
│       ├── main.dart              # Uygulama giriş noktası & tema yapılandırması
│       ├── screens/
│       │   ├── home_screen.dart   # Ana ekran – bağlantı yönetimi
│       │   ├── remote_screen.dart # Uzaktan kumanda ekranı (kontroller + touchpad)
│       │   ├── scan_screen.dart   # QR kod tarama ekranı
│       │   └── settings_screen.dart # Ayarlar
│       ├── services/
│       │   ├── websocket_service.dart  # WebSocket istemcisi & otomatik yeniden bağlanma
│       │   └── discovery_service.dart  # mDNS cihaz keşfi
│       ├── providers/
│       │   └── settings_provider.dart  # Ayar durumu yönetimi
│       ├── widgets/
│       │   └── presentation_timer.dart # Sunum zamanlayıcı widget'ı
│       ├── utils/
│       │   └── throttler.dart     # Fare hareketleri için throttle mekanizması
│       └── constants/             # Sabitler
│
├── quick_remote_pc/               # 🖥️ Flutter Masaüstü Uygulaması (Windows)
│   └── lib/
│       ├── main.dart              # Uygulama giriş noktası & Provider yapılandırması
│       ├── screens/
│       │   └── home_screen.dart   # Ana ekran – sunucu durumu, QR kod, bağlantı bilgileri
│       ├── services/
│       │   ├── websocket_server.dart  # TLS WebSocket sunucusu & istemci yönetimi
│       │   ├── input_simulator.dart   # Win32 SendInput API & PowerShell COM otomasyonu
│       │   └── mouse_controller.dart  # Fare konumu hesaplama & hareket
│       └── constants/             # Sabitler
│
├── packages/
│   └── quick_remote_shared/       # 📦 Paylaşılan Dart Paketi
│       └── lib/src/
│           └── remote_commands.dart   # Ortak komut sabitleri (NEXT, PREV, MODE_LASER vb.)
│
├── landing-page/                  # 🌐 Tanıtım Web Sitesi
│   ├── index.html
│   ├── style.css
│   └── assets/
│       └── hero-mockup.jpg
│
├── logo/                          # 🎨 Logo ve Konsept Görselleri
│   ├── quick_remote_icon.jpg
│   ├── quick_remote_concept_b.jpg
│   └── quick_remote_concept_c.jpg
│
├── .gitignore
└── README.md
```

---

## 🛠️ Teknolojiler

### Mobil Uygulama (Client)
| Teknoloji | Kullanım |
|-----------|----------|
| **Flutter & Dart** | Çapraz platform UI (Android & iOS) |
| **web_socket_channel** | WebSocket istemcisi |
| **mobile_scanner** | QR kod tarama |
| **sensors_plus** | Cihaz sensörleri (jiroskop) |
| **nsd** | mDNS cihaz keşfi |
| **vibration** | Haptik geri bildirim |
| **wakelock_plus** | Ekran uyku engelleme |
| **crypto** | SHA-256 PIN hashleme |
| **provider** | Durum yönetimi |
| **google_fonts & glassmorphism** | Modern UI tasarımı |

### Masaüstü Uygulama (Server)
| Teknoloji | Kullanım |
|-----------|----------|
| **Flutter & Dart** | Windows masaüstü uygulaması |
| **dart:io HttpServer** | TLS destekli WebSocket sunucusu |
| **win32 & ffi** | Windows SendInput API ile tuş/fare simülasyonu |
| **PowerShell COM** | PowerPoint COM otomasyonu (slayt durumu, kalem rengi vb.) |
| **nsd** | mDNS servis kaydı |
| **qr_flutter** | QR kod oluşturma |
| **window_manager** | Pencere yönetimi |
| **system_tray** | Sistem tepsisi entegrasyonu |
| **local_notifier** | Windows bildirimleri |
| **screen_retriever** | Ekran bilgileri |

### İletişim
| Protokol | Açıklama |
|----------|----------|
| **WebSocket (WSS)** | Düşük gecikmeli, çift yönlü iletişim |
| **TLS 1.2+** | Self-signed sertifika ile şifreli bağlantı |
| **mDNS** | `_quickremote._tcp` ile otomatik servis keşfi |
| **JSON** | Yapılandırılmış mesaj formatı |
| **Binary** | Yüksek frekanslı fare/lazer verileri için ikili protokol |

---

## 🚀 Kurulum

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)
- Windows 10/11 işletim sistemi (PC uygulaması için)
- Aynı Wi-Fi ağına bağlı cihazlar (PC ve Telefon)

---

### 1. Repoyu Klonlayın

```bash
git clone https://github.com/berat-kaan-akcan/QuickRemote.git
cd QuickRemote
```

---

### 2. PC Uygulamasını Çalıştırın

Windows bilgisayarınızda sunucuyu başlatın:

```bash
cd quick_remote_pc
flutter pub get
flutter run -d windows
```

> **Not:** Uygulama ilk çalıştırıldığında otomatik olarak bir TLS sertifikası oluşturur. Ekranda yerel IP adresiniz, port numaranız ve 4 haneli PIN kodunuz görünecektir. QR kodu taratarak veya bu bilgileri elle girerek bağlanabilirsiniz.

---

### 3. Mobil Uygulamayı Çalıştırın

Telefonunuzda istemci uygulamayı çalıştırın:

```bash
cd quick_remote_app
flutter pub get
flutter run
```

**Bağlantı Yöntemleri:**
- 📷 **QR Kod:** PC ekranındaki QR kodu telefonla tarayın
- 🔍 **Otomatik Keşif:** Aynı ağdaki PC'ler otomatik olarak listelenir
- ✏️ **Manuel:** IP adresi ve PIN kodunu elle girin

---

## 📡 Komut Protokolü

Tüm komutlar `quick_remote_shared` paketi üzerinden paylaşılır:

| Komut | Açıklama |
|-------|----------|
| `NEXT` / `PREV` | Sonraki / önceki slayt |
| `START` / `END` | Sunumu başlat (F5) / bitir (ESC) |
| `START_AT:<n>` | n. slayttan sunumu başlat |
| `LOCK` | Bilgisayarı kilitle (Win+L) |
| `MODE_ARROW` | Ok/imleç modu (Ctrl+A) |
| `MODE_LASER` | Lazer işaretçi modu (Ctrl+L) |
| `MODE_PEN` | Kalem modu (Ctrl+P) |
| `MODE_HIGHLIGHTER` | Vurgulayıcı modu (Ctrl+I) |
| `MODE_ERASER` | Silgi modu (Ctrl+E) |
| `SET_PEN_COLOR:<bgr>` | Kalem rengini BGR değeri ile değiştir |
| `LEFT_CLICK` / `RIGHT_CLICK` | Sol / sağ fare tıklaması |
| `LEFT_DOWN` / `LEFT_UP` | Fare sürükleme (basılı tut / bırak) |
| `REFRESH_STATE` | Slayt durumunu yenile |

---

## 🔐 Güvenlik Modeli

```text
 İstemci                                      Sunucu
    │                                            │
    │──── TLS Handshake ────────────────────────►│
    │◄─── Self-Signed Cert ─────────────────────│
    │                                            │
    │──── WebSocket Upgrade ───────────────────►│
    │◄─── AUTH_REQUIRED ────────────────────────│
    │                                            │
    │──── SHA-256(PIN) ────────────────────────►│
    │◄─── AUTH_OK / AUTH_FAIL ──────────────────│
    │                                            │
    │──── Komutlar (şifreli kanal) ────────────►│
    │◄─── Slayt durumu (şifreli kanal) ────────│
```

- Tüm trafik **TLS ile şifrelenir**
- PIN doğrulaması **SHA-256 hash** ile yapılır
- **5 başarısız deneme** → IP 60 saniyeliğine engellenir
- **10 saniye** içinde kimlik doğrulanmazsa bağlantı kesilir
- Sertifika parmak izi istemci tarafında saklanır (**certificate pinning**)
- Herkese açık ağ tespit edildiğinde sunucu tarafında **uyarı gösterilir**

---

## 📄 Lisans

Bu proje kişisel kullanım amaçlıdır.
