package com.quickremote.wear.ui

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumnItemScope
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.ListHeaderDefaults
import androidx.wear.compose.material3.lazy.TransformationSpec
import androidx.wear.compose.material3.lazy.transformedHeight

// Modifiers for the items of a TransformingLazyColumn: the height follows the
// morph at the screen's edges, and the first and last items keep clear of
// the time and the round bottom (the list's own padding is small on purpose).

@Composable
fun Modifier.headerItem(scope: TransformingLazyColumnItemScope, spec: TransformationSpec): Modifier = with(scope) {
    this@headerItem
        .transformedHeight(scope, spec)
        .minimumVerticalContentPadding(
            ListHeaderDefaults.minimumTopListContentPadding,
            ListHeaderDefaults.minimumBottomListContentPadding,
        )
}

@Composable
fun Modifier.buttonItem(scope: TransformingLazyColumnItemScope, spec: TransformationSpec): Modifier = with(scope) {
    this@buttonItem
        .fillMaxWidth()
        .transformedHeight(scope, spec)
        .minimumVerticalContentPadding(ButtonDefaults.minimumVerticalListContentPadding)
}

@Composable
fun Modifier.textItem(scope: TransformingLazyColumnItemScope, spec: TransformationSpec): Modifier = with(scope) {
    this@textItem
        .fillMaxWidth()
        .padding(horizontal = 8.dp)
        .transformedHeight(scope, spec)
        .minimumVerticalContentPadding(ButtonDefaults.minimumVerticalListContentPadding)
}
