# Site araçları

`site/index.html` (Türkçe) ve `site/en/index.html` (İngilizce) elle yazılmaz; ikisi de
`parts/` klasöründeki parçalardan üretilir. Böylece iki dil aynı yapıda kalır.

```bash
python3 site/tools/build_pages.py     # iki sayfayı yazar
node site/tools/verify.mjs            # tarayıcıda dener (playwright gerekir)
node site/tools/social.mjs            # paylaşım görselleri ve hero döngüsü (ffmpeg gerekir)
```

## Sayfa parçaları

- `parts/order.txt` bölümlerin sırası; her satır bir `parts/<ad>.html` dosyası.
- Görünen her cümle bir çifttir: `{{Türkçe metin||English text}}`. Çiftin içinde `||` ve
  `}}` bulunmamalı. `@ROOT@` sitenin köküne giden yol (`''` ya da `../`).
- İkonlar `icons/<ad>.path` dosyalarıdır (Material Symbols Rounded, ağırlık 400, tek
  `d` değeri). Parçada `<use href="#i-<ad>"/>` yazmak yeter; sayfaya yalnızca kullanılanlar girer.
  Yeni ikon: `https://raw.githubusercontent.com/marella/material-symbols/main/svg/400/rounded/<ad>.svg`
  dosyasındaki `d` değerini `icons/<ad-tireli>.path` olarak kaydet.
- Logo `parts/head.html` içindeki `#mark` sembolüdür (`brand/logo/favicon.svg`'den; elle çizme,
  marka betiği değişirse yeniden al).
- `main.js` metin taşımaz; metinler `data-*` özellikleriyle HTML'den okunur (`%n`, `%t` yer tutucu).

## Doğrulama (`verify.mjs`)

Yerel bir sunucuyla iki dilde, 1440 ve 390 px, açık ve koyu, `prefers-reduced-motion` açık ve
kapalı: konsol hataları, kırık `#` bağlantıları ve ikonlar, yatay kaydırma, TR/EN eşitliği; ayrıca
demoları (telefon, saat, tema, katman, PC penceresi, tepsi, kopyalama) tıklayarak dener.
`--quick` yalnızca açık ve hareketli kombinasyonu çalıştırır; `--shots=DİZİN [--only=id,id]`
bölüm ekran görüntüleri alır.

## Paylaşım görselleri

`social.html`, `assets/og/` altındaki bütün dosyaların kaynağıdır (`?lang=tr|en&format=og|square|loop`).
Sitenin `style.css` dosyasını kullanır; telefon sitedekiyle aynı çizilir. `social.mjs` hepsini yeniden
üretir: `og-<lang>.png` (1200×630), `social-<lang>.png` (1080×1080), `loop-poster-<lang>.png`,
`loop-<lang>.mp4` ve `.webm`. Döngü 6 saniyedir; `window.renderAt(saniye)` tek kareyi çizer.
