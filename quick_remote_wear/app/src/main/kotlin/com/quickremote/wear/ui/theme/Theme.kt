package com.quickremote.wear.ui.theme

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.core.content.edit
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme

/**
 * The brand palette (brand/BRAND.md), the dark ("Ink") values of the phone's
 * AppColors under the same names: a watch is always dark. With [WearPalette]
 * the only place with raw colors.
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

    // The light ("Paper") values, for the watch that stands in for a white screen.
    val paper = Color(0xFFF4F5FA)
    val paperBorder = Color(0xFFC9CEDD)
    val inkText = Color(0xFF0E1224)
    val inkTextMuted = Color(0xFF6B7194)

    val white = Color(0xFFFFFFFF)
    val black = Color(0xFF000000)
}

/**
 * A color theme of the remote. [accent] and [accentEnd] fill the Next button
 * (a gradient), [onAccent] is its symbol; [raised] fills the small buttons;
 * [ring] draws the slide progress; [laser] is the laser dot and the time.
 */
@Immutable
data class WearPalette(
    val accent: Color,
    val accentEnd: Color,
    val onAccent: Color,
    val accentText: Color,
    val raised: Color,
    val sunken: Color,
    val surface: Color,
    val border: Color,
    val text: Color,
    val textSecondary: Color,
    val muted: Color,
    val ring: Color,
    val laser: Color,
    val danger: Color,
) {
    val accentFill: Brush get() = Brush.linearGradient(listOf(accent, accentEnd))
}

/** The themes a presenter can pick; [COBALT], the brand's, is the default. */
enum class WearTheme(val palette: WearPalette) {
    COBALT(
        WearPalette(
            accent = WearColors.cobaltBright, accentEnd = WearColors.cobalt, onAccent = WearColors.white,
            accentText = WearColors.cobaltLight,
            raised = WearColors.inkRaised, sunken = WearColors.inkSunken, surface = WearColors.inkSurface,
            border = WearColors.inkBorder, text = WearColors.paperText,
            textSecondary = WearColors.paperTextSecondary, muted = WearColors.paperTextMuted,
            ring = WearColors.cobaltLight, laser = WearColors.laser, danger = WearColors.danger,
        ),
    ),

    /** Black and white: the fewest lit pixels in a dark room. */
    OLED(
        WearPalette(
            accent = Color(0xFFF4F4F6), accentEnd = Color(0xFFDCDCE2), onAccent = Color(0xFF000000),
            accentText = Color(0xFFFFFFFF),
            raised = Color(0xFF18181C), sunken = Color(0xFF0D0D0F), surface = Color(0xFF111114),
            border = Color(0xFF2A2A30), text = Color(0xFFFFFFFF),
            textSecondary = Color(0xFFB4B4BC), muted = Color(0xFF8A8A94),
            ring = Color(0xFFFFFFFF), laser = WearColors.laser, danger = WearColors.danger,
        ),
    ),

    /** Yellow on black: the most legible in sunlight and for weak eyes. */
    HIGH_CONTRAST(
        WearPalette(
            accent = Color(0xFFFFE14D), accentEnd = Color(0xFFFFD000), onAccent = Color(0xFF000000),
            accentText = Color(0xFFFFD000),
            raised = Color(0xFF1C1C1C), sunken = Color(0xFF111111), surface = Color(0xFF161616),
            border = Color(0xFF333333), text = Color(0xFFFFFFFF),
            textSecondary = Color(0xFFD0D0D0), muted = Color(0xFFB5B5B5),
            ring = Color(0xFFFFD000), laser = Color(0xFFFF5A36), danger = Color(0xFFFF4D6A),
        ),
    ),

    /** The brand's warm accent in front. */
    LASER(
        WearPalette(
            accent = Color(0xFFFF7A4D), accentEnd = Color(0xFFF05A2A), onAccent = WearColors.white,
            accentText = Color(0xFFFFB08F),
            raised = Color(0xFF241B15), sunken = Color(0xFF1A1410), surface = Color(0xFF1F1712),
            border = Color(0xFF3A2B20), text = Color(0xFFFFF3EC),
            textSecondary = Color(0xFFCDB8AB), muted = Color(0xFFA08B7E),
            ring = Color(0xFFFFB08F), laser = Color(0xFFFFD24A), danger = WearColors.danger,
        ),
    ),

    MINT(
        WearPalette(
            accent = Color(0xFF34E3B0), accentEnd = Color(0xFF12C995), onAccent = Color(0xFF032019),
            accentText = Color(0xFF34E3B0),
            raised = Color(0xFF152824), sunken = Color(0xFF0E1C19), surface = Color(0xFF11221E),
            border = Color(0xFF1F3A34), text = Color(0xFFEAFBF6),
            textSecondary = Color(0xFFA9C9C0), muted = Color(0xFF7FA59B),
            ring = Color(0xFF34E3B0), laser = WearColors.laser, danger = WearColors.danger,
        ),
    ),

    VIOLET(
        WearPalette(
            accent = Color(0xFF9B6BFF), accentEnd = Color(0xFF7C4DFF), onAccent = WearColors.white,
            accentText = Color(0xFFC4A9FF),
            raised = Color(0xFF1F1836), sunken = Color(0xFF161127), surface = Color(0xFF1A142E),
            border = Color(0xFF2E2550), text = Color(0xFFF2EEFF),
            textSecondary = Color(0xFFB9B0D6), muted = Color(0xFF8C82B0),
            ring = Color(0xFFC4A9FF), laser = WearColors.laser, danger = WearColors.danger,
        ),
    ),
    ;

    companion object {
        private const val PREFS = "quickremote"
        private const val KEY = "theme"

        /** The stored theme; [COBALT] when none was picked. */
        fun stored(context: Context): WearTheme {
            val name = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            return entries.firstOrNull { it.name == name } ?: COBALT
        }

        fun store(context: Context, theme: WearTheme) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit { putString(KEY, theme.name) }
        }
    }
}

/** The palette of the theme in use; read it with `LocalWearPalette.current`. */
val LocalWearPalette = staticCompositionLocalOf { WearTheme.COBALT.palette }

private fun WearPalette.scheme() = ColorScheme(
    // The accent's light shade carries text and icons; the filled buttons are the accent.
    primary = accentText,
    onPrimary = WearColors.ink,
    primaryContainer = accentEnd,
    onPrimaryContainer = onAccent,
    tertiary = laser,
    onTertiary = WearColors.ink,
    surfaceContainerLow = sunken,
    surfaceContainer = surface,
    surfaceContainerHigh = raised,
    onSurface = text,
    onSurfaceVariant = textSecondary,
    outline = muted,
    outlineVariant = border,
    // Pure black: the OLED pixels stay off.
    background = WearColors.black,
    onBackground = text,
    error = danger,
    onError = WearColors.ink,
)

@Composable
fun QuickRemoteTheme(theme: WearTheme = WearTheme.COBALT, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalWearPalette provides theme.palette) {
        MaterialTheme(colorScheme = theme.palette.scheme(), content = content)
    }
}
