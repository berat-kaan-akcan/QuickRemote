# 📱 QuickRemote

<div align="center">

**Akıllı telefonunuzdan bilgisayarınızı kontrol edin.**

*Sunum yönetimi, fare kontrolü ve çizim araçları — hepsi avucunuzun içinde.*

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
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
| **Sunumu Başlat / Bitir** | PowerPoint, WPS veya LibreOffice Impress sunumunu uzaktan başlatın veya sonlandırın |
| **Belirli Slayta Git** | Küçük resim ızgarasından (gösteri açıkken) veya numarayla istediğiniz slayta atlayın |
| **Slayt Durumu Senkronizasyonu** | Mevcut slayt numarası, toplam slayt sayısı ve konuşmacı notları gerçek zamanlı olarak telefonunuza aktarılır |
| **Slayt Resimleri** | Kumandada o anki slaydın resmi görünür; ayarlardan kapatılabilir (ayrıntılar aşağıda) |
| **Sunucu Görünümü** | Büyük slayt, sıradaki slayt, notlar ve Önceki/Sonraki tek ekranda; dikey ve yatay |
| **Resim Üzerinde Lazer** | Sunucu görünümündeki Lazer tuşuyla slayt resminde parmağınızın olduğu yeri gösterin |
| **Siyah / Beyaz Ekran** | Gösteriyi geçici olarak siyah veya beyaz ekranla kapatın; QuickRemote katmanı gösteri dışında da ekranı kapatabilir |
| **PDF Sunumları** | PDF görüntüleyicilerde ve tarayıcılarda sunum/tam ekran modunu açın, sayfaları çevirin (ayrıntılar aşağıda) |
| **Tarayıcıda Sunum** | PowerPoint for the web ve Google Slaytlar'ı başlatın, sayfalarını çevirin, bitirin (ayrıntılar aşağıda) |
| **Sunum Zamanlayıcı** | Süre belirleyin, uyarı titreşimleri alın; saatle eşitlenir |
| **Protected View Desteği** | PowerPoint Korumalı Görünüm otomatik olarak düzenleme moduna geçirilir |
| **WPS Office** | Windows'ta WPS Presentation, PowerPoint ile aynı COM arayüzünden (`KWPP.Application`) kontrol edilir; Linux'ta RPC ve kısayollarla (aşağıya bakın). Windows'ta video oynat/duraklat videoya tıklanarak yapılır; WPS'te başa sarma yoktur |

Hangi programda neyin çalıştığı uygulamada da yazar: **Ayarlar → Yardım → Neler yapılabilir?**

### 🖱️ Fare & Touchpad
| Özellik | Açıklama |
|---------|----------|
| **Touchpad Modu** | Telefonunuzun ekranını trackpad gibi kullanarak fareyi kontrol edin |

### 🎨 Lazer ve Çizim Araçları
| Araç | Açıklama |
|------|----------|
| **Lazer İşaretçi** | PowerPoint ve WPS'te programın kendi lazeri; Impress, PDF, tarayıcı ve gösteri dışında QuickRemote katmanı |
| **Spot Işığı** | Ekran lazerin çevresindeki daire dışında kararır (QuickRemote katmanı, her programda) |
| **Büyüteç** | Lazeri izleyen yuvarlak, iki kat büyüteç (yalnızca Windows) |
| **Kalem** | Sunum üzerine serbest çizim yapın |
| **Vurgulayıcı** | Önemli alanları fosforlu kalemle işaretleyin |
| **Silgi / Tümünü Sil** | Çizimleri tek tek silin veya slayttaki tüm çizimleri temizleyin |
| **Geri Al** | Temizle tuşunu basılı tutunca son çizgi gider (QuickRemote katmanı) |
| **Kalem ve Vurgulayıcı Rengi** | Kalem ve vurgulayıcı rengini telefondan seçin |
| **Çizimleri Koru** | Ayarlar'dan açılır: kapalıyken (varsayılan) slayt değişince çizimler silinir, açıkken slayta dönünce yeniden görünür |
| **Birden Fazla Telefon** | Bir çizimi/lazeri başlatan telefon işaretçiyi o hareket bitene kadar tutar; aynı anda basılan İleri/Geri tek slayt ilerletir |

**QuickRemote katmanı**, ekranın üstünde duran, tıklamaları geçiren ve odak almayan şeffaf bir penceredir. Lazeri ve çizimleri programa bağlı kalmadan çizer. Kimin çizeceğini PC uygulamasında **Ayarlar → Lazer** belirler: *Otomatik* (önerilen), *Her zaman QuickRemote lazeri* veya *Sunum programının kendi lazeri*. Katman Windows'ta ve Linux'ta (X11/XWayland ve bileşik pencere yöneticisi gerekir) çalışır; iki monitör ve %125 dışındaki ölçekler henüz denenmedi.

