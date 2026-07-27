//! Resolves *which* native design language the frontend should render.
//! `tauri-plugin-os` already gives the frontend a raw platform string, but
//! that's not fine-grained enough — Linux needs a second axis (GNOME vs.
//! KDE vs. unknown/fallback) that only the desktop environment's own env
//! vars expose. This module is the single source of truth both the Rust
//! side (for native window effects) and the frontend (for `data-os` /
//! `data-linux-de` attributes) read from.

use serde::Serialize;

// Every non-Windows variant is only ever constructed on its own target
// (see the `#[cfg(target_os = ...)]` arms in `detect()` below), so a
// single-platform build always reports the others as dead code — that's
// a cross-compilation artifact of checking one target at a time, not a
// real bug.
#[allow(dead_code)]
#[derive(Debug, Clone, Copy, Serialize, PartialEq, Eq)]
#[serde(rename_all = "kebab-case")]
pub enum NativeDesign {
    Windows,
    Macos,
    LinuxGnome,
    LinuxKde,
    /// Any other Linux DE (Xfce, Cinnamon, ...) falls back to the GNOME
    /// token set — flat, spacious, no compositor-specific blur assumptions.
    LinuxOther,
}

pub fn detect() -> NativeDesign {
    #[cfg(target_os = "windows")]
    {
        NativeDesign::Windows
    }
    #[cfg(target_os = "macos")]
    {
        NativeDesign::Macos
    }
    #[cfg(target_os = "linux")]
    {
        detect_linux_desktop_environment()
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        NativeDesign::LinuxOther
    }
}

#[cfg(target_os = "linux")]
fn detect_linux_desktop_environment() -> NativeDesign {
    let xdg = std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_default().to_lowercase();
    let session = std::env::var("DESKTOP_SESSION").unwrap_or_default().to_lowercase();
    let haystack = format!("{xdg} {session}");

    if haystack.contains("kde") || haystack.contains("plasma") {
        NativeDesign::LinuxKde
    } else if haystack.contains("gnome") {
        NativeDesign::LinuxGnome
    } else {
        NativeDesign::LinuxOther
    }
}

/// Applies the OS-native translucent window material. Called once on
/// window creation; the CSS layer (`os-windows.css` / `os-macos.css`) is
/// what actually paints Mica/Vibrancy-tinted surfaces on top of this —
/// this call is what makes the window background itself translucent so
/// those CSS surfaces have something real to blend with.
pub fn apply_window_effect(window: &tauri::WebviewWindow, design: NativeDesign) {
    match design {
        NativeDesign::Windows => {
            let _ = window_vibrancy::apply_mica(window, None);
        }
        NativeDesign::Macos => {
            let _ = window_vibrancy::apply_vibrancy(
                window,
                window_vibrancy::NSVisualEffectMaterial::Sidebar,
                None,
                None,
            );
        }
        NativeDesign::LinuxKde | NativeDesign::LinuxGnome | NativeDesign::LinuxOther => {
            // WebKitGTK has no first-party vibrancy hook. On KDE, KWin's own
            // compositor blur (configured system-side) shows through a
            // transparent webview automatically; GNOME gets a flat
            // translucent fallback painted entirely in CSS.
        }
    }
}
