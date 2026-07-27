# musiQ — desktop-tauri (placeholder, interim engine)

Not implemented yet in this pass. A prior scaffold of a Tauri 2 + React
desktop client existed here and was intentionally removed to restart the
monorepo cleanly — see the `legacy-scaffold-backup` git branch if it's
ever needed for reference.

**Role in the architecture:** a temporary bridge for macOS and Linux
desktop only, used until their native clients (SwiftUI for macOS,
GTK4/Libadwaita for GNOME, Qt/Kirigami for KDE) exist. Windows never uses
this client — see [`clients/windows-winui`](../windows-winui) for the
native Windows shell. This engine is explicitly not the long-term
destination for any platform; see
[`docs/architecture.md`](../../docs/architecture.md).
