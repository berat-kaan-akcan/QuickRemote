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
fun TransformingLazyColumnItemScope.headerItem(spec: TransformationSpec): Modifier =
    Modifier
        .transformedHeight(this, spec)
        .minimumVerticalContentPadding(
            ListHeaderDefaults.minimumTopListContentPadding,
            ListHeaderDefaults.minimumBottomListContentPadding,
        )

@Composable
fun TransformingLazyColumnItemScope.buttonItem(spec: TransformationSpec): Modifier =
    Modifier
        .fillMaxWidth()
        .transformedHeight(this, spec)
        .minimumVerticalContentPadding(ButtonDefaults.minimumVerticalListContentPadding)

@Composable
fun TransformingLazyColumnItemScope.textItem(spec: TransformationSpec): Modifier =
    Modifier
        .fillMaxWidth()
        .padding(horizontal = 8.dp)
        .transformedHeight(this, spec)
        .minimumVerticalContentPadding(ButtonDefaults.minimumVerticalListContentPadding)
