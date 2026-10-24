import 'package:flutter/painting.dart';

/// The raw brand palette (brand/BRAND.md). Screens read colors through
/// [AppPalette] (`context.palette`), which picks the light or dark value;
/// only the theme files use these directly.
///
/// The PC app has a copy of everything above "Phone only"; keep the two
/// copies identical.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const cobalt = Color(0xFF2F4BE0); // primary fill; primary text on Paper
  static const cobaltBright = Color(0xFF3E63F5); // gradient end of primary fills
  static const cobaltLight = Color(0xFF8EA1FF); // primary text and icons on Ink
  static const cobaltDeep = Color(0xFF1B28A3); // end of the logo's Next key gradient
  static const laser = Color(0xFFFF6A3D); // the laser dot: the one warm accent
  static const laserDeep = Color(0xFFC8401C); // laser as text on Paper

  // The logo's own (brand/tools/draw_logo.py): the dark tile's top and the
  // small Previous key's border and chevron on it.
  static const logoTileTop = Color(0xFF141A33);
  static const logoKeyBorder = Color(0xFF323A62);
  static const logoKeyChevron = Color(0xFFC9CEE6);

  // ── Neutrals, light theme ("Paper") ──────────────────────────────────────
  static const paper = Color(0xFFF4F5FA);
  static const paperSurface = Color(0xFFFFFFFF);
  static const paperSunken = Color(0xFFECEEF5);
  static const paperBorder = Color(0xFFE1E4EE);
  static const paperBorderStrong = Color(0xFFC9CEDD);
  static const inkText = Color(0xFF0E1224);
  static const inkTextSecondary = Color(0xFF4A5172);
  static const inkTextMuted = Color(0xFF686E91);
  static const paperGlass = Color(0xB8FFFFFF);
  static const paperGlassBorder = Color(0x14000000);
  static const paperShadow = Color(0x1A1B2350);
  static const paperScrim = Color(0x660E1224);

  // ── Neutrals, dark theme ("Ink") ─────────────────────────────────────────
  static const ink = Color(0xFF0A0D18);
  static const inkSurface = Color(0xFF121628);
  static const inkRaised = Color(0xFF1A1F36);
  static const inkSunken = Color(0xFF0E1222);
  static const inkBorder = Color(0xFF252B47);
  static const inkBorderStrong = Color(0xFF343B5C);
  static const paperText = Color(0xFFEEF0FA);
  static const paperTextSecondary = Color(0xFFA9AFCB);
  static const paperTextMuted = Color(0xFF8087A9);
  static const inkGlass = Color(0xB3141A30);
  static const inkGlassBorder = Color(0x1FFFFFFF);
  static const inkShadow = Color(0x66000000);
  static const inkScrim = Color(0x99000000);

  // ── Status: bright on Ink, deep on Paper (both AA on their background) ───
  static const success = Color(0xFF3DDC97);
  static const successDeep = Color(0xFF12804F);
  static const successShade = Color(0xFF1F9E6B); // start of the Start button's gradient
  static const warning = Color(0xFFFFB547);
  static const warningDeep = Color(0xFFA35F00);
  static const danger = Color(0xFFFF5C77);
  static const dangerDeep = Color(0xFFCC2240);
  static const info = Color(0xFF5CC8FF);
  static const infoDeep = Color(0xFF0A6FAD);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // ── Phone only ───────────────────────────────────────────────────────────

  // Drawing tools: bright on Ink, deep on Paper. The eraser uses the
  // secondary text color.
  static const toolLaser = Color(0xFFFF4D5E);
  static const toolLaserDeep = Color(0xFFD9233A);
  static const toolPen = Color(0xFF34D399);
  static const toolPenDeep = Color(0xFF0F8A5F);
  static const toolHighlighter = Color(0xFFFFD43B);
  static const toolHighlighterDeep = Color(0xFF8F6E00);

  // Ink swatches in the color picker: the colors drawn on the slide.
  static const inkRed = Color(0xFFFF1744);
  static const inkBlue = Color(0xFF2979FF);
  static const inkGreen = Color(0xFF00E676);
  static const inkYellow = Color(0xFFFFEA00);
  static const inkWhite = white;
  static const inkPurple = Color(0xFFD500F9);

  // The camera scrim of the QR scanner, dark in both themes.
  static const scannerScrim = Color(0xB3060810);

  // ── Color themes (Settings → Theme) ──────────────────────────────────────
  // Their backgrounds, text and primary; the laser and the status colors are
  // Cobalt's in every theme. OLED, high contrast, mint and violet match the
  // watch's WearTheme palettes.

  // OLED: black and white, the fewest lit pixels.
  static const oledBackground = Color(0xFF000000);
  static const oledSurface = Color(0xFF111114);
  static const oledRaised = Color(0xFF18181C);
  static const oledSunken = Color(0xFF0D0D0F);
  static const oledBorder = Color(0xFF2A2A30);
  static const oledBorderStrong = Color(0xFF3A3A42);
  static const oledText = Color(0xFFFFFFFF);
  static const oledTextSecondary = Color(0xFFB4B4BC);
  static const oledTextMuted = Color(0xFF8A8A94);
  static const oledPrimary = Color(0xFFDCDCE2);
  static const oledPrimaryBright = Color(0xFFF4F4F6);
  static const oledPrimaryDeep = Color(0xFFC4C4CC);

  // High contrast: yellow on black.
  static const contrastBackground = Color(0xFF000000);
  static const contrastSurface = Color(0xFF161616);
  static const contrastRaised = Color(0xFF1C1C1C);
  static const contrastSunken = Color(0xFF111111);
  static const contrastBorder = Color(0xFF3A3A3A);
  static const contrastBorderStrong = Color(0xFF4A4A4A);
  static const contrastText = Color(0xFFFFFFFF);
  static const contrastTextSecondary = Color(0xFFD0D0D0);
  static const contrastTextMuted = Color(0xFFB5B5B5);
  static const contrastPrimary = Color(0xFFFFD000);
  static const contrastPrimaryBright = Color(0xFFFFE14D);
  static const contrastPrimaryDeep = Color(0xFFE6BB00);

  // Mint: calm green on a dark sea.
  static const mintBackground = Color(0xFF0A1714);
  static const mintSurface = Color(0xFF11221E);
  static const mintRaised = Color(0xFF152824);
  static const mintSunken = Color(0xFF0E1C19);
  static const mintBorder = Color(0xFF1F3A34);
  static const mintBorderStrong = Color(0xFF2A4A43);
  static const mintText = Color(0xFFEAFBF6);
  static const mintTextSecondary = Color(0xFFA9C9C0);
  static const mintTextMuted = Color(0xFF7FA59B);
  static const mintPrimary = Color(0xFF12C995);
  static const mintPrimaryBright = Color(0xFF34E3B0);
  static const mintPrimaryDeep = Color(0xFF0E9F77);
  static const mintOnPrimary = Color(0xFF032019);

  // Violet: lively violet on a night purple. The bright end is darker than
  // the design's so that white text on it reaches 4.5:1.
  static const violetBackground = Color(0xFF110D20);
  static const violetSurface = Color(0xFF1A142E);
  static const violetRaised = Color(0xFF1F1836);
  static const violetSunken = Color(0xFF161127);
  static const violetBorder = Color(0xFF2E2550);
  static const violetBorderStrong = Color(0xFF3B3163);
  static const violetText = Color(0xFFF2EEFF);
  static const violetTextSecondary = Color(0xFFB9B0D6);
  static const violetTextMuted = Color(0xFF8C82B0);
  static const violetPrimary = Color(0xFF7C4DFF);
  static const violetPrimaryBright = Color(0xFF874DFF);
  static const violetPrimaryDeep = Color(0xFF5E2FE0);
  static const violetPrimaryText = Color(0xFFC4A9FF);

  // Sunset: cream and terracotta, light only. Primary and its bright end are
  // darker than the design's so that white text on them reaches 4.5:1.
  static const sunsetBackground = Color(0xFFFBF5EE);
  static const sunsetSurface = Color(0xFFFFFFFF);
  static const sunsetSunken = Color(0xFFF3E9DD);
  static const sunsetBorder = Color(0xFFEBDDCC);
  static const sunsetBorderStrong = Color(0xFFDCC8B3);
  static const sunsetText = Color(0xFF2A1A12);
  static const sunsetTextSecondary = Color(0xFF6B5244);
  static const sunsetTextMuted = Color(0xFF846B5C);
  static const sunsetPrimary = Color(0xFFD24226);
  static const sunsetPrimaryBright = Color(0xFFCA4C0F);
  static const sunsetPrimaryDeep = Color(0xFFB83A1F);
}
