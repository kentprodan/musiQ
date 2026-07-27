package com.musiq.app

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.windowsizeclass.ExperimentalMaterialApi3WindowSizeClassApi
import androidx.compose.material3.windowsizeclass.WindowWidthSizeClass
import androidx.compose.material3.windowsizeclass.calculateWindowSizeClass
import com.musiq.app.tv.MusiqTvApp
import com.musiq.app.ui.MusiqMobileApp
import com.musiq.app.ui.theme.MusiqTheme

/**
 * One Activity serves phones, tablets, and Android TV (see the
 * LEANBACK_LAUNCHER category in AndroidManifest.xml) — the split isn't a
 * second app, it's a runtime branch on `UiModeManager` + window size
 * class, matching how the desktop client picks a design language off one
 * `data-os` attribute rather than shipping separate builds.
 */
class MainActivity : ComponentActivity() {

    @OptIn(ExperimentalMaterialApi3WindowSizeClassApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            MusiqTheme {
                if (isTelevision()) {
                    MusiqTvApp()
                } else {
                    val windowSizeClass = calculateWindowSizeClass(this)
                    MusiqMobileApp(useNavigationRail = windowSizeClass.widthSizeClass != WindowWidthSizeClass.Compact)
                }
            }
        }
    }

    private fun isTelevision(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        return uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }
}
