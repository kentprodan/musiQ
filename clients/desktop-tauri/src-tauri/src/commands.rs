use crate::os_theme::{self, NativeDesign};

/// Called once on app boot, before React mounts, so `detectPlatform.ts` can
/// stamp `data-os` on `<html>` with zero flash-of-wrong-theme.
#[tauri::command]
pub fn get_native_design() -> NativeDesign {
    os_theme::detect()
}

#[tauri::command]
pub fn playback_play() -> Result<(), String> {
    Ok(())
}

#[tauri::command]
pub fn playback_pause() -> Result<(), String> {
    Ok(())
}

#[tauri::command]
pub fn playback_seek(position_ms: u64) -> Result<(), String> {
    let _ = position_ms;
    Ok(())
}

/// Returns the cached waveform peaks for a track (see
/// `musiq_audio_engine::waveform`), used by `WaveformSeekbar.tsx` to paint
/// the hover-expanded interactive seekbar without decoding audio in the
/// webview.
#[tauri::command]
pub fn get_waveform_peaks(track_id: String) -> Result<Vec<i8>, String> {
    let _ = track_id;
    Ok(Vec::new())
}
