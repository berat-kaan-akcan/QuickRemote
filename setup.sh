#!/bin/bash

# QuickRemote Kurulum Betiği
# Bu betik proje içindeki Flutter paketlerinin bağımlılıklarını kurar.

echo "QuickRemote bağımlılıkları kuruluyor..."
echo "========================================="

FLUTTER_CMD="flutter"
if ! command -v flutter &> /dev/null
then
    if [ -x "$HOME/flutter/bin/flutter" ]; then
        FLUTTER_CMD="$HOME/flutter/bin/flutter"
    else
        echo "Hata: 'flutter' komutu bulunamadı!"
        echo "Lütfen bilgisayarınıza Flutter SDK'sını kurun."
        exit 1
    fi
fi

echo "1. quick_remote_shared paketinin bağımlılıkları indiriliyor..."
cd packages/quick_remote_shared
$FLUTTER_CMD pub get
cd ../..
echo "-----------------------------------------"

echo "2. quick_remote_app (Mobil Uygulama) bağımlılıkları indiriliyor..."
cd quick_remote_app
$FLUTTER_CMD pub get
cd ..
echo "-----------------------------------------"

echo "3. quick_remote_pc (Masaüstü Uygulaması) bağımlılıkları indiriliyor..."
cd quick_remote_pc
$FLUTTER_CMD pub get
cd ..
echo "-----------------------------------------"

echo "Tüm bağımlılıklar başarıyla kuruldu!"
