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

### 🎵 Medya & Ses Kontrolü
| Özellik | Açıklama |
|---------|----------|
| **Sistem Ses Kontrolü** | PC'nin sesini açın, kısın, belirli bir seviyeye getirin veya tamamen kapatın |
| **Sistem Medya Kontrolü** | Spotify, YouTube vb. uygulamalarda medyayı oynatın, duraklatın, ileri/geri sarın |
| **PPT Video Kontrolü** | PowerPoint içine gömülü videoları uzaktan başlatın/durdurun veya geri sarın |

### 📊 Sunum Analitiği & Geçmiş
| Özellik | Açıklama |
|---------|----------|
| **Sunum Geçmişi** | Geçmişte yaptığınız tüm sunumların listesini ve detaylarını görüntüleyin |
| **Slayt Süreleri** | Hangi slaytta ne kadar süre harcadığınızı analiz edin |
| **Ağ Uyarıları Raporu** | Herkese açık veya güvensiz ağlarda yapılan bağlantıların güvenlik analiz raporunu alın |

### 🔗 Bağlantı & Keşif
| Özellik | Açıklama |
|---------|----------|
| **QR Kod ile Eşleşme** | PC uygulamasındaki QR kodu telefonunuzla tarayarak anında bağlanın |
| **mDNS Otomatik Keşif** | Aynı ağdaki PC'ler otomatik olarak listelenir (`_quickremote._tcp`) |
| **Manuel Bağlantı** | IP adresi ve port ile doğrudan bağlanın |
| **Bluetooth Bağlantısı** | Wi-Fi olmadan doğrudan Bluetooth (HID) üzerinden PC'nizi kontrol edin *(Yeni)* |
| **Son Cihazlar** | Daha önce bağlandığınız cihazlara hızla yeniden bağlanın (son 5 cihaz saklanır) |
| **Otomatik Yeniden Bağlanma** | Bağlantı koptuğunda otomatik olarak yeniden bağlanma desteği |
| **Arka Plan Desteği** | Uygulama arka plandayken veya telefon kilitliyken dahi bağlantıyı koruyun ve kontrol etmeye devam edin |

### 🔒 Güvenlik
| Özellik | Açıklama |
|---------|----------|
| **TLS/WSS Şifreleme** | Tüm iletişim otomatik oluşturulan self-signed sertifika ile şifrelenir |
| **4 Haneli PIN** | Her oturumda rastgele PIN oluşturulur; kimliksiz bağlantı engellenir |
| **Brute-Force Koruması** | 5 başarısız denemeden sonra IP adresi 60 saniyeliğine engellenir |
| **Sertifika Sabitleme** | İlk bağlantıda sertifika parmak izi kaydedilir; değişiklik tespit edilirse kullanıcıya sorulur |
| **Kimlik Doğrulama Zaman Aşımı** | Bağlanan istemci 10 saniye içinde doğrulanmazsa bağlantı kapatılır |
| **Bilgisayar Kilitleme** | `Win + L` ile bilgisayarı uzaktan kilitleyin |
| **Canlı Ağ İzleme** | Ağ profiliniz sürekli izlenir; herkese açık ağ tespit edilirse uyarılır ve tek tıkla güvenli (private) ağa geçebilirsiniz |

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
│   ├── lib/
│   │   ├── main.dart              # Uygulama giriş noktası & tema yapılandırması
│   │   ├── constants/             # Sabitler (renkler, ikonlar, API yolları vb.)
│   │   ├── models/                # Veri modelleri (presentation_analytics, draw_tool vb.)
│   │   ├── providers/             # Ayar durumu ve state yönetimi
│   │   ├── repositories/          # Veri tabanı ve geçmiş kayıt işlemleri
│   │   ├── screens/               # Uygulama arayüzleri (Modüler Yapı)
│   │   │   ├── analytics/         # Sunum analitiği ve rapor ekranları
│   │   │   ├── bt_remote/         # Bluetooth kontrol ekranları (Yeni)
│   │   │   ├── home/              # Ana ekran – bağlantı yönetimi
│   │   │   ├── remote/            # Uzaktan kumanda ekranı (kontroller + touchpad)
│   │   │   └── settings/          # Ayarlar ve geçmiş
│   │   ├── services/              # Arka plan servisleri
│   │   │   ├── bluetooth/         # Bluetooth HID servisleri (Yeni)
│   │   │   ├── websocket/         # WebSocket istemcisi, analitik ve state takibi
│   │   │   └── discovery_service.dart
│   │   ├── utils/                 # Yardımcı fonksiyonlar, UI bileşenleri (app_dialog vb.)
│   │   └── widgets/               # Ortak kullanılan widgetlar (presentation_timer vb.)
│   └── test/                      # 🧪 Birim ve Widget Testleri
│       ├── settings_provider_test.dart
│       └── widget_test.dart
│
├── quick_remote_pc/               # 🖥️ Flutter Masaüstü Uygulaması (Windows)
│   └── lib/
│       ├── main.dart              # Uygulama giriş noktası & Provider yapılandırması
│       ├── providers/             # State yönetimi (server_provider vb.)
│       ├── screens/
│       │   └── home/              # Ana ekran – ağ durumu, public network uyarıları, ayarlar
│       ├── services/              # Arka plan servisleri
│       │   ├── input/             # Girdi simülatörleri (Klavye, Fare, PPT, SMTC)
│       │   └── server/            # Sunucu yönetimi (Auth, Network, State)
│       └── widgets/               # Ortak kullanılan widgetlar (hover efektleri vb.)
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
| **Bluetooth (HID)** | Wi-Fi olmadan PC'yi Bluetooth üzerinden kontrol etme |
| **mobile_scanner** | QR kod tarama |
| **sensors_plus** | Cihaz sensörleri (jiroskop) |
| **nsd** | mDNS cihaz keşfi |
| **vibration** | Haptik geri bildirim |
| **wakelock_plus** | Ekran uyku engelleme |
| **flutter_background** | Uygulamanın arka planda kesintisiz çalışması |
| **permission_handler** | Gerekli sistem izinlerinin yönetimi |
| **crypto** | SHA-256 PIN hashleme |
| **provider** | Durum yönetimi |
| **google_fonts & glassmorphism** | Modern UI tasarımı |

