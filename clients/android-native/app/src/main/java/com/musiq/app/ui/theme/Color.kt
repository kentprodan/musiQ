package com.musiq.app.ui.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

// musiQ brand fallback palette — only used below Android 12 (API 31),
// where `dynamicColorScheme` (Monet) isn't available.
private val MusiqPrimary = Color(0xFF6C5CE7)
private val MusiqSecondary = Color(0xFF00CEC9)

val FallbackLightColorScheme = lightColorScheme(
    primary = MusiqPrimary,
    secondary = MusiqSecondary,
)

val FallbackDarkColorScheme = darkColorScheme(
    primary = MusiqPrimary,
    secondary = MusiqSecondary,
)