**Slayt resimleri için bilinen sınır:** dışa aktarılan resim slaydın kaydedilmiş hâlidir; animasyon adımı, çizim ve oynayan video görünmez. Ekran görüntüsü alınabilen durumlarda (gösteri penceresi veya tam ekrandaki PDF görüntüleyici/tarayıcı) o anki slayt ekranda görüneni gösterir; sıradaki slayt ve küçük resimler her zaman dışa aktarılır. Pencereli tarayıcıdan, başka bir pencereden veya masaüstünden görüntü alınmaz.

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
| **Bluetooth Bağlantısı** | Wi-Fi olmadan doğrudan Bluetooth (HID) üzerinden PC'nizi kontrol edin. PC bu telefonu klavye olarak reddederse (SDP kaydı eksik), PC uygulaması çalışıyorsa Linux'ta otomatik onarılır; aksi halde telefon, bilgisayarda cihazı yeniden bağlama/eşleştirme adımlarını gösterir |
| **Kayıtlı PC'ler** | Son 5 PC PIN'iyle saklanır; ağda bulunan kayıtlı bir PC "Kayıtlı" işaretiyle görünür ve doğrudan bağlanır |
| **Kısayollar ve Hızlı Ayarlar** | Uygulama kısayolları (Bluetooth kumanda, QR tara, son PC) ve son PC'ye bağlanan Hızlı Ayarlar kutucuğu |
| **Otomatik Yeniden Bağlanma** | Bağlantı koptuğunda otomatik olarak yeniden bağlanma desteği |
| **Arka Plan Desteği** | Uygulama arka plandayken veya telefon kilitliyken dahi bağlantıyı koruyun ve kontrol etmeye devam edin |
| **Telefon Adı** | PC'nin bağlı cihazlar listesinde telefonunuzun adı (veya modeli) görünür |

### ⌚ Wear OS
Saat uygulaması (`quick_remote_wear/`) bilgisayara telefon üzerinden ulaşır: saat ⇄ telefon (Wear OS'in kendi kanalı) ⇄ bilgisayar (telefonun Wi-Fi bağlantısı ya da Bluetooth klavye modu). Saatte eşleştirme adımı yoktur; telefonda bilgisayara bağlanınca saatteki kumanda kendiliğinden açılır. Telefondaki QuickRemote ile aynı imzayla kurulmuş olmalıdır.

| Özellik | Açıklama |
|---------|----------|
| **Slayt İleri / Geri** | Büyük İleri ve küçük Geri düğmesiyle veya döner çerçeve/kasa (bezel) ile slayt değiştirin |
| **Slayt İlerlemesi** | Üst kenarda slayt başına bir nokta (40 slayttan sonra düz yay); Bluetooth modunda bilgisayar bilgi göndermez |
| **Sunum Saati** | Başlat sayfasında − ve + ile süreyi seçin; telefonla eşitlenir, kalan veya aşılan süre görünür, uyarılar saatte titreşir |
| **Gösteriyi Başlat / Bitir** | Başlat sayfasından başlatın; Araçlar sayfasında Bitir 1 saniye basılı tutulur. PDF veya tarayıcı öndeyse Başlat "Tam ekran" olur |
| **Siyah / Beyaz Ekran** | Araçlar sayfasından |
| **Lazer İşaretçi** | Tam ekran dokunmatik alanda parmağı sürükleyin veya İleri'yi basılı tutun; jiroskop kullanılmaz |
| **Hata Bildirimi** | Bilgisayarın reddettiği komut saatte kısa bir bildirim ve titreşimle gösterilir (yalnızca Wi-Fi) |
| **Durum Ekranları** | Telefona ulaşılamıyor, telefonda uygulama kapalı ("Telefonda aç" düğmesiyle), telefon bilgisayara bağlı değil |
| **Ekranda Kalma** | Ekran kararınca ortam ekranı slayt durumunu, sunum saatini ve PC'nin adını gösterir; uyanınca saat kadranı yerine kumanda gelir (Wear OS 5+, bildirim izni gerekir) |
| **Tema ve Dil** | Tema telefondan gelir ("Saatte de kullan"); Türkçe / İngilizce sistem diline göre |

### 🌍 Arayüz
| Özellik | Açıklama |
|---------|----------|
| **Türkçe / İngilizce** | Her iki uygulama da Türkçe ve İngilizce; dil sistemi takip eder veya ayarlardan seçilir (Android 13+ uygulama dili ayarı da desteklenir) |
| **Açık / Koyu Tema** | Sistemin açık/koyu modunu takip eder veya ayarlardan seçilir |
| **Renk Temaları** | Telefonda Kobalt (varsayılan), OLED, yüksek kontrast, Nane, Mor ve Gün Batımı |
| **Azaltılmış Hareket** | Sistem daha az animasyon istediğinde animasyonlar kapanır |
| **Ortak Tasarım Sistemi** | Telefon ve PC uygulaması aynı renk, yazı tipi (Space Grotesk, Inter) ve bileşenleri kullanır; bkz. [`brand/BRAND.md`](brand/BRAND.md) |

### 🖥️ Masaüstü
| Özellik | Açıklama |
|---------|----------|
| **Sistem Tepsisi** | Pencere kapanınca uygulama tepside çalışmaya devam eder; simge sunucu durumunu gösterir (tepsi olmayan Linux masaüstlerinde kapatmak çıkış yapar) |
| **Oturumla Başlatma** | Oturum açılınca küçültülmüş başlar; istenirse sunucu da açılır (herkese açık ağda sunucu kendiliğinden açılmaz) |
| **Güncelleme Denetimi** | Yeni sürüm varsa haber verir ve sürüm sayfasını açar; kendisi indirmez, ayarlardan kapatılabilir |
| **Tek Kopya** | İkinci kez açmak var olan pencereyi öne getirir |

### 🩺 Sorun Bildirme
Uygulamalar günlüğü yalnızca cihazda tutar; uzak hata raporlama yoktur, hiçbir şey kendiliğinden gönderilmez. PIN, parmak izi, not, medya başlığı ve dosya yolları günlüğe yazılmadan temizlenir; IP adresi, port ve cihaz adları kalır. Günlüğü PC'de **Ayarlar → Sorun giderme**, telefonda **Ayarlar → Yardım** üzerinden dışa aktarıp GitHub'daki sorun bildirimine ekleyebilirsiniz.

### 🔒 Güvenlik
| Özellik | Açıklama |
|---------|----------|
| **TLS/WSS Şifreleme** | Tüm iletişim otomatik oluşturulan self-signed sertifika ile şifrelenir |
| **6 Haneli PIN** | Her oturumda rastgele PIN oluşturulur; kimliksiz bağlantı engellenir |
| **Brute-Force Koruması** | 5 başarısız denemeden sonra IP adresi 60 saniyeliğine engellenir; engel her PIN denemesinde yeniden kontrol edilir. IP başına en fazla 3, toplamda 32 doğrulanmamış bağlantı. Bir dakikada 20'den fazla hatalı PIN (hangi IP'den olursa olsun) yeni eşleştirmeleri 60 saniye durdurur |
| **Sertifika Sabitleme** | QR kodu sertifikanın SHA-256 parmak izini taşır; telefon ilk bağlantıda bile bu sertifikayı bekler, eşleşmezse bağlanmaz. QR'sız ilk bağlantıda PIN gönderilmeden önce PC ekranındaki 16 haneli güvenlik kodunu karşılaştırmanız istenir; sertifika sonradan değişirse yine sorulur |
| **Gizlenen Eşleştirme Kodu** | İlk telefon bağlandıktan sonra QR kodu ve PIN gizlenir ("Kodu göster" ile açılır); yansıtılan ekranda görünmez |
| **Bağlı Cihazlar** | PC bağlı telefonları listeler; "Çıkar" o telefonun bağlantısını keser ve PIN'i yeniler |
| **Yalnızca Yerel Ağ** | Yalnızca özel, bağlantı-yerel, loopback ve CGNAT adresleri ya da PC ile aynı alt ağdaki adresler bağlanabilir; diğerleri TLS'ten önce reddedilir |
| **Kimlik Doğrulama Zaman Aşımı** | Bağlanan istemci 5 saniye içinde doğrulanmazsa bağlantı kapatılır |
| **Odak Kontrolü** | Windows'ta çizim/siyah ekran kısayolları yalnızca slayt gösterisi penceresine gönderilir; gösteri başka bir pencerenin (Word, sunumun kendi düzenleyicisi) arkasındaysa önce öne getirilir, kısayollar başka bir pencereye yazılmaz |
| **Canlı Ağ İzleme** | Ağ profiliniz sürekli izlenir; herkese açık ağ tespit edilirse uyarılır ve ayarlara gidebilirsiniz |

