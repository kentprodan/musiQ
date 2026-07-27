package com.musiq.app

import android.app.Application

class MusiqApplication : Application() {
    // Holds the single MusiqPlayer instance (com.musiq.ffi.MusiqPlayer)
    // for the process's lifetime, mirroring how the Tauri desktop client
    // keeps one `musiq_core::Library` behind app state rather than
    // per-screen instances.
}
