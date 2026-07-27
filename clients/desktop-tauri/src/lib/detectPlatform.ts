import { invoke } from "@tauri-apps/api/core";

export type NativeDesign =
  | "windows"
  | "macos"
  | "linux-gnome"
  | "linux-kde"
  | "linux-other";

/**
 * Asks the Rust side which native design language to render (see
 * `src-tauri/src/os_theme.rs`) and stamps it onto `<html data-os="...">`.
 * Every OS-scoped stylesheet (`os-windows.css`, `os-macos.css`, ...) is a
 * plain `[data-os="..."] { }` block, so this single attribute is the only
 * branch point between them — no conditional component trees, just CSS
 * cascade.
 *
 * Must run and resolve *before* React mounts (see `main.tsx`) so the first
 * paint already has the right tokens; otherwise the window would flash
 * with default/no design tokens for one frame.
 *
 * Falls back to a user-agent guess when there's no Tauri IPC bridge to
 * answer the command (e.g. this bundle loaded in a plain browser tab
 * during `vite dev`, rather than inside the packaged Tauri webview) —
 * bootstrap must never hang waiting on an `invoke` call that can't resolve.
 */
export async function detectAndApplyPlatform(): Promise<NativeDesign> {
  let design: NativeDesign;
  try {
    design = (await invoke<string>("get_native_design")) as NativeDesign;
  } catch {
    design = guessFromUserAgent();
  }
  document.documentElement.setAttribute("data-os", design);
  return design;
}

function guessFromUserAgent(): NativeDesign {
  const ua = navigator.userAgent;
  if (ua.includes("Win")) return "windows";
  if (ua.includes("Mac")) return "macos";
  if (ua.includes("Linux")) return "linux-gnome";
  return "linux-other";
}

export function currentDesign(): NativeDesign | null {
  return document.documentElement.getAttribute("data-os") as NativeDesign | null;
}
