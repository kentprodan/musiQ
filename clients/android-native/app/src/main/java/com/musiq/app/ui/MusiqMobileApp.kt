package com.musiq.app.ui

import androidx.compose.animation.ExperimentalSharedTransitionApi
import androidx.compose.animation.SharedTransitionLayout
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Album
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QueueMusic
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.musiq.app.ui.library.LibraryGrid
import com.musiq.app.ui.nowplaying.NowPlayingScreen
import com.musiq.app.ui.player.PlayerBar

enum class LibrarySection(val label: String) { ALBUMS("Albums"), ARTISTS("Artists"), TRACKS("Tracks"), PLAYLISTS("Playlists") }

/**
 * Phone/tablet layout. `useNavigationRail` is decided once in
 * MainActivity from the window size class: `NavigationRail` on
 * tablets/landscape, bottom `NavigationBar` on phone portrait — the
 * broader library browser (equivalent to the desktop's resizeable
 * sidebar) lives behind `ModalNavigationDrawer`, opened from either nav
 * surface, since a permanently-docked sidebar doesn't fit phone widths.
 *
 * Wrapped in one `SharedTransitionLayout` so the tapped album cover in
 * `LibraryGrid`/`PlayerBar` and its enlarged counterpart in
 * `NowPlayingScreen` can share a `sharedElement` transition — the Compose
 * equivalent of the desktop's Windows "connected animation".
 */
@OptIn(ExperimentalSharedTransitionApi::class)
@Composable
fun MusiqMobileApp(useNavigationRail: Boolean) {
    var section by remember { mutableStateOf(LibrarySection.ALBUMS) }
    var nowPlayingExpanded by remember { mutableStateOf(false) }

    SharedTransitionLayout {
        ModalNavigationDrawer(drawerContent = { LibraryDrawerContent(section) { section = it } }) {
            Scaffold(
                bottomBar = { if (!useNavigationRail) MusiqBottomBar(section) { section = it } },
            ) { padding ->
                Row(modifier = Modifier.fillMaxSize().padding(padding)) {
                    if (useNavigationRail) {
                        MusiqNavigationRail(section) { section = it }
                    }
                    Box(modifier = Modifier.fillMaxSize()) {
                        if (nowPlayingExpanded) {
                            NowPlayingScreen(
                                sharedTransitionScope = this@SharedTransitionLayout,
                                onCollapse = { nowPlayingExpanded = false },
                            )
                        } else {
                            LibraryGrid(section = section)
                            PlayerBar(
                                sharedTransitionScope = this@SharedTransitionLayout,
                                onExpand = { nowPlayingExpanded = true },
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MusiqBottomBar(current: LibrarySection, onSelect: (LibrarySection) -> Unit) {
    NavigationBar {
        LibrarySection.entries.forEach { item ->
            NavigationBarItem(
                selected = item == current,
                onClick = { onSelect(item) },
                icon = { Icon(iconFor(item), contentDescription = item.label) },
                label = { Text(item.label) },
            )
        }
    }
}

@Composable
private fun MusiqNavigationRail(current: LibrarySection, onSelect: (LibrarySection) -> Unit) {
    NavigationRail {
        LibrarySection.entries.forEach { item ->
            NavigationRailItem(
                selected = item == current,
                onClick = { onSelect(item) },
                icon = { Icon(iconFor(item), contentDescription = item.label) },
                label = { Text(item.label) },
            )
        }
    }
}

@Composable
private fun LibraryDrawerContent(current: LibrarySection, onSelect: (LibrarySection) -> Unit) {
    // Full library tree (folders, smart/manual playlists, remote sources)
    // — the mobile equivalent of the desktop sidebar's contents, reached
    // via swipe-from-edge or the nav rail's menu icon rather than staying
    // permanently docked.
}

private fun iconFor(section: LibrarySection) = when (section) {
    LibrarySection.ALBUMS -> Icons.Filled.Album
    LibrarySection.ARTISTS -> Icons.Filled.Person
    LibrarySection.TRACKS -> Icons.Filled.LibraryMusic
    LibrarySection.PLAYLISTS -> Icons.Filled.QueueMusic
}
