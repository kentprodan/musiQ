package com.musiq.app.ui.nowplaying

import androidx.compose.animation.ExperimentalSharedTransitionApi
import androidx.compose.animation.SharedTransitionScope
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import kotlin.math.abs

/**
 * Full-screen Now Playing. `coverCarousel` below is the Compose take on
 * the desktop's iTunes-style CoverFlow: same distance-based rotation/
 * scale/dim formula, expressed with `graphicsLayer { rotationY = ... }`
 * (Compose's 3D transform primitive) instead of CSS `rotateY`/`translateZ`,
 * driven by horizontal drag deltas instead of scroll-wheel/trackpad.
 */
@OptIn(ExperimentalSharedTransitionApi::class)
@Composable
fun NowPlayingScreen(
    sharedTransitionScope: SharedTransitionScope,
    onCollapse: () -> Unit,
) {
    Box(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface)) {
        IconButton(onClick = onCollapse, modifier = Modifier.align(Alignment.TopStart).padding(8.dp)) {
            Icon(Icons.Filled.KeyboardArrowDown, contentDescription = "Collapse")
        }
        CoverCarousel(modifier = Modifier.align(Alignment.Center))
    }
}

private const val ALBUM_COUNT = 14
private const val SIDE_ROTATION_DEGREES = 55f
private const val PX_PER_ALBUM = 260f

@Composable
private fun CoverCarousel(modifier: Modifier = Modifier) {
    var centerIndex by remember { mutableIntStateOf(0) }
    var dragAccumPx by remember { mutableIntStateOf(0) }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(1.6f)
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragEnd = { dragAccumPx = 0 },
                ) { change, dragAmount ->
                    change.consume()
                    dragAccumPx -= dragAmount.toInt()
                    val steps = dragAccumPx / PX_PER_ALBUM.toInt()
                    if (steps != 0) {
                        centerIndex = (centerIndex + steps).coerceIn(0, ALBUM_COUNT - 1)
                        dragAccumPx -= steps * PX_PER_ALBUM.toInt()
                    }
                }
            },
    ) {
        for (index in 0 until ALBUM_COUNT) {
            val offset = index - centerIndex
            if (abs(offset) > 5) continue
            CoverTile(offset = offset, modifier = Modifier.align(Alignment.Center))
        }
    }
}

@Composable
private fun CoverTile(offset: Int, modifier: Modifier = Modifier) {
    val sign = if (offset < 0) -1f else 1f
    val depth = abs(offset)

    Box(
        modifier = modifier
            .fillMaxWidth(0.42f)
            .aspectRatio(1f)
            .graphicsLayer {
                translationX = sign * (depth * PX_PER_ALBUM * 0.85f)
                rotationY = if (offset == 0) 0f else -sign * SIDE_ROTATION_DEGREES
                cameraDistance = 24f
                val scale = if (offset == 0) 1f else 0.82f
                scaleX = scale
                scaleY = scale
                alpha = (1f - depth * 0.16f).coerceAtLeast(0f)
            }
            .background(
                MaterialTheme.colorScheme.run { if (offset == 0) primary.copy(alpha = 0.5f) else secondaryContainer },
                RoundedCornerShape(10.dp),
            ),
    )
}
