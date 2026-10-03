# 📱 QuickRemote

<div align="center">

**Akıllı telefonunuzdan bilgisayarınızı kontrol edin.**

*Sunum yönetimi, fare kontrolü ve çizim araçları — hepsi avucunuzun içinde.*

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Android-brightgreen)](#)
[![License](https://img.shields.io/badge/License-Personal_Use-blue)](#-lisans)

</div>

---

## ✨ Öne Çıkan Özellikler

### 🎯 Sunum Kontrolü
| Özellik | Açıklama |
|---------|----------|
| **Slayt İleri / Geri** | Sunumu tek dokunuşla ilerletin veya geri alın |
| **Sunumu Başlat / Bitir** | PowerPoint veya WPS sunumunu uzaktan başlatın (F5) veya sonlandırın (ESC) |
| **Belirli Slayta Git** | İstediğiniz slayt numarasına doğrudan atlayın (`START_AT`) |
| **Slayt Durumu Senkronizasyonu** | Mevcut slayt numarası, toplam slayt sayısı ve konuşmacı notları gerçek zamanlı olarak telefonunuza aktarılır |
| **Sunum Zamanlayıcı** | Sunumunuzun ne kadar sürdüğünü takip edin |
| **Protected View Desteği** | PowerPoint Korumalı Görünüm otomatik olarak düzenleme moduna geçirilir |

### 🖱️ Fare & Touchpad
| Özellik | Açıklama |
|---------|----------|
| **Touchpad Modu** | Telefonunuzun ekranını trackpad gibi kullanarak fareyi kontrol edin |

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
| **6 Haneli PIN** | Her oturumda rastgele PIN oluşturulur; kimliksiz bağlantı engellenir |
| **Brute-Force Koruması** | 5 başarısız denemeden sonra IP adresi 60 saniyeliğine engellenir; engel her PIN denemesinde yeniden kontrol edilir. IP başına en fazla 3, toplamda 32 doğrulanmamış bağlantı. Bir dakikada 20'den fazla hatalı PIN (hangi IP'den olursa olsun) yeni eşleştirmeleri 60 saniye durdurur |
| **Sertifika Sabitleme** | QR kodu sertifikanın SHA-256 parmak izini taşır; telefon ilk bağlantıda bile bu sertifikayı bekler, eşleşmezse bağlanmaz. QR'sız ilk bağlantıda PIN gönderilmeden önce PC ekranındaki 16 haneli güvenlik kodunu karşılaştırmanız istenir; sertifika sonradan değişirse yine sorulur |
| **Gizlenen Eşleştirme Kodu** | İlk telefon bağlandıktan sonra QR kodu ve PIN gizlenir ("Kodu göster" ile açılır); yansıtılan ekranda görünmez |
| **Bağlı Cihazlar** | PC bağlı telefonları listeler; "Çıkar" o telefonun bağlantısını keser ve PIN'i yeniler |
| **Kimlik Doğrulama Zaman Aşımı** | Bağlanan istemci 5 saniye içinde doğrulanmazsa bağlantı kapatılır |
| **Odak Kontrolü** | Windows'ta çizim/siyah ekran kısayolları yalnızca PowerPoint veya WPS öndeyken gönderilir; başka bir pencereye yazılmaz |
| **WPS Office** | Windows'ta WPS Presentation, PowerPoint ile aynı COM arayüzünden (`KWPP.Application`) kontrol edilir; Linux'ta RPC ve kısayollarla (aşağıya bakın). WPS'te lazer yoktur, yerine görünür fare imleci kullanılır. ⚠️ Windows'taki WPS desteği henüz gerçek bir WPS kurulumunda denenmedi |
| **Canlı Ağ İzleme** | Ağ profiliniz sürekli izlenir; herkese açık ağ tespit edilirse uyarılır ve ağ ayarlarını açabilirsiniz |

---

## 🏗️ Mimari

```text
┌─────────────────────────┐                            ┌─────────────────────────┐
│     📱 Mobile Client    │      Wi-Fi (WSS/TLS)       │    🖥️ PC Server App     │
│     (Flutter App)       │◄──────────────────────────►│  (Flutter Windows/Linux) │
│  Android                │       Local Network         │                         │
├─────────────────────────┤                            ├─────────────────────────┤
│ • QR Tarama             │      ◄── PIN Auth ──►      │ • WebSocket Server      │
│ • mDNS Keşfi            │      ◄── Commands ──►      │ • Win32 Input Simulator │
│ • Touchpad Girişi       │      ◄── SlideState ►      │ • PowerShell COM Bridge │
│ • Çizim Araçları        │      ◄── Mouse Data ►      │ • mDNS Advertisement    │
│ • Sunum Zamanlayıcı     │                            │ • QR Kod Oluşturucu     │
│ • Haptic Feedback       │                            │                         │
└─────────────────────────┘                            └─────────────────────────┘
```

**İletişim Akışı:**
1. **PC Server App** → Windows veya Linux üzerinde TLS destekli WebSocket sunucusu başlatır, mDNS ile kendini ağda duyurur ve ekranda QR kod gösterir.
2. **Mobile Client** → mDNS ile otomatik keşif yapar veya QR kodu tarayarak sunucunun IP, port ve PIN bilgilerini alır.
3. **Kimlik Doğrulama** → PIN, TLS kanalı içinde doğrulanır. QR ile bağlanıldığında telefon, QR kodundaki sertifika parmak izini doğrular.
4. **Kontrol** → Tüm komutlar (`NEXT`, `PREV`, `START`, `LOCK`, `MODE_LASER` vb.) ve fare verileri düşük gecikmeli WebSocket kanalı üzerinden iletilir.

---

## 📁 Proje Yapısı

```text
QuickRemote/
├── quick_remote_app/              # 📱 Flutter Mobil Uygulaması (Android)
│   ├── lib/
│   │   ├── main.dart              # Uygulama giriş noktası & tema yapılandırması
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
│   └── test/                      # 🧪 Birim ve widget testleri (ayarlar, BT tuş eşlemesi, hareket biriktirici)
│
├── quick_remote_pc/               # 🖥️ Flutter Masaüstü Uygulaması (Windows / Linux)
│   ├── assets/linux/              # LibreOffice Impress ve WPS köprüleri (impress_bridge.py, wps_bridge.py)
│   ├── test/                      # 🧪 Sunucu entegrasyon, komut yönlendirici, auth, Linux testleri
│   │   └── python/                # Impress ve WPS köprüsü testleri (unittest)
│   └── lib/
│       ├── main.dart              # Uygulama giriş noktası & Provider yapılandırması
│       ├── providers/             # State yönetimi (server_provider vb.)
│       ├── screens/
│       │   └── home/              # Ana ekran – ağ durumu, public network uyarıları, ayarlar
│       ├── services/              # Arka plan servisleri
│       │   ├── input/             # Girdi: windows/ (SendInput, PowerPoint/WPS COM, SMTC), linux/ (uinput, Impress, WPS, pactl, MPRIS)
│       │   └── server/            # Sunucu yönetimi (Auth, Network, State)
│       └── widgets/               # Ortak kullanılan widgetlar (hover efektleri vb.)
│
├── packages/
│   └── quick_remote_shared/       # 📦 Paylaşılan Dart Paketi
│       ├── lib/src/
│       │   ├── remote_commands.dart   # Ortak komut sabitleri ve üreticileri (NEXT, startAt(n) vb.)
│       │   └── pairing_payload.dart   # QR içeriği, parmak izi ve güvenlik kodu
│       └── test/
│
├── landing-page/                  # 🌐 Tanıtım Web Sitesi
│   ├── index.html
│   ├── style.css
│   └── assets/
│       ├── hero-mockup.jpg
│       └── logo.png
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
| **Flutter & Dart** | Android uygulaması |
| **web_socket_channel** | WebSocket istemcisi |
| **Bluetooth (HID)** | Wi-Fi olmadan PC'yi Bluetooth üzerinden kontrol etme |
| **mobile_scanner** | QR kod tarama |
| **nsd** | mDNS cihaz keşfi |
| **vibration** | Haptik geri bildirim |
| **wakelock_plus** | Ekran uyku engelleme |
| **flutter_background** | Uygulamanın arka planda kesintisiz çalışması |
| **permission_handler** | Gerekli sistem izinlerinin yönetimi |
| **crypto** | Sertifika parmak izi (SHA-256) |
| **provider** | Durum yönetimi |
| **google_fonts** | Modern UI tasarımı |

### Masaüstü Uygulama (Server)
| Teknoloji | Kullanım |
|-----------|----------|
| **Flutter & Dart** | Windows ve Linux masaüstü uygulaması |
| **dart:io HttpServer** | TLS destekli WebSocket sunucusu |
| **win32 & ffi** | Windows SendInput API ile tuş/fare simülasyonu |
| **PowerShell COM & Scripts** | PowerPoint COM otomasyonu, Sistem Ses Seviyesi ve Medya (SMTC) kontrolü |
| **nsd / Avahi** | mDNS servis kaydı (Windows / Linux) |
| **qr_flutter** | QR kod oluşturma |
| **window_manager** | Pencere yönetimi |
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

> **Not:** Uygulama ilk çalıştırıldığında otomatik olarak bir TLS sertifikası oluşturur. Ekranda yerel IP adresiniz, port numaranız ve 6 haneli PIN kodunuz görünecektir. QR kodu taratarak veya bu bilgileri elle girerek bağlanabilirsiniz.

#### 🐧 Linux

Linux'ta sunum programı olarak **LibreOffice Impress** ve **WPS Office** (WPS Presentation) kontrol edilir.

```bash
cd quick_remote_pc
flutter pub get
flutter run -d linux        # veya: flutter build linux
```

**Çalışma zamanı bağımlılıkları:** `libreoffice` (Python-UNO dahil; Debian/Ubuntu'da `python3-uno`), `python3`, `openssl`, `pactl` (PipeWire-Pulse veya PulseAudio), `avahi-daemon` (otomatik keşif için, isteğe bağlı). Derleme için ayrıca `libayatana-appindicator3` ve `libnotify` geliştirme paketleri gerekir.

**İlk kurulum:** uygulamanın üst kısmındaki Linux panelinden yapılır:
- **Klavye/fare izni:** "İzin ver" butonu `/dev/uinput` için bir udev kuralı kurar (yönetici parolası sorar). Elle kurmak için: `sudo quick_remote_pc/linux/packaging/install-uinput-rule.sh`
- **Impress bağlantısı:** "Etkinleştir" butonu LibreOffice profiline yalnızca sizin kullanıcınızın bağlanabildiği bir UNO soketi (`pipe,name=quickremote`) ekler. LibreOffice açıksa "Bağlan" butonu bunu anında etkinleştirir. Eski sürümlerin eklediği `localhost:2002` TCP dinleyicisi bu makinedeki her kullanıcıya ve uygulamaya açıktı; panelde "Güncelle" çıkarsa ona basın.
- **WPS desteği (isteğe bağlı):** WPS kuruluysa panelde bir WPS satırı çıkar. "Kur" butonu WPS'in RPC bağlayıcısı `pywpsrpc`'yi uygulamanın kendi Python sanal ortamına kurar (sistem Python'u değişmez, bir kez internet gerekir; Debian/Ubuntu'da `python3-venv` paketi gerekir).
- **Güvenlik duvarı:** firewalld/ufw 8090-8099 portlarını engelliyorsa "Portları aç" butonu görünür.

> **Bilmeniz gerekenler:** udev kuralı (`uaccess`) `/dev/uinput`'u oturumunuzdaki **her** uygulamaya açar; bu, Wayland'ın uygulamalar arası giriş yalıtımını sizin kullanıcınız için kaldırır. İzni geri almak için `sudo rm /etc/udev/rules.d/70-quickremote-uinput.rules` çalıştırın. Klavye yedekleri tuşların fiziksel konumunu gönderir; Türkçe F gibi QWERTY olmayan düzenlerde Impress köprüsü yokken B/W kısayolları farklı harf üretebilir.

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
| Bluetooth HID modu | ✅ Dokunmatik alanda "Hedef: Impress" seçilince: slayt, siyah/beyaz ekran, kalem, temizle çalışır. ⚠️ Lazer yerine fare imleci kullanılır; vurgulayıcı ve silgi gizlenir (Impress'te klavye kısayolları yok). "Hedef: WPS" seçilince vurgulayıcı da çalışır, silgi gizlenir |

Impress'e ulaşılamazsa ileri/geri, başlat ve bitir komutları klavye kısayoluna (PageDown/PageUp/F5/Esc) düşer; böylece PDF görüntüleyiciler ve tarayıcıdaki sunumlar da kontrol edilebilir. Çizim modları ve siyah/beyaz ekran yalnızca bir slayt gösterisi açıkken çalışır, başka bir pencereye tuş yazmaz.

**PDF sunumları:** İleri/geri her PDF görüntüleyicide çalışır (PageDown/PageUp). Telefondaki BAŞLAT ise görüntüleyiciye göre davranır:
- Linux'ta PDF LibreOffice Draw'da açıksa (çoğu dağıtımda varsayılan), PDF Impress'te sunum olarak açılır ve gösteri başlar. Her sayfa bir slayt olur: slayt numarası, kalem, lazer ve siyah ekran çalışır. Orijinal PDF değişmez. PowerPoint'ten dışa aktarılmış PDF'ler aynen görünür; LaTeX gibi başka kaynaklı PDF'lerde yazı tipleri kayabilir.
- Firefox'ta sunum modu açılır (Ctrl+Alt+P), Adobe Acrobat/Reader'da tam ekran (Ctrl+L), Okular'da sunum modu (Ctrl+Shift+P), WPS PDF'te tam ekran (F11; WPS PDF'te F5 bir şey yapmaz). Arch tabanlı dağıtımlarda WPS PDF `libtiff.so.5` eksik olduğu için hiç açılmayabilir; AUR'daki `libtiff5` paketi bunu çözer. Chrome, Edge ve Brave'de F11 ile tam ekran olur; BİTİR yine F11 ile çıkar. Tarayıcıya F5 gönderilmez, çünkü sayfayı yeniler.
- Linux'ta bu tanıma yalnızca X11/XWayland pencerelerinde yapılabilir; Wayland'da doğrudan çalışan tarayıcılar tanınmaz ve onlara F5 gider.

**WPS Office (Linux):** WPS'in RPC arayüzü yalnızca kendi başlattığı WPS'i yönetebilir, sizin açtığınız bir WPS'e bağlanamaz. Bu yüzden iki mod vardır:

| | Paneldeki "Sunum aç" ile açılan sunum | WPS'i kendiniz açtığınızda |
|---|---|---|
| İleri/geri, başlat/bitir, siyah/beyaz ekran | ✅ RPC | ✅ WPS kısayolları |
| Slayt numarası, notlar, n. slayttan başlatma | ✅ | ❌ Telefonda "Slayt gösterisi açık" görünür |
| Kalem, vurgulayıcı, tümünü sil | ✅ (kalem rengi dahil) | ✅ Ctrl+P / Ctrl+I / E (renk seçilemez) |
| Silgi | ✅ | ❌ |
| Lazer | ⚠️ Görünür fare imleci telefonla hareket eder (WPS'te lazer yok) | ⚠️ Aynı |
| Sunuma gömülü video | ✅ | ❌ |

Kendi açtığınız WPS'e kısayollar yalnızca WPS penceresi odaktayken gönderilir. WPS kapalıyken "Sunum aç" ile açılan WPS, sonradan çift tıklayarak açtığınız sunumları da alır ve onlar da tam kontrol edilir.

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
    │──── {"auth": PIN} (TLS içinde) ─────────►│
    │◄─── AUTH_OK / AUTH_FAIL ──────────────────│
    │                                            │
    │──── Komutlar (şifreli kanal) ────────────►│
    │◄─── Slayt durumu (şifreli kanal) ────────│
```

- Tüm trafik **TLS ile şifrelenir**
- PIN, **TLS kanalı içinde** gönderilir ve sunucuda sabit zamanlı karşılaştırılır
- **5 başarısız deneme** → IP 60 saniyeliğine engellenir (engel her denemede yeniden kontrol edilir)
- IP başına en fazla **3**, toplamda **32** doğrulanmamış bağlantı; dakikada **20'den fazla** hatalı PIN → eşleştirme 60 sn durur
- **5 saniye** içinde kimlik doğrulanmazsa bağlantı kesilir
- QR kodu sertifika parmak izini taşır; telefon ilk bağlantıda bile sertifikayı doğrular (**certificate pinning**). QR'sız ilk bağlantıda PIN gönderilmeden önce **güvenlik kodu** karşılaştırılır; parmak izi ancak PIN kabul edilince kaydedilir
- Kimlik doğrulamadan önce gönderilebilecek veri 4 KB ile sınırlıdır; sıkıştırma (permessage-deflate) kapalıdır
- İlk eşleşmeden sonra QR/PIN gizlenir; PC'den bir telefon çıkarıldığında PIN yenilenir
- Tarayıcılardan gelen (Origin başlıklı) WebSocket bağlantıları reddedilir
- Herkese açık ağ tespit edildiğinde sunucu tarafında **uyarı gösterilir**


---

## 📄 Lisans

Bu proje kişisel kullanım amaçlıdır.
