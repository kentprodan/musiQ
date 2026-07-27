package com.musiq.app.tv

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.unit.dp
import androidx.tv.material3.Border
import androidx.tv.material3.Card
import androidx.tv.material3.CardDefaults
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.StandardCardContainer
import androidx.tv.material3.Text

/**
 * Android TV layout: grid-based, D-Pad-only input, no touch/hover — so
 * every card needs an explicit, highly visible focus state rather than
 * relying on a hover ring. `androidx.tv:tv-material`'s `Card` composables
 * already animate a focus border via `CardDefaults`/`Border`; this wires
 * those parameters up and adds a scale bump on top, rather than
 * hand-rolling D-Pad focus visuals from scratch.
 */
@Composable
fun MusiqTvApp() {
    LazyVerticalGrid(
        columns = GridCells.Fixed(5),
        contentPadding = PaddingValues(32.dp),
        horizontalArrangement = Arrangement.spacedBy(20.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
        modifier = Modifier.fillMaxSize(),
    ) {
        items(count = 24, key = { it }) { index ->
            TvAlbumCard(title = "Album ${index + 1}")
        }
    }
}

@Composable
private fun TvAlbumCard(title: String) {
    var focused by remember { mutableStateOf(false) }

    StandardCardContainer(
        modifier = Modifier
            .aspectRatio(0.82f)
            .scale(if (focused) 1.08f else 1f)
            .onFocusChanged { focused = it.isFocused },
        imageCard = { interactionSource ->
            Card(
                onClick = {},
                interactionSource = interactionSource,
                border = CardDefaults.border(
                    focusedBorder = Border(
                        border = BorderStroke(3.dp, MaterialTheme.colorScheme.primary),
                        shape = RoundedCornerShape(8.dp),
                    ),
                ),
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.secondaryContainer),
                )
            }
        },
        title = { Text(title) },
    )
}