---

## 🏗️ Mimari

```text
┌──────────────┐  Wear OS  ┌─────────────────────────┐   Wi-Fi (WSS/TLS)   ┌─────────────────────────┐
│ ⌚ Wear OS    │◄─────────►│     📱 Mobile Client    │◄───────────────────►│    🖥️ PC Server App     │
│ (Kotlin,     │Data Layer │     (Flutter, Android)  │    Local Network    │ (Flutter Windows/Linux) │
│  Compose)    │           ├─────────────────────────┤                     ├─────────────────────────┤
└──────────────┘           │ • QR Tarama             │  ◄── PIN Auth ──►   │ • WebSocket Server      │
                           │ • mDNS Keşfi            │  ◄── Commands ──►   │ • SendInput / uinput    │
                           │ • Touchpad Girişi       │  ◄── SlideState ►   │ • COM / UNO / WPS köprü │
                           │ • Çizim Araçları        │  ◄── Mouse Data ►   │ • Lazer/mürekkep katmanı│
                           │ • Sunucu Görünümü       │  ◄── Slayt resmi    │ • Slayt resmi           │
                           │ • Sunum Zamanlayıcı     │                     │ • mDNS, QR, sistem tepsi│
                           └───────────┬─────────────┘                     └────────────▲────────────┘
                                       │          Bluetooth HID (PC uygulaması gerekmez)│
                                       └────────────────────────────────────────────────┘
```

**İletişim Akışı:**
1. **PC Server App** → Windows veya Linux üzerinde TLS destekli WebSocket sunucusu başlatır, mDNS ile kendini ağda duyurur ve ekranda QR kod gösterir.
2. **Mobile Client** → mDNS ile otomatik keşif yapar veya QR kodu tarayarak sunucunun IP, port ve PIN bilgilerini alır.
3. **Kimlik Doğrulama** → PIN, TLS kanalı içinde doğrulanır. QR ile bağlanıldığında telefon, QR kodundaki sertifika parmak izini doğrular; QR'sız ilk bağlantıda güvenlik kodu karşılaştırılır.
4. **Kontrol** → Tüm komutlar (`NEXT`, `PREV`, `START`, `LOCK`, `MODE_LASER` vb.) ve fare verileri düşük gecikmeli WebSocket kanalı üzerinden iletilir; PC slayt durumunu ve resimlerini aynı kanaldan gönderir.
5. **Saat** → Bilgisayarla konuşmaz; komutları telefona verir, telefon sahip olduğu bağlantıdan iletir.

---

## 📁 Proje Yapısı

