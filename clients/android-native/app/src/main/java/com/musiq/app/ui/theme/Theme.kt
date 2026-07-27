package com.musiq.app.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

/**
 * Material 3 Expressive with Dynamic Color (Monet): on Android 12+, the
 * entire palette is derived from the user's wallpaper via
 * `dynamicColorScheme`, so no two devices necessarily render musiQ with
 * the same accent — this is the one OS in the whole matrix where the
 * *user's own device*, not a design token file, is the source of the
 * palette. Falls back to a fixed musiQ brand scheme below API 31.
 */
@Composable
fun MusiqTheme(
    useDynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val dark = isSystemInDarkTheme()
    val context = LocalContext.current

    val colorScheme = when {
        useDynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        dark -> FallbackDarkColorScheme
        else -> FallbackLightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = MusiqTypography,
        content = content,
    )
}
