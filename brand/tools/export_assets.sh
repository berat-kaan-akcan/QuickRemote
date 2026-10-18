#!/usr/bin/env bash
# Renders the brand SVGs in brand/logo into the PNG/ICO files the apps and
# the brand kit use. Needs rsvg-convert (librsvg) and ImageMagick 7 (magick).
# Run from anywhere: brand/tools/export_assets.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
LOGO=brand/logo
OUT=brand/export
APP=quick_remote_app
PC=quick_remote_pc
WEAR=quick_remote_wear
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

svg() { rsvg-convert -w "$2" -h "$2" "$1" -o "$3"; }

python3 brand/tools/draw_logo.py

# ── Brand kit ────────────────────────────────────────────────────────────────
for s in 1024 512 192 180; do svg $LOGO/app-icon.svg $s $OUT/app-icon-$s.png; done
svg $LOGO/app-icon-light.svg 512 $OUT/app-icon-light-512.png
svg $LOGO/app-icon-oled.svg 512 $OUT/app-icon-oled-512.png
svg $LOGO/mark-mono.svg 512 $OUT/mark-mono-512.png
rsvg-convert -h 260 $LOGO/lockup-light-bg.svg -o $OUT/lockup-light-bg.png
rsvg-convert -h 260 $LOGO/lockup-dark-bg.svg -o $OUT/lockup-dark-bg.png
for s in 16 32 48; do svg $LOGO/favicon.svg $s "$TMP/fav-$s.png"; done
cp "$TMP/fav-32.png" $OUT/favicon-32.png
python3 brand/tools/pack_ico.py $OUT/favicon.ico "$TMP/fav-16.png" "$TMP/fav-32.png" "$TMP/fav-48.png"

# ── Phone app ────────────────────────────────────────────────────────────────
svg $LOGO/app-icon.svg 1024 $APP/assets/images/logo.png
RES=$APP/android/app/src/main/res
# Legacy launcher icon (pre-Android 8): the rounded tile.
for d in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  svg $LOGO/app-icon.svg "${d#*:}" "$RES/mipmap-${d%%:*}/ic_launcher.png"
done
# Adaptive icon (Android 8+): 108 dp layers. The foreground and monochrome
# SVGs already keep the mark inside the 66 dp safe zone.
for d in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  n=${d%%:*}; s=${d#*:}
  mkdir -p "$RES/drawable-$n"
  svg $LOGO/adaptive-foreground.svg $s "$RES/drawable-$n/ic_launcher_foreground.png"
  svg $LOGO/adaptive-monochrome.svg $s "$RES/drawable-$n/ic_launcher_monochrome.png"
  svg $LOGO/adaptive-background.svg $s "$RES/drawable-$n/ic_launcher_background.png"
  # Splash logo for Android 7-11 (launch_background.xml): the tile, 96 dp.
  t=$((s * 96 / 108))
  svg $LOGO/app-icon.svg $t "$RES/drawable-$n/splash_logo.png"
done
cp "$RES/drawable-xxxhdpi/ic_launcher_foreground.png" $APP/assets/images/logo_padded.png

# ── Watch app ────────────────────────────────────────────────────────────────
# The phone's layers with the mark on black, as on the logo board; Wear OS
# masks them to a circle.
WEAR_RES=$WEAR/app/src/main/res
for d in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  n=${d%%:*}; s=${d#*:}
  mkdir -p "$WEAR_RES/drawable-$n"
  svg $LOGO/adaptive-foreground-oled.svg $s "$WEAR_RES/drawable-$n/ic_launcher_foreground.png"
  svg $LOGO/adaptive-background-oled.svg $s "$WEAR_RES/drawable-$n/ic_launcher_background.png"
  cp "$RES/drawable-$n/ic_launcher_monochrome.png" "$WEAR_RES/drawable-$n/"
done

# ── PC app ───────────────────────────────────────────────────────────────────
svg $LOGO/app-icon.svg 1024 $PC/assets/images/logo.png
for s in 16 20 24 32 40 48 64 128 256; do svg $LOGO/app-icon.svg $s "$TMP/ico-$s.png"; done
python3 brand/tools/pack_ico.py $PC/windows/runner/resources/app_icon.ico "$TMP"/ico-{16,20,24,32,40,48,64,128,256}.png

echo "Exported to $OUT, $APP, $PC and $WEAR."