```text
QuickRemote/
├── quick_remote_app/              # 📱 Flutter Mobil Uygulaması (Android)
│   ├── lib/
│   │   ├── main.dart              # Uygulama giriş noktası & tema yapılandırması
│   │   ├── l10n/                  # Arayüz metinleri (app_tr.arb, app_en.arb) ve hata metinleri
│   │   ├── models/                # Veri modelleri (presentation_analytics, draw_tool vb.)
│   │   ├── providers/             # Ayar durumu ve state yönetimi
│   │   ├── repositories/          # Veri tabanı ve geçmiş kayıt işlemleri
│   │   ├── screens/               # Uygulama arayüzleri (Modüler Yapı)
│   │   │   ├── analytics/         # Sunum analitiği ve rapor ekranları
│   │   │   ├── bt_connect/        # Bluetooth eşleştirme ekranı
│   │   │   ├── bt_remote/         # Bluetooth kontrol ekranları
│   │   │   ├── home/              # Ana ekran – bağlantı yönetimi
│   │   │   ├── remote/            # Uzaktan kumanda ekranı (kontroller + touchpad)
│   │   │   ├── scan/              # QR kod tarama
│   │   │   └── settings/          # Ayarlar ve geçmiş
│   │   ├── services/              # Arka plan servisleri
│   │   │   ├── bluetooth/         # Bluetooth HID servisleri
│   │   │   ├── wear/              # Saat köprüsü (WearBridge)
│   │   │   ├── websocket/         # WebSocket istemcisi, analitik ve state takibi
│   │   │   └── discovery_service.dart
│   │   ├── theme/                 # Tasarım sistemi: renkler, paletler ve renk temaları, tipografi, token'lar, tema
│   │   ├── utils/                 # Yardımcı fonksiyonlar, popup'lar (app_dialog, app_bottom_sheet vb.)
│   │   └── widgets/               # Ortak widget'lar: ui/ (buton, kart, uyarı…), brand/ (logo, açılış), presentation_timer
│   ├── assets/fonts/              # Space Grotesk ve Inter (uygulamaya gömülü)
│   └── test/                      # 🧪 Birim ve widget testleri (ayarlar, BT tuş eşlemesi, çeviriler, hata metinleri)
│
├── quick_remote_pc/               # 🖥️ Flutter Masaüstü Uygulaması (Windows / Linux)
│   ├── assets/linux/              # LibreOffice Impress ve WPS köprüleri (impress_bridge.py, wps_bridge.py)
│   ├── test/                      # 🧪 Sunucu entegrasyon, komut yönlendirici, auth, Linux testleri
│   │   └── python/                # Impress ve WPS köprüsü testleri (unittest)
│   └── lib/
│       ├── main.dart              # Uygulama giriş noktası & Provider yapılandırması
│       ├── l10n/                  # Arayüz metinleri (app_tr.arb, app_en.arb)
│       ├── providers/             # State yönetimi (server, desktop, laser_overlay, language vb.)
│       ├── screens/
│       │   └── home/              # Ana ekran – sunucu durumu, eşleştirme, bağlı telefonlar, ayarlar
│       ├── services/              # Arka plan servisleri
│       │   ├── capture/           # Ekran görüntüsünden slayt resmi
│       │   ├── desktop/           # Tepsi, oturumla başlatma, güncelleme denetimi, sorun bildirme
│       │   ├── input/             # Girdi: windows/ (SendInput, PowerPoint/WPS COM, SMTC), linux/ (uinput, Impress, WPS, pactl, MPRIS)
│       │   ├── linux/             # Linux kurulum paneli, Bluetooth HID onarımı
│       │   ├── overlay/           # Lazer ve mürekkep katmanı
│       │   └── server/            # Sunucu yönetimi (Auth, Network, State, slayt resimleri)
│       ├── theme/                 # Tasarım sistemi (telefon uygulamasıyla aynı token'lar)
│       └── widgets/               # Ortak widget'lar: ui/ (buton, kart, durum çipi…), brand/ (logo)
│
├── packages/
│   └── quick_remote_shared/       # 📦 Paylaşılan Dart Paketi
│       ├── lib/src/
│       │   ├── remote_commands.dart   # Ortak komut sabitleri ve üreticileri (NEXT, startAt(n) vb.)
│       │   ├── remote_error.dart      # COMMAND_FAILED hata kodları
│       │   ├── bt_hid_repair.dart     # Bluetooth HID için SDP yenileme servisi (BtHidRepair)
│       │   ├── pairing_payload.dart   # QR içeriği, parmak izi ve güvenlik kodu
│       │   ├── move_frame.dart        # Fare/lazer ikili çerçevesi
│       │   ├── slide_image_frame.dart # Slayt resmi ikili çerçevesi
│       │   ├── presenter_caps.dart    # Öndeki pencere türü ve çalışan araçlar
│       │   ├── web_presenters.dart    # Tarayıcıdaki sunum siteleri
│       │   └── app_log.dart           # Yerel günlük ve gizli veri temizleme
│       └── test/
│
├── site/                          # 🌐 Tanıtım Web Sitesi (statik)
│   ├── index.html, en/index.html  # Türkçe ve İngilizce; tools/parts'tan üretilir, elle düzenlenmez
│   ├── style.css
│   ├── main.js                    # Canlı demolar (metin içermez)
│   ├── assets/                    # Simgeler, yazı tipleri, görseller
│   └── tools/                     # build_pages.py, verify.mjs, social.mjs
│
├── landing-page/                  # Eski site, artık güncellenmiyor
│
├── docs/raporlar/                 # Proje durumu: YAPILANLAR.md, YAPILMAYANLAR.md, özellik planları
│
├── brand/                         # 🎨 Marka kimliği
│   ├── BRAND.md                   # Stil rehberi: logo, renkler, tipografi, hareket, bileşenler
│   ├── logo/                      # Logo kaynakları (SVG): ikon, işaret, wordmark, favicon
│   ├── export/                    # Hazır PNG/ICO çıktıları
│   └── tools/                     # draw_logo.py (logo SVG'leri), export_assets.sh (uygulama ikonları)
│
├── quick_remote_wear/             # ⌚ Wear OS uygulaması (Kotlin/Compose, telefon üzerinden bağlanır)
│
├── logo/                          # Eski logo ve konsept görselleri
│   ├── quick_remote_icon.jpg
│   ├── quick_remote_concept_b.jpg
│   └── quick_remote_concept_c.jpg
│
├── NOTES.md                       # Ayrıntılı mimari notları
├── PLAY_STORE_YAPILACAKLAR.md     # Play Store'a çıkış listesi
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
| **shared_preferences** | Ayarlar, son cihazlar ve sabitlenen sertifikalar |
| **share_plus & url_launcher** | Günlüğü paylaşma, sorun bildirme |
| **flutter_localizations & intl** | Türkçe / İngilizce arayüz |

### Masaüstü Uygulama (Server)
| Teknoloji | Kullanım |
|-----------|----------|
| **Flutter & Dart** | Windows ve Linux masaüstü uygulaması |
| **dart:io HttpServer** | TLS destekli WebSocket sunucusu |
| **win32 & ffi** | Windows SendInput API ile tuş/fare simülasyonu |
| **PowerShell COM & Scripts** | PowerPoint/WPS COM otomasyonu, Sistem Ses Seviyesi ve Medya (SMTC) kontrolü |
| **uinput (FFI)** | Linux'ta sanal klavye/fare (X11 ve Wayland) |
| **Python köprüleri** | LibreOffice Impress (UNO) ve WPS (`pywpsrpc`) kontrolü |
| **dbus** | Linux'ta MPRIS medya kontrolü |
| **nsd / Avahi** | mDNS servis kaydı (Windows / Linux) |
| **qr_flutter** | QR kod oluşturma |
| **window_manager** | Pencere yönetimi |
| **screen_retriever** | Ekran bilgileri |
| **tray_manager** | Sistem tepsisi |
| **image** | Ekran görüntüsünden JPEG üretimi |
| **file_selector** | Linux'ta WPS ile açılacak sunumu seçme, günlüğü kaydetme |
| **url_launcher** | Sürüm sayfası, sorun bildirme |
| **GTK3 + cairo / GDI+** | Lazer ve mürekkep katmanı (Linux / Windows) |
| **flutter_localizations & intl** | Türkçe / İngilizce arayüz |

### Saat Uygulaması
| Teknoloji | Kullanım |
|-----------|----------|
| **Kotlin & Compose for Wear OS** | Wear OS uygulaması (Wear OS 3+, API 30) |
| **play-services-wearable** | Telefonla Wearable Data Layer iletişimi |

### İletişim
| Protokol | Açıklama |
|----------|----------|
| **WebSocket (WSS)** | Düşük gecikmeli, çift yönlü iletişim |
| **TLS 1.2+** | Self-signed sertifika ile şifreli bağlantı |
| **mDNS** | `_quickremote._tcp` ile otomatik servis keşfi |
| **JSON** | Yapılandırılmış mesaj formatı |
| **Binary** | Yüksek frekanslı fare/lazer verileri ve PC'den telefona slayt resimleri için ikili protokol |

---

## 🚀 Kurulum

### Hazır paketler (PC uygulaması)

> **Durum:** Henüz yayımlanmış bir sürüm yok; şimdilik kaynaktan derleyin. Aşağıdaki paketler, ilk sürümden itibaren [Releases](https://github.com/berat-kaan-akcan/QuickRemote/releases) sayfasında olacak. Dosyaların SHA-256 değerleri `SHA256SUMS.txt` içinde.

- **Windows 10/11:** `QuickRemote-PC-<sürüm>-windows-x64-setup.exe` dosyasını çalıştırın. Kurulum yönetici izni istemez; uygulama kullanıcı klasörüne kurulur.
  - Kurulum dosyası henüz imzasız olduğu için Windows **"Windows bilgisayarınızı korudu"** (SmartScreen) uyarısı gösterir. **Ek bilgi**'ye, sonra **Yine de çalıştır**'a tıklayın.
- **Debian, Ubuntu, Pardus:** `sudo apt install ./quickremote-pc_<sürüm>_amd64.deb`. Paket `/dev/uinput` izni için gereken udev kuralını da kurar; uygulamadaki "İzin ver" adımı gerekmez. LibreOffice Impress kontrolü için `python3-uno` (önerilen bağımlılık) kurulu olmalı.
- **Arch, CachyOS, Manjaro:** AUR paketi `quickremote-pc-bin` (henüz AUR'a gönderilmedi; `PKGBUILD` `quick_remote_pc/linux/packaging/aur/` içinde).
- **Diğer Linux dağıtımları:** `quickremote-pc-<sürüm>-linux-x64.tar.gz` arşivini açın, `quickremote-pc/quick_remote_pc` ile başlatın. Klavye/fare izni için bir kez `sudo quickremote-pc/share/install-uinput-rule.sh` çalıştırın (ya da uygulamadaki "İzin ver" tuşunu kullanın).

Kaynaktan derlemek için aşağıdaki adımları izleyin.

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47+ (Dart 3.11+)
- Android derlemesi için JDK 17–25 (Android Studio'nun JBR'si yeterli; daha yeni bir JDK sistem varsayılanıysa `flutter config --jdk-dir <yol>` ile 17–25 arası bir JDK gösterin)
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

Windows'ta sunucuyu başlatın:

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

**Çalışma zamanı bağımlılıkları:** `libreoffice` (Python-UNO dahil; Debian/Ubuntu'da `python3-uno`), `python3`, `openssl`, `pactl` (PipeWire-Pulse veya PulseAudio), `avahi-daemon` (otomatik keşif için, isteğe bağlı). Flutter ayrıca `libegl1` ve `libgles2` (Arch: `libglvnd`) ister. Derleme için GTK 3, `libx11-dev` ve `libxi-dev` geliştirme paketleri gerekir; sistem tepsisi için appindicator gerekmez.

**İlk kurulum:** uygulamanın üst kısmındaki Linux panelinden yapılır:
- **Klavye/fare izni:** "İzin ver" butonu `/dev/uinput` için bir udev kuralı kurar (yönetici parolası sorar). Elle kurmak için: `sudo quick_remote_pc/linux/packaging/install-uinput-rule.sh`
- **Impress bağlantısı:** "Etkinleştir" butonu LibreOffice profiline yalnızca sizin kullanıcınızın bağlanabildiği bir UNO soketi (`pipe,name=quickremote`) ekler. LibreOffice açıksa "Bağlan" butonu bunu anında etkinleştirir. Eski sürümlerin eklediği `localhost:2002` TCP dinleyicisi bu makinedeki her kullanıcıya ve uygulamaya açıktı; panelde "Güncelle" çıkarsa ona basın.
- **WPS desteği (isteğe bağlı):** WPS kuruluysa panelde bir WPS satırı çıkar. "Kur" butonu WPS'in RPC bağlayıcısı `pywpsrpc`'yi uygulamanın kendi Python sanal ortamına kurar (sistem Python'u değişmez, bir kez internet gerekir; Debian/Ubuntu'da `python3-venv` paketi gerekir).
- **Güvenlik duvarı:** firewalld/ufw 8090-8099 portlarını engelliyorsa "Portları aç" butonu görünür.

> **Bilmeniz gerekenler:** udev kuralı (`uaccess`) `/dev/uinput`'u oturumunuzdaki **her** uygulamaya açar; bu, Wayland'ın uygulamalar arası giriş yalıtımını sizin kullanıcınız için kaldırır. İzni geri almak için `sudo rm /etc/udev/rules.d/70-quickremote-uinput.rules` çalıştırın. Klavye yedekleri tuşların fiziksel konumunu gönderir; Türkçe F gibi QWERTY olmayan düzenlerde Impress köprüsü yokken B/W kısayolları farklı harf üretebilir. Debian paketi aynı kuralı `/usr/lib/udev/rules.d` içine koyar; onu geri almak için paketi kaldırın.

| Özellik | Linux durumu |
|---------|--------------|
| Slayt kontrolü, notlar, n. slayttan başlatma, siyah/beyaz ekran | ✅ Impress (UNO) |
| Lazer, kalem, vurgulayıcı, renk, silgi, tümünü sil, geri al, spot ışığı | ✅ QuickRemote katmanı (X11/XWayland; videonun da üstünde çizer). Büyüteç Linux'ta yok |
| Impress'in kendi araçları (Ayarlar → Lazer) | ⚠️ Lazer ve çizim videonun arkasında kalır. Vurgulayıcı LibreOffice 26.8'den itibaren yarı saydam çizgidir (animasyonlu veya medyalı slaytlarda kalın sarı kalem kalır), daha eski sürümlerde kalın sarı kalem |
| Slayt resmi | ✅ Impress ve QuickRemote'un açtığı WPS'te dışa aktarma; ekran görüntüsü yalnızca X11/XWayland pencerelerinden |
| Sunuma gömülü video oynat/duraklat | ⚠️ Çalışır; "başa sar" videoyu durdurur |
| Touchpad, tıklama, sürükleme | ✅ uinput (X11 + Wayland) |
| Ses, şimdi çalan (kapak dahil), medya tuşları | ✅ pactl + MPRIS |
| Bilgisayarı kilitle | ✅ `loginctl lock-session` |
| Otomatik keşif (mDNS) | ✅ Avahi |
| Bluetooth HID modu | ✅ Program bağlanınca sorulur. Impress: slayt, siyah/beyaz ekran, kalem, temizle çalışır. ⚠️ Lazer yerine fare imleci kullanılır; vurgulayıcı ve silgi gizlenir (Impress'te klavye kısayolları yok). WPS: vurgulayıcı, silgi (Ctrl+E) ve lazer (Ctrl+R) de çalışır |

Impress'e ulaşılamazsa ileri/geri, başlat ve bitir komutları klavye kısayoluna (PageDown/PageUp/F5/Esc) düşer; böylece PDF görüntüleyiciler ve tarayıcıdaki sunumlar da kontrol edilebilir. Programın kendi çizim araçları ve siyah/beyaz ekranı yalnızca bir slayt gösterisi açıkken çalışır, başka bir pencereye tuş yazmaz; QuickRemote katmanı bunları gösteri dışında da çizer.

**PDF sunumları:** İleri/geri PDF görüntüleyicilerde PageDown/PageUp ile çalışır. Tarayıcılarda (Chrome, Edge, Brave, Firefox) ve Linux'taki WPS PDF'te sağ/sol ok gönderilir: PageDown orada bir ekran boyu kaydırıp sayfanın ortasında durur, oklar ise bir sonraki sayfanın başına gider. Telefondaki BAŞLAT ise görüntüleyiciye göre davranır:
- Linux'ta PDF LibreOffice Draw'da açıksa (çoğu dağıtımda varsayılan), PDF Impress'te sunum olarak açılır ve gösteri başlar. Her sayfa bir slayt olur: slayt numarası, kalem, lazer ve siyah ekran çalışır. Orijinal PDF değişmez. PowerPoint'ten dışa aktarılmış PDF'ler aynen görünür; LaTeX gibi başka kaynaklı PDF'lerde yazı tipleri kayabilir.
- Firefox'ta sunum modu açılır (Ctrl+Alt+P), Adobe Acrobat/Reader'da tam ekran (Ctrl+L), Okular'da sunum modu (Ctrl+Shift+P). Chrome, Edge ve Brave'de F11 ile tam ekran olur; BİTİR yine F11 ile çıkar. Tarayıcıya F5 gönderilmez, çünkü sayfayı yeniler. SumatraPDF'te F5 sunum modunu açar.
- WPS PDF: Linux'ta tam ekran (F11; orada F5 bir şey yapmaz), Windows'ta `wps.exe` penceresindeki PDF sekmesi tanınır ve Oynat moduna geçer (Shift+F5). Arch tabanlı dağıtımlarda WPS PDF `libtiff.so.5` eksik olduğu için hiç açılmayabilir; AUR'daki `libtiff5` paketi bunu çözer.
- Windows'ta Edge, Chrome, Firefox, Acrobat, SumatraPDF ve WPS 12.1 PDF ile denendi; Okular denenmedi.
- Linux'ta tanıma X11/XWayland pencerelerinde yapılır. KDE Wayland'de yerel pencere KWin üzerinden öğrenilir (gerçek bir KDE oturumunda henüz denenmedi); diğer Wayland masaüstlerinde yerel çalışan tarayıcılar tanınmaz ve onlara F5 gider.

**Tarayıcıda sunum (PowerPoint for the web, Google Slaytlar):** Site, tarayıcı penceresinin başlığından tanınır. BAŞLAT Ctrl+F5 basar (F5 sayfayı yeniler), BİTİR Esc; sayfalar oklarla çevrilir. Google Slaytlar'da numarayla slayta gidilir. Lazer, çizim ve boş ekranı QuickRemote katmanı çizer; slayt numarası ve notlar gelmez, tam ekranda ekran görüntüsü gelir. Linux'ta başlık yalnızca X11/XWayland penceresinden okunabildiği için Wayland'de yerel çalışan bir tarayıcı düz tarayıcı sayılır. Chrome'da her iki sitede, Linux'ta Firefox'ta denendi; Edge, Windows'ta Firefox ve Bluetooth modu henüz denenmedi ([plan ve deneme listesi](docs/raporlar/PPT_WEB_PLAN.md)).

**WPS Office (Linux):** WPS'in RPC arayüzü yalnızca kendi başlattığı WPS'i yönetebilir, sizin açtığınız bir WPS'e bağlanamaz. Bu yüzden iki mod vardır:

| | Paneldeki "Sunumu WPS ile aç" ile açılan sunum | WPS'i kendiniz açtığınızda |
|---|---|---|
| İleri/geri, başlat/bitir, siyah/beyaz ekran | ✅ RPC | ✅ WPS kısayolları |
| Slayt numarası, notlar, n. slayttan başlatma | ✅ | ❌ Telefonda "Slayt gösterisi açık" görünür |
| Kalem, vurgulayıcı, tümünü sil | ✅ Kalem rengi dahil; vurgulayıcı için gösteri odakta olmalı | ✅ Ctrl+P / Ctrl+I / E (renk seçilemez) |
| Silgi | ✅ | ✅ Ctrl+E |
| Lazer | ✅ Gösteri odaktayken WPS'in lazer kalemi (Ctrl+R); odakta değilken görünür fare imleci telefonla hareket eder | ✅ Ctrl+R |
| Slayt resmi | ✅ Dışa aktarma | ⚠️ Yalnızca gösterinin ekran görüntüsü |
| Sunuma gömülü video | ❌ | ❌ |

Kendi açtığınız WPS'e kısayollar yalnızca WPS penceresi odaktayken gönderilir. WPS kapalıyken "Sunumu WPS ile aç" ile açılan WPS, sonradan çift tıklayarak açtığınız sunumları da alır ve onlar da tam kontrol edilir.

**Devral:** `pywpsrpc` kuruluyken kendi açtığınız WPS çalışıyorsa telefonda ve PC'de "Devral" çıkar. WPS'i kapatır (kaydetme sorusu size bırakılır), dosyaları QuickRemote'un WPS'inde yeniden açar ve gösteri açıksa aynı slayttan sürdürür. Kaydedilmemiş sunum devralınamaz.

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
- 🔍 **Otomatik Keşif:** Aynı ağdaki PC'ler otomatik olarak listelenir; daha önce bağlanılan bir PC kayıtlı PIN ile doğrudan bağlanır, PIN yalnızca değiştiyse sorulur
- 🔵 **Bluetooth:** Telefon bilgisayarın klavyesi ve faresi olur; PC uygulaması gerekmez, Wi-Fi'a göre daha az özellik vardır
- ✏️ **Manuel:** IP adresi ve PIN kodunu elle girin

---

### 4. Saat Uygulamasını Derleyin (isteğe bağlı)

```bash
cd quick_remote_wear
JAVA_HOME=<jdk-21-yolu> sh ./gradlew :app:assembleRelease
adb install -r app/build/outputs/apk/release/app-release.apk
```

Telefondaki uygulamayla aynı anahtarla imzalanmalıdır; ikisi de `key.properties` yoksa debug anahtarına düşer. Debug derlemesi saatte çok takılır.

---

### 5. Testler

```bash
(cd quick_remote_app && flutter test)            # telefon uygulaması
(cd quick_remote_pc && flutter test)             # PC sunucusu
(cd packages/quick_remote_shared && dart test)   # paylaşılan paket
python3 -m unittest discover -s quick_remote_pc/test/python   # Impress/WPS köprüleri (repo kökünden; LibreOffice veya WPS gerekmez)
(cd quick_remote_wear && sh ./gradlew :app:testDebugUnitTest) # saat uygulaması
```

> **Not:** Repo yolu ASCII olmayan karakter içeriyorsa (ör. `Masaüstü`) `flutter analyze` çöker; yerine `dart analyze` kullanın.

---

## 📡 Komut Protokolü

Tüm komutlar `quick_remote_shared` paketi üzerinden paylaşılır:

| Komut | Açıklama |
|-------|----------|
| `NEXT` / `PREV` | Sonraki / önceki slayt |
| `START` / `END` | Sunumu başlat / bitir (tuş programa göre değişir) |
| `START_AT:<n>` | n. slayttan sunumu başlat |
| `LOCK` | Bilgisayarı kilitle (Win+L) |
| `MODE_ARROW` | Ok/imleç modu |
| `MODE_LASER` | Lazer işaretçi modu |
| `MODE_PEN` | Kalem modu |
| `MODE_HIGHLIGHTER` | Vurgulayıcı modu |
| `MODE_ERASER` | Silgi modu |
| `MODE_SPOTLIGHT` | Spot ışığı (yalnızca QuickRemote katmanı) |
| `MODE_ZOOM` | Büyüteç (yalnızca Windows'ta katman) |
| `LASER_OFF` | Lazeri kapat |
| `ERASE_ALL` | Slayttaki tüm çizimleri sil |
| `UNDO_INK` | Son çizgiyi geri al (yalnızca QuickRemote katmanı) |
| `BLACK_SCREEN` / `WHITE_SCREEN` | Siyah / beyaz ekran |
| `SET_PEN_COLOR:<bgr>` | Kalem rengini BGR değeri ile değiştir |
| `SET_HIGHLIGHTER_COLOR:<bgr>` | Vurgulayıcı rengini BGR değeri ile değiştir |
| `SET_KEEP_INK:0/1` | Slayt değişince çizimleri koru / sil (telefonun ayarı) |
| `SLIDE_PREVIEW:0/1` | Bu telefona slayt resimlerini gönder / gönderme |
| `SLIDE_THUMB:<n>` | n. slaydın küçük resmini iste |
| `WPS_TAKE_OVER` | Kullanıcının açtığı WPS'i devral (Linux) |
| `LEFT_CLICK` / `RIGHT_CLICK` | Sol / sağ fare tıklaması |
| `LEFT_DOWN` / `LEFT_UP` | Fare sürükleme (basılı tut / bırak) |
| `REFRESH_STATE` | Slayt durumunu yenile |
| `MEDIA_PLAY_PAUSE` / `MEDIA_REWIND` | PPT gömülü video oynat/duraklat ve geri sar |
| `VOLUME_UP` / `VOLUME_DOWN` / `VOLUME_MUTE` / `VOLUME_SET:<n>` | Sistem ses seviyesi kontrolleri |
| `SYSTEM_MEDIA_PLAY_PAUSE` vb. | Sistem medya kontrolleri (Sonraki, Önceki, Durdur) |

Çizim modları, `ERASE_ALL` ve siyah/beyaz ekran, QuickRemote katmanı çizmiyorsa yalnızca bir slayt gösterisi açıkken uygulanır. Yüksek frekanslı fare/lazer hareketi JSON yerine 9 baytlık ikili çerçevelerle gönderilir; PC slayt resimlerini de ikili çerçeveyle ve yalnızca `SLIDE_PREVIEW:1` gönderen telefona yollar. Başarısız bir komut `STATUS` `COMMAND_FAILED` ve bir hata koduyla bildirilir; metni telefon kendi dilinde gösterir.

---

## 🔐 Güvenlik Modeli

```text
 İstemci                                      Sunucu
    │                                            │
    │──── TLS Handshake ────────────────────────►│
    │◄─── Self-Signed Cert ──────────────────────│
    │                                            │
    │──── WebSocket Upgrade ────────────────────►│
    │──── {"auth": PIN, "name": …} (TLS) ───────►│
    │◄─── AUTH_OK / AUTH_FAIL ───────────────────│
    │                                            │
    │──── Komutlar (şifreli kanal) ─────────────►│
    │◄─── Slayt durumu (şifreli kanal) ──────────│
