package com.quickremote.wear.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme

/**
 * The brand palette (brand/BRAND.md), the dark ("Ink") values of the phone's
 * AppColors under the same names: a watch is always dark. The only place with
 * raw colors.
 */
object WearColors {
    val cobalt = Color(0xFF2F4BE0)
    val cobaltBright = Color(0xFF3E63F5)
    val cobaltLight = Color(0xFF8EA1FF)
    val cobaltDeep = Color(0xFF1B28A3)
    val laser = Color(0xFFFF6A3D)
    val ink = Color(0xFF0A0D18)
    val inkSurface = Color(0xFF121628)
    val inkRaised = Color(0xFF1A1F36)
    val inkSunken = Color(0xFF0E1222)
    val inkBorder = Color(0xFF252B47)
    val paperText = Color(0xFFEEF0FA)
    val paperTextSecondary = Color(0xFFA9AFCB)
    val paperTextMuted = Color(0xFF7D84A6)
    val danger = Color(0xFFFF5C77)
    val white = Color(0xFFFFFFFF)
    val black = Color(0xFF000000)
}

private val colors = ColorScheme(
    // Cobalt Light carries text and icons on Ink; the filled buttons are cobalt.
    primary = WearColors.cobaltLight,
    onPrimary = WearColors.ink,
    primaryContainer = WearColors.cobalt,
    onPrimaryContainer = WearColors.white,
    tertiary = WearColors.laser,
    onTertiary = WearColors.ink,
    surfaceContainerLow = WearColors.inkSunken,
    surfaceContainer = WearColors.inkSurface,
    surfaceContainerHigh = WearColors.inkRaised,
    onSurface = WearColors.paperText,
    onSurfaceVariant = WearColors.paperTextSecondary,
    outline = WearColors.paperTextMuted,
    outlineVariant = WearColors.inkBorder,
    // Pure black: the OLED pixels stay off.
    background = WearColors.black,
    onBackground = WearColors.paperText,
    error = WearColors.danger,
    onError = WearColors.ink,
)

@Composable
fun QuickRemoteTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = colors, content = content)
}
