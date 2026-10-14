# Paylaşım görselleri ve hero döngüsü

`social.html`, `assets/og/` altındaki bütün dosyaların kaynağıdır. Sitenin
`style.css` dosyasını kullanır; telefon ve slayt sitedekiyle aynı çizilir.

| Parametre | Değerler |
|---|---|
| `lang` | `tr`, `en` |
| `format` | `og` (1200×630), `square` (1080×1080), `loop` (1280×720) |

Yeniden üretmek için siteyi yerelde sun (`python3 -m http.server -d site`),
sayfayı formatın boyutundaki bir pencerede aç ve ekran görüntüsünü al:
`og-<lang>.png`, `social-<lang>.png`, `loop-poster-<lang>.png`.

Döngü 6 saniyedir. `window.renderAt(saniye)` tek bir kareyi çizer; 30 fps
için 180 kare alınıp ffmpeg ile kodlanır:

```bash
ffmpeg -framerate 30 -i f%03d.png -c:v libx264 -pix_fmt yuv420p -crf 26 -movflags +faststart -an loop-tr.mp4
ffmpeg -framerate 30 -i f%03d.png -c:v libvpx-vp9 -b:v 0 -crf 40 -pix_fmt yuv420p -an loop-tr.webm
```
