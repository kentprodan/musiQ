import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Tauri expects a fixed dev server port and a relative build target so the
// packaged webview can load assets without an absolute URL.
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
  },
  build: {
    target: process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari13",
    outDir: "dist",
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },
});