```

- Tüm trafik **TLS ile şifrelenir**
- PIN, **TLS kanalı içinde** gönderilir ve sunucuda sabit zamanlı karşılaştırılır
- **5 başarısız deneme** → IP 60 saniyeliğine engellenir (engel her denemede yeniden kontrol edilir)
- IP başına en fazla **3**, toplamda **32** doğrulanmamış bağlantı; dakikada **20'den fazla** hatalı PIN → eşleştirme 60 sn durur
- **5 saniye** içinde kimlik doğrulanmazsa bağlantı kesilir
- QR kodu sertifika parmak izini taşır; telefon ilk bağlantıda bile sertifikayı doğrular (**certificate pinning**). QR'sız ilk bağlantıda PIN gönderilmeden önce **güvenlik kodu** karşılaştırılır; parmak izi ancak PIN kabul edilince kaydedilir
- Yalnızca yerel ağdan bağlanılabilir; diğer adresler TLS'ten önce reddedilir ve el sıkışmaya 10 saniye tanınır
- Kimlik doğrulamadan önce gönderilebilecek veri ve her mesaj 4 KB ile sınırlıdır; sıkıştırma (permessage-deflate) kapalıdır; doğrulanmış telefon saniyede en çok 30 metin komutu gönderebilir
- İlk eşleşmeden sonra QR/PIN gizlenir; PC'den bir telefon çıkarıldığında PIN yenilenir
- Tarayıcılardan gelen (Origin başlıklı) WebSocket bağlantıları reddedilir
- Herkese açık ağ tespit edildiğinde sunucu tarafında **uyarı gösterilir**

---

## 📋 Proje Durumu

Nelerin yapılıp nerede denendiği [`docs/raporlar/YAPILANLAR.md`](docs/raporlar/YAPILANLAR.md), açık işler ve henüz gerçek cihazda denenmemiş özellikler [`docs/raporlar/YAPILMAYANLAR.md`](docs/raporlar/YAPILMAYANLAR.md) içindedir. Play Store hazırlığı: [`PLAY_STORE_YAPILACAKLAR.md`](PLAY_STORE_YAPILACAKLAR.md).

---

## 📄 Lisans

Bu proje kişisel kullanım amaçlıdır.
