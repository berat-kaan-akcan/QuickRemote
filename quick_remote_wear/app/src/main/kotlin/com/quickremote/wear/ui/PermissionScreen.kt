package com.quickremote.wear.ui

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.ListHeaderDefaults
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import com.quickremote.wear.R

/** Asks for "Nearby devices"; after a refusal also offers the app's settings. */
@Composable
fun PermissionScreen(onGranted: () -> Unit) {
    val context = LocalContext.current
    var refused by remember { mutableStateOf(false) }
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        if (Permissions.granted(context, Permissions.keyboard)) onGranted() else refused = true
    }
    val listState = rememberTransformingLazyColumnState()
    val spec = rememberTransformationSpec()
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(state = listState, contentPadding = contentPadding) {
            item {
                Image(
                    WearIcons.Mark,
                    contentDescription = null,
                    modifier = Modifier
                        .minimumVerticalContentPadding(ListHeaderDefaults.minimumTopListContentPadding, 0.dp)
                        .size(36.dp),
                )
            }
            item {
                Text(
                    stringResource(R.string.permission_title),
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = TextAlign.Center,
                    modifier = textItem(spec),
                )
            }
            item {
                Text(
                    stringResource(R.string.permission_text),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = textItem(spec),
                )
            }
            item {
                Button(
                    onClick = { request.launch(Permissions.keyboard) },
                    modifier = buttonItem(spec),
                    transformation = SurfaceTransformation(spec),
                    label = { Text(stringResource(if (refused) R.string.retry else R.string.permission_grant)) },
                )
            }
            // Refused twice, Android stops asking: only the settings can grant it.
            if (refused) {
                item {
                    FilledTonalButton(
                        onClick = {
                            val intent = Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", context.packageName, null),
                            )
                            try {
                                context.startActivity(intent)
                            } catch (_: ActivityNotFoundException) {
                            }
                        },
                        modifier = buttonItem(spec),
                        transformation = SurfaceTransformation(spec),
                        label = { Text(stringResource(R.string.permission_settings)) },
                    )
                }
            }
        }
    }
}
