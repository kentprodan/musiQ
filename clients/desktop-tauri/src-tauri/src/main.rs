#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod os_theme;
mod commands;

use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_os::init())
        .plugin(tauri_plugin_window_state::Builder::default().build())
        .invoke_handler(tauri::generate_handler![
            commands::get_native_design,
            commands::playback_play,
            commands::playback_pause,
            commands::playback_seek,
            commands::get_waveform_peaks,
        ])
        .setup(|app| {
            let design = os_theme::detect();
            if let Some(window) = app.get_webview_window("main") {
                os_theme::apply_window_effect(&window, design);
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running musiQ");
}