### Masaüstü Uygulama (Server)
| Teknoloji | Kullanım |
|-----------|----------|
| **Flutter & Dart** | Windows masaüstü uygulaması |
| **dart:io HttpServer** | TLS destekli WebSocket sunucusu |
| **win32 & ffi** | Windows SendInput API ile tuş/fare simülasyonu |
| **PowerShell COM & Scripts** | PowerPoint COM otomasyonu, Sistem Ses Seviyesi ve Medya (SMTC) kontrolü |
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
- PC uygulaması için Windows 10/11 **veya** Linux (X11 ya da Wayland; KDE, GNOME vb.)
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

#### 🐧 Linux

Linux'ta sunum programı olarak **LibreOffice Impress** kontrol edilir.

```bash
cd quick_remote_pc
flutter pub get
flutter run -d linux        # veya: flutter build linux
```

**Çalışma zamanı bağımlılıkları:** `libreoffice` (Python-UNO dahil; Debian/Ubuntu'da `python3-uno`), `python3`, `openssl`, `pactl` (PipeWire-Pulse veya PulseAudio), `avahi-daemon` (otomatik keşif için, isteğe bağlı). Derleme için ayrıca `libayatana-appindicator3` ve `libnotify` geliştirme paketleri gerekir.

**İlk kurulum:** uygulamanın üst kısmındaki Linux panelinden yapılır:
- **Klavye/fare izni:** "İzin ver" butonu `/dev/uinput` için bir udev kuralı kurar (yönetici parolası sorar). Elle kurmak için: `sudo quick_remote_pc/linux/packaging/install-uinput-rule.sh`
- **Impress bağlantısı:** "Etkinleştir" butonu LibreOffice profiline yerel UNO dinleyicisi ekler (`localhost:2002`). LibreOffice açıksa "Bağlan" butonu bunu anında etkinleştirir.
- **Güvenlik duvarı:** firewalld/ufw 8090-8099 portlarını engelliyorsa "Portları aç" butonu görünür.

| Özellik | Linux durumu |
|---------|--------------|
| Slayt kontrolü, notlar, n. slayttan başlatma, siyah/beyaz ekran | ✅ Impress (UNO) |
| Kalem, renk, silgi, tümünü sil, lazer işaretçi | ✅ Impress (UNO) |
| Vurgulayıcı | ⚠️ Kalın sarı kalem olarak taklit edilir (Impress'te yarı saydam vurgulayıcı yok) |
| Sunuma gömülü video oynat/duraklat | ⚠️ Çalışır; "başa sar" videoyu durdurur |
| Touchpad, tıklama, sürükleme | ✅ uinput (X11 + Wayland) |
| Ses, şimdi çalan (kapak dahil), medya tuşları | ✅ pactl + MPRIS |
| Bilgisayarı kilitle | ✅ `loginctl lock-session` |
| Otomatik keşif (mDNS) | ✅ Avahi |
| Bluetooth HID modu | ✅ Dokunmatik alanda "Hedef: LibreOffice Impress" seçilince: slayt, siyah/beyaz ekran, kalem, temizle çalışır. ⚠️ Lazer yerine fare imleci kullanılır; vurgulayıcı ve silgi gizlenir (Impress'te klavye kısayolları yok) |

Impress açık değilse sunum komutları klavye kısayoluna (PageDown/PageUp/F5/Esc/B/W) düşer; böylece PDF görüntüleyiciler ve tarayıcıdaki sunumlar da ileri/geri kontrol edilebilir.

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
| `MEDIA_PLAY_PAUSE` / `MEDIA_REWIND` | PPT gömülü video oynat/duraklat ve geri sar |
| `VOLUME_UP` / `VOLUME_DOWN` / `VOLUME_MUTE` / `VOLUME_SET:<n>` | Sistem ses seviyesi kontrolleri |
| `SYSTEM_MEDIA_PLAY_PAUSE` vb. | Sistem medya kontrolleri (Sonraki, Önceki, Durdur) |

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
