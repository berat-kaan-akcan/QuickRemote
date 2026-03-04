import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
import pyautogui
import ctypes
import time

# 1. Firebase Bağlantısı
# serviceAccountKey.json dosyası script ile aynı klasörde olmalı
cred = credentials.Certificate("serviceAccountKey.json")

# DİKKAT: Aşağıdaki URL'yi kendi Firebase konsolundan alıp değiştirmelisin!
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://quickremote-f840b-default-rtdb.europe-west1.firebasedatabase.app/' 
})

# 2. Dinleyici Fonksiyon
def listener(event):
    # Sadece yeni veri geldiğinde veya veri değiştiğinde çalışır
    if event.data:
        command = event.data
        print(f"Gelen Komut: {command}")
        
        # --- KOMUTLAR ---
        
        if command == "NEXT":
            print(">> Slayt İleri")
            pyautogui.press('right') 
            
        elif command == "PREV":
            print("<< Slayt Geri")
            pyautogui.press('left') 
            
        elif command == "LOCK":
            print("!! Bilgisayar Kilitleniyor")
            ctypes.windll.user32.LockWorkStation() 
            
        # Komutu işledikten sonra veritabanını temizle (tekrar basılabilmesi için)
        if command != "IDLE":
            ref.set("IDLE")

# 3. Dinlemeyi Başlat
print("PC Dinlemeye Başladı... (Çıkmak için pencereyi kapat)")

# Veritabanında 'control/command' yolunu dinliyoruz
ref = db.reference('control/command')

# İlk açılışta veritabanını sıfırlayalım
ref.set("IDLE")

# Değişiklikleri canlı izle
ref.listen(listener)

# Programın kapanmaması için sonsuz döngü
while True:
    time.sleep(1)