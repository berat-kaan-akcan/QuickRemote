# site1: "Karanlık salon"

İkinci tanıtım sitesi; `site/`den ayrıdır. Sayfa tek bir karanlık salondur: bir lazer
çizgisi kaydırdıkça ilerler, başlıkların altını çizer, QR kodu ve saati daire içine alır,
sonda ekranı dolduran Sonraki tuşunun köşesine oturup logoyu tamamlar.

```bash
python3 site1/tools/build_pages.py     # iki sayfayı yazar (index.html, en/index.html)
python3 -m http.server -d site1 8765   # önizleme
```

- Metinler `tools/parts/` içinde `{{Türkçe||English}}` çiftleridir; sayfaları elle düzenleme.
- Çizginin yolu işaretlerden gelir (`js/beam.js`), belge sırasıyla: `data-b="x,y x,y"` kutunun
  kesirleri (isteğe bağlı piksel kayması: `x,y,dx,dy`), `data-ring` kutuyu bir kez dolaşır,
  `.way` bölümü kaplayan görünmez ara noktadır, `data-only="wide|narrow"` yolu ekran genişliğine bağlar. Çizgi yazıya değiyorsa bir `.way` ekle.
- Başlık yazı tipi Sofia Sans Extra Condensed 800 (OFL), gövde Inter. Marka rehberindeki
  Space Grotesk'ten bu sitede bilerek ayrılındı; logo ve renkler markanındır.

## Geçici görseller

`assets/shots/` altındaki dosyalar **gerçek ekran görüntüsü değildir**: onaylı tasarım
görsellerinden kırpıldı (`QuickRemote-tasarim-ornekleri/onaylananlar`), Türkçedir ve eski logoyu
gösterir. Yayımlamadan önce aynı adlarla gerçekleriyle değiştir; çerçeveyi CSS çizer:

| Dosya | Ekran | Oran |
|---|---|---|
| `phone-controls.webp` | Kumanda, Kontroller sekmesi | 541×1186 |
| `phone-touch.webp` | Touchpad, lazer açık | 541×1186 |
| `phone-media.webp` | Medya sekmesi | 541×1186 |
| `phone-report.webp` | Sunum raporu | 541×1186 |
| `watch.webp` | Saat kumandası, yalnız kadran | 437×433 |
| `pc.webp` | PC penceresi, geniş düzen | 1502×964 |

Oran değişirse `width`/`height` özelliklerini ve `pc.webp` için `.qr-mark` konumunu güncelle.
