package com.quickremote.wear.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import com.quickremote.wear.ui.theme.WearColors

/**
 * The remote's round button: a disc of [fill] that shrinks a little while
 * pressed. [label] is what a screen reader says; the content, if any, is a
 * symbol.
 */
@Composable
fun RoundButton(
    onClick: () -> Unit,
    fill: Brush,
    diameter: Dp,
    label: String,
    modifier: Modifier = Modifier,
    border: BorderStroke? = null,
    content: @Composable BoxScope.() -> Unit = {},
) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.92f else 1f, label = "press")
    Box(
        modifier = modifier
            .size(diameter)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clip(CircleShape)
            .background(fill)
            .then(if (border != null) Modifier.border(border, CircleShape) else Modifier)
            .clickable(interactionSource = interaction, indication = null, role = Role.Button, onClick = onClick)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center,
        content = content,
    )
}

/** The brand's cobalt gradient, as on the phone's primary buttons. */
val CobaltFill = Brush.linearGradient(listOf(WearColors.cobaltBright, WearColors.cobalt))

/** The same, a shade darker. */
val CobaltDeepFill = Brush.linearGradient(listOf(WearColors.cobalt, WearColors.cobaltDeep))
