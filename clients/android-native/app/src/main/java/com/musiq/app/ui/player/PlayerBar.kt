package com.musiq.app.ui.player

import androidx.compose.animation.ExperimentalSharedTransitionApi
import androidx.compose.animation.SharedTransitionScope
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.SkipPrevious
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp

/**
 * Touch equivalent of the desktop's hover-driven Floating Player Bar:
 * there's no hover on a phone, so the waveform expands on the first touch
 * of a drag gesture and the transport controls blur out for the duration
 * of the scrub, collapsing back on release — same "waveform becomes the
 * sole focal point while scrubbing" language, translated to touch.
 *
 * `Modifier.blur` only renders on API 31+ (RenderEffect-backed); below
 * that it's a silent no-op, so pre-S devices just skip the blur and keep
 * the opacity dip.
 *
 * `sharedTransitionScope` is threaded through now so the cover here and
 * the enlarged one in `NowPlayingScreen` share a transition key once the
 * parent's expand/collapse toggle in `MusiqMobileApp` becomes an
 * `AnimatedContent` (shared elements need an `AnimatedVisibilityScope` to
 * animate within, which a plain boolean-gated `if` doesn't provide).
 */
@OptIn(ExperimentalSharedTransitionApi::class)
@Composable
fun PlayerBar(
    sharedTransitionScope: SharedTransitionScope,
    onExpand: () -> Unit,
) {
    var scrubbing by remember { mutableStateOf(false) }
    var progress by remember { mutableFloatStateOf(0.32f) }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(64.dp),
        shape = RoundedCornerShape(20.dp),
        tonalElevation = 6.dp,
        shadowElevation = 12.dp,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(horizontal = 12.dp)) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(MaterialTheme.colorScheme.primaryContainer, RoundedCornerShape(6.dp))
                    .blur(if (scrubbing) 6.dp else 0.dp)
                    .clickable(onClick = onExpand),
            )

            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(if (scrubbing) 40.dp else 4.dp)
                    .padding(horizontal = 12.dp)
                    .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(50))
                    .pointerInput(Unit) {
                        detectDragGestures(
                            onDragStart = { scrubbing = true },
                            onDragEnd = { scrubbing = false },
                            onDragCancel = { scrubbing = false },
                        ) { change, _ ->
                            progress = (change.position.x / size.width).coerceIn(0f, 1f)
                        }
                    },
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(progress)
                        .background(MaterialTheme.colorScheme.primary, RoundedCornerShape(50)),
                )
            }

            Row(modifier = Modifier.blur(if (scrubbing) 6.dp else 0.dp)) {
                IconButton(onClick = {}) { Icon(Icons.Filled.SkipPrevious, contentDescription = "Previous") }
                IconButton(onClick = {}) { Icon(Icons.Filled.PlayArrow, contentDescription = "Play") }
                IconButton(onClick = {}) { Icon(Icons.Filled.SkipNext, contentDescription = "Next") }
            }
        }
    }
}
