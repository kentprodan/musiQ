package com.musiq.app.playback

import androidx.media3.session.MediaSessionService

/**
 * Hosts the Media3 `MediaSession` backing musiQ's playback — this is what
 * exposes transport controls to the lock screen, Android Auto, and Wear OS
 * tiles, and is the Android analogue of the desktop client's Windows SMTC /
 * macOS MPNowPlayingInfoCenter integration. Delegates actual decode/output
 * to `com.musiq.ffi.MusiqPlayer` (musiq-audio-engine over UniFFI) rather
 * than implementing playback itself.
 */
class MusiqPlaybackService : MediaSessionService() {
    override fun onGetSession(controllerInfo: androidx.media3.session.MediaSession.ControllerInfo) = null
}
