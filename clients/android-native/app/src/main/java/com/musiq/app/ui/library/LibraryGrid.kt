package com.musiq.app.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.musiq.app.ui.LibrarySection

// Placeholder library data — replaced by a Flow<List<Album>> from
// musiq-core's repository queries (via MusiqPlayer/UniFFI) once the data
// layer is wired to the UI.
private data class AlbumSummary(val id: String, val title: String, val artist: String)

private val placeholderAlbums = List(18) { AlbumSummary("album-$it", "Untitled Album ${it + 1}", "Unknown Artist") }

/**
 * `LazyVerticalGrid` gets Android 12+'s stretch overscroll for free from
 * Compose Foundation — no extra plumbing needed, unlike the desktop
 * client where rubber-band scrolling is opted into per-platform in CSS.
 */
@Composable
fun LibraryGrid(section: LibrarySection) {
    LazyVerticalGrid(
        columns = GridCells.Adaptive(minSize = 140.dp),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(placeholderAlbums, key = { it.id }) { album ->
            AlbumCard(title = album.title, artist = album.artist)
        }
    }
}

@Composable
private fun AlbumCard(title: String, artist: String) {
    androidx.compose.foundation.layout.Column {
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .aspectRatio(1f)
                .background(MaterialTheme.colorScheme.secondaryContainer, RoundedCornerShape(8.dp)),
        )
        Text(title, style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(top = 6.dp))
        Text(artist, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
