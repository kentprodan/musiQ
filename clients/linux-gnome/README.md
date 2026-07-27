# musiQ — GNOME client (placeholder)

Not implemented yet. Planned: GTK4 + Libadwaita (latest), following GNOME
HIG conventions natively rather than through a themed webview.

Will consume `core/musiq-core` through a Rust GTK binding (`gtk4-rs`)
calling directly into the core crate — Linux desktop clients can link
`musiq-core` in-process rather than crossing the UniFFI boundary, since
they share the same language.

Until this exists, Linux desktop users are served by the interim
[`clients/desktop-tauri`](../desktop-tauri) client. See
[`docs/architecture.md`](../../docs/architecture.md) for the overall plan.
