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
  static const cobaltDeep = Color(0xFF1B28A3); // logo tile gradient end
  static const laser = Color(0xFFFF6A3D); // the laser dot: the one warm accent
  static const laserDeep = Color(0xFFC8401C); // laser as text on Paper

  // ── Neutrals, light theme ("Paper") ──────────────────────────────────────
  static const paper = Color(0xFFF4F5FA);
  static const paperSurface = Color(0xFFFFFFFF);
  static const paperSunken = Color(0xFFECEEF5);
  static const paperBorder = Color(0xFFE1E4EE);
  static const paperBorderStrong = Color(0xFFC9CEDD);
  static const inkText = Color(0xFF0E1224);
  static const inkTextSecondary = Color(0xFF4A5172);
  static const inkTextMuted = Color(0xFF6B7194);
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
  static const paperTextMuted = Color(0xFF7D84A6);
  static const inkGlass = Color(0xB3141A30);
  static const inkGlassBorder = Color(0x1FFFFFFF);
  static const inkShadow = Color(0x66000000);
  static const inkScrim = Color(0x99000000);

  // ── Status: bright on Ink, deep on Paper (both AA on their background) ───
  static const success = Color(0xFF3DDC97);
  static const successDeep = Color(0xFF12804F);
  static const warning = Color(0xFFFFB547);
  static const warningDeep = Color(0xFFA35F00);
  static const danger = Color(0xFFFF5C77);
  static const dangerDeep = Color(0xFFCC2240);
  static const info = Color(0xFF5CC8FF);
  static const infoDeep = Color(0xFF0A6FAD);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // ── Phone only ───────────────────────────────────────────────────────────

  // Drawing tools: bright on Ink, deep on Paper. The eraser uses warning.
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
}
